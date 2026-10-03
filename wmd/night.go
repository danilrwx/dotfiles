package main

import (
	"encoding/json"
	"fmt"
	"math"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"
)

// NightConfig is night light as the quick settings set it, kept in ~/.cache/night-light.json: the mode (off,
// on, time: From to To, sun: sunset to sunrise at Lat, Lon), and the warmth in kelvin, 6500 neutral.
type NightConfig struct {
	Mode string  `json:"mode"`
	From string  `json:"from"`
	To   string  `json:"to"`
	Temp int     `json:"temp"`
	Lat  float64 `json:"lat"`
	Lon  float64 `json:"lon"`
}

// Night is what wmd watch reports: whether the screen is warmed now, the config, and today's sunset and
// sunrise where a location is known.
type Night struct {
	On      bool   `json:"on"`
	Mode    string `json:"mode"`
	From    string `json:"from"`
	To      string `json:"to"`
	Temp    int    `json:"temp"`
	Sunset  string `json:"sunset"`
	Sunrise string `json:"sunrise"`
	Located bool   `json:"located"`
}

func nightFile() string { return filepath.Join(os.Getenv("HOME"), ".cache/night-light.json") }
func shaderDir() string { return filepath.Join(os.Getenv("HOME"), ".cache/night-light") }

func loadNight() NightConfig {
	c := NightConfig{Mode: "off", From: "21:00", To: "07:00", Temp: 4000}
	if b, err := os.ReadFile(nightFile()); err == nil {
		_ = json.Unmarshal(b, &c)
	}
	return c
}

