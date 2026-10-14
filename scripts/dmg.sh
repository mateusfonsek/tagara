#!/bin/bash
# Builds Tagara and packs it into dist/Tagara-<version>.dmg, with a shortcut to /Applications.
#
#   VERSION=0.1.7 scripts/dmg.sh
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${VERSION:-dev}"
export VERSION
scripts/bundle.sh >/dev/null

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
mv build/Tagara.app "$STAGE/Tagara.app"
ln -s /Applications "$STAGE/Applications"

mkdir -p dist
DMG="dist/Tagara-$VERSION.dmg"
rm -f "$DMG"
hdiutil create -volname "Tagara" -srcfolder "$STAGE" -fs HFS+ -format UDZO -ov "$DMG" >/dev/null
echo "$DMG"
