# Shared Ubuntu gaming setup.
# shellcheck shell=sh

lolka() {
  installed lolka-x && return 0

  log "Installing Lolka X"
  lolka_release=$(curl -fsSL -H 'Accept: application/json' https://updates.lolka.app/desktop/linux/latest) || return
  lolka_deb=$(printf '%s\n' "$lolka_release" | jq -ce '
    first(.files[] | select(.name | startswith("lolka-x_") and endswith("_amd64.deb")))
  ')
  lolka_url=$(printf '%s\n' "$lolka_deb" | jq -er '.url | select(startswith("https://"))')
  lolka_sha512=$(printf '%s\n' "$lolka_deb" | jq -er '.sha512 | select(length > 0)')
  deb_from "$lolka_url" "$lolka_sha512"
}

SCX_TAG=v1.1.4
SCX_COMMIT=e7b3a219617472cf78880ac424714e52c932db61
GAMING_PKGS="flatpak gamemode
  libvulkan1 mesa-vulkan-drivers libgl1-mesa-dri
  linux-tools-common linux-tools-generic"
scx_ok() {
  /usr/local/bin/scx_lavd --version 2>/dev/null |
    awk -v version="${SCX_TAG#v}" 'NR == 1 && $2 == version {ok=1} END {exit !ok}'
}

install_scheduler() {
  [ -d /sys/kernel/sched_ext ] || { log 'sched_ext unavailable; skipped scx_lavd'; return 0; }
  if ! scx_ok; then
    sudo apt-get install -y build-essential git clang libclang-dev libbpf-dev libelf-dev zlib1g-dev pkg-config rust-clippy || return
    src=$HOME/.cache/build/scx
    mkdir -p "${src%/*}" || return

    if [ "$(git -C "$src" rev-parse HEAD 2>/dev/null || true)" != "$SCX_COMMIT" ]; then
      # Keep any older checkout, including local changes.
      if [ -e "$src" ]; then mv "$src" "$src.backup-$(date +%s%N)" || return; fi
      git clone --depth 1 --branch "$SCX_TAG" https://github.com/sched-ext/scx "$src" || return
    fi

    [ "$(git -C "$src" rev-parse HEAD)" = "$SCX_COMMIT" ] || {
      echo 'scx release commit differs from the pinned revision' >&2; return 1;
    }
    rust=$(find /usr/lib -maxdepth 2 -path '/usr/lib/rust-*/bin' -type d | sort -V | tail -1)
    [ -x "$rust/cargo" ] || { echo 'Distribution Cargo was not found' >&2; return 1; }
    (cd "$src" && PATH="$rust:$PATH" "$rust/cargo" build --release --locked -p scx_lavd) || return
    sudo install -m 755 "$src/target/release/scx_lavd" /usr/local/bin/scx_lavd || return
    scx_ok || return
  fi
  sudo install -D -m 644 game/etc/systemd/system/scx_lavd.service /etc/systemd/system/scx_lavd.service || return
  sudo systemctl daemon-reload && sudo systemctl enable --now scx_lavd.service
}

install_gaming() {
  [ "$(dpkg --print-architecture)" = amd64 ] || { log 'Gaming packages are only configured for amd64'; return 0; }

  sudo apt-get install -y $GAMING_PKGS || return
  flatpak --user remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || return
  flatpak --user install --noninteractive --assumeyes flathub com.valvesoftware.Steam || return
  lolka || return

  for rel in etc/systemd/system/cpu-idle.service etc/polkit-1/rules.d/50-cpu-idle.rules; do
    sudo install -D -m 644 "game/$rel" "/$rel" || return
  done
  sudo systemctl daemon-reload || return
  install_scheduler || log 'Could not install scx_lavd'
}
