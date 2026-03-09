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

alias be='bundle exec'
alias rs='rails s'
alias rc='rails c'
alias rdm='rails db:migrate'
alias rdr='rails db:rollback'
alias rdrp='rails db:rollback:primary'
alias te='toolbox enter'

export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin/

export RUBYOPT="-W0"
export TERM='xterm-256color'
export EDITOR='nvim'
export VISUAL='nvim'
export PATH=$PATH:$HOME/.local/bin/
export PATH=$PATH:/var/lib/flatpak/exports/bin/
export PATH=$PATH:$HOME/dotfiles/scripts/

eval `keychain --agents ssh --eval --quiet ~/.ssh/id_ed25519`

. "$HOME/.asdf/asdf.sh"
. "$HOME/.asdf/completions/asdf.bash"

