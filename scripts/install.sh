#!/bin/bash
# Builds Tagara and installs it to ~/Applications, replacing the previous copy.
set -euo pipefail
cd "$(dirname "$0")/.."

# "dev" tells the in-app updater not to replace this build with a release.
VERSION=dev scripts/bundle.sh >/dev/null

# Move (not copy) so the build folder never holds a second Tagara.app for Spotlight to find.
mkdir -p ~/Applications
pkill -x Tagara 2>/dev/null || true
rm -rf ~/Applications/Tagara.app
mv build/Tagara.app ~/Applications/Tagara.app
echo "Instalado em ~/Applications/Tagara.app"
