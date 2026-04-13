import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;

var workout as WorkoutSession = new WorkoutSession();

class AlvarezApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        return buildMainMenu();
    }

    static function buildMainMenu() {
        var menu = new WatchUi.Menu2({:title => "Alvarez - Diper"});

        var lapLabel = WorkoutSession.formatTimePadded($.workout.firstLapTarget);
        menu.addItem(new WatchUi.MenuItem("1st lap time", lapLabel, "laptime", null));

        var modeLabel = ($.workout.mode == $.MODE_MANUAL) ? "Manual" : "GPS";
        menu.addItem(new WatchUi.MenuItem("Mode", modeLabel, "mode", null));

        menu.addItem(new WatchUi.MenuItem("Start workout", null, "start", null));

        return [menu, new ConfigMenuDelegate()] as Array;
    }
}
