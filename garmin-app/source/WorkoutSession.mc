import Toybox.Lang;
import Toybox.System;
import Toybox.Activity;
import Toybox.ActivityRecording;
import Toybox.Position;
import Toybox.Attention;
import Toybox.Timer;

const MODE_MANUAL = 0;
const MODE_GPS = 1;
const INCOMPLETE_DIST_THRESHOLD_M = 200.0;

const LAP_KEY_NUM = :lapNum;
const LAP_KEY_TIME_MS = :timeMs;
const LAP_KEY_DISTANCE = :distance;
const LAP_KEY_AVG_PACE = :avgPace;
const LAP_KEY_AVG_HR = :avgHr;
const LAP_KEY_MAX_HR = :maxHr;
const LAP_KEY_MAX_PACE = :maxPace;

class WorkoutSession {

    var firstLapTarget = 120;   // seconds, default 2:00
    var mode = $.MODE_MANUAL;

    var isRunning = false;
    var isPaused = false;
    var currentLap = 1;
    var lapStartTime = 0;       // System.getTimer() ms
    var pauseStartTime = 0;     // when pause began
    var totalPausedMs = 0;      // accumulated pause time for current lap
    var lapHistory as Array = [];
    var quartersPlayed = 0;
    var lapDistanceAtStart = 0.0;
    var lapMaxHr = 0;
    var lapMaxSpeed = 0.0;      // m/s

    var session = null;

    // If true, createSession/start failed and we continue without FIT so the
    // user can still complete the workout view flow.
    var recordingUnavailable = false;

    function initialize() {
    }

    // Returns current lap target in seconds
    function getCurrentTarget() {
        return firstLapTarget - (currentLap - 1) * 4;
    }

    // Target (seconds) for an arbitrary lap number
    function targetForLap(lapNum) {
        return firstLapTarget - (lapNum - 1) * 4;
    }

    // Did this stored lap finish under its target?
    function didPassLap(lap) {
        var target = targetForLap(WorkoutSession.lapNum(lap));
        return (WorkoutSession.lapTimeMs(lap) / 1000) <= target;
    }

    // Flag laps that were never fully completed (user failed mid-lap).
    // In GPS mode this means distance < half of 400m. In manual mode
    // distance can be 0 and we fall back to the time vs target heuristic:
    // a manual lap always gets pressed, so it's only incomplete if the
    // timer was stopped without pressing, which doesn't happen — return
    // false in that case.
    function isIncompleteLap(lap) {
        // Manual laps are explicitly user-triggered and should not be marked
        // incomplete due to noisy/absent GPS distance.
        if (mode == $.MODE_MANUAL) {
            return false;
        }
        var dist = WorkoutSession.lapDistance(lap);
        if (dist > 0.0 && dist < $.INCOMPLETE_DIST_THRESHOLD_M) {
            return true;
        }
        return false;
    }

    // --- Session-level aggregates over lapHistory ---

    static function totalElapsedMs(history as Array) {
        var total = 0;
        for (var i = 0; i < history.size(); i++) {
            total += lapTimeMs(history[i]);
        }
        return total;
    }

    static function totalDistance(history as Array) {
        var total = 0.0;
        for (var i = 0; i < history.size(); i++) {
            total += lapDistance(history[i]);
        }
        return total;
    }

    static function sessionMaxHr(history as Array) {
        var max = 0;
        for (var i = 0; i < history.size(); i++) {
            var h = lapMaxHeartRate(history[i]);
            if (h > max) { max = h; }
        }
        return max;
    }

    hidden static function lapFieldValue(lap, key) {
        if (!(lap instanceof Dictionary)) {
            return null;
        }
        return (lap as Dictionary).get(key);
    }

    static function lapFieldNumber(lap, key, defaultValue) {
        var value = lapFieldValue(lap, key);
        if (value == null) {
            return defaultValue;
        }
        if (value instanceof Number) {
            return value;
        }
        try {
            return value.toNumber();
        } catch (e) {
            return defaultValue;
        }
    }

    static function lapNum(lap) {
        return lapFieldNumber(lap, $.LAP_KEY_NUM, 0);
    }

    static function lapTimeMs(lap) {
        return lapFieldNumber(lap, $.LAP_KEY_TIME_MS, 0);
    }

    static function lapDistance(lap) {
        return lapFieldNumber(lap, $.LAP_KEY_DISTANCE, 0.0);
    }

    static function lapMaxHeartRate(lap) {
        return lapFieldNumber(lap, $.LAP_KEY_MAX_HR, 0);
    }

    // Format seconds to "M:SS" string
    static function formatTime(seconds) {
        if (seconds < 0) {
            seconds = 0;
        }
        var m = seconds / 60;
        var s = seconds % 60;
        return m.format("%d") + ":" + s.format("%02d");
    }

