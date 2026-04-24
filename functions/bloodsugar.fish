function bloodsugar --description "Print the current blood glucose value, trend arrow, and delta"
    set -l units $fishblood_units
    if test (count $argv) -gt 0
        switch "$argv[1]"
            case mmol mmol/l mmol/L
                set units mmol
            case mgdl mg/dl mg/dL
                set units mgdl
            case -h --help help
                echo "Usage: bloodsugar [mmol|mgdl]"
                echo
                echo "Prints the latest blood glucose value, trend arrow, and delta."
                echo "If no unit is given, uses \$fishblood_units (currently: $fishblood_units)."
                return 0
            case '*'
                echo "bloodsugar: unknown argument '$argv[1]' (try mmol or mgdl)" >&2
                return 1
        end
    end

    # Synchronous refresh if cache is missing or stale — call mode is interactive,
    # the user is waiting on the value, so we don't background the fetch like the
    # prompt segment does.
    set -l need_fetch 1
    if test -f $fishblood_cache
        set -l mtime (stat -c %Y $fishblood_cache 2>/dev/null)
        test -z "$mtime"; and set mtime (stat -f %m $fishblood_cache 2>/dev/null)
        if test -n "$mtime"
            set -l age (math (date +%s) - $mtime)
            if test $age -lt $fishblood_update_interval
                set need_fetch 0
            end
        end
    end
    if test $need_fetch -eq 1
        if not __fishblood_fetch_now
            echo "bloodsugar: fetch failed (check \$fishblood_url and network)" >&2
            return 1
        end
    end

    test -f $fishblood_cache; or begin
        echo "bloodsugar: no cached data" >&2
        return 1
    end
    set -l data (cat $fishblood_cache)
    set -l parts (string split \t -- $data)
    test (count $parts) -ge 3; or begin
        echo "bloodsugar: malformed cache" >&2
        return 1
    end
    set -l sgv $parts[1]
    set -l direction $parts[2]
    set -l delta $parts[3]

    # Auto-detect source units from pebble (mmol if < 40)
    set -l source_is_mmol 0
    if string match -rq '^-?[0-9]+\.?[0-9]*$' -- $sgv
        if test (math -s0 "$sgv") -lt 40
            set source_is_mmol 1
        end
    end

    # Color threshold check in mg/dL
    set -l bg_color green
    if string match -rq '^-?[0-9]+\.?[0-9]*$' -- $sgv
        set -l sgv_mgdl $sgv
        if test $source_is_mmol -eq 1
            set sgv_mgdl (math "$sgv * 18")
        end
        if test (math -s0 "$sgv_mgdl") -lt 70; or test (math -s0 "$sgv_mgdl") -gt 180
            set bg_color red
        end
    end

    # Convert for display if source units differ from requested units
    if test "$units" = mmol
        if test $source_is_mmol -eq 0
            set sgv (math -s1 "$sgv / 18")
            set delta (math -s1 "$delta / 18")
        end
    else
        if test $source_is_mmol -eq 1
            set sgv (math -s0 "$sgv * 18")
            set delta (math -s0 "$delta * 18")
        end
    end

    set -l arrow (__fishblood_arrow $direction)
    set -l unit_label mg/dL
    test "$units" = mmol; and set unit_label mmol/L

    set_color $bg_color
    echo -n $sgv
    set_color normal
    echo -n " $unit_label"
    if test -n "$arrow"
        set_color $bg_color
        echo -n " $arrow"
        set_color normal
    end
    echo " $delta"
end
