if [ -e "$(brew --prefix)/etc/profile.d/bash_completion.sh" ]; then
  source "$(brew --prefix)/etc/profile.d/bash_completion.sh"
fi

if [ -d "$HOME/.local/share/completions" ]; then
  for f in "$HOME/.local/share/completions/"*; do
    if [[ $f == *.bash ]]; then
      source "$f"
    fi
  done
fi

if [ -e "$HOME/.ssh/id_rsa" ]; then
  eval $( keychain --eval -q )
  /usr/bin/keychain --inherit any --confirm $HOME/.ssh/id_rsa -q
fi

alias kubectl=kubecolor
complete -o default -F __start_kubectl kubecolor
alias k=kubecolor
complete -o default -F __start_kubectl k


if [ -x "$(command -v eza)" ]; then
  alias ls='eza'
  alias ll='eza -lah'
fi

alias so='source ~/.bashrc'
alias sp='source ~/.bash_profile'

alias untar='tar -zxvf '

if [ -x "$(command -v nvimpager)" ]; then
  alias cat='nvimpager -c'
  alias less='nvimpager -p'

  export PAGER='nvimpager'
fi

alias kaf="kubectl apply -f"
alias kad="kubectl delete -f"

if [ -x "$(command -v nvim)" ]; then
  alias vi='nvim'
  alias vim='nvim'

  export EDITOR='nvim'
  export VISUAL='nvim'
fi

alias lg='lazygit'

export PS1='[\[\e[93m\]\t\[\e[0m\]] \[\e[32m\]\w\[\e[0m\] \[\e[94m\]󰅂\[\e[0m\] '
export FZF_DEFAULT_OPTS=""

