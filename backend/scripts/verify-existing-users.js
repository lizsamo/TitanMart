/**
 * Script to verify all existing users in the database
 *
 * This script updates all users who have isEmailVerified set to false
 * and sets it to true. This is useful for grandfathering in existing users
 * when implementing email verification for the first time.
 *
 * Usage: node scripts/verify-existing-users.js
 */

require('dotenv').config();
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, ScanCommand, UpdateCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({ region: process.env.AWS_REGION });
const docClient = DynamoDBDocumentClient.from(client);

async function verifyExistingUsers() {
  try {
    console.log('Starting to verify existing users...\n');

    // Scan all users
    const scanResult = await docClient.send(new ScanCommand({
      TableName: process.env.DYNAMODB_USERS_TABLE
    }));

    if (!scanResult.Items || scanResult.Items.length === 0) {
      console.log('No users found in the database.');
      return;
    }

    console.log(`Found ${scanResult.Items.length} users in the database.\n`);

    let verifiedCount = 0;
    let alreadyVerifiedCount = 0;
    let errorCount = 0;

    // Update each user
    for (const user of scanResult.Items) {
      try {
        if (user.isEmailVerified) {
          console.log(`✓ ${user.csufEmail} - Already verified`);
          alreadyVerifiedCount++;
          continue;
        }

        // Update user to set isEmailVerified to true and remove verificationCode
        await docClient.send(new UpdateCommand({
          TableName: process.env.DYNAMODB_USERS_TABLE,
          Key: { csufEmail: user.csufEmail },
          UpdateExpression: 'SET isEmailVerified = :verified REMOVE verificationCode',
          ExpressionAttributeValues: {
            ':verified': true
          }
        }));

        console.log(`✓ ${user.csufEmail} - Verified successfully`);
        verifiedCount++;
      } catch (error) {
        console.error(`✗ ${user.csufEmail} - Error:`, error.message);
        errorCount++;
      }
    }

    console.log('\n--- Summary ---');
    console.log(`Total users: ${scanResult.Items.length}`);
    console.log(`Newly verified: ${verifiedCount}`);
    console.log(`Already verified: ${alreadyVerifiedCount}`);
    console.log(`Errors: ${errorCount}`);
    console.log('\nDone!');
  } catch (error) {
    console.error('Fatal error:', error);
    process.exit(1);
  }
}

// Run the script
verifyExistingUsers();
