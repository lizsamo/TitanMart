/**
 * Script to list all products in the database with their seller IDs
 */

require('dotenv').config();

const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, ScanCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({ region: process.env.AWS_REGION || 'us-east-2' });
const docClient = DynamoDBDocumentClient.from(client);

const PRODUCTS_TABLE = process.env.DYNAMODB_PRODUCTS_TABLE || 'titanmart-api-products-dev';

async function listProducts() {
  try {
    console.log(`📊 Listing all products from table: ${PRODUCTS_TABLE}\n`);

    const result = await docClient.send(new ScanCommand({
      TableName: PRODUCTS_TABLE
    }));

    const products = result.Items || [];
    console.log(`Found ${products.length} products:\n`);

    products.forEach((product, index) => {
      console.log(`${index + 1}. "${product.title}"`);
      console.log(`   Product ID: ${product.id}`);
      console.log(`   Seller ID: ${product.sellerId}`);
      console.log(`   Price: $${product.price}`);
      console.log(`   Category: ${product.category}`);
      console.log(`   Available: ${product.isAvailable}`);
      console.log('');
    });

  } catch (error) {
    console.error('Error listing products:', error);
    process.exit(1);
  }
}

listProducts();
