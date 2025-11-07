# 🚀 Deployment Guide - CourseVerse

Complete guide for deploying the backend to Google Cloud and frontend to Firebase Hosting.

---

## 📋 Prerequisites

Before you begin, ensure you have:

- [ ] Google Cloud account with billing enabled
- [ ] Firebase project (courseverse-c9955) already created
- [ ] Google Cloud SDK (gcloud) installed
- [ ] Firebase CLI installed
- [ ] Java 21 installed
- [ ] Maven installed
- [ ] Flutter SDK installed

---

## 🔧 Installation of Required Tools

### Install Google Cloud SDK

**Windows (PowerShell):**

```powershell
# Download and install from: https://cloud.google.com/sdk/docs/install
# Or use Chocolatey:
choco install gcloudsdk
```

**Verify installation:**

```powershell
gcloud --version
```

### Install Firebase CLI

```powershell
npm install -g firebase-tools
```

**Verify installation:**

```powershell
firebase --version
```

---

## 🎯 Part 1: Backend Deployment to Google Cloud

You have two options for deploying the backend:

1. **Google App Engine** (Recommended for beginners)
2. **Google Cloud Run** (More flexible, containerized)

### Option A: Deploy to Google App Engine

#### Step 1: Initialize Google Cloud

```powershell
# Login to Google Cloud
gcloud auth login

# Set your project ID
gcloud config set project courseverse-c9955

# Enable required APIs
gcloud services enable appengine.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable secretmanager.googleapis.com
```

#### Step 2: Create App Engine Application

```powershell
# Create App Engine app (one-time setup)
# Choose a region close to your users (e.g., asia-south1 for India)
gcloud app create --region=asia-south1
```

#### Step 3: Setup Secrets in Secret Manager

**Important:** Never hardcode sensitive credentials in your code or config files!

```powershell
# Navigate to backend directory
cd "c:\Java Projects\CourseVerse\backend"

# Create secrets for AWS credentials
echo "YOUR_AWS_ACCESS_KEY" | gcloud secrets create aws-access-key --data-file=-
echo "YOUR_AWS_SECRET_KEY" | gcloud secrets create aws-secret-key --data-file=-

# Create secret for Firebase service account
gcloud secrets create firebase-service-account --data-file="src/main/resources/firebase-service-account-key.json"

# Grant App Engine access to secrets
$PROJECT_ID = "courseverse-c9955"
$PROJECT_NUMBER = (gcloud projects describe $PROJECT_ID --format="value(projectNumber)")

gcloud secrets add-iam-policy-binding aws-access-key --member="serviceAccount:$PROJECT_ID@appspot.gserviceaccount.com" --role="roles/secretmanager.secretAccessor"

gcloud secrets add-iam-policy-binding aws-secret-key --member="serviceAccount:$PROJECT_ID@appspot.gserviceaccount.com" --role="roles/secretmanager.secretAccessor"

gcloud secrets add-iam-policy-binding firebase-service-account --member="serviceAccount:$PROJECT_ID@appspot.gserviceaccount.com" --role="roles/secretmanager.secretAccessor"
```

#### Step 4: Update app.yaml with Secret References

Update `backend/app.yaml` to use secrets:

```yaml
runtime: java21
env: standard
instance_class: F2

env_variables:
  SPRING_PROFILES_ACTIVE: "prod"
  SPRING_CLOUD_AWS_REGION_STATIC: "ap-south-1"
  APP_AWS_S3_BUCKET_NAME: "courseverse-uploads"
  # Frontend URL - Update after frontend deployment
  CORS_ALLOWED_ORIGINS: "https://courseverse-c9955.web.app,https://courseverse-c9955.firebaseapp.com"

# Mount secrets as environment variables
env_variables:
  SPRING_CLOUD_AWS_CREDENTIALS_ACCESS_KEY: "sm://projects/courseverse-c9955/secrets/aws-access-key"
  SPRING_CLOUD_AWS_CREDENTIALS_SECRET_KEY: "sm://projects/courseverse-c9955/secrets/aws-secret-key"
  APP_FIREBASE_CONFIG_FILE: "sm://projects/courseverse-c9955/secrets/firebase-service-account"
```

#### Step 5: Build and Deploy

```powershell
# Make sure you're in the backend directory
cd "c:\Java Projects\CourseVerse\backend"

# Build the application
./mvnw clean package -DskipTests

# Deploy to App Engine
gcloud app deploy app.yaml

# View your deployed app
gcloud app browse
```

