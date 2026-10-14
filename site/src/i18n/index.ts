import { en } from './en';
import { pt } from './pt';
import type { Lang, Strings } from './types';

export const strings: Record<Lang, Strings> = { pt, en };

export function otherLang(lang: Lang): Lang {
  return lang === 'pt' ? 'en' : 'pt';
}
