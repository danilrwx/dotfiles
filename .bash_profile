export PATH="$HOME/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/dotfiles/bin:$PATH"
export PATH="$HOME/.bun/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

export GOPATH=$HOME/go
export GOBIN=$GOPATH/bin
export PATH=$HOME/go/bin:$PATH

export KREW_ROOT="$HOME/.krew"
export PATH="$KREW_ROOT/bin:$PATH"

if [ -d "$(brew --prefix)/opt/glibc" ]; then
  export PATH="$(brew --prefix)/opt/glibc/sbin:$PATH"
  export PATH="$(brew --prefix)/opt/glibc/bin:$PATH"
  export LDFLAGS="-L$(brew --prefix)/opt/glibc/lib"
  export CPPFLAGS="-I$(brew --prefix)/opt/glibc/include"
fi

if [ -f "$(brew --prefix)/opt/coreutils/libexec/gnubin" ]; then
 export PATH="/home/linuxbrew/.linuxbrew/opt/coreutils/libexec/gnubin:$PATH"
fi

export EDITOR='nvim'
export VISUAL='nvim'
export PAGER='nvimpager'
export XDG_CONFIG_HOME="$HOME/.config"
export K9S_CONFIG_DIR=$HOME/.config/k9s
export KUBECTL_EXTERNAL_DIFF="dyff between --omit-header --set-exit-code"
export KUBECONFIG=$HOME/.kubeconfigs/cluster-merge:$(find $HOME/.kubeconfigs -name kubeconfig | tr '\n' ':')

if [ -e "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

if [ -e "/opt/homebrew/bin/brew" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

if [ -e "$HOME/bin/trdl" ]; then
  source $("$HOME/bin/trdl" use flint "2")
fi

if [ -f /etc/bashrc ]; then
  source /etc/bashrc
fi

if [ -f $HOME/private.bash ]; then
  source $HOME/private.bash
fi

if [ -n "$BASH_VERSION" -a -n "$PS1" ]; then
    if [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
    fi
fi

