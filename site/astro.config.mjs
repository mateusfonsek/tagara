import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';

// Until the custom domain exists the site lives at mateusfonsek.github.io/tagara/.
// With a domain: set `site` to it, remove `base` and add public/CNAME.
export default defineConfig({
  site: 'https://mateusfonsek.github.io',
  base: '/tagara',
  trailingSlash: 'always',
  integrations: [sitemap()],
  vite: {
    // global.css imports the brand tokens from ../assets.
    server: { fs: { allow: ['..'] } },
  },
});
