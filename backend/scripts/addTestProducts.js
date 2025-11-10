const https = require('https');

const products = [
  {
    title: 'MacBook Air M2',
    description: 'Lightly used MacBook Air with M2 chip, 8GB RAM, 256GB SSD. Perfect condition, includes charger.',
    price: 899.99,
    category: 'Electronics',
    condition: 'Like New',
    imageURLs: ['https://titanmart-images.s3.us-east-2.amazonaws.com/macbook-placeholder.jpg'],
    sellerId: 'd6a518c5-817f-450d-af61-7bdd31946fd1',
    sellerName: 'Test Seller',
    isAvailable: true,
    location: 'CSUF Campus'
  },
  {
    title: 'Calculus Textbook - 8th Edition',
    description: 'Calculus: Early Transcendentals by James Stewart. Great condition, no highlighting.',
    price: 45.00,
    category: 'Books',
    condition: 'Good',
    imageURLs: ['https://titanmart-images.s3.us-east-2.amazonaws.com/textbook-placeholder.jpg'],
    sellerId: 'd6a518c5-817f-450d-af61-7bdd31946fd1',
    sellerName: 'Test Seller',
    isAvailable: true,
    location: 'CSUF Library'
  },
  {
    title: 'Desk Lamp with USB Charging',
    description: 'Modern LED desk lamp with adjustable brightness and USB charging port. Perfect for dorm room.',
    price: 25.00,
    category: 'Furniture',
    condition: 'Like New',
    imageURLs: ['https://titanmart-images.s3.us-east-2.amazonaws.com/lamp-placeholder.jpg'],
    sellerId: 'd6a518c5-817f-450d-af61-7bdd31946fd1',
    sellerName: 'Test Seller',
    isAvailable: true,
    location: 'CSUF Housing'
  },
  {
    title: 'Wireless Headphones Sony WH-1000XM4',
    description: 'Premium noise-canceling headphones. Barely used, includes case and charging cable.',
    price: 199.99,
    category: 'Electronics',
    condition: 'Like New',
    imageURLs: ['https://titanmart-images.s3.us-east-2.amazonaws.com/headphones-placeholder.jpg'],
    sellerId: 'd6a518c5-817f-450d-af61-7bdd31946fd1',
    sellerName: 'Test Seller',
    isAvailable: true,
    location: 'CSUF Campus'
  }
];

async function createProducts() {
  // First login to get token
  const loginData = JSON.stringify({
    email: 'seller@example.com',
    password: 'password123'
  });

  const loginOptions = {
    hostname: 'r3iarn2t5h.execute-api.us-east-2.amazonaws.com',
    path: '/dev/api/auth/login',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': loginData.length
    }
  };

  return new Promise((resolve, reject) => {
    const loginReq = https.request(loginOptions, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', async () => {
        if (res.statusCode !== 200) {
          console.error('Login failed:', data);
          reject(new Error('Login failed'));
          return;
        }

        const result = JSON.parse(data);
        const token = result.token;
        console.log('Successfully logged in!');

        // Create each product
        for (let i = 0; i < products.length; i++) {
          const product = products[i];
          await new Promise((resolveProduct, rejectProduct) => {
            const productData = JSON.stringify(product);
            const options = {
              hostname: 'r3iarn2t5h.execute-api.us-east-2.amazonaws.com',
              path: '/dev/api/products',
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                'Content-Length': productData.length,
                'Authorization': `Bearer ${token}`
              }
            };

            const req = https.request(options, (res) => {
              let data = '';
              res.on('data', (chunk) => { data += chunk; });
              res.on('end', () => {
                if (res.statusCode === 201 || res.statusCode === 200) {
                  console.log(`✓ Created: ${product.title} ($${product.price})`);
                  resolveProduct();
                } else {
                  console.error(`✗ Failed to create ${product.title}:`, data);
                  rejectProduct(new Error(data));
                }
              });
            });

            req.on('error', (e) => {
              console.error(`Error creating ${product.title}:`, e);
              rejectProduct(e);
            });

            req.write(productData);
            req.end();
          });
        }

        console.log('\n✓ All test products created successfully!');
        resolve();
      });
    });

    loginReq.on('error', (e) => {
      console.error('Login error:', e);
      reject(e);
    });

    loginReq.write(loginData);
    loginReq.end();
  });
}

createProducts().catch(console.error);
