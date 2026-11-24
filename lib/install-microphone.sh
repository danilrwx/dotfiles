# Desktop-only microphone processing on Ubuntu and Alpine.
# shellcheck shell=sh

microphone_rnnoise_ubuntu() (
  mic_plugin_sha=240234d4f3e0a3a5b34be93cac1215248e9446c3b799e6bfa29f9328fd5a90e4
  mic_archive_sha=df97df45a4ce81709ec20db75d3f771e4fcad33c5b863d1c29a87e9a49f186aa
  mic_plugin=$1
  [ "$(sha256sum "$mic_plugin" 2>/dev/null | awk '{print $1}')" = "$mic_plugin_sha" ] && exit 0
  mkdir -p "${mic_plugin%/*}" || exit 1
  mic_download=$(mktemp -d "${mic_plugin%/*}/.rnnoise.XXXXXXXX") || exit 1
  trap 'rm -f "$mic_download/archive.zip" "$mic_download/plugin.so"; rmdir "$mic_download"' EXIT
  fetch https://github.com/werman/noise-suppression-for-voice/releases/download/v1.22/linux-rnnoise.zip \
    "$mic_download/archive.zip" "$mic_archive_sha" &&
    unzip -p "$mic_download/archive.zip" linux-rnnoise/ladspa/librnnoise_ladspa.so > "$mic_download/plugin.so" &&
    [ "$(sha256sum "$mic_download/plugin.so" | awk '{print $1}')" = "$mic_plugin_sha" ] &&
    mv -f "$mic_download/plugin.so" "$mic_plugin"
)

microphone_configs() {
  # Only set up the filter when we know the built-in source. On a fresh Ubuntu
  # install the HONOR hardware script adds honor-dmic after desktop_configs.
  case $platform in
    ubuntu)
      [ "$(dpkg --print-architecture)" = amd64 ] || return 0
      [ "$(cat /sys/class/dmi/id/product_name 2>/dev/null)" = ZQC-P ] || return 0
      mic_rnnoise=${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles/ladspa/librnnoise_ladspa.so
      ;;
    alpine)
      [ -r /etc/pipewire/pipewire.conf.d/51-honor-dmic-array.conf ] || return 0
      mic_rnnoise=/usr/lib/ladspa/librnnoise_ladspa.so
      ;;
    *) return 0 ;;
  esac

  mic_compressor=/usr/lib/ladspa/lsp-plugins-ladspa.so
  if [ "$platform" = ubuntu ] && [ "$CONFIGS" = 0 ]; then
    microphone_rnnoise_ubuntu "$mic_rnnoise" || return 1
  fi
  if [ ! -r "$mic_rnnoise" ] || [ ! -r "$mic_compressor" ]; then
    log 'Skipping RNNoise: missing LADSPA plugins. Run ./install --desktop to install them.'
    [ "$CONFIGS" = 1 ] && return 0
    return 1
  fi

  mic_config=${XDG_CONFIG_HOME:-$HOME/.config}/pipewire/pipewire.conf.d/60-dotfiles-microphone.conf
  mic_settings=$(python3 "$HOME/dotfiles/lib/microphone-config.py" \
    "$mic_rnnoise" "$mic_compressor") || return
  if [ ! -L "$mic_config" ] && printf '%s\n' "$mic_settings" | cmp -s - "$mic_config"; then return 0; fi

  mkdir -p "${mic_config%/*}" || return
  mic_tmp=$(mktemp "${mic_config%/*}/.microphone.XXXXXXXX") || return
  printf '%s\n' "$mic_settings" > "$mic_tmp" || { rm -f "$mic_tmp"; return 1; }
  if [ -e "$mic_config" ] || [ -L "$mic_config" ]; then
    backup "$mic_config" || { rm -f "$mic_tmp"; return 1; }
  fi
  mv -f "$mic_tmp" "$mic_config" || { rm -f "$mic_tmp"; return 1; }
  log 'Microphone filters will load the next time PipeWire starts.'
}
