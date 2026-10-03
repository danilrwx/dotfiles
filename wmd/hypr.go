package main

import (
	"bufio"
	"encoding/json"
	"errors"
	"io"
	"net"
	"os"
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

// nightShader is the warm screen shader of config/hypr; nightFile keeps whether night light is wanted, so a
// config reload (which drops the shader) can put it back
func nightShader() string {
	return filepath.Join(os.Getenv("HOME"), "dotfiles/config/hypr/shaders/night.frag")
}
func nightFile() string { return filepath.Join(os.Getenv("HOME"), ".cache/night-light") }

// nightOn reports whether Hyprland's screen shader is the night one.
func nightOn() bool {
	out, err := hyprctl("j/getoption decoration:screen_shader")
	if err != nil {
		return false
	}
	var opt struct {
		Str string `json:"str"`
	}
	return json.Unmarshal([]byte(out), &opt) == nil && opt.Str == nightShader()
}

// night turns night light on or off and remembers it; apply puts back what was last chosen.
func night(args []string) error {
	if len(args) != 1 {
		return errUsage
	}
	on := args[0] == "on"
	switch args[0] {
	case "on", "off":
		if err := os.WriteFile(nightFile(), []byte(args[0]+"\n"), 0o644); err != nil {
			return err
		}
	case "apply":
		on = read(nightFile()) == "on"
	default:
		return errUsage
	}
	shader := "[[EMPTY]]"
	if on {
		shader = nightShader()
	}
	_, err := hyprctl("keyword decoration:screen_shader " + shader)
	return err
}

// keymap is the main keyboard's active layout as Hyprland names it ("English (US)", "Russian"), "" outside it.
func keymap() string {
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

// hyprEvents kicks on every layout switch, Hyprland's activelayout event; nothing outside Hyprland.
func hyprEvents(kick chan<- struct{}) {
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
