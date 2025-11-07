# CourseVerse Deployment Helper Script
# This script provides quick commands for deploying backend and frontend

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  CourseVerse Deployment Helper" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

function Show-Menu {
    Write-Host "Select deployment option:" -ForegroundColor Yellow
    Write-Host "1. Deploy Backend to Google App Engine" -ForegroundColor White
    Write-Host "2. Deploy Backend to Google Cloud Run" -ForegroundColor White
    Write-Host "3. Deploy Frontend to Firebase Hosting" -ForegroundColor White
    Write-Host "4. Deploy Both (Backend + Frontend)" -ForegroundColor White
    Write-Host "5. Setup Google Cloud Secrets" -ForegroundColor White
    Write-Host "6. View Backend Logs" -ForegroundColor White
    Write-Host "7. View Deployment Status" -ForegroundColor White
    Write-Host "8. Exit" -ForegroundColor White
    Write-Host ""
}

function Deploy-BackendAppEngine {
    Write-Host "`n>>> Deploying Backend to Google App Engine..." -ForegroundColor Green
    
    Set-Location "$PSScriptRoot\backend"
    
    Write-Host "Building application..." -ForegroundColor Yellow
    .\mvnw.cmd clean package -DskipTests
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Deploying to App Engine..." -ForegroundColor Yellow
        gcloud app deploy app.yaml --quiet
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "`n✅ Backend deployed successfully!" -ForegroundColor Green
            Write-Host "URL: https://courseverse-c9955.uc.r.appspot.com" -ForegroundColor Cyan
        } else {
            Write-Host "`n❌ Deployment failed!" -ForegroundColor Red
        }
    } else {
        Write-Host "`n❌ Build failed!" -ForegroundColor Red
    }
    
    Set-Location $PSScriptRoot
}

function Deploy-BackendCloudRun {
    Write-Host "`n>>> Deploying Backend to Google Cloud Run..." -ForegroundColor Green
    
    Set-Location "$PSScriptRoot\backend"
    
    Write-Host "Building and pushing Docker image..." -ForegroundColor Yellow
    gcloud builds submit --tag gcr.io/courseverse-c9955/courseverse-backend
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Deploying to Cloud Run..." -ForegroundColor Yellow
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
            --set-env-vars "SPRING_PROFILES_ACTIVE=prod,SPRING_CLOUD_AWS_REGION_STATIC=ap-south-1,APP_AWS_S3_BUCKET_NAME=courseverse-uploads,CORS_ALLOWED_ORIGINS=https://courseverse-c9955.web.app,https://courseverse-c9955.firebaseapp.com" `
            --set-secrets "SPRING_CLOUD_AWS_CREDENTIALS_ACCESS_KEY=aws-access-key:latest,SPRING_CLOUD_AWS_CREDENTIALS_SECRET_KEY=aws-secret-key:latest"
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "`n✅ Backend deployed successfully to Cloud Run!" -ForegroundColor Green
        } else {
            Write-Host "`n❌ Deployment failed!" -ForegroundColor Red
        }
    } else {
        Write-Host "`n❌ Build failed!" -ForegroundColor Red
    }
    
    Set-Location $PSScriptRoot
}

function Deploy-Frontend {
    Write-Host "`n>>> Deploying Frontend to Firebase Hosting..." -ForegroundColor Green
    
    Set-Location "$PSScriptRoot\frontend"
    
    Write-Host "Building Flutter web app..." -ForegroundColor Yellow
    flutter build web --release
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Deploying to Firebase Hosting..." -ForegroundColor Yellow
        firebase deploy --only hosting --project courseverse-c9955
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "`n✅ Frontend deployed successfully!" -ForegroundColor Green
            Write-Host "URL: https://courseverse-c9955.web.app" -ForegroundColor Cyan
        } else {
            Write-Host "`n❌ Deployment failed!" -ForegroundColor Red
        }
    } else {
        Write-Host "`n❌ Build failed!" -ForegroundColor Red
    }
    
    Set-Location $PSScriptRoot
}

