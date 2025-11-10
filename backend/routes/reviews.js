const express = require('express');
const router = express.Router();
const { v4: uuidv4 } = require('uuid');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand, ScanCommand } = require('@aws-sdk/lib-dynamodb');
const { authMiddleware } = require('../middleware/auth');

const client = new DynamoDBClient({ region: process.env.AWS_REGION });
const docClient = DynamoDBDocumentClient.from(client);

// Create new review
router.post('/', authMiddleware, async (req, res) => {
  try {
    const review = {
      ...req.body,
      id: uuidv4(),
      createdAt: new Date().toISOString()
    };

    await docClient.send(new PutCommand({
      TableName: process.env.DYNAMODB_REVIEWS_TABLE,
      Item: review
    }));

    res.status(201).json(review);
  } catch (error) {
    console.error('Error creating review:', error);
    res.status(500).json({ message: 'Server error creating review' });
  }
});

// Get reviews for a user
router.get('/user/:userId', async (req, res) => {
  try {
    const result = await docClient.send(new ScanCommand({
      TableName: process.env.DYNAMODB_REVIEWS_TABLE,
      FilterExpression: 'reviewedUserId = :userId',
      ExpressionAttributeValues: {
        ':userId': req.params.userId
      }
    }));

    res.json(result.Items || []);
  } catch (error) {
    console.error('Error fetching reviews:', error);
    res.status(500).json({ message: 'Server error fetching reviews' });
  }
});

module.exports = router;
