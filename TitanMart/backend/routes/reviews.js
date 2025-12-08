const express = require('express');
const router = express.Router();
const { v4: uuidv4 } = require('uuid');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand, GetCommand, QueryCommand, UpdateCommand } = require('@aws-sdk/lib-dynamodb');
const { authMiddleware } = require('../middleware/auth');

const client = new DynamoDBClient({ region: process.env.AWS_REGION });
const docClient = DynamoDBDocumentClient.from(client);

// Check if user can review another user (must have completed order together)
router.get('/can-review/:orderId/:reviewedUserId', authMiddleware, async (req, res) => {
  try {
    const { orderId, reviewedUserId } = req.params;
    const reviewerId = req.user.csufEmail;

    // Get the order
    const orderResult = await docClient.send(new GetCommand({
      TableName: process.env.DYNAMODB_ORDERS_TABLE,
      Key: { id: orderId }
    }));

    if (!orderResult.Item) {
      return res.status(404).json({ message: 'Order not found' });
    }

    const order = orderResult.Item;

    // Check if order is completed
    if (order.status.toLowerCase() !== 'completed') {
      return res.json({
        canReview: false,
        reason: 'Order must be completed before leaving a review'
      });
    }

    // Check if reviewer is part of the order (buyer or seller)
    const isPartOfOrder = order.buyerId === reviewerId || order.sellerId === reviewerId;
    if (!isPartOfOrder) {
      return res.json({
        canReview: false,
        reason: 'You are not part of this order'
      });
    }

    // Check if the reviewed user is the other party in the order
    const isOtherParty = (order.buyerId === reviewedUserId && order.sellerId === reviewerId) ||
                         (order.sellerId === reviewedUserId && order.buyerId === reviewerId);
    if (!isOtherParty) {
      return res.json({
        canReview: false,
        reason: 'You can only review the other party in the transaction'
      });
    }

    // Check if review already exists for this order and reviewer
    const existingReviewResult = await docClient.send(new QueryCommand({
      TableName: process.env.DYNAMODB_REVIEWS_TABLE,
      IndexName: 'OrderIndex',
      KeyConditionExpression: 'orderId = :orderId',
      FilterExpression: 'reviewerId = :reviewerId AND reviewedUserId = :reviewedUserId',
      ExpressionAttributeValues: {
        ':orderId': orderId,
        ':reviewerId': reviewerId,
        ':reviewedUserId': reviewedUserId
      }
    }));

    if (existingReviewResult.Items && existingReviewResult.Items.length > 0) {
      return res.json({
        canReview: false,
        reason: 'You have already reviewed this user for this order'
      });
    }

    res.json({ canReview: true });
  } catch (error) {
    console.error('Error checking review eligibility:', error);
    res.status(500).json({ message: 'Server error checking review eligibility' });
  }
});