function Setup-Secrets {
    Write-Host "`n>>> Setting up Google Cloud Secrets..." -ForegroundColor Green
    
    Write-Host "`nThis will create secrets in Google Cloud Secret Manager." -ForegroundColor Yellow
    Write-Host "Make sure you have your credentials ready." -ForegroundColor Yellow
    Write-Host ""
    
    $awsAccessKey = Read-Host "Enter AWS Access Key"
    $awsSecretKey = Read-Host "Enter AWS Secret Key" -AsSecureString
    
    # Convert secure string to plain text for gcloud
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($awsSecretKey)
    $awsSecretKeyPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    
    Write-Host "`nCreating secrets..." -ForegroundColor Yellow
    
    # Create AWS access key secret
    echo $awsAccessKey | gcloud secrets create aws-access-key --data-file=- 2>$null
    if ($LASTEXITCODE -ne 0) {
        echo $awsAccessKey | gcloud secrets versions add aws-access-key --data-file=-
    }
    
    # Create AWS secret key secret
    echo $awsSecretKeyPlain | gcloud secrets create aws-secret-key --data-file=- 2>$null
    if ($LASTEXITCODE -ne 0) {
        echo $awsSecretKeyPlain | gcloud secrets versions add aws-secret-key --data-file=-
    }
    
    # Create Firebase service account secret
    $firebasePath = "$PSScriptRoot\backend\src\main\resources\firebase-service-account-key.json"
    if (Test-Path $firebasePath) {
        gcloud secrets create firebase-service-account --data-file="$firebasePath" 2>$null
        if ($LASTEXITCODE -ne 0) {
            gcloud secrets versions add firebase-service-account --data-file="$firebasePath"
        }
        Write-Host "✅ Firebase service account secret created/updated" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Firebase service account key not found at: $firebasePath" -ForegroundColor Yellow
    }
    
    Write-Host "`n✅ Secrets setup completed!" -ForegroundColor Green
}

function View-Logs {
    Write-Host "`n>>> Select log source:" -ForegroundColor Yellow
    Write-Host "1. App Engine Logs" -ForegroundColor White
    Write-Host "2. Cloud Run Logs" -ForegroundColor White
    $choice = Read-Host "Enter choice"
    
    switch ($choice) {
        "1" { gcloud app logs tail }
        "2" { gcloud run services logs tail courseverse-backend --region asia-south1 }
        default { Write-Host "Invalid choice" -ForegroundColor Red }
    }
}

function View-Status {
    Write-Host "`n>>> Deployment Status" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "Backend (App Engine):" -ForegroundColor Yellow
    gcloud app describe --format="value(defaultHostname)" 2>$null
    
    Write-Host "`nBackend (Cloud Run):" -ForegroundColor Yellow
    gcloud run services describe courseverse-backend --region asia-south1 --format="value(status.url)" 2>$null
    
    Write-Host "`nFrontend (Firebase Hosting):" -ForegroundColor Yellow
    Write-Host "https://courseverse-c9955.web.app" -ForegroundColor Cyan
    Write-Host "https://courseverse-c9955.firebaseapp.com" -ForegroundColor Cyan
}

# Main loop
do {
    Show-Menu
    $choice = Read-Host "Enter your choice"
    
    switch ($choice) {
        "1" { Deploy-BackendAppEngine }
        "2" { Deploy-BackendCloudRun }
        "3" { Deploy-Frontend }
        "4" { 
            $backendChoice = Read-Host "Deploy backend to (1) App Engine or (2) Cloud Run?"
            if ($backendChoice -eq "1") {
                Deploy-BackendAppEngine
            } elseif ($backendChoice -eq "2") {
                Deploy-BackendCloudRun
            }
            Deploy-Frontend
        }
        "5" { Setup-Secrets }
        "6" { View-Logs }
        "7" { View-Status }
        "8" { 
            Write-Host "`nGoodbye! 👋" -ForegroundColor Cyan
            exit 
        }
        default { Write-Host "`n❌ Invalid choice. Please try again." -ForegroundColor Red }
    }
    
    Write-Host "`nPress any key to continue..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    Clear-Host
} while ($true)
