# CourseVerse - Quick Render Deployment Script

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  CourseVerse - Render Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

function Test-Prerequisites {
    Write-Host "Checking prerequisites..." -ForegroundColor Yellow
    
    $gitInstalled = Get-Command git -ErrorAction SilentlyContinue
    $firebaseInstalled = Get-Command firebase -ErrorAction SilentlyContinue
    $flutterInstalled = Get-Command flutter -ErrorAction SilentlyContinue
    
    if (-not $gitInstalled) {
        Write-Host "❌ Git is not installed!" -ForegroundColor Red
        return $false
    }
    
    if (-not $firebaseInstalled) {
        Write-Host "❌ Firebase CLI is not installed!" -ForegroundColor Red
        Write-Host "   Install with: npm install -g firebase-tools" -ForegroundColor Yellow
        return $false
    }
    
    if (-not $flutterInstalled) {
        Write-Host "❌ Flutter is not installed!" -ForegroundColor Red
        return $false
    }
    
    Write-Host "✅ All prerequisites installed!" -ForegroundColor Green
    return $true
}

function Push-ToGitHub {
    Write-Host "`n>>> Pushing code to GitHub..." -ForegroundColor Green
    
    # Check if there are changes
    git status --short
    
    $response = Read-Host "`nDo you want to commit and push changes? (y/n)"
    if ($response -eq 'y') {
        git add .
        $commitMessage = Read-Host "Enter commit message (or press Enter for default)"
        if ([string]::IsNullOrWhiteSpace($commitMessage)) {
            $commitMessage = "Update: Prepare for Render deployment"
        }
        
        git commit -m $commitMessage
        git push origin main
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Code pushed to GitHub successfully!" -ForegroundColor Green
        } else {
            Write-Host "❌ Failed to push to GitHub!" -ForegroundColor Red
            return $false
        }
    }
    return $true
}

function Deploy-Frontend {
    Write-Host "`n>>> Deploying Frontend to Firebase Hosting..." -ForegroundColor Green
    
    Set-Location "$PSScriptRoot\frontend"
    
    Write-Host "Cleaning previous build..." -ForegroundColor Yellow
    flutter clean
    
    Write-Host "Getting dependencies..." -ForegroundColor Yellow
    flutter pub get
    
    Write-Host "Building for web (this may take a few minutes)..." -ForegroundColor Yellow
    flutter build web --release
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`nDeploying to Firebase..." -ForegroundColor Yellow
        firebase deploy --only hosting --project courseverse-c9955
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "`n✅ Frontend deployed successfully!" -ForegroundColor Green
            Write-Host "🌐 URL: https://courseverse-c9955.web.app" -ForegroundColor Cyan
        } else {
            Write-Host "`n❌ Firebase deployment failed!" -ForegroundColor Red
        }
    } else {
        Write-Host "`n❌ Flutter build failed!" -ForegroundColor Red
    }
    
    Set-Location $PSScriptRoot
}

