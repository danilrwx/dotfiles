package main

import (
	"fmt"
	"sync"
	"time"
)

// Weather is the location's weather from open-meteo (no key needed): now, the day's high and low, and the
// next hours; icon names are Adwaita's (weather-clear-symbolic, ...).
type Weather struct {
	Place string  `json:"place"`
	Temp  int     `json:"temp"`
	Icon  string  `json:"icon"`
	Text  string  `json:"text"`
	High  int     `json:"high"`
	Low   int     `json:"low"`
	Hours []Hour  `json:"hours"`
	At    string  `json:"at"`
	Wind  float64 `json:"wind"`
}

// Hour is one hour of the forecast.
type Hour struct {
	Time string `json:"time"`
	Temp int    `json:"temp"`
	Icon string `json:"icon"`
}

// wmo turns a WMO weather code into Adwaita's icon and a word for it, night icons for clear and few clouds.
func wmo(code int, day bool) (icon, text string) {
	n := ""
	if !day {
		n = "-night"
	}
	switch {
	case code == 0:
		return "weather-clear" + n + "-symbolic", "Clear"
	case code <= 2:
		return "weather-few-clouds" + n + "-symbolic", "Partly cloudy"
	case code == 3:
		return "weather-overcast-symbolic", "Overcast"
	case code <= 48:
		return "weather-fog-symbolic", "Fog"
	case code <= 57:
		return "weather-showers-scattered-symbolic", "Drizzle"
	case code <= 67, code >= 80 && code <= 82:
		return "weather-showers-symbolic", "Rain"
	case code <= 77, code == 85, code == 86:
		return "weather-snow-symbolic", "Snow"
	default:
		return "weather-storm-symbolic", "Thunderstorm"
	}
}

// the last weather fetched, refreshed every 15 min by weatherLoop
var (
	weatherMu   sync.Mutex
	weatherLast *Weather
)

func fetchWeather(l Location) (*Weather, error) {
	var r struct {
		Current struct {
			Temp float64 `json:"temperature_2m"`
			Code int     `json:"weather_code"`
			Day  int     `json:"is_day"`
			Wind float64 `json:"wind_speed_10m"`
		} `json:"current"`
		Hourly struct {
			Time []string  `json:"time"`
			Temp []float64 `json:"temperature_2m"`
			Code []int     `json:"weather_code"`
			Day  []int     `json:"is_day"`
		} `json:"hourly"`
		Daily struct {
			Max []float64 `json:"temperature_2m_max"`
			Min []float64 `json:"temperature_2m_min"`
		} `json:"daily"`
	}
	u := fmt.Sprintf("https://api.open-meteo.com/v1/forecast?latitude=%.4f&longitude=%.4f&timezone=auto&forecast_days=2"+
		"&current=temperature_2m,weather_code,is_day,wind_speed_10m&hourly=temperature_2m,weather_code,is_day"+
		"&daily=temperature_2m_max,temperature_2m_min&wind_speed_unit=ms", l.Lat, l.Lon)
	if err := getJSONWith(web, u, &r); err != nil {
		return nil, err
	}
	w := &Weather{Place: l.Place, Temp: round(r.Current.Temp), Wind: r.Current.Wind, Hours: []Hour{},
		At: time.Now().Format("15:04")}
	w.Icon, w.Text = wmo(r.Current.Code, r.Current.Day == 1)
	if len(r.Daily.Max) > 0 && len(r.Daily.Min) > 0 {
		w.High, w.Low = round(r.Daily.Max[0]), round(r.Daily.Min[0])
	}
	// the next six hours, every other one, from the hour after now
	now := time.Now().Format("2006-01-02T15")
	for i, t := range r.Hourly.Time {
		if t[:13] <= now || len(w.Hours) == 6 || i >= len(r.Hourly.Temp) || i >= len(r.Hourly.Code) {
			continue
		}
		if (i % 2) == 1 {
			continue
		}
		icon, _ := wmo(r.Hourly.Code[i], i < len(r.Hourly.Day) && r.Hourly.Day[i] == 1)
		w.Hours = append(w.Hours, Hour{Time: t[11:16], Temp: round(r.Hourly.Temp[i]), Icon: icon})
	}
	return w, nil
}

func round(f float64) int {
	if f < 0 {
		return int(f - 0.5)
	}
	return int(f + 0.5)
}

// weatherLoop fetches the weather now and every 15 min (sooner, 1 min, after a failure), kicking wmd watch
// each time it has a new one.
func weatherLoop(kick chan<- struct{}) {
	for {
		wait := 15 * time.Minute
		if l, ok := loadLocation(); ok {
			if w, err := fetchWeather(l); err == nil {
				weatherMu.Lock()
				weatherLast = w
				weatherMu.Unlock()
				kick <- struct{}{}
			} else {
				wait = time.Minute
			}
		}
		time.Sleep(wait)
	}
}

func weatherState() *Weather {
	weatherMu.Lock()
	defer weatherMu.Unlock()
	return weatherLast
}
