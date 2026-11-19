# sh login profile: shared by greetd and .bash_profile (terminals, tmux, SSH).
# Non-login terminals inherit PATH and the rest from their graphical session.
# install_dev --android: sdkmanager and avdmanager, adb and fastboot, the emulator. ~/Android/Sdk is where Studio
# looks for an SDK, so a project needs no local.properties. Dead entries where the flag was never run, as
# /usr/local/go/bin is without Go
export ANDROID_HOME="$HOME/Android/Sdk"
# Keep the first occurrence, including when the inherited PATH already has duplicates.
PATH=$(printf '%s' "$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$HOME/dotfiles/private/bin:$HOME/dotfiles/bin:$HOME/.local/bin:$HOME/bin:$HOME/go/bin:/usr/local/go/bin:$HOME/.cargo/bin:$PATH" |
  awk -v RS=: 'length($0) && !seen[$0]++ {printf "%s%s", separator, $0; separator=":"}')
export PATH

# labwc exports DISPLAY even when its Xwayland executable is disabled.
case ${XDG_CURRENT_DESKTOP:-} in
  *labwc*) unset DISPLAY XAUTHORITY ;;
esac

export XDG_CONFIG_HOME="$HOME/.config"
export EDITOR='nvim'
export VISUAL='nvim'

export FZF_DEFAULT_OPTS="--height 40% --input-border=sharp --list-border=sharp --preview-border=sharp --prompt='> ' --pointer='>' --marker='>' --gutter=' ' --info=inline-right --bind ctrl-f:page-down,ctrl-b:page-up --color=fg:-1,fg+:-1,bg:-1,bg+:236,hl:10,hl+:10,info:8,marker:13,prompt:-1,spinner:8,pointer:13,header:8,border:8,gutter:-1"
# fzf follows the terminal's ANSI palette; previews use standard file tools.
export FZF_CTRL_T_OPTS="--preview 'if [ -d {} ]; then ls -1 {}; else head -c 16384 {} | head -n 100; fi'"
export FZF_ALT_C_OPTS="--preview 'ls -1 --color=always {}'"

export PI_OFFLINE=1

# None of the sessions gets the systemd --user environment, so they take it here: the socket of
# ssh-agent.socket and the ~/.config/environment.d files install links from config/environment.d
# (SSH_ASKPASS, NO_AT_BRIDGE), plain KEY=VALUE lines; only those, not what packages drop there for
# systemd alone.
export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/openssh_agent"
for _dotfiles_env_file in "$HOME"/dotfiles/config/environment.d/*.conf; do
  [ -e "$HOME/.config/environment.d/${_dotfiles_env_file##*/}" ] || continue
  # shellcheck source=/dev/null
  . "$_dotfiles_env_file"
  while IFS='=' read -r _dotfiles_env_key _dotfiles_env_value || [ -n "$_dotfiles_env_key" ]; do
    case $_dotfiles_env_key in ''|[0-9]*|*[!a-zA-Z0-9_]*) continue ;; esac
    export "${_dotfiles_env_key?}"
  done < "$_dotfiles_env_file"
done
unset _dotfiles_env_file _dotfiles_env_key _dotfiles_env_value

# The private submodule's own: the keys and tokens the CLI tools read, flint through trdl. Shared with all login shells,
# so greetd's /bin/sh gets them too and the whole session inherits them.
[ -f "$HOME/dotfiles/private/.profile" ] && . "$HOME/dotfiles/private/.profile"
if [ -f "$HOME/.cargo/env" ]; then . "$HOME/.cargo/env"; fi
