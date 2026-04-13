import type { DiperTestData, DiperLap, DiperSummary, TrackPoint } from './types';

export const parseGpxData = (content: string): DiperTestData => {
  const parser = new DOMParser();
  const xmlDoc = parser.parseFromString(content, 'text/xml');

  const isTcxFile = xmlDoc.getElementsByTagName('TrainingCenterDatabase').length > 0;
  let testDate = new Date();

  if (isTcxFile) {
    const activities = xmlDoc.getElementsByTagName('Activity');
    if (activities.length > 0) {
      const idEl = activities[0].getElementsByTagName('Id')[0];
      if (idEl?.textContent) testDate = new Date(idEl.textContent);
    }
  } else {
    const metadata = xmlDoc.getElementsByTagName('metadata')[0];
    if (metadata) {
      const timeEl = metadata.getElementsByTagName('time')[0];
      if (timeEl?.textContent) testDate = new Date(timeEl.textContent);
    }
  }

  const trackPoints: TrackPoint[] = [];
  let totalDistance = 0;
  let prevLat: number | null = null;
  let prevLon: number | null = null;
  let totalPpm = 0;
  let maxPpm = 0;
  let ppmCount = 0;
  const paceValues: number[] = [];

  if (isTcxFile) {
    const tpEls = xmlDoc.getElementsByTagName('Trackpoint');
    for (let i = 0; i < tpEls.length; i++) {
      const tp = tpEls[i];
      const timeEl = tp.getElementsByTagName('Time')[0];
      const time = timeEl?.textContent || new Date().toISOString();

      const posEl = tp.getElementsByTagName('Position')[0];
      let lat = 0, lon = 0;
      if (posEl) {
        lat = parseFloat(posEl.getElementsByTagName('LatitudeDegrees')[0]?.textContent || '0');
        lon = parseFloat(posEl.getElementsByTagName('LongitudeDegrees')[0]?.textContent || '0');
      }

      const ele = parseFloat(tp.getElementsByTagName('AltitudeMeters')[0]?.textContent || '0');

      let hr = 0;
      const hrEl = tp.getElementsByTagName('HeartRateBpm')[0];
      if (hrEl) {
        hr = parseInt(hrEl.getElementsByTagName('Value')[0]?.textContent || '0', 10);
      }

      let pointDistance = 0;
      const distEl = tp.getElementsByTagName('DistanceMeters')[0];
      if (distEl?.textContent) {
        const d = parseFloat(distEl.textContent);
        pointDistance = i > 0 ? d - totalDistance : 0;
        totalDistance = d;
      } else if (prevLat !== null && prevLon !== null) {
        pointDistance = calculateDistance(prevLat, prevLon, lat, lon);
        totalDistance += pointDistance;
      }

      let pace = 0;
      if (i > 0 && pointDistance > 0) {
        const prev = new Date(trackPoints[i - 1].time).getTime();
        const curr = new Date(time).getTime();
        const dt = (curr - prev) / 1000;
        if (dt > 0) {
          pace = dt / (pointDistance / 1000);
          if (pace >= 120 && pace <= 900) paceValues.push(pace);
        }
      }

      prevLat = lat;
      prevLon = lon;

      if (hr > 0) {
        totalPpm += hr;
        ppmCount++;
        maxPpm = Math.max(maxPpm, hr);
      }

      trackPoints.push({ time, lat, lon, ele, hr, distance: totalDistance, pace: pace > 0 ? pace : undefined });
    }
  } else {
    const trkpts = xmlDoc.getElementsByTagName('trkpt');
    for (let i = 0; i < trkpts.length; i++) {
      const p = trkpts[i];
      const lat = parseFloat(p.getAttribute('lat') || '0');
      const lon = parseFloat(p.getAttribute('lon') || '0');
      const ele = parseFloat(p.getElementsByTagName('ele')[0]?.textContent || '0');

      let hr = 0;
      const ext = p.getElementsByTagName('extensions')[0];
      if (ext) {
        const hrEl =
          ext.getElementsByTagName('gpxtpx:hr')[0] ||
          ext.getElementsByTagName('hr')[0] ||
          ext.querySelector('*|hr');
        if (hrEl?.textContent) hr = parseInt(hrEl.textContent, 10);
      }
      if (hr === 0) {
        const direct = p.getElementsByTagName('hr')[0];
        if (direct?.textContent) hr = parseInt(direct.textContent, 10);
      }

      const timeEl = p.getElementsByTagName('time')[0];
      const time = timeEl?.textContent || new Date().toISOString();

      let pointDistance = 0;
      let pace = 0;
      if (prevLat !== null && prevLon !== null) {
        pointDistance = calculateDistance(prevLat, prevLon, lat, lon);
        totalDistance += pointDistance;
        if (i > 0 && trackPoints[i - 1].time) {
          const dt = (new Date(time).getTime() - new Date(trackPoints[i - 1].time).getTime()) / 1000;
          if (dt > 0 && pointDistance > 0) {
            pace = dt / (pointDistance / 1000);
            paceValues.push(pace);
          }
        }
      }

      prevLat = lat;
      prevLon = lon;

      if (hr > 0) {
        totalPpm += hr;
        ppmCount++;
        maxPpm = Math.max(maxPpm, hr);
      }

      trackPoints.push({ time, lat, lon, ele, hr, distance: totalDistance, pace: pace > 0 ? pace : undefined });
    }
  }

  // Laps
  let laps: DiperLap[] = [];
  const lapTag = isTcxFile ? 'Lap' : 'lap';
  const lapEls = xmlDoc.getElementsByTagName(lapTag);

  if (lapEls && lapEls.length > 0) {
    for (let i = 0; i < lapEls.length; i++) {
      const lap = lapEls[i];
      const distance = parseFloat(
        lap.getElementsByTagName(isTcxFile ? 'DistanceMeters' : 'distance')[0]?.textContent || '0'
      );
      const rawTime =
        lap.getElementsByTagName(isTcxFile ? 'TotalTimeSeconds' : 'totalTime')[0]?.textContent ||
        lap.getElementsByTagName('time')[0]?.textContent ||
        '0';
      const totalTimeSec = parseFloat(rawTime);

      let avgHr = 0;
      const hrEl = lap.getElementsByTagName(isTcxFile ? 'AverageHeartRateBpm' : 'avghr')[0];
      if (hrEl) {
        if (isTcxFile) {
          avgHr = parseInt(hrEl.getElementsByTagName('Value')[0]?.textContent || '0', 10);
        } else {
          avgHr = parseInt(hrEl.textContent || '0', 10);
        }
      }

      const lapTime = formatTime(totalTimeSec * 1000);
      const paceSeconds = distance > 0 ? totalTimeSec / (distance / 1000) : 0;

      laps.push({
        lapNumber: i + 1,
        distance: Math.round(distance),
        time: lapTime,
        pace: paceSeconds,
        ppm: avgHr || estimateLapPpm(trackPoints, i),
      });
    }
  } else {
    laps = generateDefaultLaps(trackPoints);
  }

  const filtered = paceValues.filter(p => p >= 180 && p <= 600);
  const avgPaceSeconds = filtered.length > 0 ? filtered.reduce((s, p) => s + p, 0) / filtered.length : 300;

  const firstT = trackPoints[0]?.time;
  const lastT = trackPoints[trackPoints.length - 1]?.time;
  const totalTimeMs = firstT && lastT ? new Date(lastT).getTime() - new Date(firstT).getTime() : 0;

  const summary: DiperSummary = {
    totalDistance: Math.round(totalDistance),
    totalTime: formatTime(totalTimeMs),
    averagePpm: ppmCount > 0 ? Math.round(totalPpm / ppmCount) : 0,
    maxPpm,
    averagePace: formatPaceToString(avgPaceSeconds * 1000, 1000),
    testDate: testDate.toISOString().split('T')[0],
  };

  return { laps, summary, trackPoints };
};

