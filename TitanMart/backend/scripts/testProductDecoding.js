/**
 * Test script to verify API response matches iOS expectations
 */

const https = require('https');

https.get('https://r3iarn2t5h.execute-api.us-east-2.amazonaws.com/dev/api/products', (res) => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    const products = JSON.parse(data);

    console.log('✓ Successfully fetched', products.length, 'products\n');

    // Check first product structure
    if (products.length > 0) {
      const product = products[0];
      console.log('Sample Product Structure:');
      console.log('  title:', product.title);
      console.log('  id:', product.id);
      console.log('  description:', product.description);
      console.log('  price:', product.price);
      console.log('  category:', product.category);
      console.log('  condition:', product.condition);
      console.log('  imageURLs:', Array.isArray(product.imageURLs) ? `array(${product.imageURLs.length})` : 'missing');
      console.log('  sellerId:', product.sellerId);
      console.log('  sellerName:', product.sellerName);
      console.log('  sellerRating:', product.sellerRating !== undefined ? product.sellerRating : '(missing - OPTIONAL)');
      console.log('  isAvailable:', product.isAvailable);
      console.log('  createdAt:', product.createdAt);
      console.log('  location:', product.location);

      // Check for any unexpected fields
      const expectedFields = ['id', 'title', 'description', 'price', 'category', 'condition',
                              'imageURLs', 'sellerId', 'sellerName', 'sellerRating',
                              'isAvailable', 'createdAt', 'location'];
      const actualFields = Object.keys(product);
      const unexpectedFields = actualFields.filter(f => !expectedFields.includes(f));

      if (unexpectedFields.length > 0) {
        console.log('\n⚠️  Unexpected fields:', unexpectedFields);
      } else {
        console.log('\n✓ All fields match expected structure');
      }

      // Check categories
      console.log('\n📊 Categories found in database:');
      const categories = [...new Set(products.map(p => p.category))];
      categories.forEach(cat => {
        console.log(`  - ${cat}`);
      });

      // Check conditions
      console.log('\n📊 Conditions found in database:');
      const conditions = [...new Set(products.map(p => p.condition))];
      conditions.forEach(cond => {
        console.log(`  - ${cond}`);
      });
    }
  });
}).on('error', err => {
  console.error('Error:', err);
});
