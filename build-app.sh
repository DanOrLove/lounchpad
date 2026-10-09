#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$ROOT_DIR/dist/Lunchpad.app"

cd "$ROOT_DIR"
swift build -c release
mkdir -p "$APP_DIR/Contents/MacOS"
cp "$ROOT_DIR/.build/release/Lunchpad" "$APP_DIR/Contents/MacOS/Lunchpad"
cat > "$APP_DIR/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>Lunchpad</string>
    <key>CFBundleIdentifier</key><string>local.lunchpad.app</string>
    <key>CFBundleName</key><string>Lunchpad</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSPrincipalClass</key><string>NSApplication</string>
</dict>
</plist>
PLIST
echo "Собрано: $APP_DIR"
