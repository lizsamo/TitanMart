#!/bin/bash

# Create the titanmart-images S3 bucket
echo "Creating S3 bucket: titanmart-images..."
aws s3 mb s3://titanmart-images --region us-east-2

# Set public read access policy
echo "Setting bucket policy for public read access..."
aws s3api put-bucket-policy --bucket titanmart-images --region us-east-2 --policy '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::titanmart-images/*"
    }
  ]
}'

# Disable block public access
echo "Disabling block public access..."
aws s3api put-public-access-block --bucket titanmart-images --region us-east-2 --public-access-block-configuration \
  "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"

echo "✓ Bucket created and configured!"
echo "Now you can upload placeholder images to this bucket."
