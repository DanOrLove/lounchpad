#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_VERSION="$(cat "$ROOT_DIR/VERSION")"
APP_PATH="$ROOT_DIR/dist/Lunchpad.app"
OUTPUT_PATH="$ROOT_DIR/dist/Lunchpad-v$APP_VERSION.dmg"
STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/lunchpad-dmg.XXXXXX")"
trap 'rm -rf "$STAGING_DIR"' EXIT

if [[ ! -d "$APP_PATH" ]]; then
    echo "Не найдено приложение $APP_PATH. Сначала выполните ./build-app.sh" >&2
    exit 1
fi

ditto "$APP_PATH" "$STAGING_DIR/Lunchpad.app"
ln -s /Applications "$STAGING_DIR/Applications"

mkdir -p "$(dirname "$OUTPUT_PATH")"
hdiutil create \
    -volname "Lunchpad" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDZO \
    -imagekey zlib-level=9 \
    "$OUTPUT_PATH"

printf 'Установщик собран: %s\n' "$OUTPUT_PATH"
