package main

import (
	"errors"
	"path/filepath"
	"strconv"

	"github.com/godbus/dbus/v5"
)

// backlight is the panel's backlight device under /sys/class/backlight, "" without one.
func backlight() string {
	dirs, _ := filepath.Glob("/sys/class/backlight/*")
	if len(dirs) == 0 {
		return ""
	}
	return dirs[0]
}

// brightness is the backlight in percent of its maximum, -1 without one.
func brightness() int {
	dir := backlight()
	cur, err1 := strconv.Atoi(read(filepath.Join(dir, "brightness")))
	maxi, err2 := strconv.Atoi(read(filepath.Join(dir, "max_brightness")))
	if dir == "" || err1 != nil || err2 != nil || maxi == 0 {
		return -1
	}
	return (cur*100 + maxi/2) / maxi
}

// setBrightness sets the backlight to percent through logind's SetBrightness, which the session's user may
// call without root; never all the way down to 0, a black screen.
func setBrightness(conn *dbus.Conn, args []string) error {
	if len(args) != 1 {
		return errUsage
	}
	pct, err := strconv.Atoi(args[0])
	if err != nil {
		return errUsage
	}
	dir := backlight()
	if dir == "" {
		return errors.New("no backlight")
	}
	maxi, err := strconv.Atoi(read(filepath.Join(dir, "max_brightness")))
	if err != nil {
		return err
	}
	value := uint32(max(1, min(maxi, maxi*pct/100)))
	return conn.Object("org.freedesktop.login1", "/org/freedesktop/login1/session/auto").
		Call("org.freedesktop.login1.Session.SetBrightness", 0, "backlight", filepath.Base(dir), value).Err
}
