package main

import (
	"encoding/json"
	"net/http"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"

	"github.com/godbus/dbus/v5"
)

// Vless is mihomo's state as bin/vless runs it: off, or tun (TUN) or proxy (the system proxy); the mode, rule
// or global; the profile picked in the PROXY group and the ones to pick from. From mihomo's API, which answers
// only while it runs; bin/vless itself still does the switching.
type Vless struct {
	How      string   `json:"how"`
	Mode     string   `json:"mode"`
	Profile  string   `json:"profile"`
	Profiles []string `json:"profiles"`
}

// api is for mihomo's local API, answering at once or not running; web for the internet (the weather)
var (
	api = &http.Client{Timeout: 500 * time.Millisecond}
	web = &http.Client{Timeout: 10 * time.Second}
)

func getJSON(url string, v any) error { return getJSONWith(api, url, v) }

func getJSONWith(c *http.Client, url string, v any) error {
	resp, err := c.Get(url)
	if err != nil {
		return err
	}
	defer func() { _ = resp.Body.Close() }()
	return json.NewDecoder(resp.Body).Decode(v)
}

func vlessState() Vless {
	v := Vless{How: "off", Profiles: []string{}}
	var cfg struct {
		Mode string `json:"mode"`
		Tun  struct {
			Enable bool `json:"enable"`
		} `json:"tun"`
	}
	if getJSON("http://127.0.0.1:9090/configs", &cfg) != nil {
		return v
	}
	v.How, v.Mode = "proxy", cfg.Mode
	if cfg.Tun.Enable {
		v.How = "tun"
	}
	var group struct {
		Now string   `json:"now"`
		All []string `json:"all"`
	}
	if getJSON("http://127.0.0.1:9090/proxies/PROXY", &group) == nil {
		v.Profile = group.Now
		v.Profiles = append(v.Profiles, group.All...)
	}
	return v
}

// OpenVPN is the openvpn-client@ unit up or coming up (bin/openvpn-ctl), "" while none is, whether it is
// through, and the profiles in private/config/openvpn.
type OpenVPN struct {
	Profile  string   `json:"profile"`
	Ready    bool     `json:"ready"`
	Profiles []string `json:"profiles"`
}

func openvpnState(conn *dbus.Conn) OpenVPN {
	o := OpenVPN{Profiles: []string{}}
	files, _ := filepath.Glob(filepath.Join(os.Getenv("HOME"), "dotfiles/private/config/openvpn/*.ovpn"))
	for _, f := range files {
		o.Profiles = append(o.Profiles, strings.TrimSuffix(filepath.Base(f), ".ovpn"))
	}
	sort.Strings(o.Profiles)

	systemd := conn.Object("org.freedesktop.systemd1", "/org/freedesktop/systemd1")
	var units []struct {
		Name, Description, Load, Active, Sub, Following string
		Path                                            dbus.ObjectPath
		JobID                                           uint32
		JobType                                         string
		JobPath                                         dbus.ObjectPath
	}
	if systemd.Call("org.freedesktop.systemd1.Manager.ListUnitsByPatterns", 0,
		[]string{"active", "activating"}, []string{"openvpn-client@*.service"}).Store(&units) != nil || len(units) == 0 {
		return o
	}
	path := units[0].Path
	o.Profile = strings.TrimSuffix(strings.TrimPrefix(units[0].Name, "openvpn-client@"), ".service")
	// through once openvpn tells systemd so (sd_notify's status)
	status, err := conn.Object("org.freedesktop.systemd1", path).GetProperty("org.freedesktop.systemd1.Service.StatusText")
	var text string
	o.Ready = err == nil && status.Store(&text) == nil && strings.Contains(text, "Initialization Sequence Completed")
	return o
}
