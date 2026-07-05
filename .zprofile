if [ -e "/opt/homebrew/bin/brew" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

typeset -U path PATH

export PATH="$HOME/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/dotfiles/bin:$PATH"
export PATH="$HOME/dotfiles/private/bin:$PATH"

export XDG_CONFIG_HOME="$HOME/.config"

export PI_OFFLINE=1

if [ -e "$HOME/bin/trdl" ]; then
  source $("$HOME/bin/trdl" use flint "2")
fi

if [ -f $HOME/dotfiles/private/.zprofile ]; then
  source $HOME/dotfiles/private/.zprofile
fi
