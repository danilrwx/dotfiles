if [ -e "/opt/homebrew/bin/brew" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

export PATH="$HOME/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/dotfiles/bin:$PATH"
export PATH="$HOME/dotfiles/private/bin:$PATH"

export XDG_CONFIG_HOME="$HOME/.config"

export HISTSIZE=-1
export HISTFILESIZE=-1

export PI_OFFLINE=1

if [ -e "$HOME/bin/trdl" ]; then
  source $("$HOME/bin/trdl" use flint "2")
fi

if [ -f /etc/bashrc ]; then
  source /etc/bashrc
fi

if [ -f $HOME/dotfiles/private/.bash_profile ]; then
  source $HOME/dotfiles/private/.bash_profile
fi

if [ -n "$BASH_VERSION" -a -n "$PS1" ]; then
    if [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
    fi
fi

