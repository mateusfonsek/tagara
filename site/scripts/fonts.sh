#!/bin/bash
# Converts the brand fonts (branding/fonts, OFL) to woff2 for the site. Run once per font change.
set -euo pipefail
cd "$(dirname "$0")/.."

OUT=src/assets/fonts
mkdir -p "$OUT"
for name in AtkinsonHyperlegibleNext AtkinsonHyperlegibleMono; do
    uvx --from 'fonttools[woff]==4.65.0' fonttools ttLib.woff2 compress \
        -o "$OUT/$name.woff2" "../branding/fonts/$name.ttf"
done
cp ../branding/fonts/OFL.txt "$OUT/OFL.txt"
ls -la "$OUT"
