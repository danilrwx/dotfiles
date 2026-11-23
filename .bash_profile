# shellcheck shell=bash
. "$HOME/.profile"

# Linux virtual consoles share their default background/text with slots 0 and 7.
if [[ $TERM == linux && -t 1 && $(tty) =~ ^/dev/tty[0-9]+$ ]]; then
  if [[ -r $HOME/dotfiles/config/console/iosevka-16x32.psfu.gz ]] && command -v setfont >/dev/null; then
    setfont -C "${BASH_REMATCH[0]}" "$HOME/dotfiles/config/console/iosevka-16x32.psfu.gz" 2>/dev/null || true
  fi

  if [[ -r $HOME/dotfiles/config/foot/pastel.ini ]]; then
    awk -F= '
      $1 == "background" { color[0] = $2 }
      $1 == "foreground" { color[7] = $2 }
      $1 ~ /^regular[1-6]$/ { color[substr($1, 8)] = $2 }
      $1 ~ /^bright[0-7]$/ { color[8 + substr($1, 7)] = $2 }
      END { for (i = 0; i < 16; i++) printf "%c]P%x%s", 27, i, color[i] }
    ' "$HOME/dotfiles/config/foot/pastel.ini"
  fi
fi

[ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"
