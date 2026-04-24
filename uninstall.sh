#!/usr/bin/env sh
# Manual uninstaller for fishblood.
# Runs `fishblood disable` to restore the prompt backup, then removes
# the plugin files and universal variables.

set -eu

DEST="${XDG_CONFIG_HOME:-$HOME/.config}/fish"

echo "[+] fishblood manual uninstaller"
echo "    target: $DEST"
echo

if command -v fish >/dev/null 2>&1; then
    echo "[+] restoring fish_prompt (via __fishblood_disable)..."
    fish -c 'functions -q __fishblood_disable; and __fishblood_disable' || true

    echo "[+] clearing cache file..."
    fish -c 'set -q fishblood_cache; and command rm -f $fishblood_cache $fishblood_cache.tmp' || true

    echo "[+] erasing universal variables..."
    fish -c '
        set -e fishblood_url
        set -e fishblood_cache
        set -e fishblood_update_interval
        set -e fishblood_units
        set -e fishblood_api_secret
    ' || true
else
    echo "[!] fish not found in PATH; skipping in-shell cleanup." >&2
    echo "    You may need to manually restore ~/.config/fish/functions/fish_prompt.fish" >&2
    echo "    from its .fishblood.bak backup if one exists." >&2
fi

echo "[+] removing plugin files..."
rm -f \
    "$DEST/conf.d/fishblood.fish" \
    "$DEST/functions/fishblood.fish" \
    "$DEST/functions/fishblood_prompt_segment.fish" \
    "$DEST/functions/bloodsugar.fish" \
    "$DEST/functions/__fishblood_fetch.fish" \
    "$DEST/functions/__fishblood_fetch_now.fish" \
    "$DEST/functions/__fishblood_arrow.fish" \
    "$DEST/functions/__fishblood_enable.fish" \
    "$DEST/functions/__fishblood_disable.fish" \
    "$DEST/completions/fishblood.fish" \
    "$DEST/completions/bloodsugar.fish"

echo
echo "[+] fishblood uninstalled."
