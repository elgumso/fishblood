function fishblood_prompt_segment --description "Render the fishblood glucose segment for fish_prompt"
    __fishblood_fetch
    test -f $fishblood_cache; or return
    set -l data (cat $fishblood_cache 2>/dev/null)
    test -n "$data"; or return
    set -l parts (string split \t -- $data)
    test (count $parts) -ge 3; or return
    set -l sgv $parts[1]
    set -l direction $parts[2]
    set -l delta $parts[3]
    test -n "$sgv"; or return
    # Non-numeric sgv (e.g. "LOW", "HIGH") — display as-is, no color/conversion
    if not string match -rq '^-?[0-9]+\.?[0-9]*$' -- $sgv
        set -l arrow (__fishblood_arrow $direction)
        echo -n -s ' --> ' $sgv
        if test -n "$arrow"
            echo -n -s ' ' $arrow
        end
        return
    end
    # Auto-detect source units: pebble returns the server's display units.
    # mmol/L is always < 40, mg/dL is always >= 40.
    set -l source_is_mmol 0
    if test (math -s0 "$sgv") -lt 40
        set source_is_mmol 1
    end
    # Color threshold check in mg/dL: low < 70, high > 180
    set -l sgv_mgdl $sgv
    if test $source_is_mmol -eq 1
        set sgv_mgdl (math "$sgv * 18")
    end
    set -l bg_color green
    if test (math -s0 "$sgv_mgdl") -lt 70; or test (math -s0 "$sgv_mgdl") -gt 180
        set bg_color red
    end
    # Convert for display if source units differ from fishblood_units
    if test "$fishblood_units" = mmol
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
    echo -n -s ' --> '
    set_color $bg_color
    echo -n -s $sgv
    if test -n "$arrow"
        echo -n -s ' ' $arrow
    end
    set_color normal
    echo -n -s ' {' $delta '}'
end
