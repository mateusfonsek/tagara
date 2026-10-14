import type { Lang } from '../i18n/types';

/** Joins the site base ("/tagara/", "/tagara", "/" or "") with a path inside the site. */
export function withBase(base: string, path = ''): string {
  const root = base.replace(/\/+$/, '');
  const rest = path.replace(/^\/+/, '');
  return `${root}/${rest}`;
}

/** Home page of a language: Portuguese at the root, English under /en/. */
export function localeHref(base: string, lang: Lang): string {
  return withBase(base, lang === 'pt' ? '' : 'en/');
}
