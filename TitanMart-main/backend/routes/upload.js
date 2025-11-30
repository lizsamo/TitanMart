const express = require('express');
const router = express.Router();
const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');
const { authMiddleware } = require('../middleware/auth');
const multer = require('multer');
const { v4: uuidv4 } = require('uuid');

// Configure S3 client
const s3Client = new S3Client({ region: process.env.AWS_REGION });

// Configure multer for memory storage
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit per file
  },
  fileFilter: (req, file, cb) => {
    // Accept images only
    if (!file.mimetype.startsWith('image/')) {
      return cb(new Error('Only image files are allowed!'), false);
    }
    cb(null, true);
  }
});

// Upload single image
router.post('/image', authMiddleware, upload.single('image'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'No file uploaded' });
    }

    // Generate unique filename
    const fileExtension = req.file.originalname.split('.').pop();
    const fileName = `${uuidv4()}.${fileExtension}`;
    const key = `products/${req.user.csufEmail}/${fileName}`;

    // Upload to S3
    const command = new PutObjectCommand({
      Bucket: process.env.S3_BUCKET_NAME,
      Key: key,
      Body: req.file.buffer,
      ContentType: req.file.mimetype
    });

    await s3Client.send(command);

    // Return the public URL
    const imageUrl = `https://${process.env.S3_BUCKET_NAME}.s3.${process.env.AWS_REGION}.amazonaws.com/${key}`;

    res.json({
      message: 'Image uploaded successfully',
      url: imageUrl
    });
  } catch (error) {
    console.error('Error uploading image:', error);
    res.status(500).json({ message: 'Server error uploading image' });
  }
});

// Upload multiple images
router.post('/images', authMiddleware, upload.array('images', 5), async (req, res) => {
  try {
    if (!req.files || req.files.length === 0) {
      return res.status(400).json({ message: 'No files uploaded' });
    }

    const uploadPromises = req.files.map(async (file) => {
      const fileExtension = file.originalname.split('.').pop();
      const fileName = `${uuidv4()}.${fileExtension}`;
      const key = `products/${req.user.csufEmail}/${fileName}`;

      const command = new PutObjectCommand({
        Bucket: process.env.S3_BUCKET_NAME,
        Key: key,
        Body: file.buffer,
        ContentType: file.mimetype
      });

      await s3Client.send(command);

      return `https://${process.env.S3_BUCKET_NAME}.s3.${process.env.AWS_REGION}.amazonaws.com/${key}`;
    });

    const imageUrls = await Promise.all(uploadPromises);

    res.json({
      message: 'Images uploaded successfully',
      urls: imageUrls
    });
  } catch (error) {
    console.error('Error uploading images:', error);
    res.status(500).json({ message: 'Server error uploading images' });
  }
});

module.exports = router;
