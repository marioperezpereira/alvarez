import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Timer;
import Toybox.Lang;
import Toybox.Activity;
import Toybox.Attention;

class ActivityView extends WatchUi.View {

    var updateTimer = null;
    var bigFont = Graphics.FONT_NUMBER_MEDIUM;
    var backlightCounter = 0;

    function initialize() {
        View.initialize();
    }

    function onShow() {
        // Pick the largest number font available
        if (Graphics has :FONT_NUMBER_HOT) {
            bigFont = Graphics.FONT_NUMBER_HOT;
        }

        // Refresh at 4 Hz — smooth enough for M:SS display and progress bar,
        // and cuts per-tick object allocations (ActivityInfo, Strings) to 40%
        // of the previous 10 Hz rate, preventing GC pressure / OOM on long tests.
        updateTimer = new Timer.Timer();
        updateTimer.start(method(:onTimer), 250, true);
        backlightCounter = 0;
    }

    function onHide() {
        if (updateTimer != null) {
            updateTimer.stop();
            updateTimer = null;
        }
    }

    function onTimer() as Void {
        if (!$.workout.isPaused) {
            var elapsedMs = $.workout.getElapsedMs();

            // Single ActivityInfo fetch per tick — avoids redundant allocations
            // that caused GC pressure and OOM crashes on long tests (~2-3 min).
            var info = $.workout.getInfo();

            // Sample HR and speed for lap max tracking
            $.workout.sampleSensors(info);

            // Fire quarter metronome tones
            $.workout.checkQuarterTones(elapsedMs);

            // In GPS mode, check for auto-lap
            $.workout.checkAutoLap(info);
        }

        // Keep screen awake — refresh backlight every ~3 seconds (at 4Hz: 12 ticks ≈ 3s)
        backlightCounter++;
        if (backlightCounter >= 12) {
            backlightCounter = 0;
            if (Attention has :backlight) {
                Attention.backlight(true);
            }
        }

        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();

        // Black background
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var elapsedMs = $.workout.getElapsedMs();
        var targetSec = $.workout.getCurrentTarget();
        var targetMs = targetSec * 1000;
        var lapNum = $.workout.currentLap;
        var modeStr = ($.workout.mode == $.MODE_MANUAL) ? "MANUAL" : "GPS";

        // --- Top: LAP number and mode ---
        var topY = h * 8 / 100;
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, topY, Graphics.FONT_SMALL,
            "LAP " + lapNum + "  " + modeStr,
            Graphics.TEXT_JUSTIFY_CENTER);

        // --- Center: Elapsed time (large) ---
        var elapsedStr = WorkoutSession.formatElapsedMs(elapsedMs);
        var centerY = h * 22 / 100;

        // Color: white if under target, red if over
        if (elapsedMs > targetMs && targetMs > 0) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        }
        dc.drawText(w / 2, centerY, bigFont,
            elapsedStr,
            Graphics.TEXT_JUSTIFY_CENTER);

        // --- Below center: TARGET ---
        var targetY = h * 55 / 100;
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, targetY, Graphics.FONT_MEDIUM,
            "TARGET " + WorkoutSession.formatTime(targetSec),
            Graphics.TEXT_JUSTIFY_CENTER);

        // --- Bottom: Progress bar with quarter markers ---
        drawProgressBar(dc, w, h, elapsedMs, targetMs);
    }

    function drawProgressBar(dc, w, h, elapsedMs, targetMs) {
        var barW = w * 66 / 100;     // ~300px on 454
        var barH = h * 3 / 100;
        if (barH < 6) { barH = 6; }
        var barX = (w - barW) / 2;
        var barY = h * 68 / 100;

        // Background
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(barX, barY, barW, barH);

        // Fill based on progress
        var progress = 0.0;
        if (targetMs > 0) {
            progress = elapsedMs.toFloat() / targetMs.toFloat();
            if (progress > 1.0) {
                progress = 1.0;
            }
        }

        var fillW = (barW * progress).toNumber();
        if (fillW > 0) {
            // Green if under target, yellow if close, red if over
            if (progress < 0.85) {
                dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
            } else if (progress < 1.0) {
                dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            } else {
                dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            }
            dc.fillRectangle(barX, barY, fillW, barH);
        }

        // Quarter markers (vertical white lines at 25%, 50%, 75%)
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        for (var q = 1; q <= 3; q++) {
            var qx = barX + (barW * q / 4);
            dc.fillRectangle(qx, barY, 2, barH);
        }

        // Outline
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(barX, barY, barW, barH);
    }
}
