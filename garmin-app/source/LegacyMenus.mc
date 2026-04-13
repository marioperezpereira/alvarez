// Legacy Menu / MenuInputDelegate stack for CIQ 2.x devices (fr235, fr630,
// fenix3, fenix3hr, vivoactive_hr, epix gen1) that don't support Menu2.
//
// All symbols in this file are annotated (:legacy_only); the jungle config
// excludes them when building for modern devices (see monkey.jungle).

import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;

// ---------- Config menu delegate ----------
// (Main menu construction lives in AlvarezApp.buildMainMenu (:legacy_only))

(:legacy_only)
class ConfigMenuLegacyDelegate extends WatchUi.MenuInputDelegate {

    function initialize() {
        MenuInputDelegate.initialize();
    }

    function onMenuItem(item) {
        if (item == :laptime) {
            showLapTimeMenu();
        } else if (item == :mode) {
            showModeMenu();
        } else if (item == :start) {
            $.workout.startWorkout();
            WatchUi.switchToView(new ActivityView(), new ActivityDelegate(), WatchUi.SLIDE_LEFT);
        }
    }

    function showLapTimeMenu() {
        var menu = new WatchUi.Menu();
        menu.setTitle("1st lap time");

        // 31 items: 2:00 to 4:00 in 4s steps. Use symbols :lap_120 .. :lap_240.
        for (var t = 120; t <= 240; t += 4) {
            var label = WorkoutSession.formatTimePadded(t);
            menu.addItem(label, lapTimeSymbol(t));
        }

        WatchUi.pushView(menu, new LapTimeMenuLegacyDelegate(), WatchUi.SLIDE_UP);
    }

    function showModeMenu() {
        var menu = new WatchUi.Menu();
        menu.setTitle("Mode");
        var manualLabel = ($.workout.mode == $.MODE_MANUAL) ? "Manual (current)" : "Manual";
        var gpsLabel = ($.workout.mode == $.MODE_GPS) ? "GPS (current)" : "GPS";
        menu.addItem(manualLabel, :mode_manual);
        menu.addItem(gpsLabel, :mode_gps);
        WatchUi.pushView(menu, new ModeMenuLegacyDelegate(), WatchUi.SLIDE_UP);
    }
}

// Map a lap-time in seconds to a stable symbol. The symbol set is finite
// (31 values) so a static lookup is cheaper than stringifying at runtime.
(:legacy_only)
function lapTimeSymbol(t) {
    // 2:00..4:00 in 4s steps
    if (t == 120) { return :lap_120; }
    if (t == 124) { return :lap_124; }
    if (t == 128) { return :lap_128; }
    if (t == 132) { return :lap_132; }
    if (t == 136) { return :lap_136; }
    if (t == 140) { return :lap_140; }
    if (t == 144) { return :lap_144; }
    if (t == 148) { return :lap_148; }
    if (t == 152) { return :lap_152; }
    if (t == 156) { return :lap_156; }
    if (t == 160) { return :lap_160; }
    if (t == 164) { return :lap_164; }
    if (t == 168) { return :lap_168; }
    if (t == 172) { return :lap_172; }
    if (t == 176) { return :lap_176; }
    if (t == 180) { return :lap_180; }
    if (t == 184) { return :lap_184; }
    if (t == 188) { return :lap_188; }
    if (t == 192) { return :lap_192; }
    if (t == 196) { return :lap_196; }
    if (t == 200) { return :lap_200; }
    if (t == 204) { return :lap_204; }
    if (t == 208) { return :lap_208; }
    if (t == 212) { return :lap_212; }
    if (t == 216) { return :lap_216; }
    if (t == 220) { return :lap_220; }
    if (t == 224) { return :lap_224; }
    if (t == 228) { return :lap_228; }
    if (t == 232) { return :lap_232; }
    if (t == 236) { return :lap_236; }
    return :lap_240;
}

// Inverse of lapTimeSymbol: symbol -> seconds.
(:legacy_only)
function lapTimeSeconds(sym) {
    if (sym == :lap_120) { return 120; }
    if (sym == :lap_124) { return 124; }
    if (sym == :lap_128) { return 128; }
    if (sym == :lap_132) { return 132; }
    if (sym == :lap_136) { return 136; }
    if (sym == :lap_140) { return 140; }
    if (sym == :lap_144) { return 144; }
    if (sym == :lap_148) { return 148; }
    if (sym == :lap_152) { return 152; }
    if (sym == :lap_156) { return 156; }
    if (sym == :lap_160) { return 160; }
    if (sym == :lap_164) { return 164; }
    if (sym == :lap_168) { return 168; }
    if (sym == :lap_172) { return 172; }
    if (sym == :lap_176) { return 176; }
    if (sym == :lap_180) { return 180; }
    if (sym == :lap_184) { return 184; }
    if (sym == :lap_188) { return 188; }
    if (sym == :lap_192) { return 192; }
    if (sym == :lap_196) { return 196; }
    if (sym == :lap_200) { return 200; }
    if (sym == :lap_204) { return 204; }
    if (sym == :lap_208) { return 208; }
    if (sym == :lap_212) { return 212; }
    if (sym == :lap_216) { return 216; }
    if (sym == :lap_220) { return 220; }
    if (sym == :lap_224) { return 224; }
    if (sym == :lap_228) { return 228; }
    if (sym == :lap_232) { return 232; }
    if (sym == :lap_236) { return 236; }
    if (sym == :lap_240) { return 240; }
    return 120;  // fallback
}

(:legacy_only)
class LapTimeMenuLegacyDelegate extends WatchUi.MenuInputDelegate {

    function initialize() {
        MenuInputDelegate.initialize();
    }

    function onMenuItem(item) {
        $.workout.firstLapTarget = lapTimeSeconds(item);
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        rebuildMainMenu();
    }
}

(:legacy_only)
class ModeMenuLegacyDelegate extends WatchUi.MenuInputDelegate {

    function initialize() {
        MenuInputDelegate.initialize();
    }

    function onMenuItem(item) {
        if (item == :mode_manual) {
            $.workout.mode = $.MODE_MANUAL;
        } else if (item == :mode_gps) {
            $.workout.mode = $.MODE_GPS;
        }
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        rebuildMainMenu();
    }
}

// ---------- Pause menu (invoked from ActivityDelegate.showPauseMenu legacy) ----------

(:legacy_only)
class PauseMenuLegacyDelegate extends WatchUi.MenuInputDelegate {

    function initialize() {
        MenuInputDelegate.initialize();
    }

    function onMenuItem(item) {
        if (item == :resume) {
            $.workout.resume();
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else if (item == :end) {
            $.workout.stopWorkout();
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            WatchUi.switchToView(new SummaryView(), new SummaryDelegate(), WatchUi.SLIDE_RIGHT);
        }
    }
}
