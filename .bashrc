#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

PS1='[\u@\h \W]\$ '

alias ls='ls --color=auto'
alias l='ls -lah'
alias c='clear'
alias grep='grep --color=auto'
alias untar='tar -zxvf '
alias wget='wget -c '

alias be='bundle exec'
alias rs='rails s'
alias rc='rails c'
alias rdm='rails db:migrate'
alias rdr='rails db:rollback'
alias rdrp='rails db:rollback:primary'

alias lg='lazygit'

. $HOME/dotfiles/.bash_path

# . /usr/share/fzf/key-bindings.bash
# . /usr/share/fzf/completion.bash
