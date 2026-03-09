#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

[ "$TERM" = "xterm-kitty" ] && alias ssh="kitty +kitten ssh"
PS1='[\u@\h \W]\$ '

alias ls='ls --color=auto'
alias l='ls -lah'
alias grep='grep --color=auto'

export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

export RUBYOPT="-W0"
export TERM=xterm-256color
export TERMINAL=foot-client
export PATH=$PATH:$HOME/.local/bin/

eval `keychain --agents ssh --eval --quiet ~/.ssh/id_ed25519`

