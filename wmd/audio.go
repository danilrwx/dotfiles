package main

import (
	"bufio"
	"encoding/json"
	"errors"
	"math"
	"os/exec"
	"slices"
	"sort"
	"strconv"
	"strings"
)

// Sound is a PipeWire sink or source: its node id (for wpctl set-default), its name, whether it is the default.
type Sound struct {
	ID   int    `json:"id"`
	Name string `json:"name"`
	Def  bool   `json:"def"`
}

// Audio is the sinks and sources by name, so a list holds still as the default moves, and the Bluetooth
// headset's mode: headphones (A2DP) or handsfree (HFP), "" without one.
type Audio struct {
	Sinks   []Sound `json:"sinks"`
	Sources []Sound `json:"sources"`
	Headset string  `json:"headset"`
	// the default output's and input's level, 0 to 1 as wpctl puts it, and whether muted
	Volume  float64 `json:"volume"`
	Muted   bool    `json:"muted"`
	Mic     float64 `json:"mic"`
	MicMute bool    `json:"micMuted"`
}

// pwObject is the part of a pw-dump object read here.
type pwObject struct {
	ID       int    `json:"id"`
	Type     string `json:"type"`
	Props    map[string]any
	Metadata []struct {
		Key   string          `json:"key"`
		Value json.RawMessage `json:"value"` // an object for the defaults, a number or string for others
	} `json:"metadata"`
	Info struct {
		Props  map[string]any `json:"props"`
		Params struct {
			EnumRoute []struct {
				Available string `json:"available"`
				Devices   []int  `json:"devices"`
			} `json:"EnumRoute"`
			Profile []struct {
				Name string `json:"name"`
			} `json:"Profile"`
			Props []struct {
				ChannelVolumes []float64 `json:"channelVolumes"`
				Mute           bool      `json:"mute"`
			} `json:"Props"`
			EnumProfile []struct {
				Index    int    `json:"index"`
				Name     string `json:"name"`
				Priority int    `json:"priority"`
			} `json:"EnumProfile"`
		} `json:"params"`
	} `json:"info"`
}

func str(m map[string]any, k string) string {
	s, _ := m[k].(string)
	return s
}

func num(m map[string]any, k string) int {
	f, _ := m[k].(float64)
	return int(f)
}

// audioState reads pw-dump: the nodes of class Audio/Sink or Audio/Source (wpctl lists WirePlumber's internal
// Bluetooth nodes as sinks, the headset's real one sitting under its filters), left out unless the default
// when every port of theirs the card reports unplugged ("available": "no": an HDMI output with no display;
// a port ALSA cannot sense, the speaker or a mic, says "unknown").
func pwDump() ([]pwObject, error) {
	out, err := exec.Command("pw-dump").Output()
	if err != nil {
		return nil, err
	}
	var objs []pwObject
	return objs, json.Unmarshal(out, &objs)
}

func audioState() (Audio, error) {
	a := Audio{Sinks: []Sound{}, Sources: []Sound{}}
	objs, err := pwDump()
	if err != nil {
		return a, err
	}
	defaults := map[string]string{}
	routes := map[int]pwObject{}
	for _, o := range objs {
		switch o.Type {
		case "PipeWire:Interface:Metadata":
			if str(o.Props, "metadata.name") == "default" {
				for _, m := range o.Metadata {
					var v struct {
						Name string `json:"name"`
					}
					if json.Unmarshal(m.Value, &v) == nil {
						defaults[m.Key] = v.Name
					}
				}
			}
		case "PipeWire:Interface:Device":
			routes[o.ID] = o
			if a.Headset == "" && str(o.Info.Props, "device.api") == "bluez5" {
				a.Headset = "headphones"
				if p := o.Info.Params.Profile; len(p) > 0 && strings.HasPrefix(p[0].Name, "headset-head-unit") {
					a.Headset = "handsfree"
				}
			}
		}
	}
	for _, o := range objs {
		p := o.Info.Props
		if o.Type != "PipeWire:Interface:Node" {
			continue
		}
		var list *[]Sound
		var key string
		switch str(p, "media.class") {
		case "Audio/Sink":
			list, key = &a.Sinks, "default.audio.sink"
		case "Audio/Source":
			list, key = &a.Sources, "default.audio.source"
		default:
			continue
		}
		def := str(p, "node.name") == defaults[key]
		plugged, any := false, false
		for _, r := range routes[num(p, "device.id")].Info.Params.EnumRoute {
			if slices.Contains(r.Devices, num(p, "card.profile.device")) {
				any = true
				plugged = plugged || r.Available != "no"
			}
		}
		if !def && any && !plugged {
			continue
		}
		name := str(p, "node.nick")
		if name == "" {
			name = str(p, "node.description")
		}
		*list = append(*list, Sound{ID: o.ID, Name: name, Def: def})
		// the default's level: wpctl's is the cube root of the first channel's volume
		if def && len(o.Info.Params.Props) > 0 {
			pr := o.Info.Params.Props[0]
			level := 0.0
			if len(pr.ChannelVolumes) > 0 {
				level = math.Round(math.Cbrt(pr.ChannelVolumes[0])*100) / 100
			}
			if key == "default.audio.sink" {
				a.Volume, a.Muted = level, pr.Mute
			} else {
				a.Mic, a.MicMute = level, pr.Mute
			}
		}
	}
	for _, l := range [][]Sound{a.Sinks, a.Sources} {
		sort.Slice(l, func(i, j int) bool { return l[i].Name < l[j].Name })
	}
	return a, nil
}

// audioEvents kicks on every change PipeWire reports, pw-dump's monitor printing one.
func audioEvents(kick chan<- struct{}) {
	cmd := exec.Command("pw-dump", "--monitor", "--no-colors")
	out, err := cmd.StdoutPipe()
	if err != nil || cmd.Start() != nil {
		return
	}
	s := bufio.NewScanner(out)
	s.Buffer(make([]byte, 1<<20), 1<<24)
	for s.Scan() {
		if s.Text() == "]" {
			kick <- struct{}{}
		}
	}
}

// headset flips the Bluetooth headset between headphones (its best A2DP profile: the good sound, no mic) and
// handsfree (its best headset-head-unit: with the mic), through wpctl.
func headset() error {
	objs, err := pwDump()
	if err != nil {
		return err
	}
	for _, o := range objs {
		if o.Type != "PipeWire:Interface:Device" || str(o.Info.Props, "device.api") != "bluez5" {
			continue
		}
		want := "headset-head-unit"
		if p := o.Info.Params.Profile; len(p) > 0 && strings.HasPrefix(p[0].Name, want) {
			want = "a2dp-sink"
		}
		best, prio := -1, -1
		for _, e := range o.Info.Params.EnumProfile {
			if strings.HasPrefix(e.Name, want) && e.Priority > prio {
				best, prio = e.Index, e.Priority
			}
		}
		if best < 0 {
			return errors.New("the headset has no " + want + " profile")
		}
		return exec.Command("wpctl", "set-profile", strconv.Itoa(o.ID), strconv.Itoa(best)).Run()
	}
	return errors.New("no Bluetooth headset")
}
