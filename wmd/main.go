// wmd: the desktop's state and switches for the bar (config/quickshell), from the services themselves rather
// than their command-line tools: Wi-Fi through iwd and Bluetooth through BlueZ (D-Bus), the radios through
// /dev/rfkill, the power profile through power-profiles-daemon, the backlight through logind, the keyboard
// layout through Hyprland's sockets, the sound devices through pw-dump, VLESS through mihomo's API, OpenVPN
// through systemd.
//
//	wmd watch                                 the state as a JSON line, again on every change
//	wmd wifi on|off|scan|disconnect           the radio, a scan, leave the network
//	wmd wifi connect SSID                     join a network; one iwd does not know reads its passphrase from stdin
//	wmd bt on|off|connect ADDR|disconnect ADDR
//	wmd power set PROFILE                     power-saver, balanced, performance
//	wmd brightness PERCENT                    the backlight
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

var errUsage = errors.New("usage: wmd watch | wifi on|off|scan|disconnect|connect SSID | " +
	"bt on|off|connect ADDR|disconnect ADDR | power set PROFILE | brightness PERCENT")

// State is what wmd watch prints.
type State struct {
	Wifi       Wifi      `json:"wifi"`
	Bluetooth  Bluetooth `json:"bt"`
	Power      Power     `json:"power"`
	Brightness int       `json:"brightness"`
	Keymap     string    `json:"keymap"`
	Audio      Audio     `json:"audio"`
	Vless      Vless     `json:"vless"`
	OpenVPN    OpenVPN   `json:"openvpn"`
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
	if s.Power, err = powerState(conn); err != nil {
		fmt.Fprintln(os.Stderr, "wmd: power:", err)
	}
	if s.Audio, err = audioState(); err != nil {
		fmt.Fprintln(os.Stderr, "wmd: audio:", err)
	}
	s.Brightness, s.Keymap = brightness(), keymap()
	s.Vless, s.OpenVPN = vlessState(), openvpnState(conn)
	return s
}

// watch prints the state, then again 100 ms after the last of a burst of changes: iwd, BlueZ and
// power-profiles-daemon signal theirs on D-Bus, Hyprland its layout switches, PipeWire its changes through
// pw-dump's monitor. Every 3 s besides, for what tells nothing: a network's strength, the backlight, VLESS,
// OpenVPN. Only a state that differs from the last one printed goes out.
func watch(conn *dbus.Conn) error {
	for _, sender := range []string{iwd, bluez, ppd} {
		if err := conn.AddMatchSignal(dbus.WithMatchSender(sender)); err != nil {
			return err
		}
	}
	signals := make(chan *dbus.Signal, 64)
	conn.Signal(signals)
	kick := make(chan struct{}, 64)
	go hyprEvents(kick)
	go audioEvents(kick)

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
	tick := time.NewTicker(3 * time.Second)
	for {
		select {
		case <-signals:
			settle.Reset(100 * time.Millisecond)
		case <-kick:
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
	case "power":
		return power(conn, args[1:])
	case "brightness":
		return setBrightness(conn, args[1:])
	}
	return errUsage
}

func main() {
	if err := run(os.Args[1:]); err != nil {
		fmt.Fprintln(os.Stderr, "wmd:", err)
		os.Exit(1)
	}
}
