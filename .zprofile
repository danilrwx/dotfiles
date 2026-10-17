# the session environment is .profile's, shared with greetd's sh; zsh only drops PATH duplicates
emulate sh -c '. "$HOME/.profile"'
typeset -U path PATH
# private's env is .profile's, shared with greetd's sh
