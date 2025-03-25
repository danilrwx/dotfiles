export MOZ_ENABLE_WAYLAND=1
export _JAVA_AWT_WM_NONREPARENTING=1
export JAVA_TOOL_OPTIONS='-Djdk.gtk.version=2.2'


eval $(keychain --eval --quiet ~/.ssh/id_ed25519)

[ "$(tty)" = "/dev/tty1" ] && exec sway
