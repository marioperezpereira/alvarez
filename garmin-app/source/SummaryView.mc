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

        // Lap rows — one compact line per lap: "L1  0:02  3:30/km  180"
        var lapFont = Graphics.FONT_XTINY;
        var lapFontH = dc.getFontHeight(lapFont);
        var lineH = lapFontH + 2;

        fontH = dc.getFontHeight(Graphics.FONT_SMALL);
        y += fontH + 4;

        // Calculate how many laps fit
        var maxY = h * 92 / 100;
        var maxLaps = (maxY - y) / lineH;
        if (maxLaps < 1) {
            maxLaps = 1;
        }

        // Show most recent laps that fit
        var startIdx = totalLaps - maxLaps;
        if (startIdx < 0) {
            startIdx = 0;
        }

        var leftPad = w * 8 / 100;

        for (var i = startIdx; i < totalLaps; i++) {
            var lap = laps[i] as Dictionary;
            var lapNum = lap["lapNum"] as Number;
            var timeMs = lap["timeMs"] as Number;
            var maxPace = lap["maxPace"] as Float;
            var maxHr = lap["maxHr"] as Number;

            var timeStr = WorkoutSession.formatElapsedMs(timeMs);
            var maxPaceStr = WorkoutSession.formatPace(maxPace);
            var hrStr = (maxHr > 0) ? maxHr + "" : "--";

            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(leftPad, y, lapFont,
                "L" + lapNum + " " + timeStr,
                Graphics.TEXT_JUSTIFY_LEFT);
            dc.drawText(w - leftPad, y, lapFont,
                maxPaceStr + "  " + hrStr,
                Graphics.TEXT_JUSTIFY_RIGHT);
            y += lineH;
        }
    }
}
