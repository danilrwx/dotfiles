package main

import (
	"errors"
	"os"
	"path/filepath"
	"strings"
)

// rfkill types, as the kernel numbers them
const (
	rfkillWLAN      = 1
	rfkillBluetooth = 2
)

// setBlocked soft-blocks or unblocks every radio of a type through /dev/rfkill, which logind opens to the
// session's user: an rfkill_event with RFKILL_OP_CHANGE_ALL.
func setBlocked(typ uint8, blocked bool) error {
	f, err := os.OpenFile("/dev/rfkill", os.O_WRONLY, 0)
	if err != nil {
		return err
	}
	const opChangeAll = 3
	soft := uint8(0)
	if blocked {
		soft = 1
	}
	_, err = f.Write([]byte{0, 0, 0, 0, typ, opChangeAll, soft, 0})
	return errors.Join(err, f.Close())
}

// blocked reports whether any radio of the named type ("wlan", "bluetooth") is soft- or hard-blocked.
func blocked(name string) bool {
	dirs, _ := filepath.Glob("/sys/class/rfkill/rfkill*")
	for _, d := range dirs {
		if read(filepath.Join(d, "type")) != name {
			continue
		}
		if read(filepath.Join(d, "soft")) == "1" || read(filepath.Join(d, "hard")) == "1" {
			return true
		}
	}
	return false
}

func read(path string) string {
	b, _ := os.ReadFile(path)
	return strings.TrimSpace(string(b))
}
