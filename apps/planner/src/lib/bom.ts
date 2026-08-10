import type { PlannerModule } from "./types";

export interface BomLine {
  productId: string;
  productVariationId: string | null;
  quantity: number;
}

// Mimari Doküman §1.4 / §5 — /api/planner/import gövdesiyle aynı şekil,
// dönüştürme adımı gerektirmez. Aynı ürün+varyasyon birden yerleştirilmişse
// tek satırda toplanır.
export function buildBom(modules: PlannerModule[]): BomLine[] {
  const byKey = new Map<string, BomLine>();

  for (const m of modules) {
    const key = `${m.productId}__${m.productVariationId ?? ""}`;
    const existing = byKey.get(key);
    if (existing) {
      existing.quantity += 1;
    } else {
      byKey.set(key, { productId: m.productId, productVariationId: m.productVariationId, quantity: 1 });
    }
  }

  return Array.from(byKey.values());
}
