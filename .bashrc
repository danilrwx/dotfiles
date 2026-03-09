# If not running interactively, don't do anything
# case $- in
#     *i*) ;;
#       *) return;;
# esac

HISTCONTROL=ignoreboth

shopt -s histappend

HISTSIZE=10000
HISTFILESIZE=20000

shopt -s checkwinsize

[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
	debian_chroot=$(cat /etc/debian_chroot)
fi

case "$TERM" in
xterm-color | *-256color) color_prompt=yes ;;
esac

force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
	if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
		color_prompt=yes
	else
		color_prompt=
	fi
fi

if [ "$color_prompt" = yes ]; then
	PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
	PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

case "$TERM" in
xterm* | rxvt*)
	PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
	;;
*) ;;
esac

alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

if [ -f ~/.bash_aliases ]; then
	. ~/.bash_aliases
fi

if ! shopt -oq posix; then
	if [ -f /usr/share/bash-completion/bash_completion ]; then
		. /usr/share/bash-completion/bash_completion
	elif [ -f /etc/bash_completion ]; then
		. /etc/bash_completion
	fi
fi

if [ -f ~/dotfiles/base.bash ]; then
	. ~/dotfiles/base.bash
fi

if [ -x /usr/bin/dircolors ]; then
	test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
	alias ls='ls --color=auto'
	alias dir='dir --color=auto'
	alias vdir='vdir --color=auto'
	alias grep='grep --color=auto'
	alias fgrep='fgrep --color=auto'
	alias egrep='egrep --color=auto'
fi

alias l='ls -lah'
alias untar='tar -zxvf '
alias wget='wget -c '

alias be='bundle exec'
alias rs='bin/rails s'
alias rc='bin/rails c'
alias rdm='bin/rails db:migrate'
alias rdr='bin/rails db:rollback'
alias rdrp='bin/rails db:rollback:primary'

alias lg='lazygit'
# alias vim='nvim'
# alias vi='nvim'

export GOPATH=$HOME/go
export RUBYOPT="-W0"
export COLORTERM=truecolor
export EDITOR='nvim'
export VISUAL='nvim'
export PATH=$PATH:$GOPATH/bin/
export PATH=$PATH:$HOME/.cargo/bin/
export PATH=$PATH:$HOME/.local/bin/
export PATH=$PATH:$HOME/dotfiles/scripts/
export K9S_CONFIG_DIR=$HOME/.config/k9s
export FZF_DEFAULT_OPTS="--height 60% --layout=reverse --border"
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"

[[ -e $HOME/.config/sops ]] && export PUB_KEY=$(cat $HOME/.config/sops/age/keys.txt | grep "public" | awk '{print $4}')
[[ -e $HOME/.config/sops ]] && export SOPS_AGE_KEY_FILE=$HOME/.config/sops/age/keys.txt

[[ -e /usr/bin/keychain ]] && eval $(keychain --agents ssh --eval --quiet ~/.ssh/id_ed25519)
[[ -e /usr/bin/kubectl ]] && source <(kubectl completion bash)

eval "$(fzf --bash)"

[[ -e /home/linuxbrew/.linuxbrew/bin/brew ]] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
[[ -e /home/linuxbrew/.linuxbrew/opt/asdf ]] && . <(asdf completion bash)
