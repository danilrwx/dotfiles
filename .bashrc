#

# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias l='ls -lah'
alias lg='lazygit'
alias c='clear'
alias grep='grep --color=auto'
alias untar='tar -zxvf '
alias wget='wget -c '

alias be='bundle exec'
alias rs='bin/rails s'
alias rc='bin/rails c'
alias rdm='bin/rails db:migrate'
alias rdr='bin/rails db:rollback'
alias rdrp='bin/rails db:rollback:primary'

. $HOME/dotfiles/.bash_path

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
