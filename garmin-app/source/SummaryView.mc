import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;

class SummaryView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var laps = $.workout.lapHistory;
        var totalLaps = laps.size();

        // Title
        var y = h * 10 / 100;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, y, Graphics.FONT_MEDIUM,
            "SUMMARY",
            Graphics.TEXT_JUSTIFY_CENTER);

        // Total laps
        var fontH = dc.getFontHeight(Graphics.FONT_MEDIUM);
        y += fontH + 4;
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, y, Graphics.FONT_SMALL,
            totalLaps + " laps completed",
            Graphics.TEXT_JUSTIFY_CENTER);

        if (totalLaps == 0) {
            fontH = dc.getFontHeight(Graphics.FONT_SMALL);
            y += fontH + 20;
            dc.drawText(w / 2, y, Graphics.FONT_SMALL,
                "No laps recorded",
                Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }

        // Lap rows - two lines per lap: time+pace, then HR
        var lapFont = Graphics.FONT_XTINY;
        var lapFontH = dc.getFontHeight(lapFont);
        var lineH = lapFontH + 6;

        fontH = dc.getFontHeight(Graphics.FONT_SMALL);
        y += fontH + 8;

        // Calculate how many laps fit (2 lines per lap)
        var maxY = h * 88 / 100;
        var maxLaps = (maxY - y) / (lineH * 2);
        if (maxLaps < 1) {
            maxLaps = 1;
        }

        // Show most recent laps that fit
        var startIdx = totalLaps - maxLaps;
        if (startIdx < 0) {
            startIdx = 0;
        }

        var leftPad = w * 12 / 100;

        for (var i = startIdx; i < totalLaps; i++) {
            var lap = laps[i] as Dictionary;
            var lapNum = lap["lapNum"] as Number;
            var timeMs = lap["timeMs"] as Number;
            var maxPace = lap["maxPace"] as Float;
            var maxHr = lap["maxHr"] as Number;
            var avgHr = lap["avgHr"] as Number;

            var timeStr = WorkoutSession.formatElapsedMs(timeMs);
            var maxPaceStr = WorkoutSession.formatPace(maxPace);

            // Line 1: Lap number, time, max pace
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(leftPad, y, lapFont,
                "L" + lapNum + "  " + timeStr,
                Graphics.TEXT_JUSTIFY_LEFT);
            dc.drawText(w - leftPad, y, lapFont,
                "max " + maxPaceStr + "/km",
                Graphics.TEXT_JUSTIFY_RIGHT);
            y += lineH;

            // Line 2: HR info
            var hrStr = "";
            if (avgHr > 0 || maxHr > 0) {
                hrStr = "HR " + avgHr + " / max " + maxHr + " bpm";
            } else {
                hrStr = "HR --";
            }
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(leftPad, y, lapFont, hrStr,
                Graphics.TEXT_JUSTIFY_LEFT);
            y += lineH;
        }
    }
}
