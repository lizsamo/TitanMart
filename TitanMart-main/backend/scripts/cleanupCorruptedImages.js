/**
 * Clean up products with corrupted images
 *
 * This script:
 * 1. Scans all products
 * 2. Downloads and checks if images are valid JPEGs
 * 3. Deletes products with corrupted images
 */

require('dotenv').config();
const https = require('https');

const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, ScanCommand, DeleteCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({ region: process.env.AWS_REGION || 'us-east-2' });
const docClient = DynamoDBDocumentClient.from(client);

const PRODUCTS_TABLE = process.env.DYNAMODB_PRODUCTS_TABLE || 'titanmart-api-products-dev';

// Check if image is corrupted by checking JPEG header
function checkImageValidity(url) {
  return new Promise((resolve, reject) => {
    const timeout = setTimeout(() => {
      resolve({ valid: false, reason: 'Timeout' });
    }, 5000); // 5 second timeout

    const req = https.get(url, (res) => {
      clearTimeout(timeout);
      if (res.statusCode !== 200) {
        resolve({ valid: false, reason: `HTTP ${res.statusCode}` });
        return;
      }

      const chunks = [];
      let bytesRead = 0;
      const maxBytes = 20; // Only need first 20 bytes to check header

      res.on('data', (chunk) => {
        if (bytesRead < maxBytes) {
          chunks.push(chunk);
          bytesRead += chunk.length;

          // Stop reading after we have enough bytes
          if (bytesRead >= maxBytes) {
            res.destroy();
          }
        }
      });

      res.on('end', () => {
        const buffer = Buffer.concat(chunks);

        // Valid JPEG starts with FFD8
        if (buffer[0] === 0xFF && buffer[1] === 0xD8) {
          resolve({ valid: true });
        } else {
          // Check if it's the corrupted UTF-8 pattern (EFBFBD)
          if (buffer[0] === 0xEF && buffer[1] === 0xBF && buffer[2] === 0xBD) {
            resolve({ valid: false, reason: 'Corrupted (UTF-8 encoding error)' });
          } else {
            resolve({ valid: false, reason: 'Invalid JPEG header' });
          }
        }
      });

      res.on('error', (err) => {
        clearTimeout(timeout);
        resolve({ valid: false, reason: err.message });
      });
    }).on('error', (err) => {
      clearTimeout(timeout);
      resolve({ valid: false, reason: err.message });
    });

    req.setTimeout(5000, () => {
      req.destroy();
      resolve({ valid: false, reason: 'Request timeout' });
    });
  });
}

async function cleanupCorruptedImages() {
  try {
    console.log('🔍 Scanning for products with corrupted images...\n');

    // Get all products
    const scanResult = await docClient.send(new ScanCommand({
      TableName: PRODUCTS_TABLE
    }));

    const products = scanResult.Items || [];
    console.log(`Found ${products.length} total products\n`);

    const corruptedProducts = [];

    // Check each product's images
    for (const product of products) {
      if (!product.imageURLs || product.imageURLs.length === 0) {
        console.log(`⚪ ${product.title}: No images (skipping)`);
        continue;
      }

      const firstImageUrl = product.imageURLs[0];
      console.log(`🔎 Checking ${product.title}...`);

      const result = await checkImageValidity(firstImageUrl);

      if (result.valid) {
        console.log(`  ✅ Valid image`);
      } else {
        console.log(`  ❌ Corrupted: ${result.reason}`);
        corruptedProducts.push(product);
      }
    }

    console.log(`\n📊 Summary:`);
    console.log(`  Total products: ${products.length}`);
    console.log(`  Corrupted: ${corruptedProducts.length}`);
    console.log(`  Valid: ${products.length - corruptedProducts.length}\n`);

    if (corruptedProducts.length === 0) {
      console.log('✓ No corrupted images found!');
      return;
    }

    console.log('Products to delete:');
    corruptedProducts.forEach(p => {
      console.log(`  - ${p.title} ($${p.price})`);
    });

    if (process.env.CONFIRM !== 'true') {
      console.log('\n⚠️  Run with CONFIRM=true to delete:');
      console.log('CONFIRM=true node scripts/cleanupCorruptedImages.js\n');
      return;
    }

    console.log('\n🗑️  Deleting corrupted products...\n');

    for (const product of corruptedProducts) {
      await docClient.send(new DeleteCommand({
        TableName: PRODUCTS_TABLE,
        Key: { id: product.id }
      }));
      console.log(`✓ Deleted: ${product.title}`);
    }

    console.log(`\n✅ Cleanup complete! Deleted ${corruptedProducts.length} products with corrupted images.`);

  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

cleanupCorruptedImages();
