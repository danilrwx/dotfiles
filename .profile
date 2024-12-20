# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

[[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx

# export QT_SCALE_FACTOR=2
# export XCURSOR_SIZE=48
# export GDK_DPI_SCALE=0.5
# export GDK_SCALE=2
