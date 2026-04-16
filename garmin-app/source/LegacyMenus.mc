// Legacy UI stack for CIQ 1.x devices (fr235, fr630, fenix3, fenix3_hr,
// vivoactive_hr) that don't support Menu2 and don't allow pushing native
// Menus on top of native Menus.
//
// Approach: avoid nested native Menus entirely. The config screen is a
// custom View with button-driven navigation. The pause screen is a single
// Menu (pushed on top of ActivityView, which is a user View — safe).
//
// All symbols in this file are annotated (:legacy_only); the jungle config
// excludes them when building for modern devices (see monkey.jungle).

import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.System;

// ---------- Config View (initial view on legacy devices) ----------

(:legacy_only)
class LegacyConfigView extends WatchUi.View {
    // 0 = 1st lap time, 1 = mode, 2 = Start workout
    hidden var _field = 0;

    function initialize() {
        View.initialize();
    }

    function cycleUp() as Void {
        _field = (_field + 2) % 3;
        WatchUi.requestUpdate();
    }

    function cycleDown() as Void {
        _field = (_field + 1) % 3;
        WatchUi.requestUpdate();
    }

    // START pressed on the focused field.
    function activate() as Void {
        if (_field == 0) {
            $.workout.firstLapTarget += 4;
            if ($.workout.firstLapTarget > 240) {
                $.workout.firstLapTarget = 120;
            }
            WatchUi.requestUpdate();
        } else if (_field == 1) {
            $.workout.mode = ($.workout.mode == $.MODE_MANUAL) ? $.MODE_GPS : $.MODE_MANUAL;
            WatchUi.requestUpdate();
        } else {
            $.workout.startWorkout();
            WatchUi.switchToView(
                new ActivityView(),
                new ActivityDelegate(),
                WatchUi.SLIDE_LEFT
            );
        }
    }

    function onUpdate(dc) {
        var w = dc.getWidth();
        var h = dc.getHeight();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Title
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            w / 2, h * 8 / 100,
            Graphics.FONT_SMALL,
            "Alvarez Diper",
            Graphics.TEXT_JUSTIFY_CENTER
        );

        // Fields
        _drawField(dc, w, h * 32 / 100, "1st lap",
            WorkoutSession.formatTimePadded($.workout.firstLapTarget),
            _field == 0);

        var modeStr = ($.workout.mode == $.MODE_MANUAL) ? "Manual" : "GPS";
        _drawField(dc, w, h * 50 / 100, "Mode", modeStr, _field == 1);

        _drawField(dc, w, h * 68 / 100, "", "Start workout", _field == 2);

        // Hint
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            w / 2, h * 88 / 100,
            Graphics.FONT_XTINY,
            "UP/DOWN  START",
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }

    hidden function _drawField(dc, w, y, label, value, focused) {
        var color = focused ? Graphics.COLOR_YELLOW : Graphics.COLOR_WHITE;
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        var text = (label.length() > 0) ? label + ": " + value : value;
        dc.drawText(
            w / 2, y,
            Graphics.FONT_SMALL,
            text,
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }
}

(:legacy_only)
class LegacyConfigDelegate extends WatchUi.BehaviorDelegate {
    hidden var _view;

    function initialize(view) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onKey(keyEvent) {
        var key = keyEvent.getKey();
        if (key == WatchUi.KEY_UP) {
            _view.cycleUp();
            return true;
        }
        if (key == WatchUi.KEY_DOWN) {
            _view.cycleDown();
            return true;
        }
        if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START) {
            _view.activate();
            return true;
        }
        return false;
    }
}

// ---------- Pause menu (invoked from ActivityDelegate.showPauseMenu legacy) ----------
//
// ActivityView is a user View, so pushing a single native Menu on top of it
// is fine. PauseMenu has no nested submenus: selecting an item either
// auto-pops (Resume) or calls switchToView (End).

(:legacy_only)
class PauseMenuLegacyDelegate extends WatchUi.MenuInputDelegate {

    function initialize() {
        MenuInputDelegate.initialize();
    }

    function onMenuItem(item) {
        if (item == :resume) {
            // Framework will auto-pop the pause menu, returning to ActivityView.
            $.workout.resume();
        } else if (item == :end) {
            $.workout.stopWorkout();
            // switchToView replaces the pause menu with the summary.
            var summary = new SummaryView();
            WatchUi.switchToView(
                summary,
                new SummaryDelegate(summary),
                WatchUi.SLIDE_RIGHT
            );
        }
    }
}
