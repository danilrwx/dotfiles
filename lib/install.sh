# Shared POSIX sh helpers for the base and development installers.
# shellcheck shell=sh
BACKUP_DIR=
log() { printf '\033[0;31m%s\033[0m\n' "$*"; }

fetch() {
  fetch_url=$1
  fetch_file=$2
  fetch_want=$3
  fetch_alg=sha256sum

  case "$fetch_want" in sha1:*) fetch_alg=sha1sum; fetch_want=${fetch_want#sha1:} ;; esac
  fetch_want=$(printf '%s' "$fetch_want" | tr -d '[:space:]')
  [ -n "$fetch_want" ] || { log "$fetch_url: no checksum to verify it against, not downloaded"; return 1; }
  curl -fsSL -o "$fetch_file" "$fetch_url" || { rm -f "$fetch_file"; return 1; }
  fetch_sum=$("$fetch_alg" "$fetch_file" | awk '{print $1}')
  [ "$fetch_sum" = "$fetch_want" ] && return 0

  log "$fetch_url: ${fetch_alg%sum} is $fetch_sum, want $fetch_want"
  rm -f "$fetch_file"
  return 1
}

unpack() {
  unpack_a=$1
  unpack_dir=$2

  case "$unpack_a" in
  *.tar.gz|*.tgz) unpack_bad=$(tar -tzf "$unpack_a" | grep -E '^/|(^|/)\.\.(/|$)') && { log "$unpack_a: $unpack_bad"; return 1; }
                  mkdir -p "$unpack_dir" && tar -xzf "$unpack_a" -C "$unpack_dir" ;;
  *.tar.xz)       unpack_bad=$(tar -tJf "$unpack_a" | grep -E '^/|(^|/)\.\.(/|$)') && { log "$unpack_a: $unpack_bad"; return 1; }
                  mkdir -p "$unpack_dir" && tar -xJf "$unpack_a" -C "$unpack_dir" ;;
  *.zip)          unpack_bad=$(unzip -Z1 "$unpack_a" | grep -E '^/|(^|/)\.\.(/|$)') && { log "$unpack_a: $unpack_bad"; return 1; }
                  unzip -q "$unpack_a" -d "$unpack_dir" ;;
  *)              log "$unpack_a: not a tar.gz, tar.xz or zip"; return 1 ;;
  esac
}

asroot() {
  asroot_dir=$1
  shift

  if [ -w "$(dirname "$asroot_dir")" ]; then "$@"; else sudo "$@"; fi
}

swap_tree() {
  swap_new=$1
  swap_dir=$2
  asroot "$swap_dir" rm -rf "$swap_dir.new" || return 1
  asroot "$swap_dir" mv "$swap_new" "$swap_dir.new" || { asroot "$swap_dir" rm -rf "$swap_dir.new"; return 1; }

  if [ -e "$swap_dir" ]; then
    asroot "$swap_dir" mv "$swap_dir" "$swap_dir.old" || {
      asroot "$swap_dir" rm -rf "$swap_dir.new"
      return 1
    }
  fi

  if asroot "$swap_dir" mv "$swap_dir.new" "$swap_dir"; then
    asroot "$swap_dir" rm -rf "$swap_dir.old"
    return 0
  fi

  if [ -e "$swap_dir.old" ] && asroot "$swap_dir" mv "$swap_dir.old" "$swap_dir"; then
    log "$swap_dir: the previous tree is back"
  fi
  return 1
}

installed() {
  dpkg-query -W -f='${db:Status-Status}\n' "$1" 2>/dev/null | grep -qx installed
}

backup() {
  backup_src=$1
  backup_mode=${2:-move}
  backup_n=0

  if [ -z "$BACKUP_DIR" ]; then
    (umask 077; mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/backups") || return
    BACKUP_DIR=$(mktemp -d "${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/backups/$(date +%Y%m%d-%H%M%S).XXXXXX") || return
  fi

  backup_base=$BACKUP_DIR/${backup_src#/}
  backup_dst=$backup_base

  while [ -e "$backup_dst" ] || [ -L "$backup_dst" ]; do
    backup_n=$((backup_n + 1))
    backup_dst=$backup_base.$backup_n
  done
  mkdir -p "$(dirname "$backup_dst")" || return

  if [ "$backup_mode" = root ]; then
    sudo cp -a -- "$backup_src" "$backup_dst" || return
  else
    mv -- "$backup_src" "$backup_dst" || return
  fi

  log "Archived $backup_src to $backup_dst"
}

link() {
  link_src=$1
  link_dst=$2

  case "$link_src" in /*) ;; *) link_src=$HOME/dotfiles/$link_src ;; esac

  [ -e "$link_src" ] || { log "Missing config source: $link_src"; return 1; }

  if [ -e "$link_dst.bak" ] || [ -L "$link_dst.bak" ]; then backup "$link_dst.bak" || return; fi

  if [ -L "$link_dst" ] && [ "$(readlink -f "$link_dst")" = "$(readlink -f "$link_src")" ]; then return 0; fi
  mkdir -p "$(dirname "$link_dst")" || return

  if [ -e "$link_dst" ] || [ -L "$link_dst" ]; then backup "$link_dst" || return; fi
  ln -sT -- "$link_src" "$link_dst"
}

retire_link() {
  retired_dst=$HOME/$1
  retired_src=$HOME/dotfiles/$2
  [ -L "$retired_dst" ] && [ "$(readlink "$retired_dst")" = "$retired_src" ] || return 0

  backup "$retired_dst"
}

put() {
  put_src=${3:-etc/${1#/etc/}}
  put_dst=$1

  if [ -r "$put_dst" ] && cmp -s "$put_src" "$put_dst"; then return 1; fi
  sudo cmp -s "$put_src" "$put_dst" && return 1

  if sudo test -e "$put_dst" || sudo test -L "$put_dst"; then backup "$put_dst" root || return; fi
  sudo install -D -m "${2:-644}" "$put_src" "$put_dst"
}

join_group() {
  # Read the group database; this session may predate the group change.
  id -nG "$USER" | grep -qw "$1" && return

  log "Adding user to $1 group"
  sudo usermod -aG "$1" "$USER"
}

git_sync() {
  if [ -d "$1/.git" ]; then
    git -C "$1" pull -q --ff-only || log "Failed to update $1. Continue installation."
  else
    mkdir -p "$(dirname "$1")" && git clone -q "$2" "$1"
  fi
}

deb_from() {
  deb_file=$(mktemp --suffix .deb)
  deb_status=0
  { curl -fsSL -o "$deb_file" "$1" &&
    { [ -z "${2:-}" ] || [ "$(openssl dgst -sha512 -binary "$deb_file" | base64 -w0)" = "$2" ] || { log "$1: checksum mismatch"; false; }; } &&

    sudo apt install -y "$deb_file"; } || deb_status=$?
  rm -f "$deb_file"
  return "$deb_status"
}

user_systemctl() {
  [ -n "${XDG_RUNTIME_DIR:-}" ] || return

  systemctl --user "$@"
}

migrate_backups() {
  for old_archive in "${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/retired" "$HOME/.local/state/dotfiles-x11"; do
    if [ -e "$old_archive" ] || [ -L "$old_archive" ]; then backup "$old_archive" || return; fi
  done

  return 0
}