    // Format seconds to "MM:SS" string with leading zero on minutes
    static function formatTimePadded(seconds) {
        if (seconds < 0) {
            seconds = 0;
        }
        var m = seconds / 60;
        var s = seconds % 60;
        return m.format("%02d") + ":" + s.format("%02d");
    }

    // Format milliseconds to "M:SS" display string
    static function formatElapsedMs(ms) {
        var totalSeconds = (ms / 1000).toNumber();
        if (totalSeconds < 0) {
            totalSeconds = 0;
        }
        var m = totalSeconds / 60;
        var s = totalSeconds % 60;
        return m.format("%d") + ":" + s.format("%02d");
    }

    // Format milliseconds to "MM:SS" display with leading zero
    static function formatElapsedMsPadded(ms) {
        var totalSeconds = (ms / 1000).toNumber();
        if (totalSeconds < 0) {
            totalSeconds = 0;
        }
        var m = totalSeconds / 60;
        var s = totalSeconds % 60;
        return m.format("%02d") + ":" + s.format("%02d");
    }

    function startWorkout() {
        recordingUnavailable = false;
        session = null;

        // Create FIT recording session using non-deprecated Activity constants.
        var sport = Activity.SPORT_RUNNING;
        var subSport = Activity.SUB_SPORT_TRACK;

        try {
            session = ActivityRecording.createSession({
                :name => "Alvarez - Diper",
                :sport => sport,
                :subSport => subSport
            });
            if (session != null) {
                session.start();
            } else {
                recordingUnavailable = true;
            }
        } catch (e) {
            session = null;
            recordingUnavailable = true;
        }

        // Enable GPS
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
        isRunning = true;
        isPaused = false;
        currentLap = 1;
        quartersPlayed = 0;
        totalPausedMs = 0;
        lapHistory = [];
        lapStartTime = System.getTimer();

        // Grab initial distance
        var info = Activity.getActivityInfo();
        if (info != null && info.elapsedDistance != null) {
            lapDistanceAtStart = info.elapsedDistance;
        } else {
            lapDistanceAtStart = 0.0;
        }
    }

    // GPS callback (required by enableLocationEvents but we read distance from ActivityInfo)
    function onPosition(info as Position.Info) as Void {
        // Position data is recorded automatically by the FIT session
    }

    function getElapsedMs() {
        if (!isRunning) {
            return 0;
        }
        if (isPaused) {
            return pauseStartTime - lapStartTime - totalPausedMs;
        }
        return System.getTimer() - lapStartTime - totalPausedMs;
    }

    function pause() {
        if (!isRunning || isPaused) {
            return;
        }
        isPaused = true;
        pauseStartTime = System.getTimer();
        if (session != null) {
            try {
                session.stop();
            } catch (e) {
                recordingUnavailable = true;
            }
        }
    }

    function resume() {
        if (!isRunning || !isPaused) {
            return;
        }

        // Rebase distance so movement while paused does not count toward the
        // current GPS lap after resume.
        var info = Activity.getActivityInfo();
        if (info != null && info.elapsedDistance != null) {
            lapDistanceAtStart = info.elapsedDistance;
        }

        totalPausedMs += System.getTimer() - pauseStartTime;
        isPaused = false;
        if (session != null) {
            try {
                session.start();
            } catch (e) {
                recordingUnavailable = true;
            }
        }
    }

    function getCurrentLapDistance() {
        var info = Activity.getActivityInfo();
        if (info != null && info.elapsedDistance != null) {
            return info.elapsedDistance - lapDistanceAtStart;
        }
        return 0.0;
    }

    // Fetch ActivityInfo once per timer tick. Callers (sampleSensors,
    // checkAutoLap) receive this instead of calling getActivityInfo()
    // themselves, cutting per-tick allocations in half.
    function getInfo() {
        return Activity.getActivityInfo();
    }

    // Call on each timer tick to track max HR and max speed for current lap.
    // Receives a pre-fetched ActivityInfo to avoid redundant allocations.
    function sampleSensors(info) {
        if (!isRunning || isPaused || info == null) {
            return;
        }
        if (info.currentHeartRate != null && info.currentHeartRate > lapMaxHr) {
            lapMaxHr = info.currentHeartRate;
        }
        if (info.currentSpeed != null && info.currentSpeed > lapMaxSpeed) {
            lapMaxSpeed = info.currentSpeed;
        }
    }

    function completeLap() {
        _recordLap(true, true);
    }

