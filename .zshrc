PROMPT="[%F{11}%*%f] %F{10}%~%f %F{12}󰅂%f "

autoload -Uz compinit && compinit -i

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
--color=bg+:#313244,bg:-1,spinner:#F5E0DC,hl:#F38BA8 \
--color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC \
--color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 \
--color=selected-bg:#45475A \
--color=border:#6C7086,label:#CDD6F4"

source ~/.zprofile
source <(fzf --zsh)
source <(flint completion --shell=zsh)

if [ -e $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
  source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

if [ -e ~/private.zsh ]; then
  source ~/private.zsh
fi

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

