package main

import (
	"os"
	"path/filepath"
	"sort"
	"strings"
)

// Theme is bin/theme's pick, as it keeps it in ~/.cache/theme: dark or dark-wall, the wallpaper, and the
// wallpapers to pick from in ~/Pictures/wallpapers. bin/theme itself does the switching.
type Theme struct {
	Mode       string   `json:"mode"`
	Wallpaper  string   `json:"wallpaper"`
	Wallpapers []string `json:"wallpapers"`
}

func themeState() Theme {
	home := os.Getenv("HOME")
	state := filepath.Join(home, ".cache/theme")
	if x := os.Getenv("XDG_CACHE_HOME"); x != "" {
		state = filepath.Join(x, "theme")
	}
	t := Theme{Mode: read(filepath.Join(state, "mode")), Wallpaper: read(filepath.Join(state, "wallpaper")), Wallpapers: []string{}}
	if t.Mode == "" {
		t.Mode = "dark"
	}
	files, _ := os.ReadDir(filepath.Join(home, "Pictures/wallpapers"))
	for _, f := range files {
		switch strings.ToLower(filepath.Ext(f.Name())) {
		case ".jpg", ".jpeg", ".png":
			t.Wallpapers = append(t.Wallpapers, filepath.Join(home, "Pictures/wallpapers", f.Name()))
		}
	}
	sort.Strings(t.Wallpapers)
	return t
}
