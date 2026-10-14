#!/bin/bash
# Builds Tagara and installs it to ~/Applications, replacing the previous copy.
set -euo pipefail
cd "$(dirname "$0")/.."

scripts/bundle.sh >/dev/null

# Move (not copy) so the build folder never holds a second Tagara.app for Spotlight to find.
mkdir -p ~/Applications
pkill -x Tagara 2>/dev/null || true
rm -rf ~/Applications/Tagara.app
mv build/Tagara.app ~/Applications/Tagara.app
echo "Instalado em ~/Applications/Tagara.app"
