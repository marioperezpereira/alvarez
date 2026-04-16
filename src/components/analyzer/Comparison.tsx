import React, { useMemo } from 'react';
import { CartesianGrid, Legend, Line, LineChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts';
import type { StoredTest } from '../../lib/types';
import { formatPace } from '../../lib/gpxParser';
import { isIncompleteLap } from '../../lib/lapStats';

const COLORS = ['#ff701a', '#111111', '#1f6feb', '#16a34a', '#6d28d9'];

export default function Comparison({ tests, tolerance = 2 }: { tests: StoredTest[]; tolerance?: number }) {
  const { rows, tickVals } = useMemo(() => {
    const groups = new Map<number, Record<string, number>>();
    tests.forEach((t, idx) => {
      const laps = t.data.laps;
      const lastIdx = laps.length - 1;
      laps.forEach((lap, i) => {
        if (typeof lap.pace !== 'number' || lap.pace <= 0) return;
        // Skip the last lap if it's incomplete (failure partial lap)
        if (i === lastIdx && isIncompleteLap(lap.distance)) return;
        let key: number | null = null;
        for (const k of groups.keys()) {
          if (Math.abs(k - lap.pace) <= tolerance) { key = k; break; }
        }
        if (key === null) { key = lap.pace; groups.set(key, {}); }
        const g = groups.get(key)!;
        g[`hr_${idx}`] = lap.ppm;
      });
    });
    const rows = Array.from(groups.entries())
      .map(([pace, rec]) => ({ pace: Math.round(pace), ...rec }))
      .sort((a, b) => a.pace - b.pace);
    const ticks: number[] = [];
    if (rows.length) {
      const start = Math.floor(rows[0].pace / 20) * 20;
      const end = Math.ceil(rows[rows.length - 1].pace / 20) * 20;
      for (let p = start; p <= end; p += 20) ticks.push(p);
    }
    return { rows, tickVals: ticks };
  }, [tests, tolerance]);

  if (tests.length < 2) {
    return <p className="text-sm text-ink/60">Añade al menos dos tests para compararlos.</p>;
  }

  return (
    <div className="space-y-8">
      <div className="h-72 md:h-96">
        <ResponsiveContainer width="100%" height="100%">
          <LineChart data={rows} margin={{ top: 8, right: 24, left: 8, bottom: 8 }}>
            <CartesianGrid strokeDasharray="3 3" stroke="rgba(17,17,17,0.08)" />
            <XAxis
              dataKey="pace"
              tickFormatter={(v) => formatPace(Number(v))}
              ticks={tickVals}
              scale="linear"
              type="number"
              domain={['dataMin', 'dataMax']}
              reversed
              tick={{ fill: 'rgba(17,17,17,0.6)', fontSize: 12 }}
              label={{ value: 'Ritmo', position: 'insideBottomRight', offset: -4, fill: 'rgba(17,17,17,0.6)', fontSize: 12 }}
            />
            <YAxis
              domain={['dataMin - 10', 'dataMax + 10']}
              tick={{ fill: 'rgba(17,17,17,0.6)', fontSize: 12 }}
              width={48}
              label={{ value: 'FC (ppm)', angle: -90, position: 'insideLeft', fill: 'rgba(17,17,17,0.6)', fontSize: 12 }}
            />
            <Tooltip
              contentStyle={{ backgroundColor: '#faf7f2', border: '1px solid rgba(17,17,17,0.15)', borderRadius: 4, fontSize: 12 }}
              labelFormatter={(l) => `Ritmo ${formatPace(Number(l))}/km`}
              formatter={(v) => [`${v} ppm`, 'FC']}
            />
            <Legend wrapperStyle={{ fontSize: 12 }} />
            {tests.map((t, i) => (
              <Line
                key={t.id}
                type="monotone"
                dataKey={`hr_${i}`}
                name={t.label}
                stroke={COLORS[i % COLORS.length]}
                strokeWidth={2}
                dot={{ r: 3 }}
                activeDot={{ r: 6 }}
                connectNulls
              />
            ))}
          </LineChart>
        </ResponsiveContainer>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full border-collapse text-sm">
          <thead>
            <tr className="border-b border-ink/10 text-left text-xs uppercase tracking-wider text-ink/50">
              <th className="py-2 pr-4">Ritmo</th>
              {tests.map((t) => (
                <th key={t.id} className="py-2 pr-4 text-right">{t.label}</th>
              ))}
            </tr>
          </thead>
          <tbody className="tabular-nums">
            {rows.map((r, idx) => (
              <tr key={idx} className="border-b border-ink/5">
                <td className="py-2 pr-4 font-display">{formatPace(r.pace)}/km</td>
                {tests.map((_, i) => (
                  <td key={i} className="py-2 pr-4 text-right">{(r as any)[`hr_${i}`] ?? '—'}</td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
