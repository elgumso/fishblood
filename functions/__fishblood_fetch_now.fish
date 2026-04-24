function __fishblood_fetch_now --description "Synchronously refresh the fishblood cache from the /pebble endpoint"
    if string match -q "*your_nightscout_server*" -- $fishblood_url
        return 1
    end
    # /pebble returns sgv and bgdelta in the server's configured display units
    # (mmol/L or mg/dL). We store the raw values and auto-detect units at
    # display time via the sgv < 40 heuristic (mmol/L is always < 40).
    set -l url "$fishblood_url/pebble"
    set -l curl_args -sfL --max-time 5
    if test -n "$fishblood_api_secret"
        set -l hash (echo -n $fishblood_api_secret | sha1sum 2>/dev/null | awk '{print $1}')
        if test -z "$hash"
            set hash (echo -n $fishblood_api_secret | shasum 2>/dev/null | awk '{print $1}')
        end
        if test -n "$hash"
            set curl_args $curl_args -H "api-secret: $hash"
        end
    end
    set -l raw (curl $curl_args "$url" 2>/dev/null \
        | jq -r '.bgs[0] | [.sgv, (.direction // "NONE"), (.bgdelta // "0")] | @tsv' 2>/dev/null)
    test -n "$raw"; or return 1
    set -l parts (string split \t -- $raw)
    test (count $parts) -ge 3; or return 1
    test -n "$parts[1]"; or return 1
    test "$parts[1]" != null; or return 1
    set -l tmp $fishblood_cache.tmp
    printf '%s\t%s\t%s\n' $parts[1] $parts[2] $parts[3] >$tmp
    and mv $tmp $fishblood_cache
    or begin
        command rm -f $tmp
        return 1
    end
end
