import { describe, expect, it, vi } from 'vitest';
import { copyText } from './clipboard';

describe('copyText', () => {
  it('writes the text and reports success', async () => {
    const writeText = vi.fn(async () => {});
    await expect(copyText('curl …', { writeText })).resolves.toBe(true);
    expect(writeText).toHaveBeenCalledWith('curl …');
  });

  it('reports failure when there is no Clipboard API', async () => {
    await expect(copyText('curl …', undefined)).resolves.toBe(false);
  });

  it('reports failure when the browser refuses', async () => {
    const writeText = vi.fn(async () => {
      throw new DOMException('denied', 'NotAllowedError');
    });
    await expect(copyText('curl …', { writeText })).resolves.toBe(false);
  });
});
