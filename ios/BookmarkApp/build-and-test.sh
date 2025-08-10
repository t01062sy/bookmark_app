#!/bin/bash

# Build and Test Script for BookmarkApp with Share Extension
# Run this script after setting up the Share Extension target in Xcode

set -e

PROJECT_DIR="/Users/shohei.yoneda/playground/bookmark_app/ios/BookmarkApp"
PROJECT_NAME="BookmarkApp"
WORKSPACE_NAME="${PROJECT_NAME}.xcworkspace"
PROJECT_FILE="${PROJECT_NAME}.xcodeproj"
SCHEME_NAME="BookmarkApp"
SIMULATOR_NAME="iPhone 15 Pro"
SIMULATOR_OS=""

cd "$PROJECT_DIR"

echo "🚀 Building BookmarkApp with Share Extension..."

# Check if Xcode Command Line Tools are installed
if ! xcode-select -p &>/dev/null; then
    echo "❌ Xcode Command Line Tools not found. Please install them first:"
    echo "   xcode-select --install"
    exit 1
fi

# Check if workspace exists, otherwise use project
if [ -f "$WORKSPACE_NAME" ]; then
    BUILD_TARGET="-workspace $WORKSPACE_NAME"
    echo "📦 Using workspace: $WORKSPACE_NAME"
else
    BUILD_TARGET="-project $PROJECT_FILE"
    echo "📦 Using project: $PROJECT_FILE"
fi

# Get simulator device ID
SIMULATOR_ID=$(xcrun simctl list devices available | grep "$SIMULATOR_NAME" | head -1 | sed 's/.*(\(.*\)).*/\1/')

if [ -z "$SIMULATOR_ID" ]; then
    echo "❌ Simulator not found: $SIMULATOR_NAME"
    echo "Available simulators:"
    xcrun simctl list devices available | grep "iPhone"
    exit 1
fi

echo "📱 Using simulator: $SIMULATOR_NAME ($SIMULATOR_ID)"

# Boot simulator if not running
SIMULATOR_STATE=$(xcrun simctl list devices | grep "$SIMULATOR_ID" | grep -o "Shutdown\|Booted")
if [ "$SIMULATOR_STATE" = "Shutdown" ]; then
    echo "🔄 Booting simulator..."
    xcrun simctl boot "$SIMULATOR_ID"
    sleep 3
fi

# Open Simulator app
open -a Simulator

# Clean build
echo "🧹 Cleaning build..."
xcodebuild clean $BUILD_TARGET -scheme "$SCHEME_NAME" -destination "platform=iOS Simulator,id=$SIMULATOR_ID" -quiet

# Build main app
echo "🔨 Building main app..."
xcodebuild build $BUILD_TARGET -scheme "$SCHEME_NAME" -destination "platform=iOS Simulator,id=$SIMULATOR_ID" -quiet

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    
    # Find the built app
    BUILD_DIR=$(xcodebuild -showBuildSettings $BUILD_TARGET -scheme "$SCHEME_NAME" -destination "platform=iOS Simulator,id=$SIMULATOR_ID" | grep "BUILT_PRODUCTS_DIR" | head -1 | sed 's/.*= //')
    APP_PATH="$BUILD_DIR/${PROJECT_NAME}.app"
    
    if [ -d "$APP_PATH" ]; then
        # Install the app
        echo "📲 Installing app on simulator..."
        xcrun simctl install "$SIMULATOR_ID" "$APP_PATH"
        
        # Get bundle identifier
        BUNDLE_ID=$(plutil -p "$APP_PATH/Info.plist" | grep CFBundleIdentifier | sed 's/.*=> "//' | sed 's/"//')
        
        # Launch the app
        echo "🚀 Launching app..."
        xcrun simctl launch "$SIMULATOR_ID" "$BUNDLE_ID"
        
        echo ""
        echo "✅ BookmarkApp launched successfully!"
        echo "📱 Simulator: $SIMULATOR_NAME"
        echo "📦 Bundle ID: $BUNDLE_ID"
        echo ""
        echo "🔧 To test Share Extension:"
        echo "1. Open Safari in the simulator"
        echo "2. Navigate to any website"  
        echo "3. Tap the Share button"
        echo "4. Look for 'Add to Bookmarks' option"
        echo ""
        
    else
        echo "❌ App not found at: $APP_PATH"
        exit 1
    fi
    
else
    echo "❌ Build failed!"
    exit 1
fi