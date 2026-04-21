import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;

// Brand palette — matches the web app
const COLOR_ACCENT = 0xff701a;   // orange
const COLOR_PASS = 0x00aa4a;     // darker green, legible on black
const COLOR_FAIL = 0xd93025;     // red

class SummaryView extends WatchUi.View {

    // 0 = result hero, 1 = laps table, 2 = progression charts
    var _page = 0;
    // Sub-pagination inside the laps table (index of the visible block)
    var _lapsBlock = 0;
    // How many lap rows fit per block; computed on first render
    var _lapsPerBlock = 8;

    // Cached big font for the hero number — resolved in onLayout
    var _heroFont = Graphics.FONT_NUMBER_MEDIUM;

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Graphics.Dc) as Void {
        // NUMBER_HOT is plenty big (~90px on FR970) and leaves room for the
        // label + verdict + totals. THAI_HOT is too tall and collides.
        if (Graphics has :FONT_NUMBER_HOT) {
            _heroFont = Graphics.FONT_NUMBER_HOT;
        } else {
            _heroFont = Graphics.FONT_NUMBER_MEDIUM;
        }
    }

    // Called by the delegate
    function nextPage() as Void {
        var laps = $.workout.lapHistory as Array;
        if (_page == 1 && _hasMoreLapBlocks(laps)) {
            _lapsBlock++;
            WatchUi.requestUpdate();
            return;
        }
        if (_page < 2) {
            _page++;
            _lapsBlock = 0;
            WatchUi.requestUpdate();
        }
    }

    function prevPage() as Void {
        if (_page == 1 && _lapsBlock > 0) {
            _lapsBlock--;
            WatchUi.requestUpdate();
            return;
        }
        if (_page > 0) {
            _page--;
            _lapsBlock = 0;
            WatchUi.requestUpdate();
        }
    }

    // True when the next invocation of nextPage() would no longer advance —
    // i.e. we're on the final page and no more lap blocks to reveal.
    function isAtEnd() as Boolean {
        // Page 2 is always terminal. Lap-table block pagination only applies
        // while _page == 1.
        return _page >= 2;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        if (_page == 0) {
            _renderResult(dc);
        } else if (_page == 1) {
            _renderLapsTable(dc);
        } else {
            _renderProgression(dc);
        }

        _drawPageDots(dc);
    }

    // ---------------- Page 0 — Result hero ----------------

    hidden function _renderResult(dc) {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var laps = $.workout.lapHistory as Array;

        // Top label
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 8 / 100, Graphics.FONT_XTINY,
            "TEST ÁLVAREZ", Graphics.TEXT_JUSTIFY_CENTER);

        if (laps.size() == 0) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, h / 2, Graphics.FONT_SMALL,
                "No se registraron vueltas", Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }

        // Figure out completed count and failure lap (if any)
        var completed = 0;
        var failedAtLap = -1;
        for (var i = 0; i < laps.size(); i++) {
            var lap = laps[i];
            if ($.workout.isIncompleteLap(lap)) {
                failedAtLap = WorkoutSession.lapNum(lap);
                break;
            }
            if ($.workout.didPassLap(lap)) {
                completed++;
            } else {
                failedAtLap = WorkoutSession.lapNum(lap);
                break;
            }
        }

        // Huge number — completed laps. Use VCENTER so we can anchor it
        // precisely at 35% of the screen height without computing font
        // metrics.
        var numY = h * 35 / 100;
        dc.setColor($.COLOR_ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, numY, _heroFont,
            completed.format("%d"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Label under the number
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 58 / 100, Graphics.FONT_XTINY,
            (completed == 1) ? "VUELTA COMPLETADA" : "VUELTAS COMPLETADAS",
            Graphics.TEXT_JUSTIFY_CENTER);

        // Verdict line
        var verdictY = h * 68 / 100;
        if (failedAtLap > 0) {
            dc.setColor($.COLOR_FAIL, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, verdictY, Graphics.FONT_XTINY,
                "Fallo en L" + failedAtLap, Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            dc.setColor($.COLOR_PASS, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, verdictY, Graphics.FONT_XTINY,
                "Completado", Graphics.TEXT_JUSTIFY_CENTER);
        }

        // Totals — combine into one line if there's no distance data
        var totalMs = WorkoutSession.totalElapsedMs(laps);
        var totalDist = WorkoutSession.totalDistance(laps);
        var maxHr = WorkoutSession.sessionMaxHr(laps);

        var statsY = h * 78 / 100;
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);

        var statsStr = WorkoutSession.formatElapsedMs(totalMs);
        if (totalDist > 0) {
            statsStr = (totalDist / 1000.0).format("%.2f") + " km · " + statsStr;
        }
        dc.drawText(w / 2, statsY, Graphics.FONT_XTINY, statsStr,
            Graphics.TEXT_JUSTIFY_CENTER);

        if (maxHr > 0) {
            dc.drawText(w / 2, h * 85 / 100, Graphics.FONT_XTINY,
                "HR máx " + maxHr.format("%d"),
                Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    // ---------------- Page 1 — Laps table ----------------

    hidden function _renderLapsTable(dc) {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var laps = $.workout.lapHistory as Array;

        var topY = h * 10 / 100;
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, topY, Graphics.FONT_XTINY,
            "VUELTAS", Graphics.TEXT_JUSTIFY_CENTER);

        if (laps.size() == 0) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, h / 2, Graphics.FONT_SMALL,
                "Sin vueltas", Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }

        // Column x positions — tuned for round screen, middle zone is widest
        var colNum = w * 18 / 100;
        var colTgt = w * 38 / 100;
        var colTime = w * 62 / 100;
        var colHr = w * 82 / 100;

        var rowFont = Graphics.FONT_XTINY;
        var rowH = dc.getFontHeight(rowFont) + 3;

        // Header row
        var headerY = h * 20 / 100;
        dc.setColor($.COLOR_ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(colNum, headerY, rowFont, "#", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(colTgt, headerY, rowFont, "TGT", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(colTime, headerY, rowFont, "TIME", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(colHr, headerY, rowFont, "HR", Graphics.TEXT_JUSTIFY_CENTER);

        // Divider
        var divY = headerY + rowH;
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(w * 10 / 100, divY, w * 80 / 100, 1);

        // Compute how many rows fit between divider and footer
        var footerY = h * 90 / 100;
        var maxLaps = (footerY - divY - 4) / rowH;
        if (maxLaps < 1) { maxLaps = 1; }
        _lapsPerBlock = maxLaps;

        var startIdx = _lapsBlock * maxLaps;
        if (startIdx >= laps.size()) {
            _lapsBlock = 0;
            startIdx = 0;
        }
        var endIdx = startIdx + maxLaps;
        if (endIdx > laps.size()) { endIdx = laps.size(); }

        var y = divY + 4;
        for (var i = startIdx; i < endIdx; i++) {
            var lap = laps[i];
            var lapNum = WorkoutSession.lapNum(lap);
            var timeMs = WorkoutSession.lapTimeMs(lap);
            var hr = WorkoutSession.lapMaxHeartRate(lap);
            var target = $.workout.targetForLap(lapNum);
            var incomplete = $.workout.isIncompleteLap(lap);
            var passed = $.workout.didPassLap(lap) && !incomplete;

            if (incomplete || !passed) {
                dc.setColor($.COLOR_FAIL, Graphics.COLOR_TRANSPARENT);
            } else {
                dc.setColor($.COLOR_PASS, Graphics.COLOR_TRANSPARENT);
            }

            dc.drawText(colNum, y, rowFont, lapNum.format("%d"),
                Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(colTgt, y, rowFont, WorkoutSession.formatTime(target),
                Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(colTime, y, rowFont, WorkoutSession.formatElapsedMs(timeMs),
                Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(colHr, y, rowFont,
                (hr != null && hr > 0) ? hr.format("%d") : "--",
                Graphics.TEXT_JUSTIFY_CENTER);
            y += rowH;
        }

        // Sub-paginator hint if there are more blocks
        if (_hasMoreLapBlocks(laps) || _lapsBlock > 0) {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            var hint = "L" + (startIdx + 1) + "–L" + endIdx + " / " + laps.size();
            dc.drawText(w / 2, footerY - 4, Graphics.FONT_XTINY, hint,
                Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    hidden function _hasMoreLapBlocks(laps as Array) {
        return (_lapsBlock + 1) * _lapsPerBlock < laps.size();
    }

    // ---------------- Page 2 — Progression chart ----------------

    hidden function _renderProgression(dc) {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var laps = $.workout.lapHistory as Array;

        var topY = h * 8 / 100;
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, topY, Graphics.FONT_XTINY,
            "PROGRESIÓN", Graphics.TEXT_JUSTIFY_CENTER);

        if (laps.size() == 0) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, h / 2, Graphics.FONT_SMALL,
                "Sin datos", Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }

        // Chart areas — two vertically stacked bands.
        // Using timeMs instead of avgPace so manual-mode tests (no GPS,
        // where avgPace = 0) still render meaningful bars.
        var chartX = w * 14 / 100;
        var chartW = w * 72 / 100;
        var bandH = h * 18 / 100;

        var paceY = h * 32 / 100;
        var hrY = h * 66 / 100;

        _drawBarChart(dc, "TIEMPO / VUELTA", chartX, paceY, chartW, bandH,
            laps, :timeMs, true);
        _drawBarChart(dc, "HR MÁX / VUELTA", chartX, hrY, chartW, bandH,
            laps, :maxHr, false);
    }

    // Draws a labeled bar chart inside (x, y, w, h). `isPace` implies both
    // the series color (orange for pace, white for HR) AND whether the
    // scale is inverted (smaller pace value = taller bar). Combined to
    // stay under CIQ 1.x's 9-argument limit per method.
    hidden function _drawBarChart(dc, label, x, y, w, h, laps as Array, field, isPace) {
        var baseColor = isPace ? $.COLOR_ACCENT : Graphics.COLOR_WHITE;
        var invertScale = isPace;

        // Label centered above the chart band
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x + w / 2, y - dc.getFontHeight(Graphics.FONT_XTINY) - 2,
            Graphics.FONT_XTINY, label, Graphics.TEXT_JUSTIFY_CENTER);

        // Find min/max of field, skipping null/zero values
        var vmin = -1;
        var vmax = -1;
        for (var i = 0; i < laps.size(); i++) {
            var vi = WorkoutSession.lapFieldNumber(laps[i], field, 0);
            if (vi <= 0) { continue; }
            if (vmin < 0 || vi < vmin) { vmin = vi; }
            if (vi > vmax) { vmax = vi; }
        }
        if (vmin < 0) {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(x + w / 2, y + h / 2, Graphics.FONT_XTINY,
                "sin datos", Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }

        // Baseline (faint)
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x, y + h - 1, w, 1);

        // Bars
        var n = laps.size();
        if (n < 1) { return; }
        var gap = 2;
        var barW = (w - gap * (n - 1)) / n;
        if (barW < 2) { barW = 2; gap = 1; }

        var range = vmax - vmin;
        if (range < 1) { range = 1; }

        for (var i = 0; i < n; i++) {
            var lap = laps[i];
            var vi = WorkoutSession.lapFieldNumber(lap, field, 0);
            if (vi <= 0) { continue; }

            // Normalize to 0..80 within min/max, floor at 20% so the shortest
            // bar is still visible.
            var normalized = vi - vmin;
            var pct = (normalized * 80) / range;
            if (invertScale) { pct = 80 - pct; }
            pct += 20;

            var barH = (h * pct) / 100;
            if (barH < 2) { barH = 2; }
            if (barH > h) { barH = h; }

            var bx = x + i * (barW + gap);
            var by = y + h - barH;

            // Failure lap overrides color
            if ($.workout.isIncompleteLap(lap)
                || !$.workout.didPassLap(lap)) {
                dc.setColor($.COLOR_FAIL, Graphics.COLOR_TRANSPARENT);
            } else {
                dc.setColor(baseColor, Graphics.COLOR_TRANSPARENT);
            }
            dc.fillRectangle(bx, by, barW, barH);
        }

        // X-axis ticks
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y + h + 1, Graphics.FONT_XTINY, "L1",
            Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(x + w, y + h + 1, Graphics.FONT_XTINY,
            "L" + n.format("%d"), Graphics.TEXT_JUSTIFY_RIGHT);
    }

    // ---------------- Page indicator dots ----------------

    hidden function _drawPageDots(dc) {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cy = h * 96 / 100;
        var r = 3;
        var gap = 10;
        var totalW = 3 * (2 * r) + 2 * gap;
        var x0 = (w - totalW) / 2 + r;

        for (var i = 0; i < 3; i++) {
            if (i == _page) {
                dc.setColor($.COLOR_ACCENT, Graphics.COLOR_TRANSPARENT);
            } else {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            }
            dc.fillCircle(x0 + i * (2 * r + gap), cy, r);
        }
    }
}
