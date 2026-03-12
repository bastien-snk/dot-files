# Source tracked Zsh modules in lexical order, then any untracked local override.

zsh_config_dir="${${(%):-%x}:A:h}/rc.d"

if [ -d "$zsh_config_dir" ]; then
  for zsh_rc in "$zsh_config_dir"/*.zsh(.N); do
    source "$zsh_rc"
  done
fi
