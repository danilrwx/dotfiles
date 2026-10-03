package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"net/url"
	"os"
	"path/filepath"
	"strconv"
	"strings"
)

// Location is where the machine is, for the weather and night light's sunset and sunrise: set once by
// `wmd location CITY` (open-meteo's geocoding) or `wmd location LAT LON`, kept in ~/.config/wmd.json.
type Location struct {
	Place string  `json:"place"`
	Lat   float64 `json:"lat"`
	Lon   float64 `json:"lon"`
}

func locationFile() string { return filepath.Join(os.Getenv("HOME"), ".config/wmd.json") }

func loadLocation() (Location, bool) {
	var l Location
	b, err := os.ReadFile(locationFile())
	if err != nil || json.Unmarshal(b, &l) != nil {
		return l, false
	}
	return l, l.Lat != 0 || l.Lon != 0
}

func location(args []string) error {
	var l Location
	switch len(args) {
	case 0:
		return errUsage
	case 2:
		lat, err1 := strconv.ParseFloat(args[0], 64)
		lon, err2 := strconv.ParseFloat(args[1], 64)
		if err1 == nil && err2 == nil {
			l = Location{Place: fmt.Sprintf("%.2f, %.2f", lat, lon), Lat: lat, Lon: lon}
			break
		}
		fallthrough
	default:
		// a place by its name, the first open-meteo knows
		var found struct {
			Results []struct {
				Name      string  `json:"name"`
				Country   string  `json:"country"`
				Latitude  float64 `json:"latitude"`
				Longitude float64 `json:"longitude"`
			} `json:"results"`
		}
		name := strings.Join(args, " ")
		if err := getJSONWith(web, "https://geocoding-api.open-meteo.com/v1/search?count=1&name="+url.QueryEscape(name), &found); err != nil {
			return err
		}
		if len(found.Results) == 0 {
			return errors.New("no place called " + name)
		}
		r := found.Results[0]
		l = Location{Place: r.Name + ", " + r.Country, Lat: r.Latitude, Lon: r.Longitude}
	}
	b, err := json.MarshalIndent(l, "", "  ")
	if err != nil {
		return err
	}
	if err := os.WriteFile(locationFile(), append(b, '\n'), 0o644); err != nil {
		return err
	}
	fmt.Println(l.Place)
	return nil
}
