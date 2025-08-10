#!/usr/bin/env bash
set -euo pipefail

SCHEME="BookmarkApp"
DEST_NAME="iPhone 15 Pro"
DERIVED="build"
BUNDLE_ID="com.example.BookmarkApp"

echo "› Booting simulator…"
xcrun simctl boot "$DEST_NAME" || true
xcrun simctl bootstatus booted -b
open -a Simulator

echo "› Building…"
if [ -d "*.xcworkspace" ] || ls *.xcworkspace >/dev/null 2>&1; then
  WORKSPACE=$(ls *.xcworkspace | head -n1)
  xcodebuild -workspace "$WORKSPACE" -scheme "$SCHEME" -configuration Debug -sdk iphonesimulator -destination "platform=iOS Simulator,name=$DEST_NAME" -derivedDataPath "$DERIVED" | xcbeautify || true
else
  PROJECT=$(ls *.xcodeproj | head -n1)
  xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Debug -sdk iphonesimulator -destination "platform=iOS Simulator,name=$DEST_NAME" -derivedDataPath "$DERIVED" | xcbeautify || true
fi

APP_PATH=$(find "$DERIVED/Build/Products/Debug-iphonesimulator" -maxdepth 1 -name "*.app" | head -n1)
echo "› Installing $APP_PATH"
xcrun simctl uninstall booted "$BUNDLE_ID" || true
xcrun simctl install booted "$APP_PATH"

echo "› Launching $BUNDLE_ID"
xcrun simctl launch --console booted "$BUNDLE_ID"
