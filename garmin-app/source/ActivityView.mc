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
    var tickCounter = 0;

    // --- Cached display strings (rebuilt only when values change) ---
    // Avoids creating new String objects every onUpdate, which caused
    // GC pressure → OOM crash on FR970 after ~90s.
    var cachedTopLabel = "LAP 1  MANUAL";
    var cachedElapsed = "0:00";
    var cachedTarget = "TARGET 2:00";
    var cachedElapsedMs = 0;
    var cachedTargetMs = 120000;
    var cachedOverTarget = false;
    var cachedLap = 0;          // track lap changes to rebuild cachedTopLabel/cachedTarget
    var cachedSecond = -1;      // track second changes to rebuild cachedElapsed

    function initialize() {
        View.initialize();
    }

    function onShow() {
        if (Graphics has :FONT_NUMBER_HOT) {
            bigFont = Graphics.FONT_NUMBER_HOT;
        }

        // 4 Hz for quarter-tone detection and auto-lap.
        // Display repaints only once per second (see tickCounter logic).
        updateTimer = new Timer.Timer();
        updateTimer.start(method(:onTimer), 250, true);
        backlightCounter = 0;
        tickCounter = 0;
        cachedLap = 0;
        cachedSecond = -1;
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

            // Single ActivityInfo fetch per tick
            var info = $.workout.getInfo();
            $.workout.sampleSensors(info);
            $.workout.checkQuarterTones(elapsedMs);
            $.workout.checkAutoLap(info);

            // Update cached values for display.
            // Strings are only rebuilt when the visible value actually changes.
            var currentSec = (elapsedMs / 1000).toNumber();
            if (currentSec < 0) { currentSec = 0; }

            // Rebuild elapsed string only when the second changes (~1Hz)
            if (currentSec != cachedSecond) {
                cachedSecond = currentSec;
                var m = currentSec / 60;
                var s = currentSec % 60;
                cachedElapsed = m.format("%d") + ":" + s.format("%02d");
                cachedElapsedMs = elapsedMs;

                var targetSec = $.workout.getCurrentTarget();
                cachedTargetMs = targetSec * 1000;
                cachedOverTarget = (elapsedMs > cachedTargetMs && cachedTargetMs > 0);
            }

            // Rebuild top label and target string only on lap change
            var lap = $.workout.currentLap;
            if (lap != cachedLap) {
                cachedLap = lap;
                var modeStr = ($.workout.mode == $.MODE_MANUAL) ? "MANUAL" : "GPS";
                cachedTopLabel = "LAP " + lap + "  " + modeStr;

                var targetSec = $.workout.getCurrentTarget();
                cachedTarget = "TARGET " + WorkoutSession.formatTime(targetSec);
                cachedTargetMs = targetSec * 1000;
            }
        }

        // Repaint display once per second (every 4th tick at 4Hz).
        // Quarter tones and auto-lap still run at 4Hz above.
        tickCounter++;
        if (tickCounter >= 4) {
            tickCounter = 0;
            WatchUi.requestUpdate();
        }

        // Backlight every ~3s (12 ticks at 4Hz)
        backlightCounter++;
        if (backlightCounter >= 12) {
            backlightCounter = 0;
            if (Attention has :backlight) {
                Attention.backlight(true);
            }
        }
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();

        // Black background
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // --- Top: LAP number and mode ---
        var topY = h * 15 / 100;
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, topY, Graphics.FONT_SMALL,
            cachedTopLabel,
            Graphics.TEXT_JUSTIFY_CENTER);

        // --- Center: Elapsed time (large) ---
        var centerY = h * 30 / 100;
        if (cachedOverTarget) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        }
        dc.drawText(w / 2, centerY, bigFont,
            cachedElapsed,
            Graphics.TEXT_JUSTIFY_CENTER);

        // --- Below center: TARGET ---
        var targetY = h * 60 / 100;
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, targetY, Graphics.FONT_MEDIUM,
            cachedTarget,
            Graphics.TEXT_JUSTIFY_CENTER);

        // --- Bottom: Progress bar with quarter markers ---
        drawProgressBar(dc, w, h);
    }

    function drawProgressBar(dc, w, h) {
        var barW = w * 66 / 100;
        var barH = h * 3 / 100;
        if (barH < 6) { barH = 6; }
        var barX = (w - barW) / 2;
        var barY = h * 76 / 100;

        // Background
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(barX, barY, barW, barH);

        // Fill — integer-only arithmetic (no toFloat)
        var fillW = 0;
        if (cachedTargetMs > 0 && cachedElapsedMs > 0) {
            // (barW * elapsedMs) could overflow Int32 on large screens,
            // so clamp elapsed first and use 100-based percentage.
            var elapsed = cachedElapsedMs;
            if (elapsed > cachedTargetMs) { elapsed = cachedTargetMs; }
            var pct = (elapsed * 100) / cachedTargetMs;  // 0–100
            fillW = (barW * pct) / 100;
        }

        if (fillW > 0) {
            var pct = 0;
            if (cachedTargetMs > 0) {
                pct = (cachedElapsedMs * 100) / cachedTargetMs;
            }
            if (pct < 85) {
                dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
            } else if (pct < 100) {
                dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            } else {
                dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            }
            dc.fillRectangle(barX, barY, fillW, barH);
        }

        // Quarter markers
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
