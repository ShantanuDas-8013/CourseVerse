# 🚨 CRITICAL: Execute Before Pushing to GitHub

## ⚡ Quick Start (5 Minutes)

### 1. Run the cleanup script (REQUIRED)

```powershell
cd "c:\Java Projects\CourseVerse"
.\cleanup-sensitive-files.ps1
```

### 2. Commit security files

```powershell
git add .gitignore backend/.gitignore frontend/.gitignore
git add backend/src/main/resources/application.properties.example
git add SECURITY.md README.md QUICK_START.md
git commit -m "Security: Add .gitignore and protect sensitive credentials"
```

### 3. 🔴 ROTATE CREDENTIALS (CRITICAL!)

#### AWS Credentials

```
❌ IMMEDIATELY DELETE THIS KEY: AKIA3CMCCDJWPPYLL4AE
```

1. Go to AWS IAM Console
2. Delete/deactivate access key: `AKIA3CMCCDJWPPYLL4AE`
3. Generate new access key
4. Update `application.properties` with new key

#### Firebase Service Account

1. Go to Firebase Console → Service Accounts
2. Delete existing service account key
3. Generate new private key
4. Save as `firebase-service-account-key.json`

### 4. Push to GitHub

```powershell
git remote add origin https://github.com/ShantanuDas-8013/CourseVerse.git
git branch -M main
git push -u origin main
```

---

## 📋 Verification Checklist

Before pushing, verify:

- [ ] ✅ Ran `cleanup-sensitive-files.ps1`
- [ ] ✅ `git status` shows NO sensitive files
- [ ] ✅ AWS key `AKIA3CMCCDJWPPYLL4AE` has been deleted
- [ ] ✅ New AWS credentials generated
- [ ] ✅ New Firebase service account key generated
- [ ] ✅ `.gitignore` files are committed
- [ ] ✅ `application.properties.example` exists
- [ ] ✅ Actual `application.properties` is NOT in git status

---

## 🔍 Quick Test

Run this to ensure sensitive files are protected:

```powershell
git status --short
```

**Expected**: Should NOT see any of these files:

- ❌ `application.properties`
- ❌ `firebase-service-account-key.json`
- ❌ `google-services.json`
- ❌ `backend/target/`

**If you see them**: They need to be removed from tracking!

---

## 🆘 Emergency: Already Pushed Credentials?

If you already pushed sensitive data to GitHub:

### Immediate Actions (Do NOW!)

1. **Revoke AWS credentials** in IAM Console
2. **Delete Firebase service account key** in Firebase Console
3. **Make repository private** on GitHub (Settings → Danger Zone)

### Clean Git History (Advanced)

```powershell
# Install git-filter-repo
pip install git-filter-repo

# Remove sensitive files from history
git filter-repo --path backend/src/main/resources/application.properties --invert-paths
git filter-repo --path backend/src/main/resources/firebase-service-account-key.json --invert-paths

# Force push (⚠️ This rewrites history!)
git push origin --force --all
```

### Contact GitHub Support

- If repository was public, contact GitHub to purge cached copies
- Request removal from search engines (Google, etc.)

---

## 📞 Need Help?

- **Detailed Guide**: See `SECURITY.md`
- **Setup Instructions**: See `README.md`
- **All todo complete**: You're ready to push! 🚀

---

## ✅ Post-Push: New Developer Setup

Share these steps with team members:

1. Clone the repository
2. Copy `application.properties.example` to `application.properties`
3. Add their own AWS credentials
4. Download Firebase service account key
5. Download `google-services.json` for Android
6. See `SECURITY.md` for detailed setup

---

**Remember**: Security is NOT optional. Exposed credentials can cost thousands of dollars! 💰🔒
