// wmd: the desktop's state and switches for the bar (config/quickshell), straight from D-Bus: Wi-Fi through
// iwd, Bluetooth through BlueZ, the radios through /dev/rfkill.
//
//	wmd watch                                 the state as a JSON line, again on every change
//	wmd wifi on|off|scan|disconnect           the radio, a scan, leave the network
//	wmd wifi connect SSID                     join a network; one iwd does not know reads its passphrase from stdin
//	wmd bt on|off|connect ADDR|disconnect ADDR
//
// Installed by `go install github.com/danilrwx/dotfiles/wmd@latest`.
package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"time"

	"github.com/godbus/dbus/v5"
)

var errUsage = errors.New("usage: wmd watch | wifi on|off|scan|disconnect|connect SSID | bt on|off|connect ADDR|disconnect ADDR")

// State is what wmd watch prints.
type State struct {
	Wifi      Wifi      `json:"wifi"`
	Bluetooth Bluetooth `json:"bt"`
}

func state(conn *dbus.Conn) State {
	var s State
	var err error
	if s.Wifi, err = wifiState(conn); err != nil {
		fmt.Fprintln(os.Stderr, "wmd: wifi:", err)
	}
	if s.Bluetooth, err = btState(conn); err != nil {
		fmt.Fprintln(os.Stderr, "wmd: bt:", err)
	}
	return s
}

// watch prints the state, then again whenever iwd or BlueZ signal a change, 100 ms after the last of a burst,
// and every 10 s besides, as iwd signals nothing when a network's strength alone moves. Only a state that
// differs from the last one printed goes out.
func watch(conn *dbus.Conn) error {
	for _, sender := range []string{iwd, bluez} {
		if err := conn.AddMatchSignal(dbus.WithMatchSender(sender)); err != nil {
			return err
		}
	}
	signals := make(chan *dbus.Signal, 64)
	conn.Signal(signals)

	enc := json.NewEncoder(os.Stdout)
	var last string
	emit := func() error {
		b, _ := json.Marshal(state(conn))
		if string(b) == last {
			return nil
		}
		last = string(b)
		return enc.Encode(json.RawMessage(b))
	}
	if err := emit(); err != nil {
		return err
	}
	settle := time.NewTimer(time.Hour)
	tick := time.NewTicker(10 * time.Second)
	for {
		select {
		case <-signals:
			settle.Reset(100 * time.Millisecond)
		case <-settle.C:
			if err := emit(); err != nil {
				return err
			}
		case <-tick.C:
			if err := emit(); err != nil {
				return err
			}
		}
	}
}

func run(args []string) error {
	if len(args) == 0 {
		return errUsage
	}
	conn, err := dbus.ConnectSystemBus()
	if err != nil {
		return err
	}
	defer func() { _ = conn.Close() }()
	switch args[0] {
	case "watch":
		return watch(conn)
	case "wifi":
		return wifi(conn, args[1:])
	case "bt":
		return bt(conn, args[1:])
	}
	return errUsage
}

func main() {
	if err := run(os.Args[1:]); err != nil {
		fmt.Fprintln(os.Stderr, "wmd:", err)
		os.Exit(1)
	}
}
