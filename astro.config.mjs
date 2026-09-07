import { defineConfig } from 'astro/config';
import tailwind from '@astrojs/tailwind';
import mdx from '@astrojs/mdx';
import vercel from '@astrojs/vercel/serverless';

export default defineConfig({
  site: 'https://abrilpijamasylenceria.vercel.app',
  defaultLocale: 'es',
  output: 'server',
  adapter: vercel({
    runtime: 'nodejs22.x'
  }),
  integrations: [
    tailwind({ applyBaseStyles: false }),
    mdx(),
  ],
});