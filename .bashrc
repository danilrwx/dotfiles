PS1='[\[\e[93m\]\t\[\e[0m\]] \[\e[32m\]\w\[\e[0m\] \[\e[94m\]󰅂\[\e[0m\] '

if [ -z "$PS1" ]; then
  return
fi

if [ -f /etc/bashrc ]; then
  source /etc/bashrc
fi

if [ -f ~/private.bash ]; then
  source ~/private.bash
fi

if [ -e "$(brew --prefix)/etc/profile.d/bash_completion.sh" ]; then
  source "$(brew --prefix)/etc/profile.d/bash_completion.sh"
fi

SSH_ENV="/tmp/.ssh_environment_added"
function start_agent {
  echo "Initializing new SSH agent..."
  echo > "${SSH_ENV}"
  /usr/bin/ssh-add -c $HOME/.ssh/id_rsa;
}

if [ -f "${SSH_ENV}" ]; then
  ps -ef | grep ssh-agent > /dev/null || {
    start_agent;
  }
else
  start_agent;
fi

source <(fzf --bash)
source <(kubectl completion bash)
source <(flint completion --shell=bash)

source ~/fzf-tab-completion/bash/fzf-bash-completion.sh
bind -x '"\t": fzf_bash_completion'

alias kubectl=kubecolor
complete -o default -F __start_kubectl kubecolor
alias k=kubecolor
complete -o default -F __start_kubectl k

alias ls='ls --color=auto'
alias so='source ~/.bashrc'
alias sp='source ~/.bash_profile'
alias untar='tar -zxvf '
alias cat='nvimpager -c'
alias less='nvimpager -p'
alias kaf="kubectl apply -f"
alias kad="kubectl delete -f"
alias vi='nvim'
alias vim='nvim'
alias lg='lazygit'
