import type { Config } from 'tailwindcss'

const config: Config = {
  darkMode: ['class'],
  content: [
    './pages/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
    './app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        // COR brand colors
        cor: {
          primary: '#1E40AF', // Blue 800
          secondary: '#3B82F6', // Blue 500
          accent: '#60A5FA', // Blue 400
        },
        // Stage colors (matching Flutter app)
        stage: {
          1: '#4CAF50', // Green
          2: '#FFEB3B', // Yellow
          3: '#FF9800', // Orange
          4: '#F44336', // Red
          5: '#9C27B0', // Purple
        },
        // Heat level colors
        heat: {
          1: '#2196F3', // Blue
          2: '#4CAF50', // Green
          3: '#FFEB3B', // Yellow
          4: '#FF9800', // Orange
          5: '#B71C1C', // Dark Red
        },
        // Alert severity colors
        severity: {
          info: '#3B82F6', // Blue
          alert: '#F59E0B', // Amber
          emergency: '#EF4444', // Red
        },
        border: 'hsl(var(--border))',
        input: 'hsl(var(--input))',
        ring: 'hsl(var(--ring))',
        background: 'hsl(var(--background))',
        foreground: 'hsl(var(--foreground))',
        primary: {
          DEFAULT: 'hsl(var(--primary))',
          foreground: 'hsl(var(--primary-foreground))',
        },
        secondary: {
          DEFAULT: 'hsl(var(--secondary))',
          foreground: 'hsl(var(--secondary-foreground))',
        },
        destructive: {
          DEFAULT: 'hsl(var(--destructive))',
          foreground: 'hsl(var(--destructive-foreground))',
        },
        muted: {
          DEFAULT: 'hsl(var(--muted))',
          foreground: 'hsl(var(--muted-foreground))',
        },
        accent: {
          DEFAULT: 'hsl(var(--accent))',
          foreground: 'hsl(var(--accent-foreground))',
        },
        popover: {
          DEFAULT: 'hsl(var(--popover))',
          foreground: 'hsl(var(--popover-foreground))',
        },
        card: {
          DEFAULT: 'hsl(var(--card))',
          foreground: 'hsl(var(--card-foreground))',
        },
      },
      borderRadius: {
        lg: 'var(--radius)',
        md: 'calc(var(--radius) - 2px)',
        sm: 'calc(var(--radius) - 4px)',
      },
    },
  },
  plugins: [],
}

export default config
