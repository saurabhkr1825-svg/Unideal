#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "Starting Flutter Web build for Vercel..."

# 1. Download Flutter SDK from stable channel
if [ ! -d "flutter" ]; then
    echo "Cloning Flutter SDK..."
    git clone https://github.com/flutter/flutter.git -b stable
fi

# 2. Add flutter to PATH
export PATH="$PATH:`pwd`/flutter/bin"

# 3. Print flutter version (also triggers initial download of Dart SDK and other tools)
echo "Flutter version:"
flutter --version

# 4. Enable flutter web (just in case)
echo "Enabling Flutter Web..."
flutter config --enable-web

# 5. Fetch dependencies
echo "Getting packages..."
flutter pub get

# 6. Build the web app
echo "Building Flutter Web..."
flutter build web --release

echo "Build completed successfully. Output is in build/web."
