// Betterfox Smoothfox: Zen smooth scrolling (smaller minimum step).
user_pref("apz.overscroll.enabled", true);
user_pref("general.smoothScroll", true);
user_pref("general.smoothScroll.msdPhysics.continuousMotionMaxDeltaMS", 12);
user_pref("general.smoothScroll.msdPhysics.enabled", true);
user_pref("general.smoothScroll.msdPhysics.motionBeginSpringConstant", 600);
user_pref("general.smoothScroll.msdPhysics.regularSpringConstant", 650);
user_pref("general.smoothScroll.msdPhysics.slowdownMinDeltaMS", 25);
// Restore the default ratio changed by Natural V3.
user_pref("general.smoothScroll.msdPhysics.slowdownMinDeltaRatio", "1.3");
user_pref("general.smoothScroll.msdPhysics.slowdownSpringConstant", 250);
user_pref("general.smoothScroll.currentVelocityWeighting", "0.15");
user_pref("general.smoothScroll.stopDecelerationWeighting", "0.6");
user_pref("mousewheel.default.delta_multiplier_y", 200);

// Keep the smaller minimum step preferred during the Zen test.
user_pref("mousewheel.min_line_scroll_amount", 5);
user_pref("general.smoothScroll.mouseWheel.durationMinMS", 80);

// Reset the earlier XInput2 speed experiment to the Firefox default.
user_pref("apz.gtk.pangesture.pixel_delta_mode_multiplier", "40.0");

// Preferences outside the enterprise-policy allowlist.
user_pref("beacon.enabled", false);
user_pref("findbar.highlightAll", true);
user_pref("full-screen-api.transition-duration.enter", "0 0");
user_pref("full-screen-api.transition-duration.leave", "0 0");
user_pref("privacy.antitracking.isolateContentScriptResources", true);

// Allow DRM-protected playback (Widevine).
user_pref("media.eme.enabled", true);

// Desktop palette for browser chrome and built-in pages.
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// Keep inactive tabs loaded.
user_pref("browser.tabs.unloadOnLowMemory", false);
