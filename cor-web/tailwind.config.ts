import type { Config } from 'tailwindcss'

const config: Config = {
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        'cor-orange': '#FF6B35',
        'cor-dark': '#1a1a2e',
        'cor-blue': '#16213e',
      },
    },
  },
  plugins: [],
}
export default config
