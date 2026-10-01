# the session environment is .profile's, shared with greetd's sh; zsh only drops PATH duplicates
emulate sh -c '. "$HOME/.profile"'
typeset -U path PATH

if [ -f $HOME/dotfiles/private/.zprofile ]; then
  source $HOME/dotfiles/private/.zprofile
fi
