const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Routes
const uploadRoutes = require('./routes/upload');
const authRoutes = require('./routes/auth');
const productRoutes = require('./routes/products');
const orderRoutes = require('./routes/orders');
const reviewRoutes = require('./routes/reviews');
const paymentModule = require('./routes/payment'); // 👈 import the module

// Middleware
app.use(cors());

// Upload routes FIRST - no body parsing
app.use('/api/upload', uploadRoutes);

// 🔥 Stripe webhook route BEFORE express.json()
app.post(
  '/api/payment/webhook',
  express.raw({ type: 'application/json' }),
  paymentModule.handleStripeWebhook
);

// JSON parser for all other routes
app.use(express.json());

// Other routes
app.use('/api/auth', authRoutes);
app.use('/api/products', productRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/reviews', reviewRoutes);
app.use('/api/payment', paymentModule.router); // 👈 normal payment routes, including /create-intent

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

