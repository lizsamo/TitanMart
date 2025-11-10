/**
 * Fix products with broken image URLs by setting them to empty arrays
 */

require('dotenv').config();

const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, ScanCommand, UpdateCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({ region: process.env.AWS_REGION || 'us-east-2' });
const docClient = DynamoDBDocumentClient.from(client);

const PRODUCTS_TABLE = process.env.DYNAMODB_PRODUCTS_TABLE || 'titanmart-api-products-dev';

async function fixProductImages() {
  try {
    console.log('🔍 Scanning for products with broken image URLs...\n');

    const result = await docClient.send(new ScanCommand({
      TableName: PRODUCTS_TABLE
    }));

    const products = result.Items || [];

    // Find products with titanmart-images bucket URLs (non-existent bucket)
    const brokenProducts = products.filter(p =>
      p.imageURLs &&
      p.imageURLs.some(url => url.includes('titanmart-images.s3'))
    );

    console.log(`Found ${brokenProducts.length} products with broken image URLs:\n`);

    if (brokenProducts.length === 0) {
      console.log('✓ No broken image URLs found!');
      return;
    }

    brokenProducts.forEach(p => {
      console.log(`  - ${p.title}`);
      console.log(`    Current URLs: ${p.imageURLs.join(', ')}`);
    });

    if (process.env.CONFIRM !== 'true') {
      console.log('\n⚠️  Dry run mode. Run with CONFIRM=true to update:');
      console.log('CONFIRM=true node scripts/fixProductImages.js\n');
      return;
    }

    console.log('\n🔧 Updating products...\n');

    for (const product of brokenProducts) {
      await docClient.send(new UpdateCommand({
        TableName: PRODUCTS_TABLE,
        Key: { id: product.id },
        UpdateExpression: 'SET imageURLs = :empty',
        ExpressionAttributeValues: {
          ':empty': []
        }
      }));
      console.log(`✓ Updated: ${product.title}`);
    }

    console.log(`\n✓ Fixed ${brokenProducts.length} products!`);
    console.log('Note: Products will now show placeholder images until real images are uploaded.');

  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

fixProductImages();
