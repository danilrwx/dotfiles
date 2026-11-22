# User configuration shared by Labwc sessions. Platform login and packages are below.
# shellcheck shell=sh

labwc_configs() {
  labwc_dir=$HOME/.config/labwc
  if [ -L "$labwc_dir" ]; then backup "$labwc_dir" || return; fi
  for labwc_file in rc.xml autostart shutdown kanshi.conf; do
    link "config/labwc/$labwc_file" "$labwc_dir/$labwc_file" || return
  done
  if [ "$platform" = ubuntu ] && [ "$(cat /sys/class/dmi/id/product_name 2>/dev/null)" = ZQC-P ]; then
    labwc_settings=$(
      cat config/labwc/environment &&
      printf '%s\n' 'WLR_NO_HARDWARE_CURSORS=1' 'WLR_DRM_NO_ATOMIC=1'
    ) || return
    if ! printf '%s\n' "$labwc_settings" | cmp -s - "$labwc_dir/environment"; then
      labwc_env=$(mktemp "$labwc_dir/.environment.XXXXXXXX") || return
      printf '%s\n' "$labwc_settings" > "$labwc_env" || { rm -f "$labwc_env"; return 1; }
      if [ -e "$labwc_dir/environment" ] || [ -L "$labwc_dir/environment" ]; then
        backup "$labwc_dir/environment" || { rm -f "$labwc_env"; return 1; }
      fi
      mv "$labwc_env" "$labwc_dir/environment" || return
    fi
  else
    link config/labwc/environment "$labwc_dir/environment" || return
  fi
  retire_link .cwmrc config/cwm/cwmrc || return
  retire_link .xinitrc config/cwm/session || return
  retire_link .xsession config/cwm/session || return
}

ubuntu_login() {
  sudo install -d /etc/greetd/sessions /etc/greetd/xsessions || return
  sudo ln -sfnT /usr/share/wayland-sessions/labwc.desktop /etc/greetd/sessions/labwc.desktop || return
  if ! cmp -s etc/greetd/config.toml /etc/greetd/config.toml; then put /etc/greetd/config.toml || return; fi

  for retired_session in /usr/share/wayland-sessions/labwc-game.desktop /usr/local/bin/labwc-gaming \
    /usr/local/share/xsessions/cwm.desktop /usr/local/bin/dotfiles-cwm-session; do
    sudo test -e "$retired_session" || continue
    backup "$retired_session" root && sudo rm "$retired_session" || return
  done
}

admin() {
  if [ "$(id -u)" -eq 0 ]; then "$@"
  elif command -v doas >/dev/null; then doas "$@"
  else sudo "$@"
  fi
}

portable_packages() {
  portable_user=$(id -un)
  case $platform in
    alpine)
      admin setup-wayland-base bash git tmux vim curl jq fzf fd ugrep python3 \
        labwc foot firefox wmenu dunst libnotify swaybg swayidle swaylock wl-clipboard \
        grim slurp wlr-randr kanshi wlopm seatd xwayland font-terminus mpv || return
      id -Gn "$portable_user" | grep -qw seat || admin addgroup "$portable_user" seat || return
      admin rc-update add seatd default || return
      admin rc-service seatd start
      ;;
    openbsd)
      admin pkg_add bash git vim-- curl jq fzf fd ugrep python%3.14 dbus \
        labwc foot firefox wmenu dunst libnotify swaybg swayidle swaylock wl-clipboard \
        grim slurp wlr-randr kanshi wlopm seatd xwayland terminus-font mpv || return
      id -Gn "$portable_user" | grep -qw _seatd || admin user mod -G _seatd "$portable_user" || return
      admin rcctl enable seatd || return
      admin rcctl check seatd || admin rcctl start seatd
      ;;
  esac
}
