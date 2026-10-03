package main

import (
	"testing"
	"time"
)

func TestNight(t *testing.T) {
	// a span past midnight
	if !within(23*60, 21*60, 7*60) || !within(6*60, 21*60, 7*60) || within(12*60, 21*60, 7*60) {
		t.Error("within: 21:00-07:00 wrong")
	}
	// Riga, the equinox: sunrise and sunset about 12 h apart, around 06:20 and 18:30 UTC
	rise, set, ok := sun(time.Date(2026, 9, 23, 12, 0, 0, 0, time.UTC), 56.95, 24.1)
	if !ok || rise.Hour() < 3 || rise.Hour() > 5 || set.Hour() < 15 || set.Hour() > 17 {
		t.Errorf("sun: rise %v set %v", rise, set)
	}
	// 6500 K no change, warmer less blue
	if r, g, b := gains(6500); r < 0.99 || g < 0.97 || b < 0.97 {
		t.Errorf("gains(6500) = %v %v %v", r, g, b)
	}
	if _, _, b := gains(3000); b > 0.7 {
		t.Errorf("gains(3000) blue %v", b)
	}
}
