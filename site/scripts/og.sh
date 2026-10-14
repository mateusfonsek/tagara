#!/bin/bash
# Renders the social preview images (public/og-pt.png, public/og-en.png) from og/og.html.
# Needs Google Chrome; run again whenever the art or the slogans change.
set -euo pipefail
cd "$(dirname "$0")/.."

CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
for lang in pt en; do
    "$CHROME" --headless=new --disable-gpu --hide-scrollbars --allow-file-access-from-files \
        --force-device-scale-factor=1 --window-size=1200,630 --virtual-time-budget=3000 \
        --screenshot="$PWD/public/og-$lang.png" "file://$PWD/og/og.html?lang=$lang"
done
sips -g pixelWidth -g pixelHeight public/og-pt.png public/og-en.png
