import { describe, expect, it } from 'vitest';
import { localeHref, withBase } from './paths';

describe('withBase', () => {
  it('joins a subpath base with a file', () => {
    expect(withBase('/tagara/', 'favicon.svg')).toBe('/tagara/favicon.svg');
    expect(withBase('/tagara', 'favicon.svg')).toBe('/tagara/favicon.svg');
  });

  it('ignores extra slashes on either side', () => {
    expect(withBase('/tagara//', '/og-pt.png')).toBe('/tagara/og-pt.png');
  });

  it('works at the domain root (custom domain)', () => {
    expect(withBase('/', 'favicon.svg')).toBe('/favicon.svg');
    expect(withBase('', 'favicon.svg')).toBe('/favicon.svg');
  });

  it('returns the base itself for an empty path', () => {
    expect(withBase('/tagara/')).toBe('/tagara/');
    expect(withBase('/')).toBe('/');
  });
});

describe('localeHref', () => {
  it('puts Portuguese at the root and English under /en/', () => {
    expect(localeHref('/tagara/', 'pt')).toBe('/tagara/');
    expect(localeHref('/tagara/', 'en')).toBe('/tagara/en/');
  });

  it('works at the domain root', () => {
    expect(localeHref('/', 'pt')).toBe('/');
    expect(localeHref('/', 'en')).toBe('/en/');
  });
});