const estimateLapPpm = (trackPoints: TrackPoint[], lapIndex: number): number => {
  if (trackPoints.length === 0) return 0;
  const pointsPerLap = Math.ceil(trackPoints.length / (lapIndex + 1));
  const startIdx = Math.min(lapIndex * pointsPerLap, trackPoints.length - 1);
  const endIdx = Math.min((lapIndex + 1) * pointsPerLap, trackPoints.length);
  let total = 0, count = 0;
  for (let i = startIdx; i < endIdx; i++) {
    if (trackPoints[i].hr > 0) { total += trackPoints[i].hr; count++; }
  }
  return count > 0 ? Math.round(total / count) : 0;
};

const generateDefaultLaps = (trackPoints: TrackPoint[]): DiperLap[] => {
  const laps: DiperLap[] = [];
  const lapDistance = 400;
  let curDist = 0, curTime = 0, curPpm = 0, curPpmCount = 0;

  trackPoints.forEach((point, index) => {
    if (index === 0) return;
    const prev = trackPoints[index - 1];
    const pd = point.distance - prev.distance;
    const dt = new Date(point.time).getTime() - new Date(prev.time).getTime();
    curDist += pd;
    curTime += dt;
    if (point.hr > 0) { curPpm += point.hr; curPpmCount++; }

    if (curDist >= lapDistance || index === trackPoints.length - 1) {
      const lapTime = formatTime(curTime);
      const paceSeconds = curDist > 0 ? curTime / 1000 / (curDist / 1000) : 0;
      const avgPpm = curPpmCount > 0 ? Math.round(curPpm / curPpmCount) : 0;
      laps.push({
        lapNumber: laps.length + 1,
        distance: Math.round(curDist),
        time: lapTime,
        pace: paceSeconds,
        ppm: avgPpm,
      });
      curDist = 0; curTime = 0; curPpm = 0; curPpmCount = 0;
    }
  });

  return laps;
};

export const calculateDistance = (lat1: number, lon1: number, lat2: number, lon2: number): number => {
  const R = 6371e3;
  const φ1 = (lat1 * Math.PI) / 180;
  const φ2 = (lat2 * Math.PI) / 180;
  const Δφ = ((lat2 - lat1) * Math.PI) / 180;
  const Δλ = ((lon2 - lon1) * Math.PI) / 180;
  const a = Math.sin(Δφ / 2) ** 2 + Math.cos(φ1) * Math.cos(φ2) * Math.sin(Δλ / 2) ** 2;
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
};

export const formatTime = (ms: number): string => {
  const minutes = Math.floor(ms / 60000);
  const seconds = Math.floor((ms % 60000) / 1000);
  return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
};

export const formatPace = (paceSec: number): string => {
  if (!paceSec || paceSec <= 0) return '—';
  const m = Math.floor(paceSec / 60);
  const s = Math.floor(paceSec % 60);
  return `${m}:${s.toString().padStart(2, '0')}`;
};

export const formatPaceToString = (ms: number, distMeters: number): string => {
  if (distMeters <= 0 || ms <= 0) return '00:00';
  const paceSec = ms / 1000 / (distMeters / 1000);
  return formatPace(paceSec);
};
