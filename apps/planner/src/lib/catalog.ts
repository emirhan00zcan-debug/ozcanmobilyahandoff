// Ana sitedeki /api/planner/catalog uç noktasının istemcisi (bkz. Mimari
// Doküman §1.3). Planlayıcı kendi ürün veritabanını tutmaz.

export interface CatalogVariation {
  id: string;
  sku: string;
  price: number;
  hexColor: string | null;
  heightOverrideCm: number | null;
}

export interface CatalogProduct {
  productId: string;
  name: string;
  dimensionsMm: { w: number; h: number; d: number };
  basePrice: number;
  images: string[];
  variations: CatalogVariation[];
}

const ANASITE_URL = import.meta.env.VITE_ANASITE_URL || "https://ozcanmobilyahandoff.vercel.app";

export async function fetchCatalog(productIds: string[]): Promise<CatalogProduct[]> {
  if (productIds.length === 0) return [];

  const url = `${ANASITE_URL}/api/planner/catalog?ids=${productIds.join(",")}`;
  const res = await fetch(url);
  if (!res.ok) {
    throw new Error(`Katalog isteği başarısız oldu (${res.status})`);
  }
  return res.json();
}