**Your backend will be available at:** `https://courseverse-c9955.uc.r.appspot.com`

---

### Option B: Deploy to Google Cloud Run

#### Step 1: Initialize Google Cloud

```powershell
# Login to Google Cloud
gcloud auth login

# Set your project
gcloud config set project courseverse-c9955

# Enable required APIs
gcloud services enable run.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable secretmanager.googleapis.com
gcloud services enable containerregistry.googleapis.com
```

#### Step 2: Setup Secrets (Same as App Engine)

Follow Step 3 from Option A above.

#### Step 3: Build and Push Docker Image

```powershell
# Navigate to backend directory
cd "c:\Java Projects\CourseVerse\backend"

# Build and push to Google Container Registry
gcloud builds submit --tag gcr.io/courseverse-c9955/courseverse-backend

# Alternative: Build locally and push
# docker build -t gcr.io/courseverse-c9955/courseverse-backend .
# docker push gcr.io/courseverse-c9955/courseverse-backend
```

#### Step 4: Deploy to Cloud Run

```powershell
gcloud run deploy courseverse-backend `
  --image gcr.io/courseverse-c9955/courseverse-backend `
  --platform managed `
  --region asia-south1 `
  --allow-unauthenticated `
  --port 8080 `
  --memory 1Gi `
  --cpu 1 `
  --min-instances 1 `
  --max-instances 10 `
  --set-env-vars "SPRING_PROFILES_ACTIVE=prod,SPRING_CLOUD_AWS_REGION_STATIC=ap-south-1,APP_AWS_S3_BUCKET_NAME=courseverse-uploads" `
  --set-secrets "SPRING_CLOUD_AWS_CREDENTIALS_ACCESS_KEY=aws-access-key:latest,SPRING_CLOUD_AWS_CREDENTIALS_SECRET_KEY=aws-secret-key:latest,APP_FIREBASE_CONFIG_FILE=firebase-service-account:latest"
```

**Your backend will be available at:** The URL displayed after deployment (e.g., `https://courseverse-backend-xxx-uc.a.run.app`)

---

## 🎨 Part 2: Frontend Deployment to Firebase Hosting

### Step 1: Login to Firebase

```powershell
# Login to Firebase
firebase login

# Verify you're logged in
firebase projects:list
```

### Step 2: Initialize Firebase Hosting (if not already done)

```powershell
# Navigate to frontend directory
cd "c:\Java Projects\CourseVerse\frontend"

# Initialize Firebase (select Hosting)
firebase init hosting

# When prompted:
# - Select "Use an existing project"
# - Choose "courseverse-c9955"
# - Public directory: build/web
# - Single-page app: Yes
# - Set up automatic builds: No
# - Overwrite index.html: No
```

### Step 3: Update Backend URL in Frontend

Before building, update your frontend to point to the deployed backend URL.

**Find your API configuration file (likely in `lib/core/constants/` or similar):**

```dart
// Example: lib/core/constants/api_constants.dart
class ApiConstants {
  // Replace with your actual backend URL
  static const String baseUrl = 'https://courseverse-c9955.uc.r.appspot.com'; // App Engine
  // OR
  // static const String baseUrl = 'https://courseverse-backend-xxx-uc.a.run.app'; // Cloud Run
}
```

### Step 4: Build Flutter Web App

```powershell
# Make sure you're in frontend directory
cd "c:\Java Projects\CourseVerse\frontend"

# Build for web production
flutter build web --release

# This creates optimized files in build/web/
```

### Step 5: Deploy to Firebase Hosting

```powershell
# Deploy to Firebase
firebase deploy --only hosting

# Or deploy with a specific project
firebase deploy --only hosting --project courseverse-c9955
```

**Your frontend will be available at:**

- Primary: `https://courseverse-c9955.web.app`
- Alternative: `https://courseverse-c9955.firebaseapp.com`

---

## 🔄 Update Backend CORS Settings

After frontend deployment, update backend CORS settings:

### For App Engine:

Update `backend/app.yaml`:

```yaml
env_variables:
  CORS_ALLOWED_ORIGINS: "https://courseverse-c9955.web.app,https://courseverse-c9955.firebaseapp.com"
```

Redeploy:

```powershell
cd "c:\Java Projects\CourseVerse\backend"
gcloud app deploy
```

