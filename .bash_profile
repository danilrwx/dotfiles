# shellcheck shell=bash
# Login shells (SSH and tmux) share the graphical session's environment.
. "$HOME/.profile"
[ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"
