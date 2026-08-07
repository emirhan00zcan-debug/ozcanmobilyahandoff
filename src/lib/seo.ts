// Meta başlık/açıklama, canonical URL ve sitemap/robots için ortak SEO yardımcıları.

export const SITE_URL = (process.env.NEXT_PUBLIC_SITE_URL ?? "https://ozcanmobilya.com").replace(/\/$/, "");

export function absoluteUrl(path: string): string {
  return path ? `${SITE_URL}/${path.replace(/^\//, "")}` : SITE_URL;
}

// Meta description ~155-160 karakterde kesilmezse Google sonuçlarda kendi kısaltmasını
// gösterir; kelime ortasından kesmemek için son kelimeyi at.
export function truncateForMeta(text: string, maxLength = 160): string {
  const trimmed = text.trim().replace(/\s+/g, " ");
  if (trimmed.length <= maxLength) return trimmed;
  return trimmed.slice(0, maxLength - 1).replace(/\s+\S*$/, "") + "…";
}
