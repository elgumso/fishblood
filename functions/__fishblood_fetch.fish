function __fishblood_fetch --description "Refresh fishblood cache in the background if stale"
    if test -f $fishblood_cache
        set -l mtime (stat -c %Y $fishblood_cache 2>/dev/null)
        test -z "$mtime"; and set mtime (stat -f %m $fishblood_cache 2>/dev/null)
        if test -n "$mtime"
            set -l age (math (date +%s) - $mtime)
            if test $age -lt $fishblood_update_interval
                return 0
            end
        end
    end
    # Spawn an external fish process for the fetch instead of backgrounding the
    # function directly — fish waits for backgrounded *functions* to finish even
    # with `disown`, but a separate fish -c process is a true external command
    # from the parent's perspective, so `&` detaches it properly.
    fish -c __fishblood_fetch_now >/dev/null 2>&1 &
    disown 2>/dev/null
end
