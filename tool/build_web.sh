#!/usr/bin/env bash
# Build PWA Mabar: `flutter build web` + mengisi daftar precache & versi di sw.js.
# Pakai ini, bukan `flutter build web` langsung — tanpa langkah kedua app tidak jalan offline.
#
#   tool/build_web.sh                 # deploy di root domain
#   tool/build_web.sh --base-href /mabar/   # deploy di sub-path (mis. GitHub Pages)
set -euo pipefail
cd "$(dirname "$0")/.."

# --no-web-resources-cdn: CanvasKit disajikan dari server sendiri, bukan gstatic.com,
# supaya bisa ikut di-cache service worker (cross-origin tidak kita cache).
flutter build web --release --no-tree-shake-icons --no-web-resources-cdn --no-wasm-dry-run "$@"

cd build/web
files=$(find . -type f \
  ! -path './canvaskit/*' ! -name '*.symbols' ! -name '.last_build_id' \
  ! -name 'sw.js' ! -name 'flutter_service_worker.js' \
  | sed 's|^\./||' | LC_ALL=C sort)

# Versi = hash isi seluruh file, jadi sw.js hanya berubah (dan memicu update) kalau app-nya berubah.
version=$(echo "$files" | xargs shasum | shasum | cut -c1-12)
list=$(echo "$files" | sed 's/.*/"&"/' | paste -sd, -)

sed -i.bak -e "s|__MABAR_VERSION__|$version|" -e "s|__MABAR_PRECACHE__|[$list]|" sw.js
rm sw.js.bak
echo "sw.js: versi $version, $(echo "$files" | wc -l | tr -d ' ') file di-precache"
