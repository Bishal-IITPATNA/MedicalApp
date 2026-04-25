#!/usr/bin/env bash
# Rebuild the Flutter web frontend and deploy it under /app/frontend/web_dist.
# Usage:  bash /app/scripts/build_frontend.sh
set -euo pipefail

export PATH="$PATH:/app/.flutter/bin"
APP_DIR="/app/.flutter_app"
DIST_DIR="/app/frontend/web_dist"
INDEX_SHIM_BACKUP="/tmp/_seevak_index_shim.html"

if [ ! -d "$APP_DIR" ]; then
  echo "Flutter source dir $APP_DIR not found"; exit 1
fi

# Preserve the locale-shim index.html across rebuilds
if [ -f "$DIST_DIR/index.html" ]; then
  cp "$DIST_DIR/index.html" "$INDEX_SHIM_BACKUP"
fi

cd "$APP_DIR"
flutter pub get
# /api is a relative URL so the same build works for preview AND production
flutter build web --release --dart-define=API_BASE_URL=/api

rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"
cp -r "$APP_DIR/build/web/." "$DIST_DIR/"

if [ -f "$INDEX_SHIM_BACKUP" ]; then
  cp "$INDEX_SHIM_BACKUP" "$DIST_DIR/index.html"
fi

sudo supervisorctl restart frontend || true
echo "Frontend rebuilt at $DIST_DIR"
