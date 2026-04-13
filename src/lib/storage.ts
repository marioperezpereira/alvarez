import type { StoredTest } from './types';

const KEY = 'diper.tests.v1';

export function loadTests(): StoredTest[] {
  if (typeof window === 'undefined') return [];
  try {
    const raw = window.localStorage.getItem(KEY);
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

export function saveTests(tests: StoredTest[]): void {
  if (typeof window === 'undefined') return;
  window.localStorage.setItem(KEY, JSON.stringify(tests));
}

export function addTest(test: StoredTest): StoredTest[] {
  const tests = loadTests();
  tests.push(test);
  saveTests(tests);
  return tests;
}

export function removeTest(id: string): StoredTest[] {
  const tests = loadTests().filter(t => t.id !== id);
  saveTests(tests);
  return tests;
}

export function updateTest(id: string, patch: Partial<StoredTest>): StoredTest[] {
  const tests = loadTests().map(t => (t.id === id ? { ...t, ...patch } : t));
  saveTests(tests);
  return tests;
}
