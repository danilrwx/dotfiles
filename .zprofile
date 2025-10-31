if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

if [ -d "$HOME/dotfiles/bin" ] ; then
    PATH="$HOME/dotfiles/bin:$PATH"
fi

if [ -d "$HOME/.bun/bin" ] ; then
    PATH="$HOME/.bun/bin:$PATH"
fi

if [ -d "$HOME/.cargo/bin" ] ; then
    PATH="$HOME/.cargo/bin:$PATH"
fi

if [ -d "$HOME/go/bin" ] ; then
  GOPATH=$HOME/go
  GOBIN=$GOPATH/bin
  PATH=$GOBIN:$PATH
fi

if [ -e "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

if [ -e "/opt/homebrew/bin/brew" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

! { which flint | grep -qsE "^/home/danil/.trdl/"; } && [[ -x "$HOME/bin/trdl" ]] && source $("$HOME/bin/trdl" use flint "2")

[[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx
