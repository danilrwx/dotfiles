package main

import (
	"bufio"
	"errors"
	"fmt"
	"os"
	"sort"
	"strings"

	"github.com/godbus/dbus/v5"
)

const iwd = "net.connman.iwd"

// Network is a Wi-Fi network iwd has seen: signal in bars, 0 to 4, as iwctl draws them.
type Network struct {
	SSID      string `json:"ssid"`
	Signal    int    `json:"signal"`
	Security  string `json:"security"`
	Known     bool   `json:"known"`
	Connected bool   `json:"connected"`
}

// Wifi is the radio's state, the network it is on, and the networks in sight, the strongest first.
type Wifi struct {
	On       bool      `json:"on"`
	SSID     string    `json:"ssid"`
	Signal   int       `json:"signal"`
	Networks []Network `json:"networks"`
}

type objects map[dbus.ObjectPath]map[string]map[string]dbus.Variant

// prop stores the property k of an interface's properties into dst, reporting whether it was there and of the
// type; a missing one (a device a scan found has no Icon yet) is left alone rather than handed to godbus,
// which panics on an empty Variant.
func prop[T any](props map[string]dbus.Variant, k string, dst *T) bool {
	v, ok := props[k]
	return ok && v.Store(dst) == nil
}

func managed(conn *dbus.Conn, service string) (objects, error) {
	var objs objects
	err := conn.Object(service, "/").Call("org.freedesktop.DBus.ObjectManager.GetManagedObjects", 0).Store(&objs)
	return objs, err
}

// station is the path of the first device in station mode, "" while the radio is off.
func station(objs objects) dbus.ObjectPath {
	paths := make([]string, 0, len(objs))
	for p, ifaces := range objs {
		if _, ok := ifaces[iwd+".Station"]; ok {
			paths = append(paths, string(p))
		}
	}
	if len(paths) == 0 {
		return ""
	}
	sort.Strings(paths)
	return dbus.ObjectPath(paths[0])
}

// bars turns iwd's signal, in hundredths of a dBm, into iwctl's 0 to 4 bars.
func bars(signal int16) int {
	switch {
	case signal >= -6000:
		return 4
	case signal >= -6700:
		return 3
	case signal >= -7500:
		return 2
	case signal >= -8500:
		return 1
	}
	return 0
}

func wifiState(conn *dbus.Conn) (Wifi, error) {
	w := Wifi{On: !blocked("wlan"), Networks: []Network{}}
	objs, err := managed(conn, iwd)
	if err != nil {
		return w, err
	}
	st := station(objs)
	if st == "" {
		return w, nil
	}
	var ordered []struct {
		Path   dbus.ObjectPath
		Signal int16
	}
	if err := conn.Object(iwd, st).Call(iwd+".Station.GetOrderedNetworks", 0).Store(&ordered); err != nil {
		return w, err
	}
	for _, o := range ordered {
		props := objs[o.Path][iwd+".Network"]
		n := Network{Signal: bars(o.Signal)}
		prop(props, "Name", &n.SSID)
		prop(props, "Type", &n.Security)
		prop(props, "Connected", &n.Connected)
		_, n.Known = props["KnownNetwork"]
		if n.Connected {
			w.SSID, w.Signal = n.SSID, n.Signal
		}
		w.Networks = append(w.Networks, n)
	}
	return w, nil
}

// network finds the path of the network named ssid among those in sight.
func network(conn *dbus.Conn, ssid string) (dbus.ObjectPath, error) {
	objs, err := managed(conn, iwd)
	if err != nil {
		return "", err
	}
	for p, ifaces := range objs {
		if n, ok := ifaces[iwd+".Network"]; ok {
			var name string
			if prop(n, "Name", &name) && name == ssid {
				return p, nil
			}
		}
	}
	return "", fmt.Errorf("no network %q in sight; scan first", ssid)
}

// agent answers iwd's passphrase request with the one read from stdin, for a network iwd does not know yet.
type agent struct{ passphrase func() (string, error) }

func (a agent) RequestPassphrase(dbus.ObjectPath) (string, *dbus.Error) {
	p, err := a.passphrase()
	if err != nil {
		return "", dbus.MakeFailedError(err)
	}
	return p, nil
}
func (agent) Release() *dbus.Error      { return nil }
func (agent) Cancel(string) *dbus.Error { return nil }

func stdinPassphrase() (string, error) {
	line, err := bufio.NewReader(os.Stdin).ReadString('\n')
	if err != nil && line == "" {
		return "", errors.New("a passphrase is needed on stdin")
	}
	return strings.TrimRight(line, "\r\n"), nil
}

func wifi(conn *dbus.Conn, args []string) error {
	if len(args) == 0 {
		return errUsage
	}
	switch args[0] {
	case "on", "off":
		return setBlocked(rfkillWLAN, args[0] == "off")
	case "scan", "disconnect":
		objs, err := managed(conn, iwd)
		if err != nil {
			return err
		}
		st := station(objs)
		if st == "" {
			return errors.New("Wi-Fi is off")
		}
		method := map[string]string{"scan": "Scan", "disconnect": "Disconnect"}[args[0]]
		return conn.Object(iwd, st).Call(iwd+".Station."+method, 0).Err
	case "forget":
		if len(args) != 2 {
			return errUsage
		}
		path, err := network(conn, args[1])
		if err != nil {
			return err
		}
		known, err := conn.Object(iwd, path).GetProperty(iwd + ".Network.KnownNetwork")
		if err != nil {
			return fmt.Errorf("%q is not a known network", args[1])
		}
		var kpath dbus.ObjectPath
		if err := known.Store(&kpath); err != nil {
			return err
		}
		return conn.Object(iwd, kpath).Call(iwd+".KnownNetwork.Forget", 0).Err
	case "connect":
		if len(args) != 2 {
			return errUsage
		}
		path, err := network(conn, args[1])
		if err != nil {
			return err
		}
		const agentPath = dbus.ObjectPath("/wmd/agent")
		if err := conn.Export(agent{stdinPassphrase}, agentPath, iwd+".Agent"); err != nil {
			return err
		}
		manager := conn.Object(iwd, "/net/connman/iwd")
		if err := manager.Call(iwd+".AgentManager.RegisterAgent", 0, agentPath).Err; err != nil {
			return err
		}
		defer manager.Call(iwd+".AgentManager.UnregisterAgent", 0, agentPath)
		return conn.Object(iwd, path).Call(iwd+".Network.Connect", 0).Err
	}
	return errUsage
}