### For Cloud Run:

```powershell
gcloud run services update courseverse-backend `
  --region asia-south1 `
  --update-env-vars "CORS_ALLOWED_ORIGINS=https://courseverse-c9955.web.app,https://courseverse-c9955.firebaseapp.com"
```

---

## 🔍 Verify Deployment

### Test Backend

```powershell
# Test health endpoint
curl https://courseverse-c9955.uc.r.appspot.com/actuator/health

# Or in browser
start https://courseverse-c9955.uc.r.appspot.com/actuator/health
```

### Test Frontend

```powershell
# Open in browser
start https://courseverse-c9955.web.app
```

---

## 📊 Monitoring and Logs

### View Backend Logs

**App Engine:**

```powershell
# View logs
gcloud app logs tail

# Or in Cloud Console
start https://console.cloud.google.com/logs
```

**Cloud Run:**

```powershell
# View logs
gcloud run services logs read courseverse-backend --region asia-south1

# Follow logs
gcloud run services logs tail courseverse-backend --region asia-south1
```

### View Frontend Logs

```powershell
# View hosting logs in Firebase Console
start https://console.firebase.google.com/project/courseverse-c9955/hosting
```

---

## 🔄 Continuous Deployment Updates

### Update Backend

```powershell
cd "c:\Java Projects\CourseVerse\backend"

# Build
./mvnw clean package -DskipTests

# Deploy
gcloud app deploy  # For App Engine
# OR
gcloud builds submit --tag gcr.io/courseverse-c9955/courseverse-backend && `
gcloud run deploy courseverse-backend --image gcr.io/courseverse-c9955/courseverse-backend --region asia-south1  # For Cloud Run
```

### Update Frontend

```powershell
cd "c:\Java Projects\CourseVerse\frontend"

# Build
flutter build web --release

# Deploy
firebase deploy --only hosting
```

---

## 💰 Cost Optimization Tips

### Backend (Google Cloud)

1. **Use appropriate instance sizes**: Start with F2 for App Engine or 1 CPU/1GB for Cloud Run
2. **Set min instances to 0** for Cloud Run in dev (cold starts) or 1 for production
3. **Enable autoscaling**: Max instances based on expected traffic
4. **Use Cloud Scheduler**: Stop services during off-hours if needed

### Frontend (Firebase Hosting)

- Firebase Hosting free tier includes: 10 GB storage, 360 MB/day transfer
- Paid plan: $0.026/GB stored, $0.15/GB transferred

---

## 🔒 Security Checklist

- [ ] ✅ All secrets stored in Secret Manager (not in code)
- [ ] ✅ CORS properly configured with production URLs
- [ ] ✅ Firebase security rules configured
- [ ] ✅ IAM roles properly assigned
- [ ] ✅ HTTPS enabled (automatic with both services)
- [ ] ✅ API authentication implemented
- [ ] ✅ Regular security audits scheduled

---

## 🆘 Troubleshooting

### Backend Issues

**Build fails:**

```powershell
# Check Java version
java -version  # Should be 21

# Clear Maven cache
./mvnw clean
```

**Deployment fails:**

```powershell
# Check logs
gcloud app logs tail

# Verify IAM permissions
gcloud projects get-iam-policy courseverse-c9955
```

**Secret access denied:**

```powershell
# Verify secret permissions
gcloud secrets get-iam-policy aws-access-key
```

### Frontend Issues

**Build fails:**

```powershell
# Check Flutter
flutter doctor

# Clean and rebuild
flutter clean
flutter pub get
flutter build web --release
```

**Deployment fails:**

```powershell
# Verify Firebase project
firebase projects:list

# Check firebase.json configuration
# Ensure public directory is "build/web"
```

---

## 📚 Additional Resources

- [Google Cloud Documentation](https://cloud.google.com/docs)
- [Firebase Hosting Documentation](https://firebase.google.com/docs/hosting)
- [Spring Boot on Google Cloud](https://spring.io/guides/gs/spring-boot-on-kubernetes/)
- [Flutter Web Deployment](https://docs.flutter.dev/deployment/web)

---

## 🎉 Success!

Once deployed, your application will be live at:

- **Frontend**: https://courseverse-c9955.web.app
- **Backend**: https://courseverse-c9955.uc.r.appspot.com (or Cloud Run URL)

Share your deployed URLs and start teaching! 🚀📚
