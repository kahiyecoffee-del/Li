#!/usr/bin/env bash
# Builds the web preview and copies it into a gh-pages worktree ($1).
set -euo pipefail
out="$1"
flutter build web --release --base-href /Li/
find "$out" -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
cp -r build/web/. "$out"
cp tool/web/kill_service_worker.js "$out/flutter_service_worker.js"
touch "$out/.nojekyll"
