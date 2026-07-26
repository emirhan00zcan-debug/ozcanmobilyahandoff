"use client";

import { useEffect } from "react";
import { useCartStore } from "@/store/cart-store";

// `persist` middleware'inde `skipHydration: true` verdik çünkü Next.js'te
// server render'ı her zaman boş sepetle başlar; localStorage'daki veriyi
// server bilemez. Bu hook, sayfa client'ta mount olduktan SONRA store'u
// localStorage'dan doldurur. Böylece "server: 0 ürün, client: 3 ürün"
// hydration mismatch hatası oluşmaz — kullanıcı ilk render'da kısa an boş
// sepet görür, hemen ardından gerçek içerik gelir.
//
// Kullanım: bu hook'u tek bir yerde, örn. src/app/providers.tsx içinde
// (root layout'a sarılan "use client" bileşende) bir kez çağır.
export function useCartHydration() {
  useEffect(() => {
    useCartStore.persist.rehydrate();
  }, []);
}
