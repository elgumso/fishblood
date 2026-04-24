complete -c fishblood -f
complete -c fishblood -n __fish_use_subcommand -a status  -d "Show configuration and cached value"
complete -c fishblood -n __fish_use_subcommand -a refresh -d "Force immediate cache refresh"
complete -c fishblood -n __fish_use_subcommand -a units   -d "Show or set display units"
complete -c fishblood -n "__fish_seen_subcommand_from units" -a "mmol mgdl"
complete -c fishblood -n __fish_use_subcommand -a enable  -d "Add glucose segment to fish_prompt"
complete -c fishblood -n __fish_use_subcommand -a disable -d "Remove glucose segment from fish_prompt"
complete -c fishblood -n __fish_use_subcommand -a help    -d "Show help"
