/**
 * Script to unverify all users in the database
 *
 * This script updates all users to have isEmailVerified set to false,
 * forcing them to verify their email on next login.
 *
 * Usage: node scripts/unverify-all-users.js
 */

require('dotenv').config();
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, ScanCommand, UpdateCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({ region: process.env.AWS_REGION });
const docClient = DynamoDBDocumentClient.from(client);

async function unverifyAllUsers() {
  try {
    console.log('Starting to unverify all users...\n');

    // Scan all users
    const scanResult = await docClient.send(new ScanCommand({
      TableName: process.env.DYNAMODB_USERS_TABLE
    }));

    if (!scanResult.Items || scanResult.Items.length === 0) {
      console.log('No users found in the database.');
      return;
    }

    console.log(`Found ${scanResult.Items.length} users in the database.\n`);

    let unverifiedCount = 0;
    let alreadyUnverifiedCount = 0;
    let errorCount = 0;

    // Update each user
    for (const user of scanResult.Items) {
      try {
        if (!user.isEmailVerified) {
          console.log(`✓ ${user.csufEmail} - Already unverified`);
          alreadyUnverifiedCount++;
          continue;
        }

        // Update user to set isEmailVerified to false
        await docClient.send(new UpdateCommand({
          TableName: process.env.DYNAMODB_USERS_TABLE,
          Key: { csufEmail: user.csufEmail },
          UpdateExpression: 'SET isEmailVerified = :unverified',
          ExpressionAttributeValues: {
            ':unverified': false
          }
        }));

        console.log(`✓ ${user.csufEmail} - Set to unverified`);
        unverifiedCount++;
      } catch (error) {
        console.error(`✗ ${user.csufEmail} - Error:`, error.message);
        errorCount++;
      }
    }

    console.log('\n--- Summary ---');
    console.log(`Total users: ${scanResult.Items.length}`);
    console.log(`Newly unverified: ${unverifiedCount}`);
    console.log(`Already unverified: ${alreadyUnverifiedCount}`);
    console.log(`Errors: ${errorCount}`);
    console.log('\nDone! All users will need to verify their email on next login.');
  } catch (error) {
    console.error('Fatal error:', error);
    process.exit(1);
  }
}

// Run the script
unverifyAllUsers();
