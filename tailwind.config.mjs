/** @type {import('tailwindcss').Config} */
export default {
  content: [
    './src/**/*.{astro,html,js,jsx,md,mdx,ts,tsx,vue}',
    './public/js/**/*.js',
  ],
  theme: {
    extend: {
      colors: {
        crema: '#F8F1EE',
        creamwarm: '#F1E5DD',
        ink: '#3A1A22',
        burgundy: {
          DEFAULT: '#7B2D3F',
          900: '#4D1A28',
          700: '#7B2D3F',
          500: '#9E4858',
          300: '#C58FA0',
        },
        rosa: {
          polvo: '#D9A89B',
          soft: '#E8C9BF',
          mist: '#F2DDD7',
        },
      },
      fontFamily: {
        serif: ['Fraunces', 'ui-serif', 'Georgia', 'serif'],
        sans: ['Inter', 'ui-sans-serif', 'system-ui', 'sans-serif'],
      },
      fontSize: {
        'display-xl': ['clamp(4rem, 10vw, 9rem)', { lineHeight: '0.95', letterSpacing: '-0.02em' }],
        'display': ['clamp(2.5rem, 6vw, 5rem)', { lineHeight: '1', letterSpacing: '-0.01em' }],
        'lead': ['clamp(1.125rem, 1.5vw, 1.375rem)', { lineHeight: '1.6' }],
      },
      maxWidth: {
        'content': '85rem',
        'editorial': '72rem',
        'read': '40rem',
      },
      transitionTimingFunction: {
        'editorial': 'cubic-bezier(0.2, 0.6, 0.1, 1)',
      },
    },
  },
  plugins: [],
};
