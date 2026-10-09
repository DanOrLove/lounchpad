#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
"$ROOT_DIR/build-app.sh"
"$ROOT_DIR/build-dmg.sh"
