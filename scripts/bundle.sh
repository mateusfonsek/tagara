#!/bin/bash
# Builds Tagara.app (release, Apple Silicon) into build/Tagara.app.
#
#   VERSION=0.1.7 scripts/bundle.sh     # stamps the version into Info.plist
#
# Signs with the local "Tagara Dev" certificate when present (see setup-signing.sh),
# otherwise ad-hoc, which is what CI does.
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$(pwd -P)"

APP=build/Tagara.app
IDENTITY="${IDENTITY:-Tagara Dev}"

swift build -c release --arch arm64
BIN="$(swift build -c release --arch arm64 --show-bin-path)/Tagara"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Tagara"
cp Resources/Info.plist "$APP/Contents/Info.plist"
if [ -n "${VERSION:-}" ]; then
    plutil -replace CFBundleShortVersionString -string "$VERSION" "$APP/Contents/Info.plist"
    # CFBundleVersion must stay numeric; "dev" builds keep the one from Info.plist.
    if [[ "${VERSION##*.}" =~ ^[0-9]+$ ]]; then
        plutil -replace CFBundleVersion -string "${VERSION##*.}" "$APP/Contents/Info.plist"
    fi
fi

# Liquid Glass icon from Icon Composer plus the brand accent color, compiled into Assets.car
# (AppIcon.icns as fallback). actool resolves relative paths against $PWD, which can be stale.
xcrun actool "$ROOT/Resources/AppIcon.icon" "$ROOT/Resources/Assets.xcassets" --accent-color AccentColor \
    --compile "$ROOT/$APP/Contents/Resources" \
    --platform macosx --minimum-deployment-target 15.0 --app-icon AppIcon \
    --output-partial-info-plist "$ROOT/build/icon-info.plist" --output-format human-readable-text >/dev/null

# A stable identity keeps macOS permissions across rebuilds; ad-hoc signing resets them.
if security find-certificate -c "$IDENTITY" >/dev/null 2>&1; then
    codesign --force --options runtime --entitlements Resources/Tagara.entitlements --sign "$IDENTITY" "$APP"
else
    codesign --force --options runtime --entitlements Resources/Tagara.entitlements --sign - "$APP"
fi
echo "$APP"
