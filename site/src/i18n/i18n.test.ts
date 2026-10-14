import { describe, expect, it } from 'vitest';
import { otherLang, strings } from './index';

/** Replaces every string with its type, keeping keys and array lengths. */
function shape(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(shape);
  if (value && typeof value === 'object') {
    return Object.fromEntries(Object.entries(value).map(([key, inner]) => [key, shape(inner)]));
  }
  return typeof value;
}

describe('strings', () => {
  it('has the same structure in both languages', () => {
    expect(shape(strings.en)).toEqual(shape(strings.pt));
  });

  it('keeps demo scenes and features in the same order', () => {
    expect(strings.en.demo.scenes.map((s) => s.app)).toEqual(strings.pt.demo.scenes.map((s) => s.app));
    expect(strings.en.features.items.map((f) => f.id)).toEqual(strings.pt.features.items.map((f) => f.id));
  });

  it('has a {version} slot in the versioned download label', () => {
    for (const s of Object.values(strings)) expect(s.hero.downloadVersion).toContain('{version}');
  });

  it('has the flow, steps and anyapp fields the components draw', () => {
    for (const s of Object.values(strings)) {
      expect(s.how.steps).toHaveLength(3);
      expect(s.privacy.flow).toHaveLength(4);
      expect(s.features.anyappFields).toHaveLength(3);
      expect(s.demo.scenes).toHaveLength(3);
    }
  });

  it('maps each language to the other', () => {
    expect(otherLang('pt')).toBe('en');
    expect(otherLang('en')).toBe('pt');
  });
});
