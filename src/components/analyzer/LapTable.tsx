import React, { useMemo } from 'react';
import type { StoredTest } from '../../lib/types';
import { formatPace } from '../../lib/gpxParser';
import { computeLapMaxes, isIncompleteLap } from '../../lib/lapStats';

export default function LapTable({ test }: { test: StoredTest }) {
  const maxes = useMemo(() => computeLapMaxes(test.data), [test]);
  const lastIdx = test.data.laps.length - 1;

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
          {test.data.laps.map((lap, idx) => {
            const incomplete = idx === lastIdx && isIncompleteLap(lap.distance);
            const lapMax = maxes.get(lap.lapNumber);
            const paceCell = incomplete
              ? lapMax?.maxPace
                ? `${formatPace(lapMax.maxPace)}/km (max)`
                : '—'
              : `${formatPace(lap.pace)}/km`;
            const hrCell = incomplete
              ? lapMax?.maxHr
                ? `${lapMax.maxHr} (max)`
                : '—'
              : lap.ppm > 0
                ? `${lap.ppm}`
                : '—';
            const rowCls = incomplete
              ? 'border-b border-ink/5 text-accent'
              : 'border-b border-ink/5 hover:bg-ink/5';
            return (
              <tr key={lap.lapNumber} className={rowCls} title={incomplete ? 'Vuelta incompleta (< 400 m)' : undefined}>
                <td className="py-2 pr-4 font-display text-base">{lap.lapNumber}</td>
                <td className="py-2 pr-4">{lap.distance} m</td>
                <td className="py-2 pr-4">{lap.time}</td>
                <td className="py-2 pr-4">{paceCell}</td>
                <td className="py-2">{hrCell}</td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}
