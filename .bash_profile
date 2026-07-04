if [ -d /snap/bin ]; then
  export PATH=/snap/bin:$PATH
fi

if [ -e "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

if [ -e "/opt/homebrew/bin/brew" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

if command -v brew >/dev/null; then
  HOMEBREW_PREFIX=$(brew --prefix)
  for d in ${HOMEBREW_PREFIX}/opt/*/libexec/gnubin; do export PATH=$d:$PATH; done
  for d in ${HOMEBREW_PREFIX}/opt/*/libexec/gnuman; do export MANPATH=$d:$MANPATH; done
fi

export PATH="$HOME/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/dotfiles/bin:$PATH"
export PATH="$HOME/dotfiles/private/bin:$PATH"
export PATH="$HOME/.bun/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

export GOPATH=$HOME/go
export GOBIN=$GOPATH/bin
export PATH=$HOME/go/bin:$PATH

export XDG_CONFIG_HOME="$HOME/.config"
export K9S_CONFIG_DIR=$HOME/.config/k9s
kube_merge=$HOME/.kubeconfigs/cluster-merge
if find $HOME/.kubeconfigs -name kubeconfig 2>/dev/null | grep -q .; then
  if [ ! -f "$kube_merge" ] || find $HOME/.kubeconfigs -name kubeconfig -newer "$kube_merge" 2>/dev/null | grep -q .; then
    KUBECONFIG=$(find $HOME/.kubeconfigs -name kubeconfig | tr '\n' ':') kubectl config view --flatten > "$kube_merge" 2>/dev/null
  fi
  export KUBECONFIG=$kube_merge
fi
unset kube_merge

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

if [ -f $HOME/private.bash ]; then
  source $HOME/private.bash
fi

if [ -n "$BASH_VERSION" -a -n "$PS1" ]; then
    if [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
    fi
fi

