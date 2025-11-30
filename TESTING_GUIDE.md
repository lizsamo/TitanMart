# TitanMart Testing Guide

### Step 1: Add Files to Xcode Project 

The Swift files have been created, but need to be added to your Xcode project.

**Method A: Using Xcode**

1. Open the project:
   ```bash
   cd /Users/elizsamontoya/Documents/CPSC454-TitanMart/TitanMart
   open TitanMart.xcodeproj
   ```

2. In Xcode, in the left sidebar (Project Navigator), you'll see the TitanMart folder

3. **Add all the new files**:
   - Right-click on the "TitanMart" folder (the one with the app icon)
   - Select "Add Files to TitanMart..."
   - Navigate to: `/Users/elizsamontoya/Documents/CPSC454-TitanMart/TitanMart/TitanMart`
   - Select these folders (hold Cmd to select multiple):
     - Models
     - Views
     - ViewModels
     - Services
   - Make sure "Copy items if needed" is UNCHECKED
   - Make sure "Create groups" is selected
   - Make sure "TitanMart" target is checked
   - Click "Add"

4. Your Project Navigator should now show:
   ```
   TitanMart
   ├── Models/
   │   ├── User.swift
   │   ├── Product.swift
   │   ├── CartItem.swift
   │   ├── Order.swift
   │   └── Review.swift
   ├── Views/
   │   ├── Auth/
   │   ├── Products/
   │   ├── Cart/
   │   ├── Profile/
   │   └── MainTabView.swift
   ├── ViewModels/
   │   ├── ProductViewModel.swift
   │   └── OrderViewModel.swift
   ├── Services/
   │   ├── APIService.swift
   │   ├── AuthService.swift
   │   └── CartService.swift
   ├── TitanMartApp.swift
   └── ContentView.swift
   ```

### Step 2: Build and Run

1. Select a simulator from the top bar (iPhone 15 Pro recommended)

2. Press **Cmd + B** to build the project
   - If you get errors, check the "Common Issues" section below

3. Press **Cmd + R** to run
   - The app should launch in the simulator!

### Step 3: Test the App Features

**What You Can Test Right Now (No Backend Needed):**

#### A. Product Browsing 
1. App launches → You'll see the Browse tab with mock products
2. Scroll through the product list
3. Tap on any product to see details
4. Use the search bar to search for products
5. Tap the filter icon to filter by category

#### B. Shopping Cart
1. Tap on a product
2. Click "Add to Cart"
3. Tap the Cart tab (should show badge with item count)
4. See your cart items
5. Adjust quantities with + and - buttons
6. Remove items
7. Click "Proceed to Checkout"

#### C. Checkout Flow
1. From cart, click "Proceed to Checkout"
2. View order summary
3. Enter pickup location
4. See payment information
5. Click "Place Order"

#### D. Profile Section
1. Tap the Profile tab
2. See mock user profile
3. Browse through "My Orders", "My Listings", etc.

**What Won't Work Yet:**
- Login/Signup (you'll see the screens but can't authenticate)
- Creating real orders
- Adding new products
- Leaving reviews

---

## 🔧 Option 2: Test with Local Backend

Set up the backend locally!

### Step 1: Install Backend Dependencies

```bash
cd /Users/elizsamontoya/Documents/CPSC454-TitanMart/backend
npm install
```

This will install:
- Express.js
- AWS SDK
- Stripe
- JWT libraries
- And more...

### Step 2: Create Environment File

```bash
cd /Users/elizsamontoya/Documents/CPSC454-TitanMart/backend
cp .env.example .env
```

Edit `.env` with minimal values for local testing:
```bash
# Minimal config for local testing
PORT=3000
NODE_ENV=development
JWT_SECRET=test_secret_key_for_local_development_only
JWT_EXPIRES_IN=7d

# Mock AWS (won't actually connect)
AWS_REGION=us-west-2

# Leave Stripe/Email empty for now
```

### Step 3: Run the Server

```bash
npm run dev
```

You should see:
```
TitanMart API running on port 3000
```

### Step 4: Test API Endpoints

Open a new terminal and test:

```bash
# Health check
curl http://localhost:3000/health

# Should return: {"status":"OK","message":"TitanMart API is running"}
```

**Note**: Without AWS credentials, the database operations won't work, but you can verify the server is running!

### Step 5: Connect iOS App to Local Backend

1. Open `APIService.swift` in Xcode
2. Find the line: `private let baseURL = "https://your-api-gateway-url.amazonaws.com/prod"`
3. Change it to: `private let baseURL = "http://localhost:3000/api"`
4. Rebuild the app (Cmd + Shift + K to clean, then Cmd + R to run)

**Important**: The simulator can access localhost directly!

---

## Option 3: Full AWS Deployment

For complete functionality with cloud infrastructure.

### Prerequisites
- AWS Account (free tier works!)
- AWS CLI installed
- Stripe Account (free test mode)

