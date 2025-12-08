/**
 * Delete specific products with corrupted images
 * These products were created before the image upload fix
 */

require('dotenv').config();

const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, GetCommand, DeleteCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({ region: process.env.AWS_REGION || 'us-east-2' });
const docClient = DynamoDBDocumentClient.from(client);

const PRODUCTS_TABLE = process.env.DYNAMODB_PRODUCTS_TABLE || 'titanmart-api-products-dev';

// Products with corrupted images (created before 19:38 UTC with images)
const corruptedProductIds = [
  '1ae9087d-fdae-400d-8720-ca1fb2a6fed3', // Leaf
  'ac9fe98c-d740-4935-b205-88fbb0c9a4a5', // Flower 2
  'd9ff95a9-f3ba-425f-be8c-0e2c83506861', // Field
  '803e3c98-e835-4a97-b325-7617978c4431', // Water
  'ddf446dd-18e4-4414-8b09-fb023308011d'  // Fountain of Youth
];

async function deleteCorruptedProducts() {
  try {
    console.log('🗑️  Deleting products with corrupted images...\n');

    let deleted = 0;
    let notFound = 0;

    for (const productId of corruptedProductIds) {
      try {
        // First check if product exists
        const getResult = await docClient.send(new GetCommand({
          TableName: PRODUCTS_TABLE,
          Key: { id: productId }
        }));

        if (!getResult.Item) {
          console.log(`⚠️  Product not found: ${productId}`);
          notFound++;
          continue;
        }

        const productTitle = getResult.Item.title;

        if (process.env.CONFIRM !== 'true') {
          console.log(`📦 Would delete: ${productTitle} ($${getResult.Item.price})`);
          continue;
        }

        // Delete the product
        await docClient.send(new DeleteCommand({
          TableName: PRODUCTS_TABLE,
          Key: { id: productId }
        }));

        console.log(`✅ Deleted: ${productTitle} ($${getResult.Item.price})`);
        deleted++;

      } catch (error) {
        console.error(`❌ Error processing ${productId}:`, error.message);
      }
    }

    console.log(`\n📊 Summary:`);
    console.log(`  Checked: ${corruptedProductIds.length} products`);
    console.log(`  Deleted: ${deleted}`);
    console.log(`  Not found: ${notFound}`);

    if (process.env.CONFIRM !== 'true') {
      console.log('\n⚠️  Dry run complete. Run with CONFIRM=true to delete:');
      console.log('CONFIRM=true node scripts/deleteCorruptedProducts.js');
    } else {
      console.log('\n✅ Cleanup complete!');
    }

  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

deleteCorruptedProducts();
