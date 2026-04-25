#!/usr/bin/env bash
# Render Static Site build script for the Flutter Web frontend.
# Render does not ship Flutter, so we install it on each build.
# Cached to /opt/render/project/.flutter between builds when possible.
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.41.6}"
API_BASE_URL_ENV="${API_BASE_URL:-}"
FLUTTER_HOME="${RENDER_PROJECT_DIR:-$PWD/..}/.flutter"

echo "==> Flutter version target: $FLUTTER_VERSION"
echo "==> API_BASE_URL: ${API_BASE_URL_ENV:-(empty / host-relative)}"

if [ ! -x "$FLUTTER_HOME/bin/flutter" ]; then
  echo "==> Installing Flutter SDK $FLUTTER_VERSION"
  rm -rf "$FLUTTER_HOME"
  git clone --depth 1 -b "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_HOME"
fi

export PATH="$FLUTTER_HOME/bin:$PATH"
git config --global --add safe.directory "$FLUTTER_HOME"

flutter --version
flutter precache --web --no-android --no-ios --no-linux --no-windows --no-macos --no-fuchsia
flutter pub get

echo "==> Building Flutter web (release)"
flutter build web \
  --release \
  --dart-define=API_BASE_URL="$API_BASE_URL_ENV"

# Inject the navigator.language shim so the Dart `intl` package never crashes
# on browsers that report a non-canonical locale (preview / headless / older).
INDEX_FILE="build/web/index.html"
if ! grep -q "navigator.language" "$INDEX_FILE"; then
  python3 - "$INDEX_FILE" <<'PY'
import sys, pathlib
p = pathlib.Path(sys.argv[1])
html = p.read_text()
shim = '''  <script>
    (function () {
      try {
        var lang = (navigator.language || '').trim();
        var ok = /^[a-zA-Z]{2,3}(-[A-Za-z0-9]+)*$/.test(lang);
        if (!ok) {
          Object.defineProperty(navigator, 'language',  { get: function () { return 'en-US'; } });
          Object.defineProperty(navigator, 'languages', { get: function () { return ['en-US', 'en']; } });
        }
      } catch (e) {}
    })();
  </script>
</head>'''
p.write_text(html.replace('</head>', shim))
PY
  echo "==> Locale shim injected into index.html"
fi

echo "==> Build complete: build/web/"
ls -la build/web | head
