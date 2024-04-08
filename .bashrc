#

# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

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

. $HOME/dotfiles/.bash_path

[[ -e /usr/share/fzf/key-bindings.bash ]] && . /usr/share/fzf/key-bindings.bash
[[ -e /usr/share/fzf/completion.bash ]] &&   . /usr/share/fzf/completion.bash
