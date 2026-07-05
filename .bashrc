# brew bash-completion on hosts with brew; the container gets it from apt.
if command -v brew >/dev/null 2>&1; then
  bc="$(brew --prefix)/etc/profile.d/bash_completion.sh"
  [ -e "$bc" ] && source "$bc"
  unset bc
fi

if [ -d "$HOME/.local/share/completions" ]; then
  for f in "$HOME/.local/share/completions/"*; do
    if [[ $f == *.bash ]]; then
      source "$f"
    fi
  done
fi

if [ -f $HOME/dotfiles/private/.bashrc ]; then
  source $HOME/dotfiles/private/.bashrc
fi

shopt -s histappend

PROMPT_COMMAND="history -a; $PROMPT_COMMAND"

alias k=kubectl
complete -o default -F __start_kubectl k


alias ll='ls -lah'

alias so='source ~/.bashrc'
alias sp='source ~/.bash_profile'

alias untar='tar -zxvf '

alias kaf="kubectl apply -f"
alias kad="kubectl delete -f"

if [ -x "$(command -v nvim)" ]; then
  alias vi='nvim'
  alias vim='nvim'

  export EDITOR='nvim'
  export VISUAL='nvim'
fi

alias lg='lazygit'

if [ -n "${DEVCONTAINER:-}" ]; then
  export PS1='[\[\e[93m\]\t\[\e[0m\]] \[\e[91m\]['"$DEVCONTAINER"']\[\e[0m\] \[\e[32m\]\w\[\e[0m\] \[\e[94m\]󰅂\[\e[0m\] '
else
  export PS1='[\[\e[93m\]\t\[\e[0m\]] \[\e[32m\]\w\[\e[0m\] \[\e[94m\]󰅂\[\e[0m\] '
fi