func saveNight(c NightConfig) error {
	b, err := json.MarshalIndent(c, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(nightFile(), append(b, '\n'), 0o644)
}

// clock parses "HH:MM" into minutes past midnight.
func clock(s string) (int, error) {
	h, m, ok := strings.Cut(s, ":")
	hh, err1 := strconv.Atoi(h)
	mm, err2 := strconv.Atoi(m)
	if !ok || err1 != nil || err2 != nil || hh < 0 || hh > 23 || mm < 0 || mm > 59 {
		return 0, fmt.Errorf("%q is not HH:MM", s)
	}
	return hh*60 + mm, nil
}

// within reports whether minute now falls in [from, to), the span running past midnight when to < from.
func within(now, from, to int) bool {
	if from <= to {
		return now >= from && now < to
	}
	return now >= from || now < to
}

// sun returns the day's sunrise and sunset at lat, lon in local time, by NOAA's simplified equations
// (a minute or two off, enough for a screen's warmth); ok is false in a polar day or night.
func sun(day time.Time, lat, lon float64) (rise, set time.Time, ok bool) {
	rad := math.Pi / 180
	n := float64(day.YearDay())
	g := 2 * math.Pi / 365 * (n - 1)
	eqtime := 229.18 * (0.000075 + 0.001868*math.Cos(g) - 0.032077*math.Sin(g) - 0.014615*math.Cos(2*g) - 0.040849*math.Sin(2*g))
	decl := 0.006918 - 0.399912*math.Cos(g) + 0.070257*math.Sin(g) - 0.006758*math.Cos(2*g) +
		0.000907*math.Sin(2*g) - 0.002697*math.Cos(3*g) + 0.00148*math.Sin(3*g)
	cosH := math.Cos(90.833*rad)/(math.Cos(lat*rad)*math.Cos(decl)) - math.Tan(lat*rad)*math.Tan(decl)
	if cosH < -1 || cosH > 1 {
		return time.Time{}, time.Time{}, false
	}
	ha := math.Acos(cosH) / rad
	midnight := time.Date(day.Year(), day.Month(), day.Day(), 0, 0, 0, 0, time.UTC)
	at := func(minutes float64) time.Time {
		return midnight.Add(time.Duration(minutes * float64(time.Minute))).In(day.Location())
	}
	return at(720 - 4*(lon+ha) - eqtime), at(720 - 4*(lon-ha) - eqtime), true
}

// wanted reports whether the screen should be warm now under c.
func (c NightConfig) wanted(now time.Time) bool {
	minute := now.Hour()*60 + now.Minute()
	switch c.Mode {
	case "on":
		return true
	case "time":
		from, err1 := clock(c.From)
		to, err2 := clock(c.To)
		return err1 == nil && err2 == nil && within(minute, from, to)
	case "sun":
		if c.Lat == 0 && c.Lon == 0 {
			return false
		}
		rise, set, ok := sun(now, c.Lat, c.Lon)
		return ok && (now.After(set) || now.Before(rise))
	}
	return false
}

// gains are the red, green and blue factors of a white point at k kelvin (Tanner Helland's fit of the black
// body), 6500 giving no change.
func gains(k int) (r, g, b float64) {
	t := float64(max(1000, min(6500, k))) / 100
	r, b = 1, 1
	if t > 66 {
		r = 1.2929 * math.Pow(t-60, -0.1332)
		g = 1.1298 * math.Pow(t-60, -0.0755)
	} else {
		g = (99.4708*math.Log(t) - 161.1196) / 255
		if t <= 19 {
			b = 0
		} else {
			b = (138.5177*math.Log(t-10) - 305.0448) / 255
		}
	}
	clamp := func(v float64) float64 { return max(0, min(1, v)) }
	return clamp(r), clamp(g), clamp(b)
}

// shader writes the warm screen shader for k kelvin, one file a warmth so Hyprland takes a new one afresh.
func shader(k int) (string, error) {
	if err := os.MkdirAll(shaderDir(), 0o755); err != nil {
		return "", err
	}
	path := filepath.Join(shaderDir(), fmt.Sprintf("night-%d.frag", k))
	r, g, b := gains(k)
	src := fmt.Sprintf(`#version 300 es
// wmd's night light at %d K
precision highp float;
in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;
void main() {
    vec4 c = texture(tex, v_texcoord);
    fragColor = vec4(c.r * %.4f, c.g * %.4f, c.b * %.4f, c.a);
}
`, k, r, g, b)
	return path, os.WriteFile(path, []byte(src), 0o644)
}

// currentShader is Hyprland's screen shader now, "" for none.
func currentShader() string {
	out, err := hyprctl("j/getoption decoration:screen_shader")
	if err != nil {
		return ""
	}
	var opt struct {
		Str string `json:"str"`
	}
	if json.Unmarshal([]byte(out), &opt) != nil || opt.Str == "[[EMPTY]]" {
		return ""
	}
	return opt.Str
}

// applyNight sets Hyprland's screen shader to what c wants now, touching it only when that differs.
func applyNight(c NightConfig) error {
	want := ""
	if c.wanted(time.Now()) {
		var err error
		if want, err = shader(c.Temp); err != nil {
			return err
		}
	}
	if currentShader() == want {
		return nil
	}
	if want == "" {
		want = "[[EMPTY]]"
	}
	_, err := hyprctl("keyword decoration:screen_shader " + want)
	return err
}

func nightState() Night {
	c := loadNight()
	n := Night{Mode: c.Mode, From: c.From, To: c.To, Temp: c.Temp, Located: c.Lat != 0 || c.Lon != 0}
	n.On = strings.HasPrefix(currentShader(), shaderDir())
	if n.Located {
		if rise, set, ok := sun(time.Now(), c.Lat, c.Lon); ok {
			n.Sunrise, n.Sunset = rise.Format("15:04"), set.Format("15:04")
		}
	}
	return n
}

// night: mode off|on|time|sun, time FROM TO, temp K, location LAT LON, each saved and applied; apply alone
// sets the screen as the config wants now (Hyprland's exec on every start and reload, and wmd watch's tick).
func night(args []string) error {
	if len(args) == 0 {
		return errUsage
	}
	c := loadNight()
	var err error
	switch {
	case args[0] == "apply" && len(args) == 1:
		return applyNight(c)
	case args[0] == "mode" && len(args) == 2:
		switch args[1] {
		case "off", "on", "time", "sun":
			c.Mode = args[1]
		default:
			return errUsage
		}
	case args[0] == "time" && len(args) == 3:
		for _, t := range args[1:] {
			if _, err := clock(t); err != nil {
				return err
			}
		}
		c.From, c.To = args[1], args[2]
	case args[0] == "temp" && len(args) == 2:
		if c.Temp, err = strconv.Atoi(args[1]); err != nil {
			return errUsage
		}
		c.Temp = max(2500, min(6500, c.Temp))
	case args[0] == "location" && len(args) == 3:
		if c.Lat, err = strconv.ParseFloat(args[1], 64); err != nil {
			return errUsage
		}
		if c.Lon, err = strconv.ParseFloat(args[2], 64); err != nil {
			return errUsage
		}
	default:
		return errUsage
	}
	if err := saveNight(c); err != nil {
		return err
	}
	return applyNight(c)
}
