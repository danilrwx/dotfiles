export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

plugins=(git rails asdf sudo kubectl)

source $ZSH/oh-my-zsh.sh

alias ls='ls --color=auto'
alias l='ls -lah'
alias so='source ~/.zshrc'
alias c='clear'
alias grep='grep --color=auto'
alias untar='tar -zxvf '
alias wget='wget -c '

alias lg='lazygit'
# alias vim='nvim'
# alias vi='nvim'

export GOPATH=$HOME/go
export RUBYOPT="-W0"
export COLORTERM=truecolor
export EDITOR='nvim'
export VISUAL='nvim'
# export DELTA_PAGER='bat'
export PATH=$PATH:$GOPATH/bin/
export PATH=$PATH:$HOME/.cargo/bin/
export PATH=$PATH:$HOME/.local/bin/
export PATH=$PATH:$HOME/dotfiles/scripts/
export K9S_CONFIG_DIR=$HOME/.config/k9s
export FZF_DEFAULT_OPTS="--height 60% --layout=reverse --border --preview 'bat -n --color=always --theme ansi {}'"

[[ -e $HOME/.config/sops ]] && export PUB_KEY=$(cat $HOME/.config/sops/age/keys.txt | grep "public" | awk '{print $4}')
[[ -e $HOME/.config/sops ]] && export SOPS_AGE_KEY_FILE=$HOME/.config/sops/age/keys.txt

# [[ -e /usr/bin/keychain ]] && eval `keychain --agents ssh --eval --quiet ~/.ssh/id_ed25519`

[[ -e /usr/bin/kubectl ]] && source <(kubectl completion zsh)

[[ -e /home/linuxbrew/.linuxbrew/bin/brew ]] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
[[ -e /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"

[[ -e ~/private.zsh ]] && source ~/private.zsh

source <(fzf --zsh)

