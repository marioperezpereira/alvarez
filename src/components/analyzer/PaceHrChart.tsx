import React, { useMemo } from 'react';
import { CartesianGrid, Legend, Line, LineChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts';
import type { StoredTest } from '../../lib/types';
import { formatPace } from '../../lib/gpxParser';

export default function PaceHrChart({ test }: { test: StoredTest }) {
  const data = useMemo(
    () =>
      test.data.laps.map((l) => ({
        lap: l.lapNumber,
        pace: Math.round(l.pace),
        hr: l.ppm > 0 ? l.ppm : null,
      })),
    [test]
  );

  const paces = data.map((d) => d.pace).filter((n) => n > 0);
  const paceMin = Math.max(120, Math.min(...paces) - 10);
  const paceMax = Math.min(600, Math.max(...paces) + 10);

  return (
    <div className="h-72 md:h-96">
      <ResponsiveContainer width="100%" height="100%">
        <LineChart data={data} margin={{ top: 8, right: 24, left: 8, bottom: 8 }}>
          <CartesianGrid strokeDasharray="3 3" stroke="rgba(17,17,17,0.08)" />
          <XAxis
            dataKey="lap"
            tick={{ fill: 'rgba(17,17,17,0.6)', fontSize: 12 }}
            label={{ value: 'Vuelta', position: 'insideBottomRight', offset: -4, fill: 'rgba(17,17,17,0.6)', fontSize: 12 }}
          />
          <YAxis
            yAxisId="left"
            domain={[paceMax, paceMin]}
            tickFormatter={(v) => formatPace(Number(v))}
            tick={{ fill: 'rgba(17,17,17,0.6)', fontSize: 12 }}
            width={48}
          />
          <YAxis
            yAxisId="right"
            orientation="right"
            domain={['dataMin - 10', 'dataMax + 10']}
            tick={{ fill: 'rgba(17,17,17,0.6)', fontSize: 12 }}
            width={40}
          />
          <Tooltip
            contentStyle={{
              backgroundColor: '#faf7f2',
              border: '1px solid rgba(17,17,17,0.15)',
              borderRadius: 4,
              fontSize: 12,
            }}
            formatter={(value, name) => {
              if (name === 'Ritmo') return [`${formatPace(Number(value))}/km`, 'Ritmo'];
              if (name === 'FC') return [`${value} ppm`, 'FC'];
              return [value, name];
            }}
            labelFormatter={(l) => `Vuelta ${l}`}
          />
          <Legend wrapperStyle={{ fontSize: 12 }} />
          <Line
            yAxisId="left"
            type="monotone"
            dataKey="pace"
            name="Ritmo"
            stroke="#c0392b"
            strokeWidth={2}
            dot={{ r: 3 }}
            activeDot={{ r: 6 }}
            connectNulls
          />
          <Line
            yAxisId="right"
            type="monotone"
            dataKey="hr"
            name="FC"
            stroke="#111111"
            strokeWidth={1.5}
            strokeOpacity={0.6}
            dot={{ r: 2 }}
            connectNulls
          />
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
}
