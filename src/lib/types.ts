export interface TrackPoint {
  time: string;
  lat: number;
  lon: number;
  ele: number;
  hr: number;
  distance: number;
  pace?: number;
}

export interface DiperLap {
  lapNumber: number;
  distance: number;
  time: string;
  pace: number; // seconds per km
  ppm: number;
  hr?: number;
}

export interface DiperSummary {
  totalDistance: number;
  totalTime: string;
  averagePpm: number;
  maxPpm: number;
  averagePace: string;
  testDate: string;
}

export interface DiperTestData {
  laps: DiperLap[];
  summary: DiperSummary;
  trackPoints: TrackPoint[];
}

export interface StoredTest {
  id: string;
  label: string;
  date: string;
  filename?: string;
  data: DiperTestData;
}