// Create new review and update user rating
router.post('/', authMiddleware, async (req, res) => {
  try {
    const { rating, comment, reviewedUserId, orderId } = req.body;
    const reviewerId = req.user.csufEmail;
    const reviewerUsername = req.user.username;

    // Validate required fields
    if (!rating || !reviewedUserId || !orderId) {
      return res.status(400).json({
        message: 'Rating, reviewedUserId, and orderId are required'
      });
    }

    // Validate rating (1-5)
    if (rating < 1 || rating > 5) {
      return res.status(400).json({ message: 'Rating must be between 1 and 5' });
    }

    // Get the order to verify eligibility
    const orderResult = await docClient.send(new GetCommand({
      TableName: process.env.DYNAMODB_ORDERS_TABLE,
      Key: { id: orderId }
    }));

    if (!orderResult.Item) {
      return res.status(404).json({ message: 'Order not found' });
    }

    const order = orderResult.Item;

    // Verify order is completed
    if (order.status.toLowerCase() !== 'completed') {
      return res.status(400).json({ message: 'Order must be completed to leave a review' });
    }

    // Verify reviewer is part of the order
    const isPartOfOrder = order.buyerId === reviewerId || order.sellerId === reviewerId;
    if (!isPartOfOrder) {
      return res.status(403).json({ message: 'You are not part of this order' });
    }

    // Verify the reviewed user is the other party
    const isOtherParty = (order.buyerId === reviewedUserId && order.sellerId === reviewerId) ||
                         (order.sellerId === reviewedUserId && order.buyerId === reviewerId);
    if (!isOtherParty) {
      return res.status(400).json({ message: 'You can only review the other party in the transaction' });
    }

    // Check if review already exists
    const existingReviewResult = await docClient.send(new QueryCommand({
      TableName: process.env.DYNAMODB_REVIEWS_TABLE,
      IndexName: 'OrderIndex',
      KeyConditionExpression: 'orderId = :orderId',
      FilterExpression: 'reviewerId = :reviewerId AND reviewedUserId = :reviewedUserId',
      ExpressionAttributeValues: {
        ':orderId': orderId,
        ':reviewerId': reviewerId,
        ':reviewedUserId': reviewedUserId
      }
    }));

    if (existingReviewResult.Items && existingReviewResult.Items.length > 0) {
      return res.status(400).json({ message: 'You have already reviewed this user for this order' });
    }

    // Get reviewer's full name
    const reviewerResult = await docClient.send(new GetCommand({
      TableName: process.env.DYNAMODB_USERS_TABLE,
      Key: { csufEmail: reviewerId }
    }));

    const reviewerName = reviewerResult.Item?.fullName || reviewerUsername;

    // Create review
    const review = {
      id: uuidv4(),
      rating: parseInt(rating),
      comment: comment || '',
      reviewerId,
      reviewerName,
      reviewedUserId,
      orderId,
      createdAt: new Date().toISOString()
    };

    await docClient.send(new PutCommand({
      TableName: process.env.DYNAMODB_REVIEWS_TABLE,
      Item: review
    }));

    // Update reviewed user's rating
    const reviewedUserResult = await docClient.send(new GetCommand({
      TableName: process.env.DYNAMODB_USERS_TABLE,
      Key: { csufEmail: reviewedUserId }
    }));

    if (reviewedUserResult.Item) {
      const currentRating = reviewedUserResult.Item.rating || 0;
      const currentTotalRatings = reviewedUserResult.Item.totalRatings || 0;

      // Calculate new average rating
      const newTotalRatings = currentTotalRatings + 1;
      const newRating = ((currentRating * currentTotalRatings) + rating) / newTotalRatings;

      await docClient.send(new UpdateCommand({
        TableName: process.env.DYNAMODB_USERS_TABLE,
        Key: { csufEmail: reviewedUserId },
        UpdateExpression: 'SET rating = :rating, totalRatings = :totalRatings',
        ExpressionAttributeValues: {
          ':rating': newRating,
          ':totalRatings': newTotalRatings
        }
      }));
    }

    res.status(201).json(review);
  } catch (error) {
    console.error('Error creating review:', error);
    res.status(500).json({ message: 'Server error creating review' });
  }
});

// Get reviews for a user
router.get('/user/:userId', async (req, res) => {
  try {
    const result = await docClient.send(new QueryCommand({
      TableName: process.env.DYNAMODB_REVIEWS_TABLE,
      IndexName: 'ReviewedUserIndex',
      KeyConditionExpression: 'reviewedUserId = :userId',
      ExpressionAttributeValues: {
        ':userId': req.params.userId
      },
      ScanIndexForward: false // Most recent first
    }));

    res.json(result.Items || []);
  } catch (error) {
    console.error('Error fetching reviews:', error);
    res.status(500).json({ message: 'Server error fetching reviews' });
  }
});

// Get reviews for a specific order
router.get('/order/:orderId', authMiddleware, async (req, res) => {
  try {
    const result = await docClient.send(new QueryCommand({
      TableName: process.env.DYNAMODB_REVIEWS_TABLE,
      IndexName: 'OrderIndex',
      KeyConditionExpression: 'orderId = :orderId',
      ExpressionAttributeValues: {
        ':orderId': req.params.orderId
      }
    }));

    res.json(result.Items || []);
  } catch (error) {
    console.error('Error fetching order reviews:', error);
    res.status(500).json({ message: 'Server error fetching order reviews' });
  }
});

module.exports = router;
