/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        navy: {
          950: "#0A1628",
          900: "#0E1F3A",
          800: "#132B52",
          700: "#1B3A6B",
        },
        brand: {
          blue: "#2563EB",
          blueDark: "#1D4ED8",
          teal: "#14B8A6",
          tealDark: "#0F9488",
        },
        surface: {
          DEFAULT: "#FFFFFF",
          muted: "#F4F6F9",
          border: "#E2E8F0",
        },
        ink: {
          900: "#0F172A",
          700: "#334155",
          500: "#64748B",
          400: "#94A3B8",
        },
        warn: {
          DEFAULT: "#B45309",
          bg: "#FFFBEB",
          border: "#FDE68A",
        },
        danger: {
          DEFAULT: "#B91C1C",
          bg: "#FEF2F2",
          border: "#FECACA",
        },
        good: {
          DEFAULT: "#0F766E",
          bg: "#F0FDFA",
          border: "#99F6E4",
        },
      },
      fontFamily: {
        display: ["'Sora'", "system-ui", "sans-serif"],
        sans: ["'Inter'", "system-ui", "sans-serif"],
        mono: ["'IBM Plex Mono'", "ui-monospace", "monospace"],
      },
      boxShadow: {
        card: "0 1px 2px 0 rgba(15, 23, 42, 0.04), 0 1px 3px 0 rgba(15, 23, 42, 0.06)",
        elevated: "0 4px 16px -4px rgba(15, 23, 42, 0.12)",
      },
      borderRadius: {
        xl: "0.75rem",
      },
    },
  },
  plugins: [],
};
