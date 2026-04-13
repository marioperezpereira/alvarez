import Toybox.Lang;
import Toybox.System;
import Toybox.Activity;
import Toybox.ActivityRecording;
import Toybox.Position;
import Toybox.Attention;
import Toybox.Timer;

const MODE_MANUAL = 0;
const MODE_GPS = 1;

class WorkoutSession {

    var firstLapTarget = 120;   // seconds, default 2:00
    var mode = $.MODE_MANUAL;

    var isRunning = false;
    var isPaused = false;
    var currentLap = 1;
    var lapStartTime = 0;       // System.getTimer() ms
    var pauseStartTime = 0;     // when pause began
    var totalPausedMs = 0;      // accumulated pause time for current lap
    var lapHistory = [];
    var quartersPlayed = 0;
    var lapDistanceAtStart = 0.0;
    var lapMaxHr = 0;
    var lapMaxSpeed = 0.0;      // m/s

    var session = null;

    function initialize() {
    }

    // Returns current lap target in seconds
    function getCurrentTarget() {
        return firstLapTarget - (currentLap - 1) * 4;
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
        // Create FIT recording session
        session = ActivityRecording.createSession({
            :name => "Alvarez - Diper",
            :sport => Activity.SPORT_RUNNING,
            :subSport => Activity.SUB_SPORT_TRACK
        });

        // Enable GPS
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));

        session.start();
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
            session.stop();
        }
    }

    function resume() {
        if (!isRunning || !isPaused) {
            return;
        }
        totalPausedMs += System.getTimer() - pauseStartTime;
        isPaused = false;
        if (session != null) {
            session.start();
        }
    }

    function getCurrentLapDistance() {
        var info = Activity.getActivityInfo();
        if (info != null && info.elapsedDistance != null) {
            return info.elapsedDistance - lapDistanceAtStart;
        }
        return 0.0;
    }

    // Call on each timer tick to track max HR and max speed for current lap
    function sampleSensors() {
        if (!isRunning || isPaused) {
            return;
        }
        var info = Activity.getActivityInfo();
        if (info != null) {
            if (info.currentHeartRate != null && info.currentHeartRate > lapMaxHr) {
                lapMaxHr = info.currentHeartRate;
            }
            if (info.currentSpeed != null && info.currentSpeed > lapMaxSpeed) {
                lapMaxSpeed = info.currentSpeed;
            }
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
            "lapNum" => currentLap,
            "timeMs" => elapsedMs,
            "distance" => lapDist,
            "avgPace" => avgPace,
            "avgHr" => avgHr,
            "maxHr" => lapMaxHr,
            "maxPace" => maxPace
        };
        lapHistory.add(lapData);

        // Record lap in FIT (only while the session is actively recording)
        if (addFitLap && session != null) {
            session.addLap();
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

    function checkQuarterTones(elapsedMs) {
        var targetMs = getCurrentTarget() * 1000;
        if (targetMs <= 0) {
            return;
        }
        var quarterMs = targetMs / 4;

        for (var q = 1; q <= 3; q++) {
            if (elapsedMs >= q * quarterMs && quartersPlayed < q) {
                quartersPlayed = q;
                playQuarterTone();
            }
        }
    }

    function checkAutoLap() {
        if (mode != $.MODE_GPS || !isRunning) {
            return;
        }
        var lapDist = getCurrentLapDistance();
        if (lapDist >= 400.0) {
            completeLap();
        }
    }

    function playQuarterTone() {
        if (Attention has :playTone) {
            Attention.playTone(Attention.TONE_ALERT_HI);
        }
        if (Attention has :vibrate) {
            Attention.vibrate([
                new Attention.VibeProfile(100, 300)
            ]);
        }
    }

    function playLapTone() {
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
            if (!sessionAlreadyStopped) {
                session.stop();
            }
            session.save();
            session = null;
        }
        Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));
    }

    function discardWorkout() {
        isRunning = false;
        if (session != null) {
            session.stop();
            session.discard();
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
