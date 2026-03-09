if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi

if [[ -z $DISPLAY ]] && [[ $(tty) = /dev/tty1 ]]; then
  startx
fi
. "$HOME/.cargo/env"
