# Alvarez

Alvarez is a Garmin watch app for progressive 400 m interval sessions on track.

This README is the product specification for the app. It describes how the app should work screen by screen, what each button should do, and which implementation constraints were discovered during prototyping.

The goal is to give another implementation, whether by a human or another AI, a clean and reliable spec to build from.

## Product goal

The app is an incremental running test, similar to lab-based progressive tests. Each lap is 400 m and each new lap target is 4 seconds faster than the previous one. The test continues until the runner can no longer keep up with the target pace.

This is not an interval training app with rest periods — it is a continuous progressive effort test.

Example:
- Lap 1 target: 2:20
- Lap 2 target: 2:16
- Lap 3 target: 2:12
- Lap 4 target: 2:08
- ... continues without floor until the runner stops

The app should be usable while running on a Garmin Forerunner class watch (target device: Forerunner 970), especially in track sessions where the user needs:
- fast configuration
- very clear current target
- very clear current lap time
- minimal interaction while moving
- intuitive use of Garmin hardware buttons

## Core principles

- The app must feel native to a Garmin watch.
- Configuration should prefer native menus over heavily custom drawn screens.
- The in-activity screen should be minimal and glanceable.
- Manual lap handling must use the Lap button, not Start.
- Avoid dense layouts and text stacking that can overlap on device or simulator.

## Workout model

### Initial setup
The user configures:
- first lap target time
- lap mode

### Lap progression rule
- every completed lap reduces the target by 4 seconds
- there is no floor — the target keeps decreasing until the runner can no longer complete a lap in time
- the 2:00 to 4:00 range applies only to the first lap time selector, not to subsequent lap targets

### Supported lap modes

#### 1. Manual
- the user presses the physical Lap button to complete a lap
- this is the most important mode and should be treated as the reference implementation
- Manual mode still records GPS distance, heart rate, and all available sensor data
- the only difference from GPS mode is that lap completion is triggered by the user, not by distance

#### 2. GPS
- the app automatically completes a lap when 400 m is reached using normal GPS distance
- this mode exists because not all runners use a track — some run on roads or paths
- GPS distance is inherently noisy on tight track ovals; this mode should be flagged as less precise than manual on a track
- should be implemented but clearly labeled as GPS-based in the UI

#### Track mode
Track mode has been removed. The Connect IQ SDK does not expose Garmin's native track detection feature to third-party apps, so there is no way to implement it differently from GPS mode.

## Recommended hardware button behavior

### Configuration menus
- Up/Down: move through menu items
- Enter/Start: select highlighted item
- Back: return to previous menu or leave submenu without breaking state

### During activity
- Start: starts session from setup, but should not count laps during manual workout mode
- Lap: marks lap completion in Manual mode
- Back: ends activity and opens summary

## Screen-by-screen specification

## 1. Main configuration screen
This should be a native Garmin menu.

### Purpose
Allow the user to configure the session quickly without layout problems.

### Items

- `1st lap time 02:00`
- `Mode  Manual`
- `Start workout`

### Behavior
- selecting `1st lap  02:00` opens a secondary menu for editing the first lap target
- selecting `Mode  Manual` opens a secondary menu for choosing lap mode
- selecting `Start workout` starts the activity immediately with the current settings

### Requirements
- the displayed first lap value must update after returning from its submenu
- the displayed mode must update after returning from its submenu
- no custom drawn setup screen is required if the native menu is clearer and more robust

## 2. First lap target submenu
This should also be a native Garmin menu.

### Purpose
Let the user increase or decrease the first lap target in 4 second steps.

### Items
- Title: `Select 1st lap time`
- `02:00` (value of 1st lap time, can be modified)

### Behavior
- selecting `up` button increases the first lap target by 4 seconds
- selecting `down` button decreases the first lap target by 4 seconds
- valid range for the first lap only: 2:00 to 4:00 (subsequent laps decrease without floor)
- selecting `Start` button returns to the main configuration screen and sets lap time to the one selected
- selecting `Back  button returns to the main configuration screen without modifying

### UX notes
- the current value should always be visible inside the submenu
- the user should not need custom drawn adjustment screens if native menu items work better

## 3. Mode submenu
This should also be a native Garmin menu.

### Purpose
Let the user choose how laps are completed.

### Items
- Title: `Select mode`
- `Manual`
- `GPS`

### Behavior
- selecting one of `Manual` or `GPS` updates the current mode and returns to the main configuration screen

### UX notes
- mode should be explicit and visible before workout start
- GPS mode should be clearly labeled so the runner understands lap completion is distance-based

## 4. Activity screen
This is the main in-workout screen.

### Priority order of information
The screen should prioritize information in this order:
1. current lap elapsed time
2. current lap target time
3. current lap number
4. one or two secondary metrics only
5. progress indicator

### Recommended layout
A robust minimal design is preferred over a dense one.

Suggested content:
- top line: `LAP 3  MANUAL`
- large center value: current lap elapsed time, e.g. `01:12`
- below that: `TARGET 01:56`
- lower area: one or two small lines such as:
  - `LAST PACE 4:15`
  - `DIST 276m`
- bottom: progress bar and quarter markers

### Manual mode behavior
- Lap button completes the lap
- Start does not complete laps
- Back ends the session and opens summary
- GPS distance, heart rate, and all available sensor data are still recorded throughout

### GPS mode behavior
- lap auto-completes at 400 m based on GPS distance
- GPS distance on tight track ovals may drift; runners on a track should prefer Manual mode

## 5. Quarter markers and progress
The app should show progress through the current lap.

### Expected behavior
- a main progress bar shows overall progress through the current lap
- quarter markers show the four quarter segments of the lap
- the visual state should make sense from the start of the lap:
  - past quarters
  - current quarter
  - future quarters

### Audio behavior
The metronome is a critical feature, not optional. It is the primary way the runner knows whether they are on pace during a lap.

Behavior:
- a metronome cue sounds at each quarter of the current target lap time (i.e. at the 100 m marks if the runner is exactly on pace)
- if the runner hears the cue before reaching the 100 m mark, they are behind pace and need to speed up
- if the runner reaches the 100 m mark before hearing the cue, they are ahead of pace
- a different cue sounds when the lap is completed

The visual quarter markers and the audio cues must be in sync — both are driven by elapsed time vs. target time.

If audio support proves fragile on specific devices, the visual logic should still remain correct, but audio should be implemented with best effort on all supported devices.

## 6. Summary screen
This appears after ending the workout.

### Purpose
Give a quick summary that is readable on-watch.

### Recommended content
- title: `SUMMARY`
- total number of laps
- last 3 laps at minimum

Each lap line should include:
- lap number
- lap time
- distance
- average pace

Example:
- `L3   01:52   400m  4:40`

### Additional data per lap (if layout allows)
- average heart rate per lap
- max heart rate per lap

### UX principle
Summary must stay readable and minimal. If too much data causes layout risk, show fewer fields on-watch and leave richer analysis for Garmin Connect.

## Data recording

The app must record a full FIT activity session using Connect IQ's `ActivityRecording` module. This is mandatory — workout data must survive after the app closes and sync to Garmin Connect.

### Required recorded data
- session start/stop
- lap markers with timestamps
- GPS position throughout (both modes)
- distance per lap
- heart rate (if sensor available)
- any other standard fields supported by the recording API

### Design principle
Record everything the device can provide. The on-watch summary shows a minimal view, but the full data should be available in Garmin Connect for post-session analysis.

## Confirmed implementation constraints found during prototyping

### 1. Native menus are much more reliable than custom drawn setup screens
Custom drawn setup screens repeatedly suffered from text overlap and layout instability on the Forerunner 970 simulator. Native Garmin menus were far more robust.

### 2. Connect IQ text rendering is fragile
Text drawn manually with `drawText()` can behave differently than expected because of font metrics, baseline behavior, and possible simulator/device differences.

Practical consequence:
- avoid dense stacks of manually positioned text
- prefer native menus wherever possible
- keep custom activity and summary views minimal

### 3. Manual mode must be the reference implementation
Manual mode is the clearest and most testable mode. GPS and Track should only be treated as complete once they are truly implemented and validated.

### 4. Configuration should be 100 percent native if needed
If custom configuration subviews introduce overlap or instability, replace them with native menus, even if they look less fancy.

### 5. CI build automation is blocked by Garmin login flow
A GitHub Actions workflow was attempted, but Garmin CLI login is unreliable due to account login flow issues and likely 2FA interaction. This should not be treated as a solved problem.

## Recommended implementation order for a clean rewrite

### Phase 1
- valid Connect IQ project
- native configuration menus
- manual mode only
- simple activity screen
- simple summary screen

### Phase 2
- quarter metronome sounds
- proper lap history formatting
- better progress visuals

### Phase 3
- reliable GPS 400 m auto-lap mode

## Non-goals for the first clean rewrite
- forcing all promised features into v1
- dense dashboards on-watch
- Track mode (removed — not feasible via Connect IQ SDK)
- complicated custom setup flows when native menus are better

## Final design recommendation
If there is ever a tradeoff between:
- looking more custom
- and behaving more like a robust Garmin app

the implementation should choose the more robust Garmin-like behavior.

## Local build and simulator commands

Use the helper script:

- build for default device (`fr970`):
  - `./scripts/ciq.sh build`
- build for a specific device:
  - `./scripts/ciq.sh build fenix5`
- build + run in simulator:
  - `./scripts/ciq.sh all fr970`

Notes:
- the script enables Java headless mode to avoid `Abort trap: 6` crashes seen
  with OpenJDK 25 during `monkeyc` and `monkeydo` runs
- it auto-detects the newest local Connect IQ SDK under
  `~/Library/Application Support/Garmin/ConnectIQ/Sdks`
- set `CIQ_DEV_KEY` if your developer key is not at
  `~/.garmin-keys/developer_key.der`
