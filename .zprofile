PATH="$HOME/bin:$PATH"
PATH="$HOME/.local/bin:$PATH"
PATH="$HOME/dotfiles/bin:$PATH"
PATH="$HOME/.bun/bin:$PATH"
PATH="$HOME/.cargo/bin:$PATH"
PATH="$HOME/.krew/bin:$PATH"

GOPATH=$HOME/go
GOBIN=$GOPATH/bin
PATH=$HOME/go/bin:$PATH

if [ -e "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

if [ -e "/opt/homebrew/bin/brew" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

! { which flint | grep -qsE "^/home/danil/.trdl/"; } && [[ -x "$HOME/bin/trdl" ]] && source $("$HOME/bin/trdl" use flint "2")

[[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx
