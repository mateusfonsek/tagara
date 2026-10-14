import { LATEST_RELEASE_API } from './constants';

export interface LatestRelease {
  version: string;
  url: string;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null;
}

/** Picks the version and the DMG link out of GitHub's "latest release" JSON. */
export function parseLatestRelease(data: unknown): LatestRelease | null {
  if (!isRecord(data) || typeof data.tag_name !== 'string' || !Array.isArray(data.assets)) return null;
  const version = data.tag_name.replace(/^v/, '');
  if (!/^\d+(\.\d+)*$/.test(version)) return null;
  for (const asset of data.assets) {
    if (!isRecord(asset)) continue;
    const { name, browser_download_url: url } = asset;
    if (typeof name !== 'string' || typeof url !== 'string') continue;
    if (name.toLowerCase().endsWith('.dmg') && url.startsWith('https://')) return { version, url };
  }
  return null;
}

/**
 * Asks GitHub for the latest release. Any failure (offline, rate limit, slow API, no DMG)
 * gives null, and the caller keeps its plain link to the releases page.
 */
export async function fetchLatestRelease(
  fetchImpl: typeof fetch = (input, init) => fetch(input, init),
  timeoutMs = 4000,
): Promise<LatestRelease | null> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const response = await fetchImpl(LATEST_RELEASE_API, {
      headers: { Accept: 'application/vnd.github+json' },
      signal: controller.signal,
    });
    if (!response.ok) return null;
    return parseLatestRelease(await response.json());
  } catch {
    return null;
  } finally {
    clearTimeout(timer);
  }
}

export function downloadLabel(template: string, version: string): string {
  return template.replace('{version}', version);
}
