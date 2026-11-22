# shellcheck shell=bash
case $- in *i*) ;; *) return ;; esac

set -o emacs
HISTSIZE=1000000
HISTFILESIZE=1000000
HISTCONTROL=ignoredups:erasedups
shopt -s histappend checkwinsize
# Share history between terminals without replacing another shell's new entries.
PROMPT_COMMAND='history -a; history -n'
PS1='[\[\e[1;33m\]\t\[\e[0m\]] \[\e[1;32m\]\w\[\e[0m\] \[\e[1;34m\]>\[\e[0m\] '

[ -r /usr/share/bash-completion/bash_completion ] && . /usr/share/bash-completion/bash_completion
for f in "$HOME/.local/share/completions/"*.bash; do
  # shellcheck source=/dev/null
  [ -r "$f" ] && . "$f"
done
unset f

_dotfiles_install() {
  COMPREPLY=()
  local flags
  flags=$(sed -nE 's/^#   (--[a-z-]+) +.*/\1/p' "$HOME/dotfiles/install")
  mapfile -t COMPREPLY < <(compgen -W "$flags" -- "${COMP_WORDS[COMP_CWORD]}")
}
complete -F _dotfiles_install ./install dotfiles-update

if command -v dircolors >/dev/null && command ls --color=auto -d . >/dev/null 2>&1; then
  eval "$(dircolors -b | sed 's/;3\([12]\):/;9\1:/g')"
  alias ls='ls --color=auto'
fi
alias ll='ls -lah'
alias so='source ~/.bashrc'
alias sp='source ~/.profile'
alias untar='tar -zxvf '
alias k=kubectl
alias kaf='kubectl apply -f'
alias kad='kubectl delete -f'

# Use ANSI palette slots in both virtual consoles and graphical terminals.
codex() {
  if [[ -t 1 ]]; then
    FORCE_COLOR=1 command codex -c 'tui.theme="ansi"' "$@"
  else
    command codex "$@"
  fi
}
declare -F __start_kubectl >/dev/null && complete -o default -F __start_kubectl k
kctx() { local c; c=$(kubectl config get-contexts -o name | fzf) && [ -n "$c" ] && kubectl config use-context "$c"; }
kns() { local n; n=$(kubectl get ns -o name | cut -d/ -f2 | fzf) && [ -n "$n" ] && kubectl config set-context --current --namespace "$n"; }

[ -f "$HOME/dotfiles/private/.bashrc" ] && . "$HOME/dotfiles/private/.bashrc"
export GPG_TTY
GPG_TTY=$(tty)
# Keep successful interactive startup successful when no private config exists.
true
