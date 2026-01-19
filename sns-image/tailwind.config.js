/** @type {import('tailwindcss').Config} */
export default {
  content: ["./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      fontFamily: {
        sans: ["SUITE", "SpoqaHanSansNeo", "sans-serif"],
        suite: ["SUITE", "sans-serif"],
        spoqa: ["SpoqaHanSansNeo", "sans-serif"],
      },
      colors: {
        // 한자 학습 테마
        kanji: {
          primary: "#1a1a2e",
          secondary: "#16213e",
          accent: "#e94560",
          light: "#f5f5f5",
          gold: "#ffd700",
        },
        // 가사 해석 테마
        lyrics: {
          primary: "#2d1b4e",
          secondary: "#462066",
          accent: "#ff6b9d",
          light: "#fef6ff",
          highlight: "#00d4ff",
        },
      },
    },
  },
  plugins: [],
};
