#!/bin/bash

# Deployment script for CibilFixer Partner App
echo "🚀 Starting deployment process..."

# Step 1: Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
flutter pub get

# Step 2: Build Flutter web app
echo "🔨 Building Flutter web app..."
flutter build web --release --web-renderer html

# Step 3: Check if build was successful
if [ ! -d "build/web" ]; then
    echo "❌ Build failed! build/web directory not found."
    exit 1
fi

echo "✅ Build completed successfully!"

# Step 4: Prepare deployment directory
echo "📦 Preparing deployment directory..."

# Remove existing deployment directory if it exists
if [ -d "deployment" ]; then
    rm -rf deployment
fi

# Create deployment directory
mkdir deployment
cd deployment

# Initialize git repository
git init
git branch -M main

# Copy build files
cp -r ../build/web/* .

# Copy vercel.json to root
cp ../vercel.json .

# Create README for the deployment repo
cat > README.md << EOF
# CibilFixer Partner Portal - Deployment

This repository contains the built Flutter web application for the CibilFixer Partner Portal.

## Deployment
This app is automatically deployed to Vercel when changes are pushed to this repository.

## Last Build
Built on: \$(date)

## Tech Stack
- Flutter Web
- Firebase (Authentication, Firestore, Storage)
- Vercel Hosting
EOF

# Add all files
git add .

# Commit
git commit -m "Deploy: $(date '+%Y-%m-%d %H:%M:%S')"

echo "📁 Deployment files prepared in ./deployment directory"
echo ""
echo "🔗 Next steps:"
echo "1. Create a new GitHub repository for deployment"
echo "2. Add the remote: git remote add origin <your-deployment-repo-url>"
echo "3. Push: git push -u origin main"
echo "4. Connect the repository to Vercel"
echo ""
echo "✨ Deployment preparation complete!"