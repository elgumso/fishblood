function __fishblood_enable --description "Inject fishblood_prompt_segment into the user's fish_prompt"
    set -l target $__fish_config_dir/functions/fish_prompt.fish
    if test -f $target
        if grep -q fishblood_prompt_segment $target
            echo "fishblood: already enabled in $target"
            return 0
        end
        cp $target $target.fishblood.bak
    else
        mkdir -p (dirname $target)
        funcsave fish_prompt >/dev/null
        if not test -f $target
            echo "fishblood: could not locate fish_prompt to modify" >&2
            return 1
        end
        cp $target $target.fishblood.bak
    end
    set -l tmp (mktemp)
    # Default fish prompt: inject as a command substitution right after (prompt_login)
    # so the segment appears between user@host and the cwd/suffix.
    if grep -q 'prompt_login' $target
        sed 's/(prompt_login)/(prompt_login)(fishblood_prompt_segment)/' $target >$tmp
    else
        # Fallback for non-default prompts: inject a call before the last `end`.
        # The segment will appear at the end of the prompt — for better positioning,
        # add (fishblood_prompt_segment) to your fish_prompt by hand.
        awk '
            { lines[NR] = $0; if ($0 ~ /^end[[:space:]]*$/) last_end = NR }
            END {
                for (i = 1; i <= NR; i++) {
                    if (i == last_end) print "    fishblood_prompt_segment"
                    print lines[i]
                }
            }
        ' $target >$tmp
    end
    if not grep -q fishblood_prompt_segment $tmp
        command rm -f $tmp
        echo "fishblood: could not find a suitable injection point in $target" >&2
        echo "         add 'fishblood_prompt_segment' to your fish_prompt manually." >&2
        return 1
    end
    mv $tmp $target
    echo "fishblood: enabled (modified $target, backup at $target.fishblood.bak)"
    echo "Start a new shell to see the change."
end