function Show-RenderInstructions {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  Render Backend Deployment Steps" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Follow these steps to deploy your backend on Render:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Go to: https://render.com/" -ForegroundColor White
    Write-Host "   - Sign up or login (use GitHub login)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Click 'New +' then 'Web Service'" -ForegroundColor White
    Write-Host ""
    Write-Host "3. Connect your repository:" -ForegroundColor White
    Write-Host "   - Repository: ShantanuDas-8013/CourseVerse" -ForegroundColor Gray
    Write-Host "   - Branch: main" -ForegroundColor Gray
    Write-Host ""
    Write-Host "4. Configure the service:" -ForegroundColor White
    Write-Host "   - Name: courseverse-backend" -ForegroundColor Gray
    Write-Host "   - Root Directory: backend" -ForegroundColor Gray
    Write-Host "   - Runtime: Docker" -ForegroundColor Gray
    Write-Host "   - Instance Type: Free (or Starter for production)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "5. Add Environment Variables:" -ForegroundColor White
    Write-Host "   - SPRING_PROFILES_ACTIVE = prod" -ForegroundColor Gray
    Write-Host "   - SERVER_PORT = 10000" -ForegroundColor Gray
    Write-Host "   - SPRING_CLOUD_AWS_REGION_STATIC = ap-south-1" -ForegroundColor Gray
    Write-Host "   - APP_AWS_S3_BUCKET_NAME = courseverse-uploads" -ForegroundColor Gray
    Write-Host "   - SPRING_CLOUD_AWS_CREDENTIALS_ACCESS_KEY = [Your AWS Key]" -ForegroundColor Gray
    Write-Host "   - SPRING_CLOUD_AWS_CREDENTIALS_SECRET_KEY = [Your AWS Secret]" -ForegroundColor Gray
    Write-Host "   - CORS_ALLOWED_ORIGINS = https://courseverse-c9955.web.app" -ForegroundColor Gray
    Write-Host ""
    Write-Host "6. Add Secret File (Firebase credentials):" -ForegroundColor White
    Write-Host "   - Click 'Add Secret File'" -ForegroundColor Gray
    Write-Host "   - Filename: /etc/secrets/firebase-service-account-key.json" -ForegroundColor Gray
    Write-Host "   - Content: [Paste your Firebase service account JSON]" -ForegroundColor Gray
    Write-Host ""
    Write-Host "7. Click 'Create Web Service'" -ForegroundColor White
    Write-Host ""
    Write-Host "First deployment takes 5-10 minutes" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "For detailed instructions, see: RENDER_DEPLOYMENT.md" -ForegroundColor Cyan
}

function Show-Menu {
    Write-Host "`nSelect an option:" -ForegroundColor Yellow
    Write-Host "1. Check Prerequisites" -ForegroundColor White
    Write-Host "2. Push Code to GitHub" -ForegroundColor White
    Write-Host "3. Show Render Backend Setup Instructions" -ForegroundColor White
    Write-Host "4. Deploy Frontend to Firebase" -ForegroundColor White
    Write-Host "5. Do Everything (Push + Show Instructions + Deploy Frontend)" -ForegroundColor White
    Write-Host "6. View Deployment URLs" -ForegroundColor White
    Write-Host "7. Exit" -ForegroundColor White
    Write-Host ""
}

function Show-URLs {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  Your Deployment URLs" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Frontend (Firebase):" -ForegroundColor Yellow
    Write-Host "  https://courseverse-c9955.web.app" -ForegroundColor Cyan
    Write-Host "  https://courseverse-c9955.firebaseapp.com" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Backend (Render):" -ForegroundColor Yellow
    Write-Host "  Check your Render dashboard for the URL" -ForegroundColor Gray
    Write-Host "  Format: https://courseverse-backend.onrender.com" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Render Dashboard:" -ForegroundColor Yellow
    Write-Host "  https://dashboard.render.com/" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Firebase Console:" -ForegroundColor Yellow
    Write-Host "  https://console.firebase.google.com/project/courseverse-c9955" -ForegroundColor Cyan
}

# Main execution
$continue = $true

while ($continue) {
    Show-Menu
    $choice = Read-Host "Enter your choice"
    
    switch ($choice) {
        "1" { 
            Test-Prerequisites
        }
        "2" { 
            Push-ToGitHub
        }
        "3" { 
            Show-RenderInstructions
        }
        "4" { 
            Deploy-Frontend
        }
        "5" {
            Write-Host "`nStarting complete deployment process..." -ForegroundColor Green
            
            if (Test-Prerequisites) {
                if (Push-ToGitHub) {
                    Show-RenderInstructions
                    
                    $deployFrontend = Read-Host "`nDo you want to deploy frontend now? (y/n)"
                    if ($deployFrontend -eq 'y') {
                        Deploy-Frontend
                    }
                }
            }
        }
        "6" {
            Show-URLs
        }
        "7" { 
            Write-Host "`nGoodbye!" -ForegroundColor Cyan
            $continue = $false
        }
        default { 
            Write-Host "`n❌ Invalid choice. Please try again." -ForegroundColor Red 
        }
    }
    
    if ($continue) {
        Write-Host "`nPress any key to continue..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        Clear-Host
    }
}
