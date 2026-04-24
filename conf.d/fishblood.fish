set -q fishblood_url; or set -U fishblood_url "https://your_nightscout_server.com"
set -q fishblood_cache; or set -U fishblood_cache /tmp/blood
set -q fishblood_update_interval; or set -U fishblood_update_interval 60
set -q fishblood_units; or set -U fishblood_units mmol
set -q fishblood_api_secret; or set -U fishblood_api_secret ""

function _fishblood_install --on-event fishblood_install
    echo "fishblood installed."
    echo
    echo "Next steps:"
    echo "  1. Point it at your Nightscout instance:"
    echo "       set -U fishblood_url https://your.nightscout.example"
    echo "  2. Add the glucose segment to your fish_prompt:"
    echo "       fishblood enable"
    echo "  3. Start a new shell."
    echo
    echo "Requires: curl, jq"
end

function _fishblood_update --on-event fishblood_update
    echo "fishblood updated."
end

function _fishblood_uninstall --on-event fishblood_uninstall
    __fishblood_disable 2>/dev/null
    command rm -f $fishblood_cache $fishblood_cache.tmp
    set -e fishblood_url
    set -e fishblood_cache
    set -e fishblood_update_interval
    set -e fishblood_units
    set -e fishblood_api_secret
    echo "fishblood uninstalled."
end
