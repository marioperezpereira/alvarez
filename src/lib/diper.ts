// Protocol calculations for the Test Álvarez.
// Each lap is 400 m; each lap's target is 4 s faster than the previous.

export function lapTargetSeconds(firstLapSec: number, lapNumber: number): number {
  return firstLapSec - (lapNumber - 1) * 4;
}

export function lapPaceSecPerKm(lapTargetSec: number): number {
  // 400 m lap → seconds/km = lap time × 2.5
  return lapTargetSec * 2.5;
}

export function formatMSS(totalSec: number): string {
  if (totalSec < 0) totalSec = 0;
  const m = Math.floor(totalSec / 60);
  const s = Math.floor(totalSec % 60);
  return `${m}:${s.toString().padStart(2, '0')}`;
}

export function lapsUntilFailure(firstLapSec: number, minLapSec = 60): number {
  // How many laps can theoretically be run before hitting an impossibly fast target
  return Math.floor((firstLapSec - minLapSec) / 4) + 1;
}
