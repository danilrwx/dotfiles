#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

[ "$TERM" = "xterm-kitty" ] && alias ssh="kitty +kitten ssh"
alias ls='ls --color=auto'
alias l='ls -lah'
alias grep='grep --color=auto'

PS1='[\u@\h \W]\$ '
