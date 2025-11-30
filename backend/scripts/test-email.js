/**
 * Test script to verify email sending works
 *
 * Usage: node scripts/test-email.js YOUR_EMAIL@csu.fullerton.edu
 */

require('dotenv').config();
const { sendVerificationEmail } = require('../utils/email');

async function testEmail() {
  const testEmail = process.argv[2];

  if (!testEmail) {
    console.error('Usage: node scripts/test-email.js YOUR_EMAIL@csu.fullerton.edu');
    process.exit(1);
  }

  console.log(`Attempting to send test verification email to: ${testEmail}`);
  console.log(`AWS Region: ${process.env.AWS_REGION}`);
  console.log(`From email: lizsamon@csu.fullerton.edu\n`);

  try {
    const testCode = '123456';
    await sendVerificationEmail(testEmail, testCode);
    console.log('\n✅ SUCCESS! Email sent successfully.');
    console.log('Check your inbox (and spam folder) for the verification email.');
  } catch (error) {
    console.error('\n❌ FAILED! Error sending email:');
    console.error('Error code:', error.code);
    console.error('Error message:', error.message);
    console.error('\nFull error:', error);

    if (error.code === 'MessageRejected' || error.message.includes('not verified')) {
      console.log('\n📧 AWS SES is likely in SANDBOX MODE.');
      console.log('Solutions:');
      console.log('1. Verify the recipient email in AWS SES console');
      console.log('2. Request production access for SES');
      console.log('\nTo verify an email in SES:');
      console.log('- Go to: https://console.aws.amazon.com/ses/');
      console.log('- Click "Verified identities"');
      console.log('- Click "Create identity"');
      console.log('- Choose "Email address" and enter:', testEmail);
      console.log('- Check that email inbox for verification link');
    }
  }
}

testEmail();
