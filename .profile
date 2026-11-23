# sh login profile: shared by greetd and .bash_profile (terminals, tmux, SSH).
# Non-login terminals inherit PATH and the rest from their graphical session.
# install --android: sdkmanager and avdmanager, adb and fastboot, the emulator. ~/Android/Sdk is where Studio
# looks for an SDK, so a project needs no local.properties. Dead entries where the flag was never run, as
# /usr/local/go/bin is without Go
export ANDROID_HOME="$HOME/Android/Sdk"
# Keep the first occurrence, including when the inherited PATH already has duplicates.
PATH=$(printf '%s' "$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$HOME/dotfiles/private/bin:$HOME/dotfiles/bin:$HOME/.local/bin:$HOME/bin:$HOME/go/bin:/usr/local/go/bin:$HOME/.cargo/bin:$PATH" |
  awk -v RS=: 'length($0) && !seen[$0]++ {printf "%s%s", separator, $0; separator=":"}')
export PATH

export XDG_CONFIG_HOME="$HOME/.config"
export EDITOR='vim'
export VISUAL='vim'

# Select the bitmap on Linux virtual console logins.
if [ "${TERM:-}" = linux ] && [ -t 1 ] && linux_tty=$(tty); then
  case ${linux_tty#/dev/tty} in
    ''|*[!0-9]*) ;;
    *)
      if [ -r "$HOME/dotfiles/config/console/jetbrains-mono-16x32.psfu.gz" ] && command -v setfont >/dev/null; then
        setfont -C "$linux_tty" "$HOME/dotfiles/config/console/jetbrains-mono-16x32.psfu.gz" 2>/dev/null || true
      fi
      ;;
  esac
  unset linux_tty
fi

# OpenBSD wscons starts in VT220 mode. Enable UTF-8 on local display consoles.
if [ -t 0 ] && [ -t 1 ] && [ "${TERM:-}" = vt220 ]; then
  case $(tty) in
    /dev/ttyC[0-9ab])
      export LC_CTYPE="${LC_CTYPE:-C.UTF-8}"
      printf '\033%%G'
      ;;
  esac
fi

# Keep the current line readable with ANSI colors and a small console font repertoire.
FZF_DEFAULT_OPTS="--height 40% --prompt='> ' --pointer='>' --marker='>' --gutter=' ' --info=inline-right --bind ctrl-f:page-down,ctrl-b:page-up --color=fg:-1,fg+:15,bg:-1,bg+:0,hl:10,hl+:15:underline,info:8,marker:13,prompt:-1,spinner:8,pointer:15,header:8,border:8,gutter:-1"
if [ "${XDG_SESSION_TYPE:-}" != tty ] && [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then
  FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS --input-border=sharp --list-border=sharp --preview-border=sharp"
else
  FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS --no-unicode --preview-border=none"
fi
export FZF_DEFAULT_OPTS
# Previews use standard file tools.
export FZF_CTRL_T_OPTS="--preview 'if [ -d {} ]; then ls -1 {}; else dd bs=16384 count=1 2>/dev/null < {} | head -n 100; fi'"
export FZF_ALT_C_OPTS="--preview 'ls -1 {}'"

export PI_OFFLINE=1

# None of the sessions gets the systemd --user environment, so they take it here: the socket of
# ssh-agent.socket and the ~/.config/environment.d files install links from config/environment.d
# (SSH_ASKPASS, NO_AT_BRIDGE), plain KEY=VALUE lines; only those, not what packages drop there for
# systemd alone.
if [ -z "${SSH_AUTH_SOCK:-}" ] && [ -S "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/openssh_agent" ]; then
  export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/openssh_agent"
fi
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
