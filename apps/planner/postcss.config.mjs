// Boş: apps/planner kendi CSS'ini yazar, Tailwind kullanmaz. Bu dosya yoksa
// Vite'ın postcss-load-config'i üst dizinlere tırmanıp ana sitenin
// tailwind.config.ts'ini (postcss.config.mjs) yanlışlıkla devralıyor.
export default { plugins: {} };
