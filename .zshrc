export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

plugins=(git rails asdf sudo fzf)

source $ZSH/oh-my-zsh.sh

alias ls='ls --color=auto'
alias l='ls -lah'
alias so='source ~/.zshrc'
alias c='clear'
alias grep='grep --color=auto'
alias untar='tar -zxvf '
alias wget='wget -c '
alias lg='lazygit'

export RUBYOPT="-W0"
export COLORTERM=truecolor
export EDITOR='vim'
export VISUAL='vim'
export DFT_BACKGROUND=light

export PATH=$PATH:$GOPATH/bin/
export PATH=$PATH:$HOME/.cargo/bin/
export PATH=$PATH:$HOME/.local/bin/
export PATH=$PATH:$HOME/dotfiles/scripts/
export PATH=$PATH:$HOME/.bun/bin

export XDG_CONFIG_HOME="$HOME/.config"
export K9S_CONFIG_DIR=$HOME/.config/k9s
export KUBECTL_EXTERNAL_DIFF="dyff between --omit-header --set-exit-code"

export FZF_DEFAULT_OPTS="
  --tmux --height 60%
  --layout=reverse --border
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"
export FZF_CTRL_R_OPTS="
  --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
  --header 'Press CTRL-Y to copy command into clipboard'"
export FZF_CTRL_T_OPTS="
  --walker-skip .git,node_modules,target
  --preview 'bat -n --color=always {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"
export FZF_ALT_C_OPTS="
  --walker-skip .git,node_modules,target
  --preview 'tree -C {}'"

[[ -e $HOME/.config/sops ]] && export PUB_KEY=$(cat $HOME/.config/sops/age/keys.txt | grep "public" | awk '{print $4}')
[[ -e $HOME/.config/sops ]] && export SOPS_AGE_KEY_FILE=$HOME/.config/sops/age/keys.txt
# [[ -e /usr/bin/keychain ]] && eval `keychain --agents ssh --eval --quiet ~/.ssh/id_ed25519`

[[ -e /home/linuxbrew/.linuxbrew/bin/brew ]] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
[[ -e /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"

source <(fzf --zsh)
source <(kubectl completion zsh)

go_bin_path="$(asdf which go 2>/dev/null)"
if [[ -n "${go_bin_path}" ]]; then
  abs_go_bin_path="$(readlink -f "${go_bin_path}")"

  export GOROOT
  GOROOT="$(dirname "$(dirname "${abs_go_bin_path}")")"

  export GOPATH
  GOPATH="$(dirname "${GOROOT}")/packages"

  export GOBIN
  GOBIN="$(dirname "${GOROOT}")/packages/bin"
fi

[[ -e ~/private.zsh ]] && source ~/private.zsh
