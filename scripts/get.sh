#!/bin/bash
# Installs (or updates) Tagara from the latest GitHub release.
#
#   curl -fsSL https://raw.githubusercontent.com/mateusfonsek/tagara/main/scripts/get.sh | bash
#
# Downloads the latest DMG, replaces /Applications/Tagara.app, clears the quarantine flag
# so macOS doesn't block the first launch, and opens the app.
set -euo pipefail

REPO="mateusfonsek/tagara"
DEST="${DEST:-/Applications}"

say() { printf '\033[1m%s\033[0m\n' "$1"; }
fail() { printf 'Erro: %s\n' "$1" >&2; exit 1; }

[ "$(uname -s)" = "Darwin" ] || fail "o Tagara só roda no macOS."
[ "$(uname -m)" = "arm64" ] || fail "o Tagara precisa de um Mac com Apple Silicon (M1 ou mais novo)."

say "Procurando a versão mais recente…"
URL=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
    | grep -o '"browser_download_url": *"[^"]*\.dmg"' | head -1 | cut -d'"' -f4)
[ -n "$URL" ] || fail "não achei o DMG na última release de $REPO."

TMP=$(mktemp -d)
MOUNT="$TMP/volume"
cleanup() {
    hdiutil detach "$MOUNT" -quiet 2>/dev/null || true
    rm -rf "$TMP"
}
trap cleanup EXIT

say "Baixando $(basename "$URL")…"
curl -fL --progress-bar -o "$TMP/Tagara.dmg" "$URL"

hdiutil attach "$TMP/Tagara.dmg" -nobrowse -readonly -quiet -mountpoint "$MOUNT"
[ -d "$MOUNT/Tagara.app" ] || fail "o DMG não tem o Tagara.app."

if pgrep -x Tagara >/dev/null; then
    say "Fechando o Tagara aberto…"
    osascript -e 'with timeout of 5 seconds' -e 'quit app "Tagara"' -e 'end timeout' >/dev/null 2>&1 || true
    # The quit request can be ignored (it is, when the app itself started this script to
    # update), and `open` would then just bring the old process back to front.
    for _ in 1 2 3 4 5 6 7 8 9 10; do pgrep -x Tagara >/dev/null || break; sleep 0.3; done
    pkill -x Tagara 2>/dev/null || true
    for _ in 1 2 3 4 5 6 7 8 9 10; do pgrep -x Tagara >/dev/null || break; sleep 0.3; done
fi

say "Instalando em ${DEST}…"
mkdir -p "$DEST"
rm -rf "$DEST/Tagara.app"
cp -R "$MOUNT/Tagara.app" "$DEST/Tagara.app"
xattr -dr com.apple.quarantine "$DEST/Tagara.app" 2>/dev/null || true

if [ "$DEST" = "/Applications" ] && [ -d "$HOME/Applications/Tagara.app" ]; then
    printf 'Aviso: também existe %s. Apague uma das cópias para não ter dois Tagaras.\n' "$HOME/Applications/Tagara.app"
fi

if [ "${OPEN:-1}" = "1" ]; then
    say "Pronto! Abrindo o Tagara."
    open "$DEST/Tagara.app"
else
    say "Pronto! Tagara instalado em ${DEST}."
fi
