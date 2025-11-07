# ================================================================
# CourseVerse - Remove Sensitive Files from Git Tracking
# ================================================================
# 
# This script removes sensitive files from git tracking while
# keeping them in your local filesystem.
#
# IMPORTANT: Run this BEFORE your first commit to GitHub!
#
# ================================================================

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "CourseVerse - Security Cleanup Script" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Check if we're in the correct directory
$currentDir = Get-Location
if (-not (Test-Path "backend") -or -not (Test-Path "frontend")) {
    Write-Host "[ERROR] Please run this script from the CourseVerse root directory!" -ForegroundColor Red
    Write-Host "Current directory: $currentDir" -ForegroundColor Yellow
    exit 1
}

Write-Host "[OK] Verified: Running from project root directory" -ForegroundColor Green
Write-Host ""

# Initialize git if not already done
if (-not (Test-Path ".git")) {
    Write-Host "[INIT] Initializing Git repository..." -ForegroundColor Yellow
    git init
    Write-Host "[OK] Git repository initialized" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host "[OK] Git repository already initialized" -ForegroundColor Green
    Write-Host ""
}

# Function to safely remove files from git tracking
function Remove-FromGitTracking {
    param (
        [string]$FilePath,
        [string]$Description
    )
    
    if (Test-Path $FilePath) {
        Write-Host "[REMOVE] Removing from git: $Description" -ForegroundColor Yellow
        git rm --cached $FilePath 2>&1 | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] Removed: $FilePath" -ForegroundColor Green
        } else {
            Write-Host "  [SKIP] Not tracked or already removed: $FilePath" -ForegroundColor DarkGray
        }
    } else {
        Write-Host "  [INFO] File not found (OK if deleted): $FilePath" -ForegroundColor DarkGray
    }
}

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "Step 1: Removing Sensitive Backend Files" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

Remove-FromGitTracking `
    -FilePath "backend/src/main/resources/application.properties" `
    -Description "Backend configuration (AWS credentials)"

Remove-FromGitTracking `
    -FilePath "backend/src/main/resources/firebase-service-account-key.json" `
    -Description "Firebase service account key"

Remove-FromGitTracking `
    -FilePath "backend/target/classes/application.properties" `
    -Description "Compiled backend configuration"

Remove-FromGitTracking `
    -FilePath "backend/target/classes/firebase-service-account-key.json" `
    -Description "Compiled Firebase key"

# Remove entire target directory (build artifacts)
if (Test-Path "backend/target") {
    Write-Host ""
    Write-Host "[REMOVE] Removing entire backend/target directory from git..." -ForegroundColor Yellow
    git rm -r --cached backend/target/ 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] Removed: backend/target/" -ForegroundColor Green
    } else {
        Write-Host "  [SKIP] Not tracked or already removed: backend/target/" -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "Step 2: Removing Sensitive Frontend Files" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

Remove-FromGitTracking `
    -FilePath "frontend/android/app/google-services.json" `
    -Description "Firebase Android configuration"

# Remove build directory
if (Test-Path "frontend/build") {
    Write-Host ""
    Write-Host "[REMOVE] Removing entire frontend/build directory from git..." -ForegroundColor Yellow
    git rm -r --cached frontend/build/ 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] Removed: frontend/build/" -ForegroundColor Green
    } else {
        Write-Host "  [SKIP] Not tracked or already removed: frontend/build/" -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "Step 3: Verification" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[CHECK] Checking git status..." -ForegroundColor Yellow
Write-Host ""

# Get git status
$gitStatus = git status --short

if ($gitStatus) {
    Write-Host "Current changes to be committed:" -ForegroundColor Yellow
    Write-Host $gitStatus -ForegroundColor White
    
    # Check if sensitive files are still in the status
    $sensitiveFiles = @(
        "application.properties",
        "firebase-service-account-key.json",
        "google-services.json"
    )
    
    $foundSensitive = $false
    foreach ($file in $sensitiveFiles) {
        if ($gitStatus -match $file) {
            Write-Host ""
            Write-Host "[WARNING] Sensitive file still appears in git status: $file" -ForegroundColor Red
            $foundSensitive = $true
        }
    }
    
    if (-not $foundSensitive) {
        Write-Host ""
        Write-Host "[OK] No sensitive files detected in git status!" -ForegroundColor Green
    }
} else {
    Write-Host "[OK] No changes in git status (clean working directory)" -ForegroundColor Green
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "Step 4: Next Steps" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[SUCCESS] Sensitive files have been removed from git tracking!" -ForegroundColor Green
Write-Host ""

Write-Host "[NEXT STEPS] What to do next:" -ForegroundColor Yellow
Write-Host ""

Write-Host "1. Add and commit the security files:" -ForegroundColor White
Write-Host "   git add .gitignore backend/.gitignore frontend/.gitignore" -ForegroundColor Cyan
Write-Host "   git add backend/src/main/resources/application.properties.example" -ForegroundColor Cyan
Write-Host "   git add SECURITY.md README.md" -ForegroundColor Cyan
Write-Host "   git commit -m `"Security: Add .gitignore and protect sensitive credentials`"" -ForegroundColor Cyan
Write-Host ""

Write-Host "2. IMPORTANT - Rotate exposed credentials:" -ForegroundColor White
Write-Host "   * AWS: Delete access key AKIA3CMCCDJWPPYLL4AE and create new one" -ForegroundColor Red
Write-Host "   * Firebase: Regenerate service account key" -ForegroundColor Red
Write-Host "   * See SECURITY.md for detailed instructions" -ForegroundColor Yellow
Write-Host ""

Write-Host "3. Add your remote and push:" -ForegroundColor White
Write-Host "   git remote add origin https://github.com/ShantanuDas-8013/CourseVerse.git" -ForegroundColor Cyan
Write-Host "   git branch -M main" -ForegroundColor Cyan
Write-Host "   git push -u origin main" -ForegroundColor Cyan
Write-Host ""

Write-Host "4. For new developers to set up the project, refer to SECURITY.md" -ForegroundColor White
Write-Host ""

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "[SUCCESS] Security cleanup complete!" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[REMINDER] Your sensitive files are still in your local directory," -ForegroundColor Yellow
Write-Host "           they are just no longer tracked by git. This is what you want!" -ForegroundColor Yellow
Write-Host ""
