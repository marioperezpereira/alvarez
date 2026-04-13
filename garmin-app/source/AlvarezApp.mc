import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;

var workout as WorkoutSession = new WorkoutSession();

class AlvarezApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // Modern devices (CIQ 3.x): Menu2 can be returned directly as initial view.
    (:modern_only)
    function getInitialView() {
        return buildMainMenu();
    }

    // Legacy devices (CIQ 1.x): CIQ 1.x has two restrictions that preclude
    // using a native Menu as the initial view or nesting Menus:
    //   1. The base view must be a user View subclass.
    //   2. You cannot pushView a native Menu on top of another native Menu
    //      without crashing with "Native base view is not supported".
    // So we replace the entire config stack with a custom View driven by
    // UP/DOWN/START buttons.
    (:legacy_only)
    function getInitialView() {
        var view = new LegacyConfigView();
        return [view, new LegacyConfigDelegate(view)];
    }

    (:modern_only)
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
