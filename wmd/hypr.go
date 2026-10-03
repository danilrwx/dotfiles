package main

import (
	"bufio"
	"encoding/json"
	"errors"
	"io"
	"net"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

// hyprSocket is one of Hyprland's sockets (".socket.sock" for requests, ".socket2.sock" for events), "" outside
// Hyprland.
func hyprSocket(name string) string {
	sig := os.Getenv("HYPRLAND_INSTANCE_SIGNATURE")
	if sig == "" {
		return ""
	}
	return filepath.Join(os.Getenv("XDG_RUNTIME_DIR"), "hypr", sig, name)
}

// hyprctl sends a request to Hyprland's socket ("j/devices", "keyword ...") and returns its answer.
func hyprctl(req string) (string, error) {
	sock := hyprSocket(".socket.sock")
	if sock == "" {
		return "", errors.New("not under Hyprland")
	}
	c, err := net.Dial("unix", sock)
	if err != nil {
		return "", err
	}
	defer func() { _ = c.Close() }()
	if _, err := io.WriteString(c, req); err != nil {
		return "", err
	}
	b, err := io.ReadAll(c)
	return string(b), err
}

// keymap is the main keyboard's active layout as the compositor names it ("English (US)", "Russian"): Hyprland's
// main keyboard, sway's first one; "" under neither.
func keymap() string {
	if os.Getenv("SWAYSOCK") != "" {
		return swayKeymap()
	}
	out, err := hyprctl("j/devices")
	if err != nil {
		return ""
	}
	var devices struct {
		Keyboards []struct {
			Main   bool   `json:"main"`
			Keymap string `json:"active_keymap"`
		} `json:"keyboards"`
	}
	if json.Unmarshal([]byte(out), &devices) != nil {
		return ""
	}
	for _, k := range devices.Keyboards {
		if k.Main {
			return k.Keymap
		}
	}
	return ""
}

// hyprEvents kicks on every layout switch, Hyprland's activelayout event or sway's input one; nothing under
// neither.
func hyprEvents(kick chan<- struct{}) {
	if os.Getenv("SWAYSOCK") != "" {
		swayEvents(kick)
		return
	}
	sock := hyprSocket(".socket2.sock")
	if sock == "" {
		return
	}
	c, err := net.Dial("unix", sock)
	if err != nil {
		return
	}
	s := bufio.NewScanner(c)
	for s.Scan() {
		if strings.HasPrefix(s.Text(), "activelayout>>") {
			kick <- struct{}{}
		}
	}
}

// swayKeymap is the first keyboard's active layout under sway.
func swayKeymap() string {
	out, err := exec.Command("swaymsg", "-r", "-t", "get_inputs").Output()
	if err != nil {
		return ""
	}
	var inputs []struct {
		Type   string `json:"type"`
		Layout string `json:"xkb_active_layout_name"`
	}
	if json.Unmarshal(out, &inputs) != nil {
		return ""
	}
	for _, i := range inputs {
		if i.Type == "keyboard" && i.Layout != "" {
			return i.Layout
		}
	}
	return ""
}

// swayEvents kicks on sway's input events (a layout switch among them), for as long as swaymsg runs.
func swayEvents(kick chan<- struct{}) {
	cmd := exec.Command("swaymsg", "-m", "-t", "subscribe", `["input"]`)
	out, err := cmd.StdoutPipe()
	if err != nil || cmd.Start() != nil {
		return
	}
	s := bufio.NewScanner(out)
	for s.Scan() {
		kick <- struct{}{}
	}
	_ = cmd.Wait()
}
