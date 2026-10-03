package main

import (
	"fmt"
	"sort"

	"github.com/godbus/dbus/v5"
)

const bluez = "org.bluez"

// Device is a paired Bluetooth device; icon is BlueZ's (audio-headset, input-mouse, ...).
type Device struct {
	Address   string `json:"address"`
	Name      string `json:"name"`
	Icon      string `json:"icon"`
	Connected bool   `json:"connected"`
}

// Bluetooth is the radio's state, the first device connected, and the paired devices by name.
type Bluetooth struct {
	On        bool     `json:"on"`
	Connected string   `json:"connected"`
	Devices   []Device `json:"devices"`
}

func btState(conn *dbus.Conn) (Bluetooth, error) {
	b := Bluetooth{Devices: []Device{}}
	objs, err := managed(conn, bluez)
	if err != nil {
		return b, err
	}
	for _, ifaces := range objs {
		if a, ok := ifaces[bluez+".Adapter1"]; ok {
			var on bool
			_ = a["Powered"].Store(&on)
			b.On = b.On || on
		}
		d, ok := ifaces[bluez+".Device1"]
		if !ok {
			continue
		}
		var paired bool
		if d["Paired"].Store(&paired) != nil || !paired {
			continue
		}
		var dev Device
		_ = d["Address"].Store(&dev.Address)
		_ = d["Alias"].Store(&dev.Name)
		_ = d["Icon"].Store(&dev.Icon)
		_ = d["Connected"].Store(&dev.Connected)
		b.Devices = append(b.Devices, dev)
	}
	sort.Slice(b.Devices, func(i, j int) bool { return b.Devices[i].Name < b.Devices[j].Name })
	for _, d := range b.Devices {
		if d.Connected {
			b.Connected = d.Name
			break
		}
	}
	return b, nil
}

// device finds a paired device's path by its address.
func device(conn *dbus.Conn, address string) (dbus.ObjectPath, error) {
	objs, err := managed(conn, bluez)
	if err != nil {
		return "", err
	}
	for p, ifaces := range objs {
		if d, ok := ifaces[bluez+".Device1"]; ok {
			var a string
			if d["Address"].Store(&a) == nil && a == address {
				return p, nil
			}
		}
	}
	return "", fmt.Errorf("no device %s", address)
}

func bt(conn *dbus.Conn, args []string) error {
	if len(args) == 0 {
		return errUsage
	}
	switch args[0] {
	case "on":
		// unblocked, the adapter comes up unpowered: powered on as well
		if err := setBlocked(rfkillBluetooth, false); err != nil {
			return err
		}
		objs, err := managed(conn, bluez)
		if err != nil {
			return err
		}
		for p, ifaces := range objs {
			if _, ok := ifaces[bluez+".Adapter1"]; ok {
				obj := conn.Object(bluez, p)
				if err := obj.SetProperty(bluez+".Adapter1.Powered", dbus.MakeVariant(true)); err != nil {
					return err
				}
			}
		}
		return nil
	case "off":
		return setBlocked(rfkillBluetooth, true)
	case "connect", "disconnect":
		if len(args) != 2 {
			return errUsage
		}
		path, err := device(conn, args[1])
		if err != nil {
			return err
		}
		method := map[string]string{"connect": "Connect", "disconnect": "Disconnect"}[args[0]]
		return conn.Object(bluez, path).Call(bluez+".Device1."+method, 0).Err
	}
	return errUsage
}
