import { describe, expect, it } from 'vitest';
import { TIMING, buildTimeline, cycleLength, spokenWords, stepAt } from './timeline';

describe('buildTimeline', () => {
  const steps = buildTimeline([2, 5]);

  it('plays idle, listening, typing and done for each scene, in order', () => {
    expect(steps.map((s) => `${s.scene}:${s.phase}`)).toEqual([
      '0:idle', '0:listening', '0:typing', '0:done',
      '1:idle', '1:listening', '1:typing', '1:done',
    ]);
  });

  it('has no gaps between steps and starts at zero', () => {
    expect(steps[0].start).toBe(0);
    for (let i = 1; i < steps.length; i++) expect(steps[i].start).toBe(steps[i - 1].end);
  });

  it('listens longer to longer sentences', () => {
    const listen = (scene: number) => steps.find((s) => s.scene === scene && s.phase === 'listening')!;
    expect(listen(0).end - listen(0).start).toBe(TIMING.listenBase + 2 * TIMING.perWord);
    expect(listen(1).end - listen(1).start).toBeGreaterThan(listen(0).end - listen(0).start);
  });
});

describe('stepAt', () => {
  const steps = buildTimeline([3, 3, 3]);
  const length = cycleLength(steps);

  it('starts idle on the first scene', () => {
    expect(stepAt(steps, 0)).toEqual({ step: steps[0], progress: 0 });
  });

  it('wraps around at the end of the cycle', () => {
    expect(stepAt(steps, length).step).toBe(steps[0]);
    expect(stepAt(steps, length + TIMING.idle + 1).step.phase).toBe('listening');
  });

  it('handles the last millisecond and negative time', () => {
    expect(stepAt(steps, length - 1).step).toBe(steps[steps.length - 1]);
    expect(stepAt(steps, -1).step).toBe(steps[steps.length - 1]);
  });

  it('reports progress inside a step', () => {
    const listening = steps[1];
    const middle = (listening.start + listening.end) / 2;
    expect(stepAt(steps, middle).progress).toBeCloseTo(0.5);
  });

  it('refuses an empty timeline', () => {
    expect(() => stepAt([], 0)).toThrow();
  });
});

describe('spokenWords', () => {
  it('shows nothing before speaking and everything after', () => {
    expect(spokenWords('idle', 0.9, 6)).toBe(0);
    expect(spokenWords('typing', 0, 6)).toBe(6);
    expect(spokenWords('done', 0.5, 6)).toBe(6);
  });

  it('reveals words one by one while listening', () => {
    expect(spokenWords('listening', 0, 6)).toBe(0);
    expect(spokenWords('listening', 0.5, 6)).toBe(3);
    expect(spokenWords('listening', 0.99, 6)).toBe(6);
  });
});
