function __fishblood_disable --description "Remove fishblood_prompt_segment from the user's fish_prompt"
    set -l target $__fish_config_dir/functions/fish_prompt.fish
    set -l backup $target.fishblood.bak
    if test -f $backup
        mv $backup $target
        echo "fishblood: restored $target from backup"
        return 0
    end
    if test -f $target
        if grep -q fishblood_prompt_segment $target
            set -l tmp (mktemp)
            grep -v fishblood_prompt_segment $target >$tmp
            mv $tmp $target
            echo "fishblood: removed segment call from $target"
            return 0
        end
    end
    echo "fishblood: nothing to disable"
end
