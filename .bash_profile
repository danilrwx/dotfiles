if [ -e "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

if [ -e "/opt/homebrew/bin/brew" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

HOMEBREW_PREFIX=$(brew --prefix)
for d in ${HOMEBREW_PREFIX}/opt/*/libexec/gnubin; do export PATH=$d:$PATH; done
for d in ${HOMEBREW_PREFIX}/opt/*/libexec/gnuman; do export MANPATH=$d:$MANPATH; done

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

export EDITOR='nvim'
export VISUAL='nvim'
export PAGER='nvimpager'
export XDG_CONFIG_HOME="$HOME/.config"
export K9S_CONFIG_DIR=$HOME/.config/k9s
export KUBECTL_EXTERNAL_DIFF="dyff between --omit-header --set-exit-code"
export KUBECONFIG=$HOME/.kubeconfigs/cluster-merge:$(find $HOME/.kubeconfigs -name kubeconfig | tr '\n' ':')
export FZF_DEFAULT_OPTS="
--color=bg+:#262626,bg:#1c1c1c,fg:#d0d0d0
--color=border:#444444
--color=spinner:#af87ff,hl:#5f87ff
--color=header:#808080
--color=info:#5fafaf,pointer:#ff875f,marker:#87af5f
--color=prompt:#5f87ff
--color=fg+:#ffffff,hl+:#ff875f
--color=query:#d0d0d0
"

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

