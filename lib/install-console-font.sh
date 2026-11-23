#!/bin/sh
set -eu

if [ "$(id -u)" != 0 ]; then
  printf '%s\n' 'Run lib/install-console-font.sh as root.' >&2
  exit 1
fi

cd "$(dirname "$0")/../config/console"

set_font_setting() {
  settings=$1
  assignment=$2
  settings_tmp=$(mktemp "$settings.XXXXXXXX")
  trap 'rm -f "$settings_tmp"' 0
  input=/dev/null
  if [ -f "$settings" ]; then
    input=$settings
    cp -p "$input" "$settings_tmp"
  else
    chmod 644 "$settings_tmp"
  fi
  awk -v key="${assignment%%=*}" -v assignment="$assignment" '
    $0 ~ "^[[:blank:]]*" key "[[:blank:]]*=" {
      if (!written++) print assignment
      next
    }
    { print }
    END { if (!written) print assignment }
  ' "$input" > "$settings_tmp"
  if ! cmp -s "$settings_tmp" "$settings"; then
    mv -f "$settings_tmp" "$settings"
  fi
}

case $(uname -s) in
  OpenBSD)
    font_dir=/usr/local/share/dotfiles/console
    install -d "$font_dir"
    install -m 644 ./jetbrains-mono-*.wsfont.gz OFL.txt "$font_dir/"
    install -m 755 load-wsfont "$font_dir/"
    install -m 755 dotfiles_console_font /etc/rc.d/
    rcctl enable dotfiles_console_font
    rcctl start dotfiles_console_font
    ;;
  Linux)
    . /etc/os-release
    case $ID in
      ubuntu|chimera)
        install -d /etc/console-setup
        install -m 644 jetbrains-mono-16x32.psfu.gz /etc/console-setup/
        install -m 644 OFL.txt /etc/console-setup/jetbrains-mono-OFL.txt
        set_font_setting /etc/default/console-setup 'FONT="/etc/console-setup/jetbrains-mono-16x32.psfu.gz"'
        setupcon --save-only --font-only
        ;;
      alpine)
        install -d /usr/share/consolefonts
        install -m 644 jetbrains-mono-16x32.psfu.gz /usr/share/consolefonts/
        install -m 644 OFL.txt /usr/share/consolefonts/jetbrains-mono-OFL.txt
        set_font_setting /etc/conf.d/consolefont 'consolefont="/usr/share/consolefonts/jetbrains-mono-16x32.psfu.gz"'
        rc-update add consolefont boot
        ;;
      *)
        printf 'Unsupported Linux distribution: %s\n' "$ID" >&2
        exit 1
        ;;
    esac
    ;;
  *)
    printf '%s\n' 'Expected OpenBSD or Linux.' >&2
    exit 1
    ;;
esac
