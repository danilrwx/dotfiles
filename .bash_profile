if [ -e "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

if [ -e "/opt/homebrew/bin/brew" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

if [ -e "/home/linuxbrew/.linuxbrew/etc/profile.d/bash_completion.sh" ]; then
  source "/home/linuxbrew/.linuxbrew/etc/profile.d/bash_completion.sh"
fi

PATH="$HOME/bin:$PATH"
PATH="$HOME/.local/bin:$PATH"
PATH="$HOME/dotfiles/bin:$PATH"
PATH="$HOME/.bun/bin:$PATH"
PATH="$HOME/.cargo/bin:$PATH"

GOPATH=$HOME/go
GOBIN=$GOPATH/bin
PATH=$HOME/go/bin:$PATH

KREW_ROOT="$HOME/.krew"
PATH="$KREW_ROOT/bin:$PATH"

! { which flint | grep -qsE "^/home/danil/.trdl/"; } && [[ -x "$HOME/bin/trdl" ]] && source $("$HOME/bin/trdl" use flint "2")

EDITOR='nvim'
VISUAL='nvim'
XDG_CONFIG_HOME="$HOME/.config"
K9S_CONFIG_DIR=$HOME/.config/k9s
KUBECTL_EXTERNAL_DIFF="dyff between --omit-header --set-exit-code"
KUBECONFIG=$HOME/.kubeconfigs/cluster-merge:$(find $HOME/.kubeconfigs -name kubeconfig | tr '\n' ':')
FZF_DEFAULT_OPTS=" \
  --color=bg+:#313244,bg:-1,spinner:#F5E0DC,hl:#F38BA8 \
  --color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC \
  --color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 \
  --color=selected-bg:#45475A \
  --color=border:#6C7086,label:#CDD6F4"

PS1='[\[\e[93m\]\t\[\e[0m\]] \[\e[32m\]\w\[\e[0m\] \[\e[94m\]󰅂\[\e[0m\] '

if [ -e ~/.bashrc ]; then
  source ~/.bashrc
fi
