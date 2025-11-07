# 🚀 Render Deployment Guide - CourseVerse

Complete guide for deploying the backend to Render and frontend to Firebase Hosting.

---

## 📋 Why Render?

- ✅ **Free tier available** - Perfect for getting started
- ✅ **Easy setup** - No complex configurations
- ✅ **Auto-deploy** from GitHub
- ✅ **Built-in HTTPS**
- ✅ **Environment variables** management
- ✅ **Automatic health checks**

---

## 🎯 Part 1: Backend Deployment to Render

### Step 1: Prepare Your GitHub Repository

First, ensure your code is pushed to GitHub (without sensitive files):

```powershell
# Make sure you're in the project root
cd "c:\Java Projects\CourseVerse"

# Check git status
git status

# Add all files (sensitive files are already in .gitignore)
git add .

# Commit
git commit -m "Add Render deployment configuration"

# Push to GitHub
git push origin main
```

### Step 2: Sign Up / Login to Render

1. Go to [Render.com](https://render.com/)
2. Sign up or login (you can use GitHub login)
3. This will automatically connect your GitHub account

### Step 3: Create a New Web Service

1. Click **"New +"** button → **"Web Service"**
2. Connect your GitHub repository: `ShantanuDas-8013/CourseVerse`
3. Grant Render access to the repository

### Step 4: Configure the Web Service

Fill in the following details:

**Basic Settings:**

- **Name**: `courseverse-backend`
- **Region**: Singapore (closest to India) or any preferred region
- **Branch**: `main`
- **Root Directory**: `backend`
- **Runtime**: `Docker`

**Build & Deploy:**

- **Dockerfile Path**: `Dockerfile.render` (or just `Dockerfile`)

**Instance Type:**

- Select **"Free"** for testing (goes to sleep after inactivity)
- Or **"Starter ($7/month)"** for production (always on)

### Step 5: Add Environment Variables

In the **Environment** section, add these variables:

| Key                                       | Value                                                                         |
| ----------------------------------------- | ----------------------------------------------------------------------------- |
| `SPRING_PROFILES_ACTIVE`                  | `prod`                                                                        |
| `SERVER_PORT`                             | `10000`                                                                       |
| `SPRING_CLOUD_AWS_REGION_STATIC`          | `ap-south-1`                                                                  |
| `APP_AWS_S3_BUCKET_NAME`                  | `courseverse-uploads`                                                         |
| `SPRING_CLOUD_AWS_CREDENTIALS_ACCESS_KEY` | `YOUR_AWS_ACCESS_KEY`                                                         |
| `SPRING_CLOUD_AWS_CREDENTIALS_SECRET_KEY` | `YOUR_AWS_SECRET_KEY`                                                         |
| `CORS_ALLOWED_ORIGINS`                    | `https://courseverse-c9955.web.app,https://courseverse-c9955.firebaseapp.com` |

**Important:** Click "Add Secret File" for Firebase credentials:

- **Filename**: `/etc/secrets/firebase-service-account-key.json`
- **Contents**: Paste the entire content of your `firebase-service-account-key.json`

### Step 6: Deploy!

1. Click **"Create Web Service"**
2. Render will automatically:
   - Clone your repository
   - Build the Docker image
   - Deploy the application
   - Assign a URL (e.g., `https://courseverse-backend.onrender.com`)

**⏱️ First deployment takes 5-10 minutes**

### Step 7: Verify Backend Deployment

Once deployed, test your backend:

```powershell
# Test health endpoint (replace with your Render URL)
curl https://courseverse-backend.onrender.com/actuator/health
```

Or open in browser:

```
https://courseverse-backend.onrender.com/actuator/health
```

You should see:

```json
{
  "status": "UP"
}
```

---

## 🎨 Part 2: Frontend Deployment to Firebase Hosting

### Step 1: Update Backend URL in Frontend

Update your frontend to use the Render backend URL:

**Find and edit your API configuration file** (likely `lib/core/constants/api_constants.dart` or similar):

```dart
class ApiConstants {
  // Replace with your Render URL
  static const String baseUrl = 'https://courseverse-backend.onrender.com';

  // API endpoints
  static const String loginEndpoint = '$baseUrl/api/auth/login';
  static const String coursesEndpoint = '$baseUrl/api/courses';
  // ... other endpoints
}
```

### Step 2: Build Flutter Web App

```powershell
cd "c:\Java Projects\CourseVerse\frontend"

# Clean previous build
flutter clean

# Get dependencies
flutter pub get

# Build for web (production)
flutter build web --release
```

### Step 3: Deploy to Firebase Hosting

```powershell
# Make sure you're in frontend directory
cd "c:\Java Projects\CourseVerse\frontend"

# Login to Firebase (if not already logged in)
firebase login

# Deploy to Firebase Hosting
firebase deploy --only hosting --project courseverse-c9955
```

**⏱️ Deployment takes 2-3 minutes**

### Step 4: Verify Frontend Deployment

Your frontend will be live at:

- **Primary URL**: `https://courseverse-c9955.web.app`
- **Alternative URL**: `https://courseverse-c9955.firebaseapp.com`

Open in browser and test the application!

---

## 🔄 Update Backend CORS After Frontend Deployment

After frontend is deployed, verify CORS is set correctly in Render:

1. Go to Render Dashboard → Your service
2. Go to **Environment** tab
3. Check `CORS_ALLOWED_ORIGINS` includes your Firebase URLs:
   ```
   https://courseverse-c9955.web.app,https://courseverse-c9955.firebaseapp.com
   ```
4. If you made changes, save and the service will auto-redeploy

---

## 🔄 Future Updates

### Update Backend

**Option 1: Auto-deploy (Recommended)**

```powershell
# Just push to GitHub, Render auto-deploys
git add .
git commit -m "Update backend"
git push origin main
```

**Option 2: Manual deploy from Render Dashboard**

- Go to your service → Click "Manual Deploy" → "Deploy latest commit"

### Update Frontend

```powershell
cd "c:\Java Projects\CourseVerse\frontend"

# Build
flutter build web --release

# Deploy
firebase deploy --only hosting
```

---

## 📊 Render Free Tier Details

**What's Included:**

- ✅ 750 hours/month of runtime
- ✅ Automatic HTTPS
- ✅ Custom domains (optional)
- ✅ Automatic deploys from Git
- ⚠️ Service spins down after 15 minutes of inactivity
- ⚠️ First request after sleep takes ~30 seconds (cold start)

**Upgrade to Starter ($7/month) for:**

- Always-on service (no cold starts)
- Better performance

---

## 🔍 Monitoring & Logs

### View Backend Logs (Render)

1. Go to [Render Dashboard](https://dashboard.render.com/)
2. Click on your service
3. Go to **"Logs"** tab
4. See real-time logs

### View Frontend Logs (Firebase)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select `courseverse-c9955` project
3. Go to **Hosting** section
4. Check deployment history and traffic

---

## 🔒 Security Best Practices

### Backend (Render)

- ✅ Never commit sensitive data to Git
- ✅ Use Render environment variables for secrets
- ✅ Use Secret Files for Firebase credentials
- ✅ Enable CORS only for your frontend domain
- ✅ Regularly rotate AWS credentials

### Frontend (Firebase)

- ✅ Firebase API keys in code are safe (they're meant to be public)
- ✅ Use Firebase Security Rules to protect data
- ✅ Enable Firebase App Check for additional security

---

## 🐛 Troubleshooting

### Backend Issues

**Build fails on Render:**

```
Solution: Check Render logs
- Verify Java 21 is specified correctly
- Ensure all dependencies are in pom.xml
- Check Dockerfile syntax
```

**Service keeps sleeping (Free tier):**

```
Solution: Upgrade to Starter plan ($7/month)
Or: Keep service awake with a ping service
```

**Environment variables not working:**

```
Solution:
1. Check variable names match exactly
2. Redeploy after adding variables
3. Check logs for error messages
```

**CORS errors:**

```
Solution:
1. Verify CORS_ALLOWED_ORIGINS includes your Firebase URLs
2. Check Spring Security configuration
3. Test with curl or Postman first
```

### Frontend Issues

**API calls failing:**

```
Solution:
1. Check backend URL is correct in code
2. Verify backend is running (check health endpoint)
3. Check browser console for CORS errors
4. Verify Firebase hosting deployment succeeded
```

**Build fails:**

```powershell
# Solution: Clean and rebuild
flutter clean
flutter pub get
flutter build web --release
```

**Deployment fails:**

```powershell
# Solution: Check Firebase authentication
firebase login --reauth
firebase use courseverse-c9955
firebase deploy --only hosting
```

---

## 💰 Cost Breakdown

### Backend (Render)

- **Free Tier**: $0/month
  - 750 hours runtime
  - Spins down after inactivity
- **Starter**: $7/month
  - Always on
  - Better for production

### Frontend (Firebase Hosting)

- **Free Tier**: Includes
  - 10 GB storage
  - 360 MB/day transfer
- **Paid**: Pay as you go
  - $0.026/GB stored
  - $0.15/GB transferred

### AWS S3 (File Storage)

- **Free Tier** (first 12 months):
  - 5 GB storage
  - 20,000 GET requests
  - 2,000 PUT requests
- **After free tier**:
  - ~$0.023/GB/month

**Total estimated cost for small app:** $0-10/month

---

## 🎉 Your App is Live!

Once deployed, your application will be available at:

- **Frontend**: https://courseverse-c9955.web.app
- **Backend**: https://courseverse-backend.onrender.com

Share these URLs and start using your app! 🚀📚

---

## 📚 Additional Resources

- [Render Documentation](https://render.com/docs)
- [Firebase Hosting Docs](https://firebase.google.com/docs/hosting)
- [Spring Boot on Render](https://render.com/docs/deploy-spring-boot)
- [Flutter Web Deployment](https://docs.flutter.dev/deployment/web)

---

## 🆘 Need Help?

If you encounter issues:

1. Check the troubleshooting section above
2. Review Render logs for backend issues
3. Check browser console for frontend issues
4. Verify all environment variables are set correctly

Good luck with your deployment! 🎊
