import { useRef, useState, useEffect, useCallback } from 'react';

// --- Config ---
const FIRST_LAP_SEC = 140; // 2:20
const DEC_SEC = 4;
const TOTAL_LAPS = 12;
const COMPRESSION = 20;
const PAUSE_BETWEEN_LOOPS_MS = 3000;
const PULSE_DURATION_MS = 500;

// Colors
const INK = '#111111';
const ACCENT = '#ff701a';

// --- Track geometry (stadium shape) ---
const VB_W = 700;
const VB_H = 340;
const CY = VB_H / 2;
const STRAIGHT_LEN = 200;
const CURVE_R = 90;
const LANES = 6;
const LANE_W = 7;

const LEFT_X = VB_W / 2 - STRAIGHT_LEN / 2;
const RIGHT_X = VB_W / 2 + STRAIGHT_LEN / 2;

// Perimeter fractions
const PERIMETER = 2 * STRAIGHT_LEN + 2 * Math.PI * CURVE_R;
const STRAIGHT_FRAC = STRAIGHT_LEN / PERIMETER;
const CURVE_FRAC = (Math.PI * CURVE_R) / PERIMETER;

// Start/finish line Y extents on the top straight (spans all lanes)
const LINE_Y_INNER = CY - (CURVE_R - LANE_W / 2);
const LINE_Y_OUTER = CY - (CURVE_R + (LANES - 1) * LANE_W + LANE_W / 2);

/**
 * Build SVG path for a single lane of the stadium track.
 */
function lanePath(lane: number): string {
  const offset = lane * LANE_W;
  const r = CURVE_R + offset;
  const topY = CY - r;
  const botY = CY + r;
  return [
    `M ${LEFT_X} ${topY}`,
    `L ${RIGHT_X} ${topY}`,
    `A ${r} ${r} 0 0 1 ${RIGHT_X} ${botY}`,
    `L ${LEFT_X} ${botY}`,
    `A ${r} ${r} 0 0 1 ${LEFT_X} ${topY}`,
    'Z',
  ].join(' ');
}

/**
 * Get (x, y) on lane-1 center for parameter t ∈ [0, 1).
 *
 * COUNTER-CLOCKWISE direction (real athletics).
 * t=0 at LEFT_X on top straight (start/finish line).
 *
 * Segments (CCW from LEFT_X):
 *   1. Left semicircle: top → bottom (centered at LEFT_X, CY)
 *   2. Bottom straight: LEFT_X → RIGHT_X (left to right)
 *   3. Right semicircle: bottom → top (centered at RIGHT_X, CY)
 *   4. Top straight: RIGHT_X → LEFT_X (right to left, home straight)
 */
const SEG1 = CURVE_FRAC; // end of left curve
const SEG2 = SEG1 + STRAIGHT_FRAC; // end of bottom straight
const SEG3 = SEG2 + CURVE_FRAC; // end of right curve
// SEG4 = 1.0 (end of top straight / home straight)

function trackPoint(t: number): { x: number; y: number } {
  const tt = ((t % 1) + 1) % 1;

  if (tt < SEG1) {
    // Left semicircle: centered at (LEFT_X, CY), from top going down (CCW)
    const frac = tt / CURVE_FRAC;
    const angle = -Math.PI / 2 - frac * Math.PI;
    return {
      x: LEFT_X + CURVE_R * Math.cos(angle),
      y: CY + CURVE_R * Math.sin(angle),
    };
  }

  if (tt < SEG2) {
    // Bottom straight: left → right
    const frac = (tt - SEG1) / STRAIGHT_FRAC;
    return { x: LEFT_X + frac * STRAIGHT_LEN, y: CY + CURVE_R };
  }

  if (tt < SEG3) {
    // Right semicircle: centered at (RIGHT_X, CY), from bottom going up (CCW)
    const frac = (tt - SEG2) / CURVE_FRAC;
    const angle = Math.PI / 2 - frac * Math.PI;
    return {
      x: RIGHT_X + CURVE_R * Math.cos(angle),
      y: CY + CURVE_R * Math.sin(angle),
    };
  }

  // Top straight (home straight): right → left
  const frac = (tt - SEG3) / (1 - SEG3);
  return { x: RIGHT_X - frac * STRAIGHT_LEN, y: CY - CURVE_R };
}

