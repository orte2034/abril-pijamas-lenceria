import { defineConfig } from 'astro/config';
import tailwind from '@astrojs/tailwind';
import mdx from '@astrojs/mdx';

export default defineConfig({
  site: 'https://abrilpijamasylenceria.vercel.app',
  defaultLocale: 'es',
  integrations: [
    tailwind({ applyBaseStyles: false }),
    mdx(),
  ],
});
