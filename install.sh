#!/usr/bin/env sh
# Manual installer for fishblood — for users not running a fish plugin manager.
# Copies the plugin into $XDG_CONFIG_HOME/fish (default ~/.config/fish).

set -eu

SRC="$(cd "$(dirname "$0")" && pwd)"
DEST="${XDG_CONFIG_HOME:-$HOME/.config}/fish"

echo "[+] fishblood manual installer"
echo "    source: $SRC"
echo "    target: $DEST"
echo

missing=""
for cmd in fish curl jq; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        missing="$missing $cmd"
    fi
done
if [ -n "$missing" ]; then
    echo "[-] missing required dependencies:$missing" >&2
    echo "    install them and re-run this script." >&2
    exit 1
fi

fish_ver=$(fish -c 'echo $version')
case "$fish_ver" in
    3.[3-9]*|3.[1-9][0-9]*|[4-9].*|[1-9][0-9]*.*) ;;
    *)
        echo "[-] fish $fish_ver detected; fishblood requires 3.3.0 or newer." >&2
        exit 1
        ;;
esac

mkdir -p "$DEST/conf.d" "$DEST/functions" "$DEST/completions"

echo "[+] copying plugin files..."
cp "$SRC/conf.d/fishblood.fish"            "$DEST/conf.d/"
cp "$SRC/functions/fishblood.fish"         "$DEST/functions/"
cp "$SRC/functions/fishblood_prompt_segment.fish" "$DEST/functions/"
cp "$SRC/functions/bloodsugar.fish"        "$DEST/functions/"
cp "$SRC/functions/__fishblood_fetch.fish"      "$DEST/functions/"
cp "$SRC/functions/__fishblood_fetch_now.fish"  "$DEST/functions/"
cp "$SRC/functions/__fishblood_arrow.fish"      "$DEST/functions/"
cp "$SRC/functions/__fishblood_enable.fish"     "$DEST/functions/"
cp "$SRC/functions/__fishblood_disable.fish"    "$DEST/functions/"
cp "$SRC/completions/fishblood.fish"       "$DEST/completions/"
cp "$SRC/completions/bloodsugar.fish"      "$DEST/completions/"

echo
echo "[+] installed."
echo
echo "Next steps:"
echo "  1. Set your Nightscout URL (in a fish shell):"
echo "       set -U fishblood_url https://your.nightscout.example"
echo "  2. Pick display units (default is mmol):"
echo "       fishblood units mmol   # or mgdl"
echo "  3. Splice the segment into your fish_prompt:"
echo "       fishblood enable"
echo "  4. Start a new shell."
echo
echo "Uninstall later with: $SRC/uninstall.sh"
