function fishblood --description "Manage the fishblood Nightscout prompt integration"
    set -l cmd $argv[1]
    set -e argv[1]
    switch "$cmd"
        case status ''
            echo "URL:      $fishblood_url"
            echo "Cache:    $fishblood_cache"
            echo "Interval: "$fishblood_update_interval"s"
            echo "Units:    $fishblood_units"
            if test -n "$fishblood_api_secret"
                echo "Secret:   (set)"
            else
                echo "Secret:   (not set)"
            end
            if test -f $fishblood_cache
                set -l raw (cat $fishblood_cache)
                echo "Raw:      $raw"
                set -l parts (string split \t -- $raw)
                if test (count $parts) -ge 3
                    set -l sgv $parts[1]
                    set -l delta $parts[3]
                    if string match -rq '^-?[0-9]+\.?[0-9]*$' -- $sgv
                        set -l source_is_mmol 0
                        if test (math -s0 "$sgv") -lt 40
                            set source_is_mmol 1
                        end
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
                    end
                    set -l arrow (__fishblood_arrow $parts[2])
                    echo "Display:  --> $sgv $arrow {$delta}"
                end
                set -l mtime (stat -c %Y $fishblood_cache 2>/dev/null)
                test -z "$mtime"; and set mtime (stat -f %m $fishblood_cache 2>/dev/null)
                if test -n "$mtime"
                    echo "Age:      "(math (date +%s) - $mtime)"s"
                end
            else
                echo "Current:  (no data)"
            end
        case refresh
            command rm -f $fishblood_cache
            if __fishblood_fetch_now
                echo "Refreshed: "(cat $fishblood_cache)
            else
                echo "fishblood: refresh failed (check \$fishblood_url and network)" >&2
                return 1
            end
        case units
            set -l u $argv[1]
            switch "$u"
                case mmol mgdl
                    set -U fishblood_units $u
                    echo "fishblood: display units set to $u"
                case ''
                    echo "$fishblood_units"
                case '*'
                    echo "fishblood: units must be 'mmol' or 'mgdl'" >&2
                    return 1
            end
        case enable
            __fishblood_enable
        case disable
            __fishblood_disable
        case help -h --help
            echo "Usage: fishblood <command>"
            echo
            echo "Commands:"
            echo "  status          Show configuration and cached value (default)"
            echo "  refresh         Force an immediate cache refresh"
            echo "  units [mmol|mgdl]  Show or set display units"
            echo "  enable          Splice the glucose segment into your fish_prompt"
            echo "  disable         Remove the glucose segment from your fish_prompt"
            echo "  help            Show this message"
            echo
            echo "Config (set as universal variables):"
            echo "  set -U fishblood_url <nightscout-url>"
            echo "  set -U fishblood_units mmol            (or mgdl; default mmol)"
            echo "  set -U fishblood_api_secret <secret>   (plaintext; hashed before sending)"
            echo "  set -U fishblood_update_interval <s>   (default 60)"
            echo "  set -U fishblood_cache <path>          (default /tmp/blood)"
        case '*'
            echo "fishblood: unknown command '$cmd' (try 'fishblood help')" >&2
            return 1
    end
end
