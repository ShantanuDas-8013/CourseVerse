# ⚡ Quick Deployment Guide

Get your CourseVerse application deployed in under 30 minutes!

---

## 🎯 Quick Prerequisites Check

Run these commands to verify you have everything:

```powershell
# Check if tools are installed
gcloud --version        # Google Cloud SDK
firebase --version      # Firebase CLI
java -version          # Java 21
flutter --version      # Flutter SDK
```

**Don't have them?** Install from:

- Google Cloud SDK: https://cloud.google.com/sdk/docs/install
- Firebase CLI: `npm install -g firebase-tools`
- Java 21: https://adoptium.net/
- Flutter: https://docs.flutter.dev/get-started/install

---

## 🚀 Deployment in 5 Steps

### Step 1: Login to Services (2 minutes)

```powershell
# Login to Google Cloud
gcloud auth login

# Set your project
gcloud config set project courseverse-c9955

# Login to Firebase
firebase login
```

### Step 2: Enable Required APIs (1 minute)

```powershell
# Enable all required Google Cloud APIs
gcloud services enable appengine.googleapis.com cloudbuild.googleapis.com secretmanager.googleapis.com run.googleapis.com
```

### Step 3: Setup Secrets (3 minutes)

**Option A - Use the interactive script:**

```powershell
cd "c:\Java Projects\CourseVerse"
.\deploy.ps1
# Select option 5 (Setup Google Cloud Secrets)
```

**Option B - Manual setup:**

```powershell
# Create AWS credentials secrets
echo "YOUR_AWS_ACCESS_KEY" | gcloud secrets create aws-access-key --data-file=-
echo "YOUR_AWS_SECRET_KEY" | gcloud secrets create aws-secret-key --data-file=-

# Create Firebase secret
gcloud secrets create firebase-service-account --data-file="backend/src/main/resources/firebase-service-account-key.json"
```

### Step 4: Deploy Backend (10 minutes)

**Option A - App Engine (Recommended):**

```powershell
cd "c:\Java Projects\CourseVerse\backend"
.\mvnw.cmd clean package -DskipTests
gcloud app deploy app.yaml
```

**Option B - Cloud Run:**

```powershell
cd "c:\Java Projects\CourseVerse\backend"
gcloud builds submit --tag gcr.io/courseverse-c9955/courseverse-backend
gcloud run deploy courseverse-backend --image gcr.io/courseverse-c9955/courseverse-backend --region asia-south1 --allow-unauthenticated
```

**Option C - Use the deployment script:**

```powershell
cd "c:\Java Projects\CourseVerse"
.\deploy.ps1
# Select option 1 or 2
```

### Step 5: Deploy Frontend (10 minutes)

```powershell
cd "c:\Java Projects\CourseVerse\frontend"

# Build for web
flutter build web --release

# Deploy to Firebase
firebase deploy --only hosting --project courseverse-c9955
```

**Or use the deployment script:**

```powershell
cd "c:\Java Projects\CourseVerse"
.\deploy.ps1
# Select option 3
```

---

## 🎉 You're Live!

Your application is now deployed at:

- **Frontend**: https://courseverse-c9955.web.app
- **Backend**:
  - App Engine: https://courseverse-c9955.uc.r.appspot.com
  - Cloud Run: Check the URL in deployment output

---

## 🔧 Using the Deployment Script

We've created a helper script that makes deployment easier:

```powershell
cd "c:\Java Projects\CourseVerse"
.\deploy.ps1
```

**Menu Options:**

1. Deploy Backend to Google App Engine
2. Deploy Backend to Google Cloud Run
3. Deploy Frontend to Firebase Hosting
4. Deploy Both (Backend + Frontend)
5. Setup Google Cloud Secrets
6. View Backend Logs
7. View Deployment Status
8. Exit

---

## 🔄 Quick Updates

### Update Backend

```powershell
cd "c:\Java Projects\CourseVerse\backend"
.\mvnw.cmd clean package -DskipTests
gcloud app deploy  # or your preferred deployment method
```

### Update Frontend

```powershell
cd "c:\Java Projects\CourseVerse\frontend"
flutter build web --release
firebase deploy --only hosting
```

---

## ⚠️ Important Notes

### Before First Deployment:

1. **Update frontend API URL** - Edit your API configuration to point to the backend URL
2. **Check CORS settings** - Make sure backend allows your frontend domain
3. **Verify secrets** - Ensure all secrets are created in Secret Manager

### After Deployment:

1. **Test the application** - Visit your frontend URL and test functionality
2. **Check logs** - Monitor for any errors
3. **Update DNS** (optional) - Configure custom domain if needed

---

## 🐛 Quick Troubleshooting

### Build Fails

```powershell
# Backend
cd backend
.\mvnw.cmd clean
.\mvnw.cmd clean package -DskipTests

# Frontend
cd frontend
flutter clean
flutter pub get
flutter build web --release
```

### Deployment Fails

```powershell
# Check if you're logged in
gcloud auth list
firebase login --reauth

# Verify project
gcloud config get-value project
firebase projects:list
```

### Can't Access Secrets

```powershell
# Check secret exists
gcloud secrets list

# Grant access to App Engine
gcloud secrets add-iam-policy-binding aws-access-key --member="serviceAccount:courseverse-c9955@appspot.gserviceaccount.com" --role="roles/secretmanager.secretAccessor"
```

---

## 📚 Need More Details?

Check out the comprehensive [DEPLOYMENT.md](DEPLOYMENT.md) guide for:

- Detailed step-by-step instructions
- Cost optimization tips
- Security best practices
- Advanced configuration options
- Monitoring and logging setup

---

## 💡 Pro Tips

1. **Start with App Engine** - It's simpler for beginners
2. **Test locally first** - Make sure everything works before deploying
3. **Use the deployment script** - It handles most common tasks
4. **Monitor logs** - Keep an eye on logs after deployment
5. **Set up CI/CD later** - Once you're comfortable, automate deployments

---

## 🆘 Need Help?

- Check [DEPLOYMENT.md](DEPLOYMENT.md) for detailed troubleshooting
- Review [SECURITY.md](SECURITY.md) for security best practices
- See [README.md](README.md) for general project information

Happy deploying! 🚀
