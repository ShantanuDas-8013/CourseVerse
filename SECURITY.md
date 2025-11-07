# 🔒 CourseVerse Security & Configuration Guide

## ⚠️ CRITICAL: Before Pushing to GitHub

This guide will help you secure sensitive information before pushing your code to a public repository.

---

## 🚨 Security Vulnerabilities Found

The following sensitive files were detected in your project:

### 1. **Backend Credentials (CRITICAL)**

- **File**: `backend/src/main/resources/application.properties`
- **Contains**:
  - AWS Access Key ID: `AKIA3CMCCDJWPPYLL4AE`
  - AWS Secret Access Key (exposed)
  - S3 Bucket configuration

### 2. **Firebase Service Account Key (CRITICAL)**

- **File**: `backend/src/main/resources/firebase-service-account-key.json`
- **Contains**: Private keys for Firebase Admin SDK
- **Risk**: Full access to your Firebase project

### 3. **Frontend Firebase Configuration**

- **Files**:
  - `frontend/android/app/google-services.json`
  - `frontend/lib/firebase_options.dart`
- **Contains**: Firebase API keys and project configuration

### 4. **API Endpoint Configuration**

- **File**: `frontend/lib/core/services/api_service.dart`
- **Contains**: Hardcoded localhost URL (Line 19)

---

## 🛡️ Security Fixes Applied

### ✅ 1. Created Comprehensive .gitignore Files

- Root `.gitignore` - protects entire project
- Updated `backend/.gitignore` - protects AWS and Firebase credentials
- Updated `frontend/.gitignore` - protects Firebase configuration files

### ✅ 2. Created Configuration Template

- `backend/src/main/resources/application.properties.example` - template with placeholders

---

## 📋 Required Actions Before Pushing

### Step 1: Remove Tracked Sensitive Files

Run these commands in PowerShell from the project root:

```powershell
# Navigate to your project directory
cd "c:\Java Projects\CourseVerse"

# Initialize git if not already done
git init

# Remove sensitive files from git tracking (but keep locally)
git rm --cached backend/src/main/resources/application.properties
git rm --cached backend/src/main/resources/firebase-service-account-key.json
git rm --cached backend/target/classes/firebase-service-account-key.json
git rm --cached backend/target/classes/application.properties
git rm --cached frontend/android/app/google-services.json

# Remove the entire target directory (build artifacts shouldn't be in git)
git rm -r --cached backend/target/
```

### Step 2: Verify .gitignore is Working

```powershell
# Check git status - sensitive files should NOT appear
git status

# If you still see sensitive files listed, they need to be added to .gitignore
```

### Step 3: Commit the Security Updates

```powershell
git add .gitignore
git add backend/.gitignore
git add frontend/.gitignore
git add backend/src/main/resources/application.properties.example
git add SECURITY.md

git commit -m "Security: Add .gitignore files and protect sensitive credentials"
```

---

## 🔧 Setting Up the Project (For New Developers)

### Backend Setup

1. **Copy the template configuration**:

   ```powershell
   cd backend/src/main/resources
   cp application.properties.example application.properties
   ```

2. **Edit `application.properties` with your credentials**:

   - Replace `YOUR_AWS_ACCESS_KEY_HERE` with your AWS Access Key
   - Replace `YOUR_AWS_SECRET_KEY_HERE` with your AWS Secret Key
   - Update the S3 bucket name if different

3. **Download Firebase Service Account Key**:
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Select your project: `courseverse-c9955`
   - Go to Project Settings > Service Accounts
   - Click "Generate New Private Key"
   - Save as `firebase-service-account-key.json` in `backend/src/main/resources/`

### Frontend Setup

1. **Download google-services.json**:

   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Select your project: `courseverse-c9955`
   - Go to Project Settings
   - Under "Your apps", select the Android app
   - Download `google-services.json`
   - Place in `frontend/android/app/`

2. **Update API Base URL** (for production):
   - Edit `frontend/lib/core/services/api_service.dart`
   - Change line 19 from `http://localhost:8080/api/v1` to your production URL

---

## 🔐 Production Security Best Practices

### 1. Use Environment Variables (Recommended)

Instead of hardcoding credentials, use environment variables:

**application.properties**:

```properties
spring.cloud.aws.credentials.access-key=${AWS_ACCESS_KEY}
spring.cloud.aws.credentials.secret-key=${AWS_SECRET_KEY}
```

**Set environment variables**:

```powershell
# Windows PowerShell
$env:AWS_ACCESS_KEY="your-key-here"
$env:AWS_SECRET_KEY="your-secret-here"
```

### 2. Use AWS IAM Roles (Best for Cloud Deployments)

For EC2, ECS, or Lambda deployments:

```properties
spring.cloud.aws.credentials.instance-profile=true
```

### 3. Rotate Exposed Credentials

**⚠️ IMPORTANT**: Since AWS credentials were exposed in this codebase:

1. **Immediately revoke the exposed AWS credentials**:

   - Go to AWS IAM Console
   - Find IAM user with key: `AKIA3CMCCDJWPPYLL4AE`
   - Delete/deactivate this access key
   - Generate new credentials

2. **Review AWS CloudTrail** for any unauthorized access

3. **Update Firebase Service Account Key**:
   - Go to Firebase Console > Service Accounts
   - Delete the old service account key
   - Generate a new one

---

## 📱 Firebase API Keys in Frontend

**Note**: Firebase API keys in `firebase_options.dart` and `google-services.json` are safe to include in your repository because:

- They are **public** by design (embedded in mobile apps)
- Security is enforced by Firebase Security Rules
- They only identify your Firebase project, not authenticate requests

**However**, you should still:

1. Configure proper Firebase Security Rules
2. Restrict API key usage in Google Cloud Console
3. Enable App Check for additional security

---

## ✅ Checklist Before Pushing

- [ ] Run `git rm --cached` commands to untrack sensitive files
- [ ] Verify `.gitignore` files are in place
- [ ] Confirm sensitive files don't appear in `git status`
- [ ] AWS credentials have been rotated/revoked
- [ ] Firebase service account key has been regenerated
- [ ] `application.properties.example` is committed (not the actual file)
- [ ] Documentation updated with setup instructions
- [ ] Test clone repository in a new directory to verify setup process

---

## 🆘 Emergency: Credentials Already Pushed

If you've already pushed sensitive credentials to GitHub:

1. **Immediately revoke all exposed credentials**:

   - AWS: Delete IAM access keys
   - Firebase: Delete service account keys

2. **Remove from Git history** (⚠️ Destructive operation):

   ```powershell
   # Install git filter-repo (if not installed)
   pip install git-filter-repo

   # Remove sensitive files from entire history
   git filter-repo --path backend/src/main/resources/application.properties --invert-paths
   git filter-repo --path backend/src/main/resources/firebase-service-account-key.json --invert-paths
   ```

3. **Force push to GitHub**:

   ```powershell
   git push origin --force --all
   ```

4. **Notify GitHub** if repository was public:
   - Contact GitHub Support to purge cached copies

---

## 📚 Additional Resources

- [GitHub Security Best Practices](https://docs.github.com/en/code-security/getting-started/securing-your-repository)
- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Firebase Security Documentation](https://firebase.google.com/docs/admin/setup)

---

## 📧 Questions?

If you have questions about securing this project, please refer to this guide or contact the development team.

**Remember**: Security is everyone's responsibility! 🔒
