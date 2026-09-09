import { defineConfig } from 'astro/config';
import tailwindcss from '@tailwindcss/vite';
import mdx from '@astrojs/mdx';
import vercel from '@astrojs/vercel';

export default defineConfig({
  site: 'https://abrilpijamasylenceria.vercel.app',
  defaultLocale: 'es',
  output: 'server',
  adapter: vercel({
    runtime: 'nodejs20.x'
  }),
  integrations: [
    mdx(),
  ],
  vite: {
    plugins: [tailwindcss()],
  },
});