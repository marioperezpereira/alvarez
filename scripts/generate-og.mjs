// Generate the Open Graph / Twitter card image for Test Álvarez.
// Output: public/og.png (1200x630)
//
// Design: Editorial split — "Test" / "Álvarez" stacked wordmark on the left
// in Fraunces; stylized stadium track floats to the right, bleeding off the
// canvas. Cream paper background, orange accent on "Álvarez" and the runner
// dot on the track.
//
// Run: node scripts/generate-og.mjs

import { readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';
import satori from 'satori';
import { Resvg } from '@resvg/resvg-js';

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = resolve(__dirname, '..');
const fontDir = resolve(__dirname, 'og-fonts');

const W = 1200;
const H = 630;

// Brand palette
const INK = '#111111';
const PAPER = '#faf7f2';
const ACCENT = '#ff701a';

// ---------------------------------------------------------------------------
// Track SVG — drawn as a background layer, positioned so it sits on the right
// half of the canvas with the right-hand curve bleeding off the edge.
// ---------------------------------------------------------------------------

const TRACK_CX = 1020; // center of the stadium (off-canvas right)
const TRACK_CY = H / 2;
const CURVE_R = 150;
const STRAIGHT_LEN = 360;
const LANE_W = 13;
const LANES = 6;

function stadiumPath(r) {
  const left = TRACK_CX - STRAIGHT_LEN / 2;
  const right = TRACK_CX + STRAIGHT_LEN / 2;
  const top = TRACK_CY - r;
  const bot = TRACK_CY + r;
  return [
    `M ${left} ${top}`,
    `L ${right} ${top}`,
    `A ${r} ${r} 0 0 1 ${right} ${bot}`,
    `L ${left} ${bot}`,
    `A ${r} ${r} 0 0 1 ${left} ${top}`,
    'Z',
  ].join(' ');
}

function buildTrackSvg() {
  const lanes = [];
  for (let i = 0; i < LANES; i++) {
    const r = CURVE_R + i * LANE_W;
    const edge = i === 0 || i === LANES - 1;
    lanes.push(
      `<path d="${stadiumPath(r)}" fill="none" stroke="${INK}" stroke-width="${edge ? 1.8 : 0.9}" opacity="${edge ? 0.3 : 0.13}" />`,
    );
  }

  // Subtle track surface
  const surface = `<path d="${stadiumPath(CURVE_R + ((LANES - 1) * LANE_W) / 2)}" fill="none" stroke="${INK}" stroke-width="${LANES * LANE_W}" opacity="0.04" />`;

  const leftX = TRACK_CX - STRAIGHT_LEN / 2;

  // Start/finish line
  const startY1 = TRACK_CY - (CURVE_R + (LANES - 1) * LANE_W + LANE_W / 2);
  const startY2 = TRACK_CY - (CURVE_R - LANE_W / 2);
  const start = `<line x1="${leftX}" y1="${startY1}" x2="${leftX}" y2="${startY2}" stroke="${INK}" stroke-width="2" opacity="0.4" />`;

  // Quarter markers (100m splits)
  const midR = CURVE_R + Math.floor((LANES - 1) / 2) * LANE_W;
  const rightX = TRACK_CX + STRAIGHT_LEN / 2;
  // 100m = bottom-left corner, 200m = bottom-right corner, 300m = top-right (off-canvas, skip)
  const qDots = [
    `<circle cx="${leftX}" cy="${TRACK_CY + midR}" r="4.5" fill="${INK}" opacity="0.25" />`,
    `<circle cx="${rightX}" cy="${TRACK_CY + midR}" r="4.5" fill="${INK}" opacity="0.25" />`,
  ].join('');

  // Runner dot — on top straight, positioned at ~30% of the way (nearer to the
  // start line so it reads as "about to enter the curve")
  const runnerLane = 2;
  const runnerR = CURVE_R + runnerLane * LANE_W;
  const runnerX = leftX + STRAIGHT_LEN * 0.28;
  const runnerY = TRACK_CY - runnerR;
  const pulses = [
    `<circle cx="${runnerX}" cy="${runnerY}" r="22" fill="none" stroke="${ACCENT}" stroke-width="2" opacity="0.22" />`,
    `<circle cx="${runnerX}" cy="${runnerY}" r="13" fill="none" stroke="${ACCENT}" stroke-width="2" opacity="0.45" />`,
    `<circle cx="${runnerX}" cy="${runnerY}" r="8" fill="${ACCENT}" />`,
  ].join('');

  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">
    ${surface}
    ${lanes.join('\n')}
    ${start}
    ${qDots}
    ${pulses}
  </svg>`;
}

const trackSvg = buildTrackSvg();
const trackDataUrl = `data:image/svg+xml;base64,${Buffer.from(trackSvg).toString('base64')}`;

// ---------------------------------------------------------------------------
// Fonts
// ---------------------------------------------------------------------------
const fraunces700 = readFileSync(resolve(fontDir, 'fraunces-bold.ttf'));
const fraunces600 = readFileSync(resolve(fontDir, 'fraunces-semibold.ttf'));
const inter400 = readFileSync(resolve(fontDir, 'inter-regular.ttf'));
const inter500 = readFileSync(resolve(fontDir, 'inter-medium.ttf'));
const inter600 = readFileSync(resolve(fontDir, 'inter-semibold.ttf'));

// ---------------------------------------------------------------------------
// Layout tree
// ---------------------------------------------------------------------------

const eyebrow = {
  type: 'div',
  props: {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 14,
      fontFamily: 'Inter',
      fontSize: 17,
      fontWeight: 600,
      letterSpacing: 3.5,
      color: 'rgba(17,17,17,0.55)',
      textTransform: 'uppercase',
    },
    children: [
      {
        type: 'div',
        props: {
          style: {
            width: 9,
            height: 9,
            borderRadius: 5,
            backgroundColor: ACCENT,
          },
        },
      },
      'Mide tu progreso como corredor',
    ],
  },
};

const wordmark = {
  type: 'div',
  props: {
    style: {
      display: 'flex',
      flexDirection: 'column',
      fontFamily: 'Fraunces',
      fontWeight: 700,
      fontSize: 180,
      lineHeight: 0.95,
      letterSpacing: -3,
      marginTop: 6,
    },
    children: [
      { type: 'div', props: { style: { display: 'flex' }, children: 'Test' } },
      {
        type: 'div',
        props: {
          style: { display: 'flex', color: ACCENT },
          children: 'Álvarez',
        },
      },
    ],
  },
};

const subtitle = {
  type: 'div',
  props: {
    style: {
      fontFamily: 'Fraunces',
      fontWeight: 600,
      fontSize: 28,
      marginTop: 26,
      color: 'rgba(17,17,17,0.78)',
      letterSpacing: -0.3,
      maxWidth: 620,
      lineHeight: 1.25,
      display: 'flex',
    },
    children:
      'Protocolo progresivo de 400 m. Mide tu VAM, tu umbral y tu condición aeróbica en un solo esfuerzo.',
  },
};

const metaStrip = {
  type: 'div',
  props: {
    style: {
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      fontFamily: 'Inter',
      fontSize: 15,
      fontWeight: 600,
      letterSpacing: 2.5,
      color: 'rgba(17,17,17,0.55)',
      textTransform: 'uppercase',
      borderTop: `1px solid rgba(17,17,17,0.14)`,
      paddingTop: 20,
    },
    children: [
      {
        type: 'div',
        props: {
          style: { display: 'flex', gap: 22, alignItems: 'center' },
          children: [
            { type: 'span', props: { children: '−4 s / vuelta' } },
            {
              type: 'span',
              props: {
                style: { color: 'rgba(17,17,17,0.25)' },
                children: '·',
              },
            },
            { type: 'span', props: { children: 'Sin pausas' } },
            {
              type: 'span',
              props: {
                style: { color: 'rgba(17,17,17,0.25)' },
                children: '·',
              },
            },
            { type: 'span', props: { children: 'Hasta el fallo' } },
          ],
        },
      },
      {
        type: 'div',
        props: {
          style: { display: 'flex', color: INK, fontWeight: 700 },
          children: 'alvarez.perezpereira.com',
        },
      },
    ],
  },
};

const node = {
  type: 'div',
  props: {
    style: {
      width: W,
      height: H,
      display: 'flex',
      flexDirection: 'column',
      justifyContent: 'space-between',
      backgroundColor: PAPER,
      color: INK,
      fontFamily: 'Inter',
      padding: '56px 72px',
      position: 'relative',
    },
    children: [
      // Background track (absolute, behind everything)
      {
        type: 'img',
        props: {
          src: trackDataUrl,
          width: W,
          height: H,
          style: { position: 'absolute', top: 0, left: 0 },
        },
      },
      // Top: eyebrow
      eyebrow,
      // Middle: wordmark + subtitle
      {
        type: 'div',
        props: {
          style: { display: 'flex', flexDirection: 'column' },
          children: [wordmark, subtitle],
        },
      },
      // Bottom: meta
      metaStrip,
    ],
  },
};

// ---------------------------------------------------------------------------
// Render
// ---------------------------------------------------------------------------

const svg = await satori(node, {
  width: W,
  height: H,
  fonts: [
    { name: 'Fraunces', data: fraunces700, weight: 700, style: 'normal' },
    { name: 'Fraunces', data: fraunces600, weight: 600, style: 'normal' },
    { name: 'Inter', data: inter400, weight: 400, style: 'normal' },
    { name: 'Inter', data: inter500, weight: 500, style: 'normal' },
    { name: 'Inter', data: inter600, weight: 600, style: 'normal' },
  ],
});

const resvg = new Resvg(svg, {
  fitTo: { mode: 'width', value: W },
  background: PAPER,
});
const png = resvg.render().asPng();
const outPath = resolve(root, 'public/og.png');
writeFileSync(outPath, png);
console.log(`Wrote ${outPath} (${png.length} bytes, ${W}×${H})`);
