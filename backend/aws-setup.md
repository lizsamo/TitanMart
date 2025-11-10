# AWS Infrastructure Setup for TitanMart

This guide will help you set up the AWS infrastructure for TitanMart.

## Prerequisites

1. AWS Account
2. AWS CLI installed and configured
3. Node.js 18.x or later
4. Serverless Framework (`npm install -g serverless`)

## Step 1: Configure AWS Credentials

```bash
aws configure
```

Enter your:
- AWS Access Key ID
- AWS Secret Access Key
- Default region (e.g., us-west-2)
- Default output format (json)

## Step 2: Install Dependencies

```bash
cd backend
npm install
```

## Step 3: Set Up Environment Variables

Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```

Update the values in `.env` with your actual credentials.

## Step 4: Deploy to AWS

Deploy the entire stack:
```bash
serverless deploy
```

This will create:
- DynamoDB tables for users, products, orders, and reviews
- S3 bucket for product images
- API Gateway endpoints
- Lambda functions
- IAM roles and policies

## Step 5: Set Up Stripe

1. Create a Stripe account at https://stripe.com
2. Get your API keys from the Stripe Dashboard
3. Add them to your `.env` file

## Step 6: Configure Email Service

For email verification, you can use:
- Gmail (with app password)
- AWS SES (Simple Email Service)
- SendGrid

Update SMTP settings in `.env`.

## Step 7: Update iOS App

After deployment, update the iOS app's `APIService.swift`:
```swift
private let baseURL = "https://your-api-gateway-url.amazonaws.com/dev"
```

## Security Best Practices

### 1. IAM Policies
The serverless.yml includes least-privilege IAM policies. Review and adjust as needed.

### 2. WAF (Web Application Firewall)
To add WAF protection:
```bash
aws wafv2 create-web-acl \
  --name titanmart-waf \
  --scope REGIONAL \
  --default-action Allow={} \
  --rules file://waf-rules.json
```

### 3. API Gateway Security
- Enable API keys for rate limiting
- Configure request validation
- Set up CORS properly

### 4. DynamoDB Encryption
All tables use encryption at rest by default.

### 5. S3 Security
- Enable bucket versioning
- Set up bucket policies
- Enable server-side encryption

## Monitoring and Alerts

### CloudWatch Alarms
```bash
# CPU utilization alarm
aws cloudwatch put-metric-alarm \
  --alarm-name titanmart-high-cpu \
  --alarm-description "Alert when CPU exceeds 80%" \
  --metric-name CPUUtilization \
  --namespace AWS/Lambda \
  --statistic Average \
  --period 300 \
  --evaluation-periods 2 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold

# API error rate alarm
aws cloudwatch put-metric-alarm \
  --alarm-name titanmart-api-errors \
  --alarm-description "Alert on API errors" \
  --metric-name 5XXError \
  --namespace AWS/ApiGateway \
  --statistic Sum \
  --period 60 \
  --evaluation-periods 1 \
  --threshold 5 \
  --comparison-operator GreaterThanThreshold
```

## Cost Optimization

1. Use DynamoDB on-demand pricing for variable workloads
2. Set up S3 lifecycle policies to move old images to Glacier
3. Monitor Lambda execution times and optimize
4. Use API Gateway caching for frequently accessed endpoints

## Testing

Test locally with serverless-offline:
```bash
npm run dev
```

## Troubleshooting

### Check Lambda Logs
```bash
serverless logs -f app -t
```

### Check DynamoDB Tables
```bash
aws dynamodb list-tables
aws dynamodb describe-table --table-name titanmart-users-dev
```

### Check API Gateway
```bash
aws apigateway get-rest-apis
```
