export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

plugins=(sudo fzf)

source $ZSH/oh-my-zsh.sh

alias ls='ls --color=auto'
alias so='source ~/.zshrc'
alias c='clear'
alias grep='grep --color=auto'
alias untar='tar -zxvf '
alias wget='wget -c '
alias lg='lazygit'

# export LANG=ru_RU.UTF-8
export EDITOR='vim'
export VISUAL='vim'

export PATH=$PATH:$GOPATH/bin/
export PATH=$PATH:$HOME/.cargo/bin/
export PATH=$PATH:$HOME/.local/bin/
export PATH=$PATH:$HOME/dotfiles/scripts/
export PATH=$PATH:$HOME/.bun/bin
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

export GOPATH=$HOME/go
export GOBIN=$GOPATH/bin
export PATH=$PATH:$GOBIN

export XDG_CONFIG_HOME="$HOME/.config"
export K9S_CONFIG_DIR=$HOME/.config/k9s
export KUBECTL_EXTERNAL_DIFF="dyff between --omit-header --set-exit-code"
export KUBECONFIG=$HOME/.kubeconfigs/cluster-merge:$(find $HOME/.kubeconfigs -name kubeconfig | tr '\n' ':')

[[ -e /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"

source <(kubectl completion zsh)

[[ -e ~/private.zsh ]] && source ~/private.zsh
