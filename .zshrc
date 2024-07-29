export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

plugins=(git rails asdf sudo kubectl)

source $ZSH/oh-my-zsh.sh

# FZF
eval "$(fzf --zsh)"

# VARIABLES
alias ls='ls --color=auto'
alias l='ls -lah'
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

alias lg='lazygit'

. $HOME/dotfiles/.zsh_path
