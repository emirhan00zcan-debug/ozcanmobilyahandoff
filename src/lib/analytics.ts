// GA4 olay yardımcıları — "Sepete Ekle", ürün görüntüleme, ödeme başlangıcı ve
// satış (purchase) noktalarında çağrılır. gtag.js yüklenmediyse (NEXT_PUBLIC_GA_MEASUREMENT_ID
// tanımsızsa, bkz. components/analytics/GoogleAnalytics.tsx) sessizce no-op kalır — Google/Apple
// girişindeki "eksik kimlik bilgisiyle çökmeme" deseniyle aynı yaklaşım (bkz. src/lib/auth.ts).

declare global {
  interface Window {
    gtag?: (...args: unknown[]) => void;
  }
}

function gtag(...args: unknown[]) {
  if (typeof window === "undefined" || typeof window.gtag !== "function") return;
  window.gtag(...args);
}

export function trackEvent(name: string, params?: Record<string, unknown>) {
  gtag("event", name, params);
}

export type AnalyticsItem = {
  item_id: string;
  item_name: string;
  price: number;
  quantity?: number;
};

// Ürün detay sayfası açıldığında — "hangi ürünün ilgi çektiği" sorusunun temel verisi.
export function trackViewItem(item: AnalyticsItem) {
  trackEvent("view_item", { currency: "TRY", value: item.price, items: [item] });
}

// "Sepete Ekle" tıklamasında (bkz. store/cart-store.ts addItem).
export function trackAddToCart(item: AnalyticsItem) {
  trackEvent("add_to_cart", {
    currency: "TRY",
    value: item.price * (item.quantity ?? 1),
    items: [item],
  });
}

// /odeme sayfası, sepet doluyken ilk açıldığında — "sepeti nerede terk ettiği" GA4
// huninde view_item -> add_to_cart -> begin_checkout -> purchase adımlarıyla görünür olur.
export function trackBeginCheckout(items: AnalyticsItem[], value: number) {
  trackEvent("begin_checkout", { currency: "TRY", value, items });
}

// Sipariş başarıyla oluşturulduğunda — GA4'ün trafik kaynağını otomatik ilişkilendirdiği
// nihai dönüşüm olayı.
export function trackPurchase(orderNumber: string, items: AnalyticsItem[], value: number) {
  trackEvent("purchase", { transaction_id: orderNumber, currency: "TRY", value, items });
}
