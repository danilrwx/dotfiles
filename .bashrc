#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

PS1='[\u@\h \W]\$ '

alias cat='bat --theme ansi'
alias ls='exa --sort=size'
alias l='ls -lah'
alias c='clear'
alias grep='grep --color=auto'

alias be='bundle exec'
alias rs='rails s'
alias rc='rails c'
alias rdm='rails db:migrate'
alias rdr='rails db:rollback'
alias rdrp='rails db:rollback:primary'

alias lg='lazygit'

export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin/

export RUBYOPT="-W0"
export TERM='xterm-256color'
export EDITOR='hx'
export VISUAL='hx'
export GIT_PAGER='delta'
export PATH=$PATH:$HOME/.cargo/bin/
export PATH=$PATH:$HOME/.local/bin/
export PATH=$PATH:$HOME/dotfiles/scripts/
export PATH=$PATH:/var/lib/flatpak/exports/bin
export HELIX_RUNTIME=$HOME/src/helix/runtime

export PS1="\[\e[01;33m\]\u\[\e[0m\]\[\e[00;37m\]@\[\e[0m\]\[\e[01;36m\]\h\[\e[0m\]\[\e[00;37m\] \t \[\e[0m\]\[\e[01;35m\]\w\[\e[0m\]\[\e[01;37m\] > \[\e[0m\]"

eval `keychain --agents ssh --eval --quiet ~/.ssh/id_ed25519`

export FZF_DEFAULT_OPTS="--height 60% --layout=reverse --border --preview 'bat -n --color=always --theme ansi {}'"

. /usr/share/fzf/key-bindings.bash
. /usr/share/fzf/completion.bash

. "$HOME/.asdf/asdf.sh"
. "$HOME/.asdf/completions/asdf.bash"
