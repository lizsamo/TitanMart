const { SESClient, SendEmailCommand } = require('@aws-sdk/client-ses');

const sesClient = new SESClient({ region: process.env.AWS_REGION || 'us-east-2' });

async function sendVerificationEmail(email, code, type = 'email-verification') {
  try {
    let subject, htmlBody;

    if (type === 'password-reset') {
      subject = 'Reset your TitanMart password';
      htmlBody = `
        <h1>Password Reset Request</h1>
        <p>Your password reset code is: <strong>${code}</strong></p>
        <p>This code will expire in 15 minutes.</p>
        <p>Please enter this code in the app to reset your password.</p>
        <p>If you didn't request a password reset, please ignore this email and your password will remain unchanged.</p>
      `;
    } else {
      subject = 'Verify your TitanMart account';
      htmlBody = `
        <h1>Welcome to TitanMart!</h1>
        <p>Your verification code is: <strong>${code}</strong></p>
        <p>Please enter this code in the app to verify your CSUF email.</p>
        <p>If you didn't create this account, please ignore this email.</p>
      `;
    }

    const params = {
      Source: 'lizsamon@csu.fullerton.edu', // Must be a verified email in SES
      Destination: {
        ToAddresses: [email]
      },
      Message: {
        Subject: {
          Data: subject,
          Charset: 'UTF-8'
        },
        Body: {
          Html: {
            Data: htmlBody,
            Charset: 'UTF-8'
          }
        }
      }
    };

    const command = new SendEmailCommand(params);
    await sesClient.send(command);
    console.log(`${type} email sent to:`, email);
  } catch (error) {
    console.error('Error sending email:', error);
    throw error; // Throw for password reset so user knows if email failed
  }
}

module.exports = { sendVerificationEmail };
