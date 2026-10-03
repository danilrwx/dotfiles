package main

import (
	"github.com/godbus/dbus/v5"
)

// power-profiles-daemon, by its old name, which every version still answers to
const ppd = "net.hadess.PowerProfiles"

// Power is the active power profile and the ones to pick from.
type Power struct {
	Active   string   `json:"active"`
	Profiles []string `json:"profiles"`
}

func powerState(conn *dbus.Conn) (Power, error) {
	p := Power{Profiles: []string{}}
	obj := conn.Object(ppd, "/net/hadess/PowerProfiles")
	v, err := obj.GetProperty(ppd + ".ActiveProfile")
	if err != nil {
		return p, err
	}
	_ = v.Store(&p.Active)
	v, err = obj.GetProperty(ppd + ".Profiles")
	if err != nil {
		return p, err
	}
	var profiles []map[string]dbus.Variant
	_ = v.Store(&profiles)
	for _, pr := range profiles {
		var name string
		if prop(pr, "Profile", &name) {
			p.Profiles = append(p.Profiles, name)
		}
	}
	return p, nil
}

func power(conn *dbus.Conn, args []string) error {
	if len(args) != 2 || args[0] != "set" {
		return errUsage
	}
	return conn.Object(ppd, "/net/hadess/PowerProfiles").SetProperty(ppd+".ActiveProfile", dbus.MakeVariant(args[1]))
}
