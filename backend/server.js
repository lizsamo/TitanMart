const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());

// Upload routes FIRST - no body parsing
app.use('/api/upload', require('./routes/upload'));

// JSON parser for all other routes
app.use(express.json());

// Other routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/products', require('./routes/products'));
app.use('/api/orders', require('./routes/orders'));
app.use('/api/reviews', require('./routes/reviews'));
app.use('/api/payment', require('./routes/payment'));

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'OK', message: 'TitanMart API is running' });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    error: 'Something went wrong!',
    message: err.message
  });
});

// For local development
if (process.env.NODE_ENV !== 'production') {
  app.listen(PORT, () => {
    console.log(`TitanMart API running on port ${PORT}`);
  });
}

// For AWS Lambda
const serverless = require('serverless-http');
module.exports.handler = serverless(app, {
  binary: ['image/*', 'multipart/form-data']
});
