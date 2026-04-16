import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.System;

class ActivityDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    // On FR970, Back/Lap is bottom right button.
    //
    // Running:  Back/Lap = mark lap,  Start/Stop = pause → pause menu
    // Pause menu handles resume / end via native Menu2

    function onBack() {
        if ($.workout.isRunning && !$.workout.isPaused) {
            // Running + Back/Lap = complete lap (manual mode)
            if ($.workout.mode == $.MODE_MANUAL) {
                $.workout.completeLap();
                WatchUi.requestUpdate();
            }
        }
        return true;
    }

    function onKey(keyEvent) {
        var key = keyEvent.getKey();

        // Start/Stop button = pause and show pause menu
        if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START) {
            if ($.workout.isRunning && !$.workout.isPaused) {
                $.workout.pause();
                showPauseMenu();
            }
            return true;
        }

        return false;
    }

    (:modern_only)
    function showPauseMenu() {
        var lapNum = $.workout.currentLap;
        var menu = new WatchUi.Menu2({:title => "Lap " + lapNum + " - Paused"});
        menu.addItem(new WatchUi.MenuItem("Resume", null, "resume", null));
        menu.addItem(new WatchUi.MenuItem("End workout", null, "end", null));
        WatchUi.pushView(menu, new PauseMenuDelegate(), WatchUi.SLIDE_UP);
    }

    (:legacy_only)
    function showPauseMenu() {
        var menu = new WatchUi.Menu();
        menu.setTitle("Lap " + $.workout.currentLap + " Paused");
        menu.addItem("Resume", :resume);
        menu.addItem("End workout", :end);
        WatchUi.pushView(menu, new PauseMenuLegacyDelegate(), WatchUi.SLIDE_UP);
    }
}

(:modern_only)
class PauseMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item) {
        var id = item.getId() as String;
        if (id.equals("resume")) {
            $.workout.resume();
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else if (id.equals("end")) {
            $.workout.stopWorkout();
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            var summary = new SummaryView();
            WatchUi.switchToView(summary, new SummaryDelegate(summary), WatchUi.SLIDE_RIGHT);
        }
    }

    // Back on pause menu = resume
    function onBack() {
        $.workout.resume();
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}
