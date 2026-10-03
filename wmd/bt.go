package main

import (
	"fmt"
	"sort"
	"time"

	"github.com/godbus/dbus/v5"
)

const bluez = "org.bluez"

// Device is a Bluetooth device paired, or found by a scan; icon is BlueZ's (audio-headset, input-mouse, ...).
type Device struct {
	Address   string `json:"address"`
	Name      string `json:"name"`
	Icon      string `json:"icon"`
	Paired    bool   `json:"paired"`
	Connected bool   `json:"connected"`
}

// Bluetooth is the radio's state, the first device connected, whether a scan runs, the paired devices by
// name, then those a scan found that have a name.
type Bluetooth struct {
	On          bool     `json:"on"`
	Connected   string   `json:"connected"`
	Discovering bool     `json:"discovering"`
	Devices     []Device `json:"devices"`
}

func btState(conn *dbus.Conn) (Bluetooth, error) {
	b := Bluetooth{Devices: []Device{}}
	objs, err := managed(conn, bluez)
	if err != nil {
		return b, err
	}
	for _, ifaces := range objs {
		if a, ok := ifaces[bluez+".Adapter1"]; ok {
			var on, scanning bool
			prop(a, "Powered", &on)
			prop(a, "Discovering", &scanning)
			b.On = b.On || on
			b.Discovering = b.Discovering || scanning
		}
		d, ok := ifaces[bluez+".Device1"]
		if !ok {
			continue
		}
		var dev Device
		prop(d, "Paired", &dev.Paired)
		prop(d, "Address", &dev.Address)
		prop(d, "Alias", &dev.Name)
		prop(d, "Icon", &dev.Icon)
		prop(d, "Connected", &dev.Connected)
		// a device found but unnamed is but its address: left out
		if _, named := d["Name"]; !dev.Paired && !named {
			continue
		}
		b.Devices = append(b.Devices, dev)
	}
	sort.Slice(b.Devices, func(i, j int) bool {
		if b.Devices[i].Paired != b.Devices[j].Paired {
			return b.Devices[i].Paired
		}
		return b.Devices[i].Name < b.Devices[j].Name
	})
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
			if prop(d, "Address", &a) && a == address {
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
	case "scan":
		return scan(conn)
	case "pair":
		if len(args) != 2 {
			return errUsage
		}
		return pair(conn, args[1])
	case "forget":
		if len(args) != 2 {
			return errUsage
		}
		path, err := device(conn, args[1])
		if err != nil {
			return err
		}
		adapter, err := adapterPath(conn)
		if err != nil {
			return err
		}
		return conn.Object(bluez, adapter).Call(bluez+".Adapter1.RemoveDevice", 0, path).Err
	}
	return errUsage
}

func adapterPath(conn *dbus.Conn) (dbus.ObjectPath, error) {
	objs, err := managed(conn, bluez)
	if err != nil {
		return "", err
	}
	for p, ifaces := range objs {
		if _, ok := ifaces[bluez+".Adapter1"]; ok {
			return p, nil
		}
	}
	return "", fmt.Errorf("no Bluetooth adapter")
}

// scan looks for devices for 20 s: BlueZ keeps a discovery only while the client that started it stays on the
// bus, so this waits it out; what it finds reaches wmd watch through BlueZ's signals.
func scan(conn *dbus.Conn) error {
	adapter, err := adapterPath(conn)
	if err != nil {
		return err
	}
	obj := conn.Object(bluez, adapter)
	if err := obj.Call(bluez+".Adapter1.StartDiscovery", 0).Err; err != nil {
		return err
	}
	time.Sleep(20 * time.Second)
	return obj.Call(bluez+".Adapter1.StopDiscovery", 0).Err
}

// btAgent pairs without asking: a device with no keys or screen (headphones, a speaker) pairs by Just Works,
// and whatever BlueZ would have confirmed is confirmed.
type btAgent struct{}

func (btAgent) Release() *dbus.Error                                       { return nil }
func (btAgent) RequestPinCode(dbus.ObjectPath) (string, *dbus.Error)       { return "0000", nil }
func (btAgent) DisplayPinCode(dbus.ObjectPath, string) *dbus.Error         { return nil }
func (btAgent) RequestPasskey(dbus.ObjectPath) (uint32, *dbus.Error)       { return 0, nil }
func (btAgent) DisplayPasskey(dbus.ObjectPath, uint32, uint16) *dbus.Error { return nil }
func (btAgent) RequestConfirmation(dbus.ObjectPath, uint32) *dbus.Error    { return nil }
func (btAgent) RequestAuthorization(dbus.ObjectPath) *dbus.Error           { return nil }
func (btAgent) AuthorizeService(dbus.ObjectPath, string) *dbus.Error       { return nil }
func (btAgent) Cancel() *dbus.Error                                        { return nil }

// pair pairs a device a scan found, through wmd's own agent, then trusts it (so it reconnects on its own) and
// connects it.
func pair(conn *dbus.Conn, address string) error {
	path, err := device(conn, address)
	if err != nil {
		return err
	}
	const agentPath = dbus.ObjectPath("/wmd/btagent")
	if err := conn.Export(btAgent{}, agentPath, bluez+".Agent1"); err != nil {
		return err
	}
	manager := conn.Object(bluez, "/org/bluez")
	if err := manager.Call(bluez+".AgentManager1.RegisterAgent", 0, agentPath, "NoInputNoOutput").Err; err != nil {
		return err
	}
	defer manager.Call(bluez+".AgentManager1.UnregisterAgent", 0, agentPath)
	dev := conn.Object(bluez, path)
	if err := dev.Call(bluez+".Device1.Pair", 0).Err; err != nil {
		return err
	}
	if err := dev.SetProperty(bluez+".Device1.Trusted", dbus.MakeVariant(true)); err != nil {
		return err
	}
	return dev.Call(bluez+".Device1.Connect", 0).Err
}
