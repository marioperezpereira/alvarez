import type { StoredTest } from './types';

// Minimal subset for share (drop trackPoints to keep URL small)
export interface SharePayload {
  label: string;
  date: string;
  laps: StoredTest['data']['laps'];
  summary: StoredTest['data']['summary'];
}

function toBase64Url(input: string): string {
  const b64 = typeof btoa !== 'undefined' ? btoa(unescape(encodeURIComponent(input))) : Buffer.from(input, 'utf-8').toString('base64');
  return b64.replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function fromBase64Url(input: string): string {
  const b64 = input.replace(/-/g, '+').replace(/_/g, '/') + '==='.slice((input.length + 3) % 4);
  const raw = typeof atob !== 'undefined' ? atob(b64) : Buffer.from(b64, 'base64').toString('utf-8');
  try { return decodeURIComponent(escape(raw)); } catch { return raw; }
}

export function encodeShare(test: StoredTest): string {
  const payload: SharePayload = {
    label: test.label,
    date: test.date,
    laps: test.data.laps,
    summary: test.data.summary,
  };
  return toBase64Url(JSON.stringify(payload));
}

export function decodeShare(token: string): StoredTest | null {
  try {
    const json = fromBase64Url(token);
    const p = JSON.parse(json) as SharePayload;
    if (!p || !p.laps || !p.summary) return null;
    return {
      id: 'shared-' + Date.now(),
      label: p.label || 'Test compartido',
      date: p.date,
      data: { laps: p.laps, summary: p.summary, trackPoints: [] },
    };
  } catch {
    return null;
  }
}
