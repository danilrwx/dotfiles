[[ -f ~/.bashrc ]] && . ~/.bashrc

if which dbus-launch >/dev/null 2>&1 && test -z "$DBUS_SESSION_BUS_ADDRESS"; then
	eval `dbus-launch --sh-syntax --exit-with-session`
fi 

if [ -z "${WAYLAND_DISPLAY}" ] && [ "${XDG_VTNR}" -eq 1 ]; then
	export SDL_VIDEODRIVER=wayland 
	export XDG_CURRENT_DESKTOP=sway
	export XDG_SESSION_DESKTOP=sway
	export MOZ_ENABLE_WAYLAND=1
	
	exec dbus-run-session sway 
fi
