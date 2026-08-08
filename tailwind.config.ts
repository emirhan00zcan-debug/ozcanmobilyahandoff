import type { Config } from "tailwindcss";

// Özcan Mobilya marka tasarım sistemi:
// - primary: logo teal'i (#005A64) — indirim rozetleri, satış fiyatı, linkler, butonlar
// - secondary: siyah (#000000) — başlıklar, gövde metni, buton zemini
// - tek font ailesi: Instrument Sans (hem display hem body)
const config: Config = {
  content: ["./src/**/*.{js,ts,jsx,tsx,mdx}"],
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: "#005A64",
          50: "#E6F1F1",
          100: "#C2DEE0",
          400: "#157885",
          600: "#00454C",
          700: "#00343A",
        },
        secondary: {
          DEFAULT: "#000000",
          light: "#666666",
        },
        // Sadece logo/wordmark için — site geneli aksan rengi değil, marka logosunun
        // kendi (gerçek logo görselindeki) teal rengi
        brand: "#005A64",
      },
      fontFamily: {
        display: ["var(--font-instrument-sans)", "sans-serif"],
        body: ["var(--font-instrument-sans)", "sans-serif"],
        script: ["var(--font-script)", "cursive"],
      },
      keyframes: {
        marquee: {
          "0%": { transform: "translateX(0%)" },
          "100%": { transform: "translateX(-50%)" },
        },
        "hero-zoom": {
          "0%": { transform: "scale(1)" },
          "100%": { transform: "scale(1.08)" },
        },
        "fade-in": {
          "0%": { opacity: "0" },
          "100%": { opacity: "1" },
        },
        "fade-in-up": {
          "0%": { opacity: "0", transform: "translateY(20px)" },
          "100%": { opacity: "1", transform: "translateY(0)" },
        },
        "cart-bump": {
          "0%": { transform: "scale(0.5)" },
          "50%": { transform: "scale(1.3)" },
          "100%": { transform: "scale(1)" },
        },
        "collection-reveal": {
          "0%": { opacity: "0", transform: "scale(0.94)" },
          "100%": { opacity: "1", transform: "scale(1)" },
        },
      },
      animation: {
        marquee: "marquee 22s linear infinite",
        // "Biz Kimiz?" bölümündeki dönen rozet (AboutSection.tsx) için — Tailwind'in
        // yerleşik "spin" keyframe'ini kullanır, sadece çok daha yavaş bir süreyle.
        "spin-slow": "spin 14s linear infinite",
        "hero-zoom": "hero-zoom 6s ease-out forwards",
        "fade-in": "fade-in 0.4s ease-out forwards",
        "fade-in-up": "fade-in-up 0.5s cubic-bezier(0.16, 1, 0.3, 1) forwards",
        "cart-bump": "cart-bump 0.4s cubic-bezier(0.34,1.56,0.64,1) forwards",
        // "Sizin İçin Seçtiklerimiz" (CollectionTabs.tsx) sekme değişiminde görsel
        // yığınının (ön + iki yan karartılmış görsel) yumuşak büyüyerek belirmesi için.
        "collection-reveal": "collection-reveal 0.6s cubic-bezier(0.16, 1, 0.3, 1) forwards",
      },
    },
  },
  plugins: [
    // scrollbar-hide utility'si için ayrı paket kurmak istemezsen
    // globals.css içindeki .scrollbar-hide class'ı yeterli (aşağıda tanımlı).
  ],
};

export default config;
