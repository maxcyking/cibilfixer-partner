@echo off
echo 🚀 Starting deployment process...

REM Step 1: Clean previous builds
echo 🧹 Cleaning previous builds...
flutter clean
flutter pub get

REM Step 2: Build Flutter web app
echo 🔨 Building Flutter web app...
flutter build web --release --web-renderer html

REM Step 3: Check if build was successful
if not exist "build\web" (
    echo ❌ Build failed! build\web directory not found.
    pause
    exit /b 1
)

echo ✅ Build completed successfully!

REM Step 4: Prepare deployment directory
echo 📦 Preparing deployment directory...

REM Remove existing deployment directory if it exists
if exist "deployment" rmdir /s /q deployment

REM Create deployment directory
mkdir deployment
cd deployment

REM Initialize git repository
git init
git branch -M main

REM Copy build files
xcopy "..\build\web\*" "." /s /e /y

REM Copy vercel.json to root
copy "..\vercel.json" "."

REM Create README for the deployment repo
echo # CibilFixer Partner Portal - Deployment > README.md
echo. >> README.md
echo This repository contains the built Flutter web application for the CibilFixer Partner Portal. >> README.md
echo. >> README.md
echo ## Deployment >> README.md
echo This app is automatically deployed to Vercel when changes are pushed to this repository. >> README.md
echo. >> README.md
echo ## Last Build >> README.md
echo Built on: %date% %time% >> README.md
echo. >> README.md
echo ## Tech Stack >> README.md
echo - Flutter Web >> README.md
echo - Firebase (Authentication, Firestore, Storage) >> README.md
echo - Vercel Hosting >> README.md

REM Add all files
git add .

REM Commit
git commit -m "Deploy: %date% %time%"

echo 📁 Deployment files prepared in .\deployment directory
echo.
echo 🔗 Next steps:
echo 1. Create a new GitHub repository for deployment
echo 2. Add the remote: git remote add origin ^<your-deployment-repo-url^>
echo 3. Push: git push -u origin main
echo 4. Connect the repository to Vercel
echo.
echo ✨ Deployment preparation complete!
pause