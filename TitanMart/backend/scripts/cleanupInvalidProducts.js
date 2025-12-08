/**
 * Cleanup script to remove products with invalid seller IDs
 *
 * This script removes products where the sellerId doesn't match
 * the UUID format used by the authentication system.
 *
 * Usage: node cleanupInvalidProducts.js
 */

// Load environment variables from .env file
require('dotenv').config();

const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, ScanCommand, DeleteCommand } = require('@aws-sdk/lib-dynamodb');

// Configure AWS region
const client = new DynamoDBClient({ region: process.env.AWS_REGION || 'us-east-2' });
const docClient = DynamoDBDocumentClient.from(client);

const PRODUCTS_TABLE = process.env.DYNAMODB_PRODUCTS_TABLE || 'titanmart-api-products-dev';

// UUID v4 format pattern (8-4-4-4-12 hex characters)
const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

async function cleanupInvalidProducts() {
  try {
    console.log('🔍 Scanning for products with invalid seller IDs...\n');

    // Scan all products
    const scanResult = await docClient.send(new ScanCommand({
      TableName: PRODUCTS_TABLE
    }));

    const products = scanResult.Items || [];
    console.log(`Found ${products.length} total products in database`);

    // Find products with invalid seller IDs
    const invalidProducts = products.filter(product => {
      const sellerId = product.sellerId;
      return !sellerId || !UUID_PATTERN.test(sellerId);
    });

    console.log(`Found ${invalidProducts.length} products with invalid seller IDs:\n`);

    if (invalidProducts.length === 0) {
      console.log('✓ No invalid products found. Database is clean!');
      return;
    }

    // Display invalid products
    invalidProducts.forEach(product => {
      console.log(`  - "${product.title}" (ID: ${product.id})`);
      console.log(`    Invalid Seller ID: ${product.sellerId}`);
      console.log(`    Price: $${product.price}`);
      console.log('');
    });

    // Ask for confirmation (in a real script, you'd use readline or prompts)
    console.log('⚠️  WARNING: This will DELETE the above products from the database!');
    console.log('Run with CONFIRM=true environment variable to proceed:');
    console.log('CONFIRM=true node cleanupInvalidProducts.js\n');

    if (process.env.CONFIRM !== 'true') {
      console.log('Dry run completed. No products were deleted.');
      return;
    }

    // Delete invalid products
    console.log('🗑️  Deleting invalid products...\n');
    let deletedCount = 0;

    for (const product of invalidProducts) {
      try {
        await docClient.send(new DeleteCommand({
          TableName: PRODUCTS_TABLE,
          Key: { id: product.id }
        }));
        console.log(`✓ Deleted: ${product.title}`);
        deletedCount++;
      } catch (error) {
        console.error(`✗ Failed to delete ${product.title}:`, error.message);
      }
    }

    console.log(`\n✓ Cleanup completed! Deleted ${deletedCount} of ${invalidProducts.length} invalid products.`);

  } catch (error) {
    console.error('Error during cleanup:', error);
    process.exit(1);
  }
}

// Run the cleanup
cleanupInvalidProducts();