// Quarter positions: 0m, 100m, 200m, 300m
const QUARTER_T = [0, 0.25, 0.5, 0.75];
const QUARTER_POS = QUARTER_T.map(trackPoint);

function formatPace(sec: number): string {
  const pace = (sec / 400) * 1000;
  const m = Math.floor(pace / 60);
  const s = Math.round(pace % 60);
  return `${m}:${s.toString().padStart(2, '0')}/km`;
}

interface PulseState {
  idx: number;
  born: number;
}

export default function TrackAnimation() {
  const containerRef = useRef<HTMLDivElement>(null);
  const rafRef = useRef<number>(0);
  const startTimeRef = useRef<number>(0);
  const visibleRef = useRef(false);
  const nowRef = useRef(0);

  const [targetSec, setTargetSec] = useState(FIRST_LAP_SEC);
  const [dotPos, setDotPos] = useState(trackPoint(0));
  const [pulses, setPulses] = useState<PulseState[]>([]);
  const [renderTime, setRenderTime] = useState(0);

  const stateRef = useRef({
    lap: 1,
    lastQuarter: -1,
    done: false,
    doneAt: 0,
  });

  const lapDuration = useCallback((lap: number) => {
    const realSec = FIRST_LAP_SEC - (lap - 1) * DEC_SEC;
    return (realSec / COMPRESSION) * 1000;
  }, []);

  const reset = useCallback(() => {
    stateRef.current = { lap: 1, lastQuarter: -1, done: false, doneAt: 0 };
    setTargetSec(FIRST_LAP_SEC);
    setDotPos(trackPoint(0));
    setPulses([]);
    startTimeRef.current = 0;
  }, []);

  const animate = useCallback(
    (now: number) => {
      nowRef.current = now;

      if (!visibleRef.current) {
        startTimeRef.current = 0;
        rafRef.current = requestAnimationFrame(animate);
        return;
      }
      if (startTimeRef.current === 0) startTimeRef.current = now;
      const st = stateRef.current;

      if (st.done) {
        if (now - st.doneAt > PAUSE_BETWEEN_LOOPS_MS) {
          reset();
          startTimeRef.current = now;
        }
        rafRef.current = requestAnimationFrame(animate);
        return;
      }

      const elapsed = now - startTimeRef.current;
      let timeAccum = 0;
      let currentLap = 1;
      let fraction = 0;

      for (let l = 1; l <= TOTAL_LAPS; l++) {
        const dur = lapDuration(l);
        if (elapsed < timeAccum + dur) {
          currentLap = l;
          fraction = (elapsed - timeAccum) / dur;
          break;
        }
        timeAccum += dur;
        if (l === TOTAL_LAPS) {
          st.done = true;
          st.doneAt = now;
          setDotPos(trackPoint(0));
          rafRef.current = requestAnimationFrame(animate);
          return;
        }
      }

      setDotPos(trackPoint(fraction));
      setRenderTime(now); // trigger re-render for pulse animation

      if (currentLap !== st.lap) {
        st.lap = currentLap;
        st.lastQuarter = -1;
        setTargetSec(FIRST_LAP_SEC - (currentLap - 1) * DEC_SEC);
      }

      // Quarter detection — fire pulse each time the runner crosses a 100m mark
      const quarter = Math.floor(fraction * 4);
      if (quarter !== st.lastQuarter) {
        st.lastQuarter = quarter;
        setPulses((prev) => [
          ...prev.filter((p) => now - p.born < PULSE_DURATION_MS),
          { idx: quarter, born: now },
        ]);
      }

      rafRef.current = requestAnimationFrame(animate);
    },
    [lapDuration, reset],
  );

  useEffect(() => {
    const mq = window.matchMedia('(prefers-reduced-motion: reduce)');
    if (mq.matches) return;

    const obs = new IntersectionObserver(
      ([entry]) => {
        visibleRef.current = entry.isIntersecting;
      },
      { threshold: 0.1 },
    );
    if (containerRef.current) obs.observe(containerRef.current);

    rafRef.current = requestAnimationFrame(animate);

    return () => {
      cancelAnimationFrame(rafRef.current);
      obs.disconnect();
    };
  }, [animate]);

  // Compute pulse visuals from JS (no SVG animate)
  const activePulses = pulses
    .map((p) => {
      const age = renderTime - p.born;
      if (age < 0 || age > PULSE_DURATION_MS) return null;
      const progress = age / PULSE_DURATION_MS; // 0 → 1
      return {
        ...p,
        r: 4 + progress * 20,
        opacity: 0.8 * (1 - progress),
      };
    })
    .filter(Boolean) as (PulseState & { r: number; opacity: number })[];

  return (
    <div ref={containerRef} className="mx-auto max-w-3xl">
      <svg
        viewBox={`0 0 ${VB_W} ${VB_H}`}
        width="100%"
        role="img"
        aria-label="Animación del protocolo: un punto recorre una pista de atletismo acelerando cada vuelta"
      >
        {/* Track surface — centered across all lanes */}
        <path
          d={lanePath((LANES - 1) / 2)}
          fill="none"
          stroke={INK}
          strokeWidth={LANES * LANE_W}
          opacity={0.04}
        />

        {/* Lane lines */}
        {Array.from({ length: LANES + 1 }, (_, i) => {
          const offset = i * LANE_W - LANE_W / 2;
          const r = CURVE_R + offset;
          const topY = CY - r;
          const botY = CY + r;
          const path = [
            `M ${LEFT_X} ${topY}`,
            `L ${RIGHT_X} ${topY}`,
            `A ${r} ${r} 0 0 1 ${RIGHT_X} ${botY}`,
            `L ${LEFT_X} ${botY}`,
            `A ${r} ${r} 0 0 1 ${LEFT_X} ${topY}`,
            'Z',
          ].join(' ');
          return (
            <path
              key={`lane-${i}`}
              d={path}
              fill="none"
              stroke={INK}
              strokeWidth={i === 0 || i === LANES ? 1.2 : 0.5}
              opacity={i === 0 || i === LANES ? 0.2 : 0.1}
            />
          );
        })}

        {/* Start/finish line at LEFT_X — spans all lanes */}
        <line
          x1={LEFT_X}
          y1={LINE_Y_OUTER}
          x2={LEFT_X}
          y2={LINE_Y_INNER}
          stroke={INK}
          strokeWidth={1.5}
          opacity={0.3}
        />

        {/* Quarter markers (100m marks) */}
        {QUARTER_POS.map((p, i) => (
          <circle key={`qm-${i}`} cx={p.x} cy={p.y} r={3} fill={INK} opacity={0.15} />
        ))}

        {/* Metronome pulses — JS-driven animation */}
        {activePulses.map((pulse) => {
          const p = QUARTER_POS[pulse.idx];
          return (
            <circle
              key={`pulse-${pulse.idx}-${pulse.born}`}
              cx={p.x}
              cy={p.y}
              r={pulse.r}
              fill="none"
              stroke={ACCENT}
              strokeWidth={2}
              opacity={pulse.opacity}
            />
          );
        })}

        {/* Runner dot */}
        <circle cx={dotPos.x} cy={dotPos.y} r={5} fill={ACCENT} />

        {/* Pace label floating above the dot */}
        <g style={{ pointerEvents: 'none' }}>
          <rect
            x={dotPos.x - 30}
            y={dotPos.y - 28}
            width={60}
            height={18}
            rx={9}
            fill="white"
            opacity={0.85}
          />
          <text
            x={dotPos.x}
            y={dotPos.y - 15.5}
            textAnchor="middle"
            fontFamily="'Inter Variable', system-ui, sans-serif"
            fontSize={10.5}
            fontWeight={500}
            fill={INK}
            opacity={0.7}
            style={{ fontVariantNumeric: 'tabular-nums' }}
          >
            {formatPace(targetSec)}
          </text>
        </g>

        {/* Center: subtle rule reminder */}
        <text
          x={VB_W / 2}
          y={CY + 5}
          textAnchor="middle"
          fontFamily="'Inter Variable', system-ui, sans-serif"
          fontSize={22}
          fill={INK}
          opacity={0.12}
          style={{ fontVariantNumeric: 'tabular-nums' }}
        >
          {`−${DEC_SEC}s / vuelta`}
        </text>
      </svg>
    </div>
  );
}
