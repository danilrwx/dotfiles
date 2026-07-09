if [ -e "/opt/homebrew/bin/brew" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

typeset -U path PATH

export PATH="$HOME/go/bin:$PATH"
export PATH="$HOME/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/dotfiles/bin:$PATH"
export PATH="$HOME/dotfiles/private/bin:$PATH"

export XDG_CONFIG_HOME="$HOME/.config"

export FZF_DEFAULT_OPTS="--height 40% --input-border=sharp --list-border=sharp --preview-border=sharp --prompt='> ' --pointer='>' --marker='>' --gutter=' ' --info=inline-right --bind ctrl-f:page-down,ctrl-b:page-up --color=fg:-1,bg:-1,hl:12,fg+:2,bg+:-1,hl+:2,info:12,border:8,label:7,prompt:7,pointer:2,marker:2,gutter:-1,spinner:12"

export PI_OFFLINE=1

if [ -f $HOME/dotfiles/private/.zprofile ]; then
  source $HOME/dotfiles/private/.zprofile
fi
