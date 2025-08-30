#!/bin/bash

# Build script for Vercel deployment
echo "Building Flutter web app..."

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build for web
flutter build web --release --web-renderer html

echo "Build completed successfully!"
echo "Web files are in build/web/"