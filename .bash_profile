if [ -e "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

if [ -e "/opt/homebrew/bin/brew" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

PATH="$HOME/bin:$PATH"
PATH="$HOME/.local/bin:$PATH"
PATH="$HOME/dotfiles/bin:$PATH"
PATH="$HOME/.bun/bin:$PATH"
PATH="$HOME/.cargo/bin:$PATH"

export GOPATH=$HOME/go
export GOBIN=$GOPATH/bin
PATH=$HOME/go/bin:$PATH

export KREW_ROOT="$HOME/.krew"
PATH="$KREW_ROOT/bin:$PATH"

if [ -d "$(brew --prefix)/opt/glibc" ]; then
  PATH="$(brew --prefix)/opt/glibc/sbin:$PATH"
  PATH="$(brew --prefix)/opt/glibc/bin:$PATH"
  LDFLAGS="-L$(brew --prefix)/opt/glibc/lib"
  CPPFLAGS="-I$(brew --prefix)/opt/glibc/include"
fi

export EDITOR='nvim'
export VISUAL='nvim'
export PAGER='nvimpager'
export XDG_CONFIG_HOME="$HOME/.config"
export K9S_CONFIG_DIR=$HOME/.config/k9s
export KUBECTL_EXTERNAL_DIFF="dyff between --omit-header --set-exit-code"
export KUBECONFIG=$HOME/.kubeconfigs/cluster-merge:$(find $HOME/.kubeconfigs -name kubeconfig | tr '\n' ':')

! { which flint | grep -qsE "^/home/danil/.trdl/"; } && [[ -x "$HOME/bin/trdl" ]] && source $("$HOME/bin/trdl" use flint "2")

if [ -e ~/.bashrc ]; then
  source ~/.bashrc
fi
