// Stok gösterimi ve miktar sınırlama yardımcıları — ürün detay, sepet ve sipariş katmanlarında ortak.

/** Stok durumu metni: "Stokta 3 adet", "Stokta son 1 adet" vb. */
export function formatStockLabel(stock: number): string {
  if (stock <= 0) return "Tükendi";
  if (stock === 1) return "Stokta son 1 adet";
  return `Stokta ${stock} adet`;
}

/** Üretim/teslim süresi metni — mobilya gibi siparişe üretilen ürünler için. */
export function formatLeadTime(days: number): string {
  if (days <= 0) return "";
  if (days === 1) return "Tahmini teslim: 1 iş günü";
  if (days <= 7) return `Tahmini teslim: ${days} iş günü`;
  const weeks = Math.ceil(days / 7);
  return `Tahmini teslim: ${days} iş günü (yaklaşık ${weeks} hafta)`;
}

/** Miktarı [1, maxStock] aralığına sıkıştırır; stok yoksa 0 döner. */
export function clampQuantity(quantity: number, maxStock: number): number {
  if (maxStock <= 0) return 0;
  return Math.max(1, Math.min(quantity, maxStock));
}

/** Sepetteki mevcut adet düşüldükten sonra eklenebilecek kalan stok. */
export function availableStock(totalStock: number, cartQuantity: number): number {
  return Math.max(0, totalStock - cartQuantity);
}
