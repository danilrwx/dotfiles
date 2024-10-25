if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

alias l='ls -lah'
alias untar='tar -zxvf '
alias wget='wget -c '

alias be='bundle exec'
alias rs='bin/rails s'
alias rc='bin/rails c'
alias rdm='bin/rails db:migrate'
alias rdr='bin/rails db:rollback'
alias rdrp='bin/rails db:rollback:primary'

alias lg='lazygit'
# alias vim='nvim'
# alias vi='nvim'

export GOPATH=$HOME/go
export RUBYOPT="-W0"
export COLORTERM=truecolor
export EDITOR='nvim'
export VISUAL='nvim'
export PATH=$PATH:$GOPATH/bin/
export PATH=$PATH:$HOME/.cargo/bin/
export PATH=$PATH:$HOME/.local/bin/
export PATH=$PATH:$HOME/dotfiles/scripts/
export K9S_CONFIG_DIR=$HOME/.config/k9s
export FZF_DEFAULT_OPTS="--height 60% --layout=reverse --border"

[[ -e $HOME/.config/sops ]] && export PUB_KEY=$(cat $HOME/.config/sops/age/keys.txt | grep "public" | awk '{print $4}')
[[ -e $HOME/.config/sops ]] && export SOPS_AGE_KEY_FILE=$HOME/.config/sops/age/keys.txt

[[ -e /usr/bin/keychain ]] && eval `keychain --agents ssh --eval --quiet ~/.ssh/id_ed25519`

[[ -e /home/linuxbrew/.linuxbrew/bin/brew ]] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

if [ ! -z ${ZSH_VERSION+x} ]; then
  eval "$(fzf --zsh)"
  [[ -e /usr/bin/kubectl ]] && source <(kubectl completion zsh)
elif [ ! -z ${BASH_VERSION+x} ]; then
  eval "$(fzf --bash)"
  [[ -e /usr/bin/kubectl ]] && source <(kubectl completion bash)
  . "/home/linuxbrew/.linuxbrew/opt/asdf/libexec/asdf.sh"
  . "/home/linuxbrew/.linuxbrew/opt/asdf/etc/bash_completion.d/asdf.bash"
fi

