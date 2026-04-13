import React, { useEffect, useState } from 'react';
import Upload from './Upload';
import Summary from './Summary';
import LapTable from './LapTable';
import PaceHrChart from './PaceHrChart';
import Comparison from './Comparison';
import type { StoredTest } from '../../lib/types';
import { addTest, loadTests, removeTest, updateTest } from '../../lib/storage';
import { decodeShare, encodeShare } from '../../lib/share';

export default function AnalyzerApp() {
  const [tests, setTests] = useState<StoredTest[]>([]);
  const [activeId, setActiveId] = useState<string | null>(null);
  const [compareMode, setCompareMode] = useState(false);
  const [selectedIds, setSelectedIds] = useState<string[]>([]);
  const [shareUrl, setShareUrl] = useState<string | null>(null);
  const [sharedOnly, setSharedOnly] = useState(false);

  // Hydrate from localStorage + URL ?t=
  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    const token = params.get('t');
    if (token) {
      const shared = decodeShare(token);
      if (shared) {
        setTests([shared]);
        setActiveId(shared.id);
        setSharedOnly(true);
        return;
      }
    }
    const loaded = loadTests();
    setTests(loaded);
    if (loaded.length) setActiveId(loaded[loaded.length - 1].id);
  }, []);

  function handleParsed(t: StoredTest) {
    if (sharedOnly) {
      setTests([t]);
      setActiveId(t.id);
      return;
    }
    const next = addTest(t);
    setTests(next);
    setActiveId(t.id);
    setShareUrl(null);
  }

  function handleDelete(id: string) {
    const next = removeTest(id);
    setTests(next);
    if (activeId === id) setActiveId(next.length ? next[next.length - 1].id : null);
    setSelectedIds((ids) => ids.filter((x) => x !== id));
  }

  function handleRename(id: string, label: string) {
    const next = updateTest(id, { label });
    setTests(next);
  }

  function toggleSelect(id: string) {
    setSelectedIds((ids) =>
      ids.includes(id) ? ids.filter((x) => x !== id) : [...ids, id].slice(-5)
    );
  }

  function buildShare(test: StoredTest) {
    const base = import.meta.env.BASE_URL || '/';
    const token = encodeShare(test);
    const url = `${window.location.origin}${base}analizador/?t=${token}`;
    setShareUrl(url);
    if (navigator.clipboard) navigator.clipboard.writeText(url).catch(() => {});
  }

  const active = tests.find((t) => t.id === activeId) || null;
  const comparisonTests = tests.filter((t) => selectedIds.includes(t.id));

  return (
    <div className="space-y-12">
      {sharedOnly && (
        <div className="rounded border border-ink/10 bg-white/60 p-4 text-sm">
          Estás viendo un test compartido. Para analizar los tuyos,{' '}
          <a href="./" className="underline">limpia la URL</a>.
        </div>
      )}

      {!sharedOnly && <Upload onParsed={handleParsed} />}

      {tests.length > 0 && (
        <section>
          <header className="mb-4 flex items-baseline justify-between gap-4">
            <h2 className="font-display text-2xl">Tus tests</h2>
            <div className="flex gap-4 text-sm">
              <button
                onClick={() => { setCompareMode(false); setSelectedIds([]); }}
                className={`${!compareMode ? 'text-ink' : 'text-ink/50 hover:text-ink'}`}
              >
                Analizar
              </button>
              {!sharedOnly && tests.length >= 2 && (
                <button
                  onClick={() => setCompareMode(true)}
                  className={`${compareMode ? 'text-ink' : 'text-ink/50 hover:text-ink'}`}
                >
                  Comparar
                </button>
              )}
            </div>
          </header>

          <ul className="divide-y divide-ink/10 border-y border-ink/10">
            {tests.map((t) => (
              <li key={t.id} className="flex items-center gap-3 py-2 text-sm">
                {compareMode ? (
                  <input
                    type="checkbox"
                    checked={selectedIds.includes(t.id)}
                    onChange={() => toggleSelect(t.id)}
                    className="accent-accent"
                  />
                ) : (
                  <input
                    type="radio"
                    name="active"
                    checked={activeId === t.id}
                    onChange={() => setActiveId(t.id)}
                    className="accent-accent"
                  />
                )}
                <input
                  value={t.label}
                  onChange={(e) => handleRename(t.id, e.target.value)}
                  className="flex-1 bg-transparent font-display text-lg outline-none focus:border-b focus:border-ink/30"
                />
                <span className="tabular-nums text-ink/50">
                  {new Date(t.date).toLocaleDateString('es-ES')}
                </span>
                <span className="tabular-nums text-ink/50">{t.data.laps.length} vueltas</span>
                {!sharedOnly && (
                  <>
                    <button onClick={() => buildShare(t)} className="text-ink/50 hover:text-accent">
                      Compartir
                    </button>
                    <button onClick={() => handleDelete(t.id)} className="text-ink/50 hover:text-accent">
                      Eliminar
                    </button>
                  </>
                )}
              </li>
            ))}
          </ul>

          {shareUrl && (
            <div className="mt-3 break-all rounded bg-ink/5 p-3 text-xs text-ink/70">
              URL copiada: {shareUrl}
            </div>
          )}
        </section>
      )}

      {!compareMode && active && (
        <section className="space-y-8">
          <Summary test={active} />
          <PaceHrChart test={active} />
          <LapTable test={active} />
        </section>
      )}

      {compareMode && (
        <section>
          {comparisonTests.length < 2 ? (
            <p className="text-sm text-ink/60">
              Selecciona 2 o más tests (máx. 5) para compararlos por ritmo.
            </p>
          ) : (
            <Comparison tests={comparisonTests} />
          )}
        </section>
      )}
    </div>
  );
}
