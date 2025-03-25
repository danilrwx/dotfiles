export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

plugins=(git rails sudo fzf)

source $ZSH/oh-my-zsh.sh

alias ls='lsd --color=auto'
alias l='lsd -lah'
alias so='source ~/.zshrc'
alias c='clear'
alias grep='grep --color=auto'
alias untar='tar -zxvf '
alias wget='wget -c '
alias lg='lazygit'

export RUBYOPT="-W0"
export COLORTERM=truecolor
export EDITOR='nvim'
export VISUAL='nvim'

export PATH=$PATH:$GOPATH/bin/
export PATH=$PATH:$HOME/.cargo/bin/
export PATH=$PATH:$HOME/.local/bin/
export PATH=$PATH:$HOME/dotfiles/scripts/
export PATH=$PATH:$HOME/.bun/bin
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

export XDG_CONFIG_HOME="$HOME/.config"
export K9S_CONFIG_DIR=$HOME/.config/k9s
export KUBECTL_EXTERNAL_DIFF="dyff between --omit-header --set-exit-code"
export KUBECONFIG=$HOME/.kubeconfigs/cluster-merge:$(find $HOME/.kubeconfigs -name kubeconfig | tr '\n' ':')

export BAT_THEME="Catppuccin Mocha"
export FZF_DEFAULT_OPTS="
  --tmux --height 60%
  --layout=reverse --border
  --bind 'ctrl-/:change-preview-window(down|hidden|)'
  --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
  --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
  --color=selected-bg:#45475a \
  --color=border:#313244,label:#cdd6f4
  "
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

[[ -e /home/linuxbrew/.linuxbrew/bin/brew ]] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
[[ -e /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"

source <(fzf --zsh)
source <(kubectl completion zsh)

export GOPATH=$HOME/go
export GOBIN=$GOPATH/bin
export PATH=$PATH:$GOBIN

[[ -e ~/private.zsh ]] && source ~/private.zsh

# Added by Windsurf
export PATH="/Users/danil/.codeium/windsurf/bin:$PATH"
