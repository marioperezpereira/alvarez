import React from 'react';
import type { StoredTest } from '../../lib/types';
import { formatPace } from '../../lib/gpxParser';

export default function LapTable({ test }: { test: StoredTest }) {
  return (
    <div className="overflow-x-auto">
      <table className="w-full border-collapse text-sm">
        <thead>
          <tr className="border-b border-ink/10 text-left text-xs uppercase tracking-wider text-ink/50">
            <th className="py-2 pr-4">Vuelta</th>
            <th className="py-2 pr-4">Distancia</th>
            <th className="py-2 pr-4">Tiempo</th>
            <th className="py-2 pr-4">Ritmo</th>
            <th className="py-2">FC</th>
          </tr>
        </thead>
        <tbody className="tabular-nums">
          {test.data.laps.map((lap) => (
            <tr key={lap.lapNumber} className="border-b border-ink/5 hover:bg-ink/5">
              <td className="py-2 pr-4 font-display text-base">{lap.lapNumber}</td>
              <td className="py-2 pr-4">{lap.distance} m</td>
              <td className="py-2 pr-4">{lap.time}</td>
              <td className="py-2 pr-4">{formatPace(lap.pace)}/km</td>
              <td className="py-2">{lap.ppm > 0 ? `${lap.ppm}` : '—'}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
