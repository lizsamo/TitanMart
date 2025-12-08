const express = require('express');
const router = express.Router();
const { v4: uuidv4 } = require('uuid');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand, ScanCommand, GetCommand } = require('@aws-sdk/lib-dynamodb');
const { authMiddleware } = require('../middleware/auth');

const client = new DynamoDBClient({ region: process.env.AWS_REGION });
const docClient = DynamoDBDocumentClient.from(client);

// Get all products (with optional filtering)
router.get('/', async (req, res) => {
  try {
    const { category, search } = req.query;

    const params = {
      TableName: process.env.DYNAMODB_PRODUCTS_TABLE
    };

    // Add filter expressions if needed
    if (category || search) {
      params.FilterExpression = [];
      params.ExpressionAttributeValues = {};

      if (category) {
        params.FilterExpression.push('category = :category');
        params.ExpressionAttributeValues[':category'] = category;
      }

      if (search) {
        params.FilterExpression.push('contains(title, :search) OR contains(description, :search)');
        params.ExpressionAttributeValues[':search'] = search;
      }

      params.FilterExpression = params.FilterExpression.join(' AND ');
    }

    const result = await docClient.send(new ScanCommand(params));
    res.json(result.Items || []);
  } catch (error) {
    console.error('Error fetching products:', error);
    res.status(500).json({ message: 'Server error fetching products' });
  }
});

// Get single product
router.get('/:id', async (req, res) => {
  try {
    const result = await docClient.send(new GetCommand({
      TableName: process.env.DYNAMODB_PRODUCTS_TABLE,
      Key: { id: req.params.id }
    }));

    if (!result.Item) {
      return res.status(404).json({ message: 'Product not found' });
    }

    res.json(result.Item);
  } catch (error) {
    console.error('Error fetching product:', error);
    res.status(500).json({ message: 'Server error fetching product' });
  }
});

// Create new product (requires authentication)
router.post('/', authMiddleware, async (req, res) => {
  try {
    const product = {
      ...req.body,
      id: uuidv4(),
      sellerId: req.user.csufEmail,
      isAvailable: true,
      createdAt: new Date().toISOString()
    };

    await docClient.send(new PutCommand({
      TableName: process.env.DYNAMODB_PRODUCTS_TABLE,
      Item: product
    }));

    res.status(201).json(product);
  } catch (error) {
    console.error('Error creating product:', error);
    res.status(500).json({ message: 'Server error creating product' });
  }
});

module.exports = router;
