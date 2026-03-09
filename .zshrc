export ZSH="$HOME/.oh-my-zsh"

local path_color='%{%F{green}%}'
local arrow_color='%{%F{blue}%}'
local time_color='%{%F{yellow}%}'
local reset_color='%{%f%}'
PROMPT='[%{${time_color}%}%D{%H:%M:%S}%{${reset_color}%}] %{${path_color}%}%~%{${reset_color}%} %{${arrow_color}%}󰅂%{${reset_color}%} '

plugins=(sudo fzf)

source $ZSH/oh-my-zsh.sh

alias ls='ls --color=auto'
alias so='source ~/.zshrc'
alias c='clear'
alias grep='grep --color=auto'
alias untar='tar -zxvf '
alias wget='wget -c '
alias kaf="kubectl apply -f"
alias kad="kubectl delete -f"
alias vi='nvim'
alias vim='nvim'
alias lg='lazygit'

source <(kubectl completion zsh)
compdef kubecolor=kubectl
alias kubectl=kubecolor
alias k=kubecolor

export EDITOR='nvim'
export VISUAL='nvim'

export XDG_CONFIG_HOME="$HOME/.config"
export K9S_CONFIG_DIR=$HOME/.config/k9s
export KUBECTL_EXTERNAL_DIFF="dyff between --omit-header --set-exit-code"
export KUBECONFIG=$HOME/.kubeconfigs/cluster-merge:$(find $HOME/.kubeconfigs -name kubeconfig | tr '\n' ':')

export FZF_DEFAULT_OPTS=" \
--color=bg+:#313244,bg:#1E1E2E,spinner:#F5E0DC,hl:#F38BA8 \
--color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC \
--color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 \
--color=selected-bg:#45475A \
--color=border:#6C7086,label:#CDD6F4"

[[ -e /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
[[ -e /home/linuxbrew/.linuxbrew/bin/brew ]] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

source <(flint completion --shell=zsh)

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  eval $( keychain --eval -q )
  keychain -q --confirm $HOME/.ssh/id_rsa
fi

h=()
if [[ -r ~/.ssh/config ]]; then
  h=($h ${${${(@M)${(f)"$(cat ~/.ssh/config)"}:#Host *}#Host }:#*[*?]*})
fi
if [[ -r ~/.ssh/known_hosts ]]; then
  h=($h ${${${(f)"$(cat ~/.ssh/known_hosts{,2} || true)"}%%\ *}%%,*}) 2>/dev/null
fi
if [[ $#h -gt 0 ]]; then
  zstyle ':completion:*:ssh:*' hosts $h
  zstyle ':completion:*:slogin:*' hosts $h
fi

autoload -Uz compinit && compinit -i


[[ -e ~/private.zsh ]] && source ~/private.zsh

