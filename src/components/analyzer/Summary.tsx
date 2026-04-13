import React from 'react';
import type { StoredTest } from '../../lib/types';

export default function Summary({ test }: { test: StoredTest }) {
  const s = test.data.summary;
  const items: { label: string; value: string }[] = [
    { label: 'Fecha', value: new Date(s.testDate).toLocaleDateString('es-ES') },
    { label: 'Distancia', value: `${(s.totalDistance / 1000).toFixed(2)} km` },
    { label: 'Tiempo', value: s.totalTime },
    { label: 'Vueltas', value: String(test.data.laps.length) },
    { label: 'Ritmo medio', value: `${s.averagePace}/km` },
    { label: 'FC media', value: s.averagePpm > 0 ? `${s.averagePpm} ppm` : '—' },
    { label: 'FC máxima', value: s.maxPpm > 0 ? `${s.maxPpm} ppm` : '—' },
  ];

  return (
    <div className="grid grid-cols-2 gap-x-6 gap-y-4 sm:grid-cols-4 lg:grid-cols-7">
      {items.map((it) => (
        <div key={it.label}>
          <div className="text-xs uppercase tracking-wider text-ink/50">{it.label}</div>
          <div className="mt-1 font-display text-2xl tabular-nums">{it.value}</div>
        </div>
      ))}
    </div>
  );
}
