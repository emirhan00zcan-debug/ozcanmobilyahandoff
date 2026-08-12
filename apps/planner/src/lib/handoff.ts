import type { BomLine } from "./bom";

const ANASITE_URL = import.meta.env.VITE_ANASITE_URL || "https://ozcanmobilyahandoff.vercel.app";

// URL'deki `handoff` parametresini (ana siteden imzalanmış, 60sn ömürlü)
// taşır — planlayıcı bu token'ı hiç çözmez/doğrulamaz, yalnızca opak bir
// biletmiş gibi geri gönderir (bkz. Mimari Doküman §1.2, §1.4).
export function readHandoffToken(): string | null {
  return new URLSearchParams(window.location.search).get("handoff");
}

// BOM'u /api/planner/import'a gönderir — başarılıysa ana sitenin sepetine
// yazılmış olur (sunucu tarafı birleştirme mantığı: bkz. route.ts yorumları).
export async function sendBomToCart(bom: BomLine[], handoffToken: string): Promise<void> {
  const res = await fetch(`${ANASITE_URL}/api/planner/import`, {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${handoffToken}` },
    body: JSON.stringify({ items: bom }),
  });

  if (!res.ok) {
    const body = await res.json().catch(() => ({}));
    throw new Error(body.error || `Sepete aktarma başarısız oldu (${res.status})`);
  }
}

export function cartUrl(): string {
  return `${ANASITE_URL}/sepet`;
}
