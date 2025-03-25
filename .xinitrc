#!/bin/sh

userresources=$HOME/.Xresources
sysresources=/etc/X11/xinit/.Xresources

if [ -f $sysresources ]; then
	xrdb -merge $sysresources
fi

if [ -f "$userresources" ]; then
	xrdb -merge "$userresources"
fi

if which dbus-launch >/dev/null 2>&1 && test -z "$DBUS_SESSION_BUS_ADDRESS"; then
	eval $(dbus-launch --sh-syntax --exit-with-session)
fi

wm-autostart

while true; do
	wm-autostart-blocking &
	dwm >/dev/null 2>&1
done
