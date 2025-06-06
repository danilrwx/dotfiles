# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

if [ -d "$HOME/dotfiles/bin" ] ; then
    PATH="$HOME/dotfiles/bin:$PATH"
fi

[[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx
