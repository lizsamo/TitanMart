// routes/payment.js
const express = require('express');
const router = express.Router();
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const { authMiddleware } = require('../middleware/auth');

const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, UpdateCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({ region: process.env.AWS_REGION });
const docClient = DynamoDBDocumentClient.from(client);

// === 1) Create payment intent (normal JSON route, behind auth) ===
router.post('/create-intent', authMiddleware, async (req, res) => {
  try {
    const { amount, orderId } = req.body;

    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(amount * 100), // dollars -> cents
      currency: 'usd',
      metadata: {
        orderId,
        userId: req.user.userId
      }
    });

    res.json({ clientSecret: paymentIntent.client_secret });
  } catch (error) {
    console.error('Error creating payment intent:', error);
    res.status(500).json({ message: 'Server error creating payment' });
  }
});

// === 2) Stripe webhook handler (needs RAW body, no auth) ===
async function handleStripeWebhook(req, res) {
  const sig = req.headers['stripe-signature'];

  let event;
  try {
    // req.body is a Buffer here because we use express.raw() in server.js
    event = stripe.webhooks.constructEvent(
      req.body,
      sig,
      process.env.STRIPE_WEBHOOK_SECRET
    );
  } catch (err) {
    console.error('Webhook signature verification failed:', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  console.log('Stripe webhook event type:', event.type);

  try {
    switch (event.type) {
      case 'payment_intent.succeeded': {
        const paymentIntent = event.data.object;
        const orderId = paymentIntent.metadata?.orderId;

        console.log('Payment succeeded for order:', orderId);

        if (orderId) {
          try {
            await docClient.send(new UpdateCommand({
              TableName: process.env.DYNAMODB_ORDERS_TABLE,
              Key: { id: orderId },
              UpdateExpression: 'SET #status = :status, updatedAt = :updatedAt',
              ExpressionAttributeNames: {
                '#status': 'status'
              },
              ExpressionAttributeValues: {
                ':status': 'completed',
                ':updatedAt': new Date().toISOString()
              }
            }));

            console.log('Order marked completed in DynamoDB:', orderId);
          } catch (dbError) {
            console.error('Error updating order status:', dbError);
          }
        } else {
          console.warn('Payment succeeded but no orderId in metadata');
        }
        break;
      }

      case 'payment_intent.payment_failed': {
        const paymentIntent = event.data.object;
        console.log('Payment failed for intent:', paymentIntent.id);
        break;
      }

      default:
        console.log(`Unhandled event type: ${event.type}`);
    }

    res.json({ received: true });
  } catch (err) {
    console.error('Webhook handler error:', err);
    res.status(500).send('Webhook handler error');
  }
}

module.exports = {
  router,
  handleStripeWebhook
};

