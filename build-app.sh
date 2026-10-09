#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$ROOT_DIR/dist/Lunchpad.app"
RESOURCE_DIR="$ROOT_DIR/Resources"
APP_VERSION="$(cat "$ROOT_DIR/VERSION")"

cd "$ROOT_DIR"
swift "$ROOT_DIR/Scripts/GenerateIcon.swift" "$RESOURCE_DIR"
swift build -c release
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"
cp "$ROOT_DIR/.build/release/Lunchpad" "$APP_DIR/Contents/MacOS/Lunchpad"
cp "$RESOURCE_DIR/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
cat > "$APP_DIR/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>Lunchpad</string>
    <key>CFBundleIdentifier</key><string>local.lunchpad.app</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>CFBundleShortVersionString</key><string>$APP_VERSION</string>
    <key>CFBundleVersion</key><string>$APP_VERSION</string>
    <key>CFBundleName</key><string>Lunchpad</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSPrincipalClass</key><string>NSApplication</string>
</dict>
</plist>
PLIST

if [[ -n "${LUNCHPAD_CODESIGN_IDENTITY:-}" ]]; then
    codesign --force --deep --options runtime --sign "$LUNCHPAD_CODESIGN_IDENTITY" "$APP_DIR"
fi

echo "Собрано: $APP_DIR"
