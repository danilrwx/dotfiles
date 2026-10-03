package main

import (
	"path/filepath"
	"strconv"
	"strings"
)

// System is the machine's load: CPU busy and memory used in percent, the CPU package's temperature in °C, the
// fans in rpm (the HONOR EC's), and the battery's draw in watts (0 on the charger).
type System struct {
	CPU    int     `json:"cpu"`
	Memory int     `json:"memory"`
	MemGiB float64 `json:"memGiB"`
	Temp   int     `json:"temp"`
	Fans   []int   `json:"fans"`
	Watts  float64 `json:"watts"`
}

// cpuTicks are /proc/stat's busy and total ticks at the last reading, the CPU's load being the share busy
// between two readings
var cpuTicks [2]uint64

func cpuLoad() int {
	line, _, _ := strings.Cut(read("/proc/stat"), "\n")
	var busy, total uint64
	for i, f := range strings.Fields(line)[1:] {
		n, _ := strconv.ParseUint(f, 10, 64)
		total += n
		if i != 3 && i != 4 { // idle, iowait
			busy += n
		}
	}
	db, dt := busy-cpuTicks[0], total-cpuTicks[1]
	cpuTicks = [2]uint64{busy, total}
	if dt == 0 {
		return 0
	}
	return int(db * 100 / dt)
}

// hwmon finds a sensor directory by its driver's name ("coretemp", "honor_ec"), "" without one.
func hwmon(name string) string {
	dirs, _ := filepath.Glob("/sys/class/hwmon/hwmon*")
	for _, d := range dirs {
		if read(filepath.Join(d, "name")) == name {
			return d
		}
	}
	return ""
}

func systemState() System {
	s := System{CPU: cpuLoad(), Fans: []int{}}
	mem := map[string]float64{}
	for _, l := range strings.Split(read("/proc/meminfo"), "\n") {
		k, v, ok := strings.Cut(l, ":")
		if ok {
			mem[k], _ = strconv.ParseFloat(strings.Fields(v)[0], 64)
		}
	}
	if mem["MemTotal"] > 0 {
		used := mem["MemTotal"] - mem["MemAvailable"]
		s.Memory = int(used * 100 / mem["MemTotal"])
		s.MemGiB = float64(int(used/1048576*10)) / 10
	}
	if d := hwmon("coretemp"); d != "" {
		t, _ := strconv.Atoi(read(filepath.Join(d, "temp1_input")))
		s.Temp = t / 1000
	}
	if d := hwmon("honor_ec"); d != "" {
		fans, _ := filepath.Glob(filepath.Join(d, "fan*_input"))
		for _, f := range fans {
			rpm, _ := strconv.Atoi(read(f))
			s.Fans = append(s.Fans, rpm)
		}
	}
	bat := "/sys/class/power_supply/BAT0"
	if read(filepath.Join(bat, "status")) == "Discharging" {
		c, _ := strconv.ParseFloat(read(filepath.Join(bat, "current_now")), 64)
		v, _ := strconv.ParseFloat(read(filepath.Join(bat, "voltage_now")), 64)
		s.Watts = float64(int(c*v/1e12*10)) / 10
	}
	return s
}
