import type { DiperTestData } from './types';

export interface LapMaxes {
  maxPace?: number; // seconds per km (lowest = fastest)
  maxHr?: number;
}

const INCOMPLETE_THRESHOLD_M = 395;

export function isIncompleteLap(distanceMeters: number): boolean {
  return distanceMeters < INCOMPLETE_THRESHOLD_M;
}

export function computeLapMaxes(data: DiperTestData): Map<number, LapMaxes> {
  const result = new Map<number, LapMaxes>();
  const points = data.trackPoints || [];
  let cumStart = 0;

  for (const lap of data.laps) {
    const cumEnd = cumStart + lap.distance;
    let maxHr = 0;
    let minPaceSec = Infinity;

    for (const p of points) {
      if (p.distance < cumStart || p.distance > cumEnd) continue;
      if (p.hr && p.hr > 0) maxHr = Math.max(maxHr, p.hr);
      if (p.pace && p.pace > 0 && p.pace < minPaceSec) minPaceSec = p.pace;
    }

    result.set(lap.lapNumber, {
      maxHr: maxHr > 0 ? maxHr : undefined,
      maxPace: minPaceSec === Infinity ? undefined : minPaceSec,
    });
    cumStart = cumEnd;
  }

  return result;
}
