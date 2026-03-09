export MOZ_ENABLE_WAYLAND=1
export _JAVA_AWT_WM_NONREPARENTING=1
export JAVA_TOOL_OPTIONS='-Djdk.gtk.version=2.2'


[ "$(tty)" = "/dev/tty1" ] && exec sway
