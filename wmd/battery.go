package main

import "github.com/godbus/dbus/v5"

const upower = "org.freedesktop.UPower"

// Battery is UPower's display device: the charge in percent, its state (charging, discharging,
// pending-charge: plugged in but held, fully-charged), the icon UPower names for it, and the seconds to empty
// or to full as it reckons them (0 while it cannot tell); Present false on a machine without one.
type Battery struct {
	Present bool    `json:"present"`
	Percent float64 `json:"percent"`
	State   string  `json:"state"`
	Icon    string  `json:"icon"`
	ToEmpty int64   `json:"toEmpty"`
	ToFull  int64   `json:"toFull"`
}

func batteryState(conn *dbus.Conn) (Battery, error) {
	var b Battery
	obj := conn.Object(upower, "/org/freedesktop/UPower/devices/DisplayDevice")
	var props map[string]dbus.Variant
	if err := obj.Call("org.freedesktop.DBus.Properties.GetAll", 0, upower+".Device").Store(&props); err != nil {
		return b, err
	}
	var state uint32
	prop(props, "IsPresent", &b.Present)
	prop(props, "Percentage", &b.Percent)
	prop(props, "State", &state)
	prop(props, "IconName", &b.Icon)
	prop(props, "TimeToEmpty", &b.ToEmpty)
	prop(props, "TimeToFull", &b.ToFull)
	b.State = map[uint32]string{1: "charging", 2: "discharging", 3: "empty", 4: "fully-charged", 5: "pending-charge",
		6: "pending-discharge"}[state]
	return b, nil
}
