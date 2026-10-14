import { prefersReducedMotion } from './motion';

/**
 * Adds .is-visible to each [data-reveal] element the first time it scrolls into view.
 * Uses a root margin instead of a ratio threshold: an element taller than the screen
 * never reaches a 30% ratio and would stay hidden.
 */
export function observeReveal(root: ParentNode = document): void {
  const elements = [...root.querySelectorAll<HTMLElement>('[data-reveal]')];
  if (prefersReducedMotion() || !('IntersectionObserver' in window)) {
    for (const element of elements) element.classList.add('is-visible');
    return;
  }
  const observer = new IntersectionObserver(
    (entries) => {
      for (const entry of entries) {
        if (!entry.isIntersecting) continue;
        entry.target.classList.add('is-visible');
        observer.unobserve(entry.target);
      }
    },
    { rootMargin: '0px 0px -8% 0px' },
  );
  for (const element of elements) observer.observe(element);
}
