if [ -e "/opt/homebrew/bin/brew" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

typeset -U path PATH

export PATH="$HOME/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/dotfiles/bin:$PATH"
export PATH="$HOME/dotfiles/private/bin:$PATH"

export XDG_CONFIG_HOME="$HOME/.config"

export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border=rounded --info=inline --prompt='❯ ' --pointer='▶' --marker='✓' --color=prompt:12,pointer:12,hl:2,hl+:10,marker:2,info:8,border:8,gutter:-1"

export PI_OFFLINE=1

if [ -f $HOME/dotfiles/private/.zprofile ]; then
  source $HOME/dotfiles/private/.zprofile
fi
