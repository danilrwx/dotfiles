export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

plugins=(git rails asdf sudo kubectl)

source $ZSH/oh-my-zsh.sh

if [ -f ~/dotfiles/base.bash ]; then
    . ~/dotfiles/base.bash
fi
