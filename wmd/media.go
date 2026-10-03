package main

import (
	"sort"
	"strings"

	"github.com/godbus/dbus/v5"
)

const mpris = "org.mpris.MediaPlayer2"

// Media is the MPRIS player playing (else the first there is): who it is, the track, its art, where it is in it
// (microseconds, read when asked), and what it can do. Name empty without a player.
type Media struct {
	Name     string `json:"name"`
	Identity string `json:"identity"`
	Title    string `json:"title"`
	Artist   string `json:"artist"`
	Art      string `json:"art"`
	Playing  bool   `json:"playing"`
	Position int64  `json:"position"`
	Length   int64  `json:"length"`
	CanPrev  bool   `json:"canPrev"`
	CanNext  bool   `json:"canNext"`
	CanPlay  bool   `json:"canPlay"`
}

// players are the MPRIS names on the session bus, sorted.
func players(conn *dbus.Conn) []string {
	var names []string
	if conn.BusObject().Call("org.freedesktop.DBus.ListNames", 0).Store(&names) != nil {
		return nil
	}
	var ps []string
	for _, n := range names {
		if strings.HasPrefix(n, mpris+".") {
			ps = append(ps, n)
		}
	}
	sort.Strings(ps)
	return ps
}

func readPlayer(conn *dbus.Conn, name string) Media {
	m := Media{Name: name}
	obj := conn.Object(name, "/org/mpris/MediaPlayer2")
	var root, p map[string]dbus.Variant
	_ = obj.Call("org.freedesktop.DBus.Properties.GetAll", 0, mpris).Store(&root)
	_ = obj.Call("org.freedesktop.DBus.Properties.GetAll", 0, mpris+".Player").Store(&p)
	prop(root, "Identity", &m.Identity)
	var status string
	prop(p, "PlaybackStatus", &status)
	m.Playing = status == "Playing"
	prop(p, "Position", &m.Position)
	prop(p, "CanGoPrevious", &m.CanPrev)
	prop(p, "CanGoNext", &m.CanNext)
	prop(p, "CanPlay", &m.CanPlay)
	var meta map[string]dbus.Variant
	prop(p, "Metadata", &meta)
	prop(meta, "xesam:title", &m.Title)
	prop(meta, "mpris:artUrl", &m.Art)
	var artists []string
	if prop(meta, "xesam:artist", &artists) {
		m.Artist = strings.Join(artists, ", ")
	}
	if !prop(meta, "mpris:length", &m.Length) {
		var l uint64
		if prop(meta, "mpris:length", &l) {
			m.Length = int64(l)
		}
	}
	return m
}

// mediaState is the player playing, else the first; zero without a session bus or a player.
func mediaState() Media {
	conn, err := dbus.SessionBus()
	if err != nil {
		return Media{}
	}
	var first *Media
	for _, n := range players(conn) {
		m := readPlayer(conn, n)
		if m.Playing {
			return m
		}
		if first == nil {
			first = &m
		}
	}
	if first == nil {
		return Media{}
	}
	return *first
}

// mediaEvents kicks on every change a player signals.
func mediaEvents(kick chan<- struct{}) {
	conn, err := dbus.SessionBus()
	if err != nil {
		return
	}
	if conn.AddMatchSignal(dbus.WithMatchObjectPath("/org/mpris/MediaPlayer2")) != nil {
		return
	}
	ch := make(chan *dbus.Signal, 32)
	conn.Signal(ch)
	for range ch {
		kick <- struct{}{}
	}
}

// media play-pause|next|previous: the player mediaState picks.
func media(args []string) error {
	if len(args) != 1 {
		return errUsage
	}
	method := map[string]string{"play-pause": "PlayPause", "next": "Next", "previous": "Previous"}[args[0]]
	if method == "" {
		return errUsage
	}
	m := mediaState()
	if m.Name == "" {
		return nil
	}
	conn, err := dbus.SessionBus()
	if err != nil {
		return err
	}
	return conn.Object(m.Name, "/org/mpris/MediaPlayer2").Call(mpris+".Player."+method, 0).Err
}
