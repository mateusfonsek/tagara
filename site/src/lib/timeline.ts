export type Phase = 'idle' | 'listening' | 'typing' | 'done';

export interface Step {
  scene: number;
  phase: Phase;
  /** ms from the start of the cycle */
  start: number;
  end: number;
}

/** Durations in ms. Listening grows with the sentence so the caption keeps a speaking pace. */
export const TIMING = {
  idle: 900,
  listenBase: 700,
  perWord: 260,
  typing: 650,
  done: 2600,
} as const;

/** One demo cycle: for each scene, idle → listening → typing → done. */
export function buildTimeline(wordCounts: readonly number[]): Step[] {
  const steps: Step[] = [];
  let time = 0;
  wordCounts.forEach((words, scene) => {
    const durations: [Phase, number][] = [
      ['idle', TIMING.idle],
      ['listening', TIMING.listenBase + words * TIMING.perWord],
      ['typing', TIMING.typing],
      ['done', TIMING.done],
    ];
    for (const [phase, ms] of durations) {
      steps.push({ scene, phase, start: time, end: time + ms });
      time += ms;
    }
  });
  return steps;
}

export function cycleLength(steps: readonly Step[]): number {
  return steps.length === 0 ? 0 : steps[steps.length - 1].end;
}

/** The step playing at `elapsed` ms (wrapping around the cycle) and how far into it, 0…1. */
export function stepAt(steps: readonly Step[], elapsed: number): { step: Step; progress: number } {
  const length = cycleLength(steps);
  if (length === 0) throw new Error('empty timeline');
  const time = ((elapsed % length) + length) % length;
  const step = steps.find((s) => time >= s.start && time < s.end) ?? steps[steps.length - 1];
  return { step, progress: (time - step.start) / (step.end - step.start) };
}

/** How many caption words have been said: one by one while listening, all of them after. */
export function spokenWords(phase: Phase, progress: number, total: number): number {
  if (phase === 'idle') return 0;
  if (phase !== 'listening') return total;
  return Math.min(total, Math.floor(progress * (total + 1)));
}
