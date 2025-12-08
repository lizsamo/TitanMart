const express = require('express');
const router = express.Router();
const { v4: uuidv4 } = require('uuid');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand, ScanCommand, UpdateCommand } = require('@aws-sdk/lib-dynamodb');
const { authMiddleware } = require('../middleware/auth');

const client = new DynamoDBClient({ region: process.env.AWS_REGION });
const docClient = DynamoDBDocumentClient.from(client);

// Create new order
router.post('/', authMiddleware, async (req, res) => {
  try {
    const order = {
      ...req.body,
      id: uuidv4(),
      status: 'pending', /////////////////////////////////////////////////
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };
    
      
    // Create the order first
    await docClient.send(new PutCommand({
      TableName: process.env.DYNAMODB_ORDERS_TABLE,
      Item: order
    }));

    // Mark all products in the order as unavailable
    if (order.items && Array.isArray(order.items)) {
      const updatePromises = order.items.map(item => {
        const productId = item.product?.id || item.productId;
        if (productId) {
          return docClient.send(new UpdateCommand({
            TableName: process.env.DYNAMODB_PRODUCTS_TABLE,
            Key: { id: productId },
            UpdateExpression: 'SET isAvailable = :available',
            ExpressionAttributeValues: {
              ':available': false
            }
          }));
        }
        return Promise.resolve();
      });

      await Promise.all(updatePromises);
      console.log(`Marked ${updatePromises.length} products as unavailable for order ${order.id}`);
    }

    res.status(201).json(order);
  } catch (error) {
    console.error('Error creating order:', error);
    res.status(500).json({ message: 'Server error creating order' });
  }
});

// Get orders for a user
router.get('/user/:userId', authMiddleware, async (req, res) => {
  try {
    const result = await docClient.send(new ScanCommand({
      TableName: process.env.DYNAMODB_ORDERS_TABLE,
      FilterExpression: 'buyerId = :userId OR sellerId = :userId',
      ExpressionAttributeValues: {
        ':userId': req.params.userId
      }
    }));

    res.json(result.Items || []);
  } catch (error) {
    console.error('Error fetching orders:', error);
    res.status(500).json({ message: 'Server error fetching orders' });
  }
});

module.exports = router;