    // Capture the current lap into lapHistory.
    // - addFitLap: whether to call session.addLap() (must be false if the FIT
    //   session has been stopped, e.g. while paused).
    // - playTone: whether to play the lap-completion tone + vibration.
    function _recordLap(addFitLap, playTone) {
        if (!isRunning || isPaused) {
            return;
        }

        var elapsedMs = getElapsedMs();
        var lapTimeSec = elapsedMs / 1000.0;
        var lapDist = getCurrentLapDistance();

        // Calculate average pace (sec/km)
        var avgPace = 0.0;
        if (lapDist > 0) {
            avgPace = (lapTimeSec / lapDist) * 1000.0;
        }

        // Get heart rate if available
        var avgHr = 0;
        var info = Activity.getActivityInfo();
        if (info != null && info.currentHeartRate != null) {
            avgHr = info.currentHeartRate;
        }

        // Max speed as pace (sec/km): 1000 / speed(m/s)
        var maxPace = 0.0;
        if (lapMaxSpeed > 0) {
            maxPace = 1000.0 / lapMaxSpeed;
        }

        // Store lap data
        var lapData = {
            :lapNum => currentLap,
            :timeMs => elapsedMs,
            :distance => lapDist,
            :avgPace => avgPace,
            :avgHr => avgHr,
            :maxHr => lapMaxHr,
            :maxPace => maxPace
        };
        lapHistory.add(lapData);

        // Record lap in FIT (only while the session is actively recording)
        if (addFitLap && session != null) {
            try {
                session.addLap();
            } catch (e) {
                recordingUnavailable = true;
            }
        }

        if (playTone) {
            playLapTone();
        }

        // Advance to next lap
        currentLap++;
        quartersPlayed = 0;
        totalPausedMs = 0;
        lapMaxHr = 0;
        lapMaxSpeed = 0.0;
        lapStartTime = System.getTimer();

        // Reset distance tracking for new lap
        if (info != null && info.elapsedDistance != null) {
            lapDistanceAtStart = info.elapsedDistance;
        }
    }

    // Returns true if a quarter tone fired on this tick, so the caller can
     // force an immediate display repaint (keeps the on-screen seconds in
     // sync with the audible beep).
    function checkQuarterTones(elapsedMs) {
        var targetMs = getCurrentTarget() * 1000;
        if (targetMs <= 0) {
            return false;
        }
        var quarterMs = targetMs / 4;
        var fired = false;

        for (var q = 1; q <= 3; q++) {
            if (elapsedMs >= q * quarterMs && quartersPlayed < q) {
                quartersPlayed = q;
                playQuarterTone();
                fired = true;
            }
        }
        return fired;
    }

    // Receives a pre-fetched ActivityInfo to avoid redundant allocations.
    function checkAutoLap(info) {
        if (mode != $.MODE_GPS || !isRunning) {
            return;
        }
        var lapDist = 0.0;
        if (info != null && info.elapsedDistance != null) {
            lapDist = info.elapsedDistance - lapDistanceAtStart;
        }
        if (lapDist >= 400.0) {
            completeLap();
        }
    }

    function playQuarterTone() {
        try {
            if (Attention has :playTone) {
                Attention.playTone(Attention.TONE_ALERT_HI);
            }
            if (Attention has :vibrate) {
                Attention.vibrate([
                    new Attention.VibeProfile(100, 300)
                ]);
            }
        } catch (e) {
            // Swallow — some devices throw when audio/haptic system is busy
        }
    }

    function playLapTone() {
        try {
            if (Attention has :playTone) {
                Attention.playTone(Attention.TONE_LAP);
            }
            if (Attention has :vibrate) {
                Attention.vibrate([
                    new Attention.VibeProfile(100, 300),
                    new Attention.VibeProfile(0, 100),
                    new Attention.VibeProfile(100, 300),
                    new Attention.VibeProfile(0, 100),
                    new Attention.VibeProfile(100, 300)
                ]);
            }
        } catch (e) {
            // Swallow — some devices throw when audio/haptic system is busy
        }
    }

    function stopWorkout() {
        // If paused, pause() already called session.stop() – don't touch the
        // session again (addLap / stop on a stopped session throws).
        var sessionAlreadyStopped = isPaused;

        if (isRunning) {
            if (isPaused) {
                // Finalize pause duration so the final lap time is accurate
                totalPausedMs += System.getTimer() - pauseStartTime;
                isPaused = false;
            }
            // Record the in-progress lap: only add to FIT if session still recording
            _recordLap(!sessionAlreadyStopped, false);
        }

        isRunning = false;
        isPaused = false;
        if (session != null) {
            try {
                if (!sessionAlreadyStopped) {
                    session.stop();
                }
            } catch (e) {
                recordingUnavailable = true;
            }
            try {
                session.save();
            } catch (e) {
                recordingUnavailable = true;
            }
            session = null;
        }
        Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));
    }

    function discardWorkout() {
        isRunning = false;
        if (session != null) {
            try {
                session.stop();
            } catch (e) {
            }
            try {
                session.discard();
            } catch (e) {
            }
            session = null;
        }
        Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));
    }

    // Format pace in seconds/km to "M:SS" string
    static function formatPace(paceSecPerKm) {
        if (paceSecPerKm <= 0 || paceSecPerKm > 5999) {
            return "--:--";
        }
        var m = paceSecPerKm.toNumber() / 60;
        var s = paceSecPerKm.toNumber() % 60;
        return m.format("%d") + ":" + s.format("%02d");
    }
}
