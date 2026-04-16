import React, { useRef, useState } from 'react';
import { parseGpxData } from '../../lib/gpxParser';
import type { StoredTest } from '../../lib/types';

type Props = {
  onParsed: (test: StoredTest) => void;
};

export default function Upload({ onParsed }: Props) {
  const inputRef = useRef<HTMLInputElement>(null);
  const [dragging, setDragging] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function handleFile(file: File) {
    setError(null);
    const name = file.name.toLowerCase();
    if (!name.endsWith('.tcx') && !name.endsWith('.gpx')) {
      setError('Formato no soportado. Sube un archivo .tcx o .gpx.');
      return;
    }
    setLoading(true);
    try {
      const text = await file.text();
      const data = parseGpxData(text);
      if (!data.laps.length) {
        setError('No se han podido extraer vueltas del archivo.');
        return;
      }
      const test: StoredTest = {
        id: `t-${Date.now()}-${Math.random().toString(36).slice(2, 7)}`,
        label: file.name.replace(/\.(tcx|gpx)$/i, ''),
        date: data.summary.testDate,
        filename: file.name,
        data,
      };
      onParsed(test);
    } catch (err) {
      console.error(err);
      setError('Error al leer el archivo. ¿Es un TCX/GPX válido?');
    } finally {
      setLoading(false);
    }
  }

  async function loadSamples() {
    setError(null);
    setLoading(true);
    try {
      const base = import.meta.env.BASE_URL || '/';
      const samples = [
        { file: 'sample_diper_2.tcx', label: 'Test septiembre 2024' },
        { file: 'sample_diper.tcx', label: 'Test noviembre 2024' },
      ];
      for (const s of samples) {
        const res = await fetch(`${base}samples/${s.file}`);
        const text = await res.text();
        const data = parseGpxData(text);
        const test: StoredTest = {
          id: `t-${Date.now()}-${s.file.replace('.tcx', '')}`,
          label: s.label,
          date: data.summary.testDate,
          filename: s.file,
          data,
        };
        onParsed(test);
      }
    } catch {
      setError('No se pudieron cargar los ejemplos.');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <div
        onClick={() => inputRef.current?.click()}
        onDragOver={(e) => { e.preventDefault(); setDragging(true); }}
        onDragLeave={() => setDragging(false)}
        onDrop={(e) => {
          e.preventDefault();
          setDragging(false);
          const f = e.dataTransfer.files[0];
          if (f) handleFile(f);
        }}
        className={`cursor-pointer rounded border border-dashed px-8 py-12 text-center transition-colors ${
          dragging ? 'border-ink bg-ink/5' : 'border-ink/20 hover:border-ink/40'
        }`}
      >
        <div className="font-display text-2xl">
          {loading ? 'Leyendo archivo…' : 'Arrastra tu TCX o GPX'}
        </div>
        <div className="mt-2 text-sm text-ink/60">o pulsa aquí para seleccionarlo</div>
        <input
          ref={inputRef}
          type="file"
          accept=".tcx,.gpx"
          className="hidden"
          onChange={(e) => {
            const f = e.target.files?.[0];
            if (f) handleFile(f);
            e.target.value = '';
          }}
        />
      </div>
      <div className="mt-3 flex items-center justify-between text-sm">
        <button
          type="button"
          onClick={loadSamples}
          className="text-ink/60 underline-offset-4 hover:text-accent hover:underline"
        >
          Probar con dos tests de ejemplo
        </button>
        {error && <span className="text-accent">{error}</span>}
      </div>
    </div>
  );
}
