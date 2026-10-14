import { afterEach, describe, expect, it, vi } from 'vitest';
import { downloadLabel, fetchLatestRelease, parseLatestRelease } from './release';

const DMG = 'https://github.com/mateusfonsek/tagara/releases/download/v0.1.12/Tagara-0.1.12.dmg';
const release = {
  tag_name: 'v0.1.12',
  assets: [
    { name: 'checksums.txt', browser_download_url: 'https://example.com/checksums.txt' },
    { name: 'Tagara-0.1.12.dmg', browser_download_url: DMG },
  ],
};

const respond = (body: unknown, status = 200) =>
  (async () => new Response(JSON.stringify(body), { status })) as unknown as typeof fetch;

describe('parseLatestRelease', () => {
  it('reads the version and the DMG link', () => {
    expect(parseLatestRelease(release)).toEqual({ version: '0.1.12', url: DMG });
  });

  it('accepts a tag without the v prefix', () => {
    expect(parseLatestRelease({ ...release, tag_name: '0.2.0' })?.version).toBe('0.2.0');
  });

  it('returns null when there is no DMG', () => {
    expect(parseLatestRelease({ ...release, assets: [release.assets[0]] })).toBeNull();
  });

  it('returns null for a non-https download link', () => {
    const assets = [{ name: 'Tagara.dmg', browser_download_url: 'http://example.com/Tagara.dmg' }];
    expect(parseLatestRelease({ ...release, assets })).toBeNull();
  });

  it('returns null for malformed data', () => {
    expect(parseLatestRelease(null)).toBeNull();
    expect(parseLatestRelease('v0.1.12')).toBeNull();
    expect(parseLatestRelease({ tag_name: 'v0.1.12' })).toBeNull();
    expect(parseLatestRelease({ tag_name: 'nightly', assets: release.assets })).toBeNull();
    expect(parseLatestRelease({ message: 'API rate limit exceeded' })).toBeNull();
  });
});

describe('fetchLatestRelease', () => {
  afterEach(() => vi.useRealTimers());

  it('returns the parsed release', async () => {
    await expect(fetchLatestRelease(respond(release))).resolves.toEqual({ version: '0.1.12', url: DMG });
  });

  it('returns null when GitHub refuses (rate limit)', async () => {
    await expect(fetchLatestRelease(respond({ message: 'API rate limit exceeded' }, 403))).resolves.toBeNull();
  });

  it('returns null when the network fails', async () => {
    const failing = (async () => {
      throw new TypeError('Failed to fetch');
    }) as unknown as typeof fetch;
    await expect(fetchLatestRelease(failing)).resolves.toBeNull();
  });

  it('gives up after the timeout', async () => {
    vi.useFakeTimers();
    const hanging = ((_: unknown, init?: RequestInit) =>
      new Promise((_resolve, reject) => {
        init?.signal?.addEventListener('abort', () => reject(new DOMException('aborted', 'AbortError')));
      })) as unknown as typeof fetch;
    const pending = fetchLatestRelease(hanging, 4000);
    await vi.advanceTimersByTimeAsync(4000);
    await expect(pending).resolves.toBeNull();
  });
});

describe('downloadLabel', () => {
  it('fills in the version', () => {
    expect(downloadLabel('Baixar v{version}', '0.1.12')).toBe('Baixar v0.1.12');
  });
});
