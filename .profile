# sh login profile: greetd sources it before the session (i3 through startx), and
# .zprofile sources it for zsh login shells (tmux, ssh), so terminals spawned by the WM, which run zsh as no
# login shell, still get PATH and the rest from the session.
PATH="$HOME/dotfiles/private/bin:$HOME/dotfiles/bin:$HOME/.local/bin:$HOME/bin:$HOME/go/bin:$PATH"
export PATH

export XDG_CONFIG_HOME="$HOME/.config"
export EDITOR='nvim'
export VISUAL='nvim'

export FZF_DEFAULT_OPTS="--height 40% --input-border=sharp --list-border=sharp --preview-border=sharp --prompt='> ' --pointer='>' --marker='>' --gutter=' ' --info=inline-right --bind ctrl-f:page-down,ctrl-b:page-up --color=fg:-1,bg:-1,hl:12,fg+:2,bg+:-1,hl+:2,info:12,border:8,label:7,prompt:7,pointer:2,marker:2,gutter:-1,spinner:12"

export PI_OFFLINE=1

# None of the sessions gets the systemd --user environment, so they take it here: the socket of
# ssh-agent.socket and the ~/.config/environment.d files install links from config/environment.d
# (SSH_ASKPASS, NO_AT_BRIDGE), plain KEY=VALUE lines; only those, not what packages drop there for
# systemd alone.
export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/openssh_agent"
set -a
# gdk-scale.conf is systemd's only: Chrome and Electron count GDK_SCALE on top of Xft.dpi and come out at 4x
for f in "$HOME"/dotfiles/config/environment.d/*.conf; do
  [ "${f##*/}" = gdk-scale.conf ] && continue
  [ -e "$HOME/.config/environment.d/${f##*/}" ] && . "$f"
done
set +a
