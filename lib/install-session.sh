# User configuration shared by Labwc sessions. Platform login and packages are below.
# shellcheck shell=sh

foot_configs() {
  foot_dir=$HOME/.config/foot
  if ! foot --check-config --config /dev/null --override=initial-color-theme=dark >/dev/null 2>&1; then
    link config/foot "$foot_dir"
    return
  fi

  # Foot 1.27 renamed the color sections and their startup selectors.
  foot_settings=$(
    sed -e '/\/pastel\.ini$/d' -e 's@/theme/foot\.ini$@/theme/foot-modern.ini@' \
      -e 's/^\[colors2\]$/[colors-light]/' config/foot/foot.ini &&
    sed 's/^\[colors\]$/[colors-dark]/' config/foot/pastel.ini
  ) || return
  if [ -L "$foot_dir" ]; then backup "$foot_dir" || return; fi
  link config/foot/terminus.ini "$foot_dir/terminus.ini" || return
  foot_config=$foot_dir/foot.ini
  if [ ! -L "$foot_config" ] && printf '%s\n' "$foot_settings" | cmp -s - "$foot_config"; then return 0; fi
  foot_tmp=$(mktemp "$foot_dir/.foot.XXXXXXXX") || return
  printf '%s\n' "$foot_settings" > "$foot_tmp" || { rm -f "$foot_tmp"; return 1; }
  if [ -e "$foot_config" ] || [ -L "$foot_config" ]; then
    backup "$foot_config" || { rm -f "$foot_tmp"; return 1; }
  fi
  mv "$foot_tmp" "$foot_config"
}

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

portable_base_packages() {
  case $platform in
    alpine)
      admin apk add bash git tmux vim curl jq fzf fd ugrep python3 kbd
      ;;
    openbsd)
      set -- bash git vim-- curl jq fzf ugrep
      case $(arch -s) in
        amd64|aarch64|riscv64) set -- "$@" fd ;;
      esac
      admin pkg_add "$@"
      ;;
  esac
}

portable_desktop_packages() {
  portable_user=$(id -un)
  case $platform in
    alpine)
      admin setup-wayland-base labwc foot firefox wmenu dunst libnotify swaybg swayidle swaylock wl-clipboard \
        grim slurp wlr-randr kanshi wlopm seatd xwayland font-iosevka-base mpv \
        greetd-agreety greetd-openrc || return
      id -Gn "$portable_user" | grep -qw seat || admin addgroup "$portable_user" seat || return
      admin rc-update add seatd default || return
      admin rc-service seatd start
      ;;
    openbsd)
      admin pkg_add dbus greetd cage regreet python%3 \
        labwc foot firefox wmenu dunst libnotify swaybg swayidle swaylock wl-clipboard \
        grim slurp wlr-randr kanshi wlopm seatd xwayland iosevka mpv || return
      id -Gn "$portable_user" | grep -qw _seatd || admin user mod -G _seatd "$portable_user" || return
      admin rcctl enable seatd || return
      admin rcctl check seatd || admin rcctl start seatd
      ;;
  esac
}

openbsd_login() {
  greetd_config=/etc/greetd/config.toml
  admin install -d -m 755 /etc/greetd/wayland-sessions /usr/local/libexec || return
  admin install -m 755 bin/start-labwc /usr/local/libexec/dotfiles-labwc-session || return
  admin install -m 644 etc/greetd/labwc.desktop /etc/greetd/wayland-sessions/labwc.desktop || return
  admin install -m 644 etc/greetd/regreet.toml /etc/greetd/dotfiles-regreet.toml || return
  if ! admin cmp -s etc/greetd/openbsd.toml "$greetd_config"; then
    if admin test -f "$greetd_config" && ! admin test -e "$greetd_config.before-dotfiles"; then
      admin cp -p "$greetd_config" "$greetd_config.before-dotfiles" || return
    fi
    admin install -m 644 etc/greetd/openbsd.toml "$greetd_config" || return
  fi
  id -Gn _greetd | grep -qw _seatd || admin user mod -G _seatd _greetd || return
  if admin rcctl ls on | grep -qx xenodm; then admin rcctl disable xenodm || return; fi
  admin rcctl enable greetd || return
  admin rcctl order seatd greetd
}

alpine_login() {
  if ! admin cmp -s etc/greetd/alpine.toml /etc/greetd/config.toml; then
    if admin test -f /etc/greetd/config.toml; then
      admin cp -an /etc/greetd/config.toml /etc/greetd/config.toml.before-dotfiles || return
    fi
    admin install -m 644 etc/greetd/alpine.toml /etc/greetd/config.toml || return
  fi
  admin rc-update add greetd default
}