### Step 1: Install Serverless Framework

```bash
npm install -g serverless
```

### Step 2: Configure AWS Credentials

```bash
aws configure
```

Enter:
- AWS Access Key ID
- AWS Secret Access Key
- Region: `us-west-2`
- Output format: `json`

### Step 3: Set Up Stripe

1. Go to https://stripe.com
2. Create account (use test mode)
3. Get your API keys from Dashboard
4. Add to `.env`:
   ```
   STRIPE_SECRET_KEY=sk_test_your_key_here
   ```

### Step 4: Deploy to AWS

```bash
cd /Users/elizsamontoya/Documents/CPSC454-TitanMart/backend
serverless deploy
```

This will:
- Create DynamoDB tables
- Set up API Gateway
- Deploy Lambda functions
- Configure S3 bucket
- Set up IAM roles

### Step 5: Get Your API URL

After deployment, you'll see:
```
endpoints:
  ANY - https://abc123.execute-api.us-west-2.amazonaws.com/dev/{proxy+}
```

Copy this URL!

### Step 6: Update iOS App

1. Open `APIService.swift`
2. Update: `private let baseURL = "https://abc123.execute-api.us-west-2.amazonaws.com/dev"`
3. Rebuild app

Now everything should work!

---

## Common Issues and Solutions

### Issue 1: Xcode Build Errors

**Error**: "Cannot find 'AuthService' in scope"

**Solution**: You haven't added the Swift files to the Xcode project yet. Go back to Step 1 above.

---

**Error**: "No such module 'SwiftUI'"

**Solution**: Make sure you're building for iOS 17.0+
1. Select TitanMart project in Project Navigator
2. Under "Deployment Info", check iOS version is 17.0 or later

---

### Issue 2: Simulator Issues

**Error**: Simulator won't launch

**Solution**:
```bash
# Kill all simulators
killall Simulator

# Restart Xcode
```

---

**Error**: "This app has crashed because it attempted to access privacy-sensitive data..."

**Solution**: This shouldn't happen, but if it does, add permissions to Info.plist

---

### Issue 3: Backend Connection Issues

**Error**: iOS app shows "Network error" or "Invalid URL"

**Solutions**:
1. Check backend is running: `curl http://localhost:3000/health`
2. Make sure API URL in `APIService.swift` is correct
3. Try using `http://127.0.0.1:3000/api` instead of `localhost`
4. Check your Mac's firewall settings

---

**Error**: "Cannot connect to backend"

**Solution**:
- If testing with local backend, make sure it's running
- Check the console output in terminal for errors
- The app works with mock data even without backend!

---

### Issue 4: npm install Errors

**Error**: "npm ERR! code EACCES"

**Solution**:
```bash
sudo chown -R $USER /usr/local/lib/node_modules
npm install
```

---

**Error**: "node version too old"

**Solution**:
```bash
# Install latest Node.js
brew install node

# Or use nvm
nvm install 18
nvm use 18
```

---

## What to Test in Each Section

### Authentication Flow (Requires Backend)
- [ ] Click "Sign Up"
- [ ] Enter CSUF email (must end with @csu.fullerton.edu)
- [ ] Try invalid email → Should show error
- [ ] Complete registration
- [ ] Login with credentials
- [ ] Logout

### Product Browsing (Works with Mock Data)
- [ ] View product list
- [ ] Search for "textbook" → Results should filter
- [ ] Filter by "Electronics" category
- [ ] Clear filters
- [ ] Tap product → View details
- [ ] Check seller rating display
- [ ] Verify price formatting

### Shopping Cart (Works with Mock Data)
- [ ] Add product to cart
- [ ] See "Added to Cart" alert
- [ ] Go to Cart tab
- [ ] Verify badge shows item count
- [ ] Increase quantity → Total updates
- [ ] Decrease quantity → Total updates
- [ ] Remove item → Cart updates
- [ ] Add multiple different products
- [ ] Verify total calculation is correct

### Checkout (Partially Works)
- [ ] Cart with items → "Proceed to Checkout"
- [ ] Order summary shows correct items
- [ ] Enter pickup location
- [ ] See payment info
- [ ] Place order (will fail without backend, but UI works)

### Profile (Works with Mock Data)
- [ ] View profile information
- [ ] See rating display
- [ ] Browse "My Orders" (empty without backend)
- [ ] Check other menu items

---

## Recommended Test Devices

**Best for demo**:
- iPhone 15 Pro (iOS 17)
- iPhone 14 Pro (iOS 17)

**Also test on**:
- iPhone SE (smaller screen)
- iPad (to see layout)

---



## Help?

1. **Can't build in Xcode?** → Make sure files are added to project
2. **Backend won't start?** → Run `npm install` first
3. **AWS deployment fails?** → Check AWS credentials
4. **App crashes?** → Check Xcode console for errors

