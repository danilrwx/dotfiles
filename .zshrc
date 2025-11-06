PROMPT="[%F{11}%*%f] %F{10}%~%f %F{12}󰅂%f "

if [ -z "$PS1" ]; then
  return
fi

if [ -e ~/private.zsh ]; then
  source ~/private.zsh
fi

HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000

setopt EXTENDED_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_SAVE_NO_DUPS

alias ls='ls --color=auto'
alias so='source ~/.zshrc'
alias sp='source ~/.zprofile'
alias untar='tar -zxvf '
alias cat='nvimpager -c'
alias less='nvimpager -p'
alias kaf="kubectl apply -f"
alias kad="kubectl delete -f"
alias vi='nvim'
alias vim='nvim'
alias lg='lazygit'
alias k=kubecolor
alias kubectl=kubecolor
compdef kubecolor=kubectl

if [ -e $(brew --prefix)/opt/zinit/zinit.zsh ]; then
  source $(brew --prefix)/opt/zinit/zinit.zsh

  zinit light jeffreytse/zsh-vi-mode
  function zvm_after_init() {
    zinit load Aloxaf/fzf-tab
    zinit load zdharma-continuum/fast-syntax-highlighting
    zinit load zdharma-continuum/history-search-multi-word
  }

  zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
fi

source <(flint completion --shell=zsh)
source <(kubectl completion zsh)

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  eval $( keychain --eval -q )
  keychain -q --confirm $HOME/.ssh/id_rsa
fi

h=()
if [[ -r ~/.ssh/config ]]; then
  h=($h ${${${(@M)${(f)"$(/usr/bin/cat ~/.ssh/config)"}:#Host *}#Host }:#*[*?]*})
fi
if [[ -r ~/.ssh/known_hosts ]]; then
  h=($h ${${${(f)"$(/usr/bin/cat ~/.ssh/known_hosts{,2} || true)"}%%\ *}%%,*}) 2>/dev/null
fi
if [[ $#h -gt 0 ]]; then
  zstyle ':completion:*:ssh:*' hosts $h
  zstyle ':completion:*:slogin:*' hosts $h
fi

