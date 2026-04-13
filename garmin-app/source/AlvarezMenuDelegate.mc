import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;

// Delegate for the main configuration menu
class ConfigMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item) {
        var id = item.getId() as String;

        if (id.equals("laptime")) {
            showLapTimeMenu();
        } else if (id.equals("mode")) {
            showModeMenu();
        } else if (id.equals("start")) {
            startWorkout();
        }
    }

    function onBack() {
        System.exit();
    }

    function showLapTimeMenu() {
        var menu = new WatchUi.Menu2({:title => "Select 1st lap"});

        // Guidance item at the top (non-functional)
        menu.addItem(new WatchUi.MenuItem(
            "Aim for at least",
            "14 laps",
            "hint", null));

        // Populate with all valid times: 2:00 to 4:00 in 4s steps
        for (var t = 120; t <= 240; t += 4) {
            var label = WorkoutSession.formatTimePadded(t);
            var startPace = (t * 25) / 10;  // t * 2.5 using integer math
            // Lap 14 target: t - 13*4 = t - 52
            var lap14target = t - 52;
            var lap14pace = (lap14target * 25) / 10;
            var subLabel = WorkoutSession.formatPace(startPace) + "/km (Lap 14: " + WorkoutSession.formatPace(lap14pace) + "/km)";
            menu.addItem(new WatchUi.MenuItem(label, subLabel, t, null));
        }

        WatchUi.pushView(menu, new LapTimeMenuDelegate(), WatchUi.SLIDE_UP);
    }

    function showModeMenu() {
        var menu = new WatchUi.Menu2({:title => "Select mode"});
        menu.addItem(new WatchUi.MenuItem(
            "Manual",
            ($.workout.mode == $.MODE_MANUAL) ? "current" : null,
            "manual",
            null));
        menu.addItem(new WatchUi.MenuItem(
            "GPS",
            ($.workout.mode == $.MODE_GPS) ? "current" : null,
            "gps",
            null));

        WatchUi.pushView(menu, new ModeMenuDelegate(), WatchUi.SLIDE_UP);
    }

    function startWorkout() {
        $.workout.startWorkout();
        WatchUi.switchToView(new ActivityView(), new ActivityDelegate(), WatchUi.SLIDE_LEFT);
    }
}

// Delegate for the lap time picker submenu
class LapTimeMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item) {
        var id = item.getId();
        // Ignore the hint item
        if (id instanceof String) {
            return;
        }
        var seconds = id as Number;
        $.workout.firstLapTarget = seconds;
        // Pop submenu, then replace main menu so it shows updated values
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        rebuildMainMenu();
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

// Delegate for the mode picker submenu
class ModeMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item) {
        var id = item.getId() as String;
        if (id.equals("manual")) {
            $.workout.mode = $.MODE_MANUAL;
        } else if (id.equals("gps")) {
            $.workout.mode = $.MODE_GPS;
        }
        // Pop submenu, then replace main menu so it shows updated values
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        rebuildMainMenu();
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

// Rebuild the main config menu in-place with updated values
function rebuildMainMenu() {
    var views = AlvarezApp.buildMainMenu();
    WatchUi.switchToView(views[0], views[1], WatchUi.SLIDE_IMMEDIATE);
}
