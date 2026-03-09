if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

if [ -f ~/private.bash ]; then
    . ~/private.bash
fi

if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc

SSH_ENV="/tmp/.ssh_environment_added"
function start_agent {
  echo "Initializing new SSH agent..."
  echo > "${SSH_ENV}"
  /usr/bin/ssh-add -c $HOME/.ssh/id_rsa; # My key.
}

if [ -f "${SSH_ENV}" ]; then
  ps -ef | grep ssh-agent > /dev/null || {
    start_agent;
  }
else
  start_agent;
fi

PS1='[\[\e[93m\]\t\[\e[0m\]] \[\e[32m\]\w\[\e[0m\] \[\e[94m\]󰅂\[\e[0m\] '

source <(kubectl completion bash)
source <(fzf --bash)
source <(flint completion --shell=bash)

alias kubectl=kubecolor
complete -o default -F __start_kubectl kubecolor
alias k=kubecolor
complete -o default -F __start_kubectl k

alias ls='ls --color=auto'
alias so='source ~/.bashrc'
alias grep='grep --color=auto'
alias untar='tar -zxvf '
alias wget='wget -c '
alias kaf="kubectl apply -f"
alias kad="kubectl delete -f"
alias vi='nvim'
alias vim='nvim'
alias lg='lazygit'
