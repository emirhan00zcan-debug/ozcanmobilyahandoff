"use client";

import { SessionProvider } from "next-auth/react";
import { useCartHydration } from "@/hooks/use-cart-hydration";
import { useCartSync } from "@/hooks/use-cart-sync";
import { useCookieConsentHydration } from "@/hooks/use-cookie-consent-hydration";

export default function Providers({ children }: { children: React.ReactNode }) {
  useCartHydration();
  useCookieConsentHydration();

  // Session kasıtlı olarak burada server'dan (auth()) değil, sadece client'ta
  // (SessionProvider'ın ilk mount'taki /api/auth/session fetch'i) okunuyor — root layout'ta
  // auth() çağrısı tüm siteyi (blog, kategori, ürün, hukuki sayfalar dahil) statik/ISR
  // üretimden dinamik render'a düşürüyordu. Girişten hemen sonra Navbar'ın güncellenmesi
  // GirisClient.tsx'teki useAuthRedirect (useSession().update()) ile ayrıca sağlanıyor.
  return (
    <SessionProvider>
      <CartSyncWrapper>{children}</CartSyncWrapper>
    </SessionProvider>
  );
}

function CartSyncWrapper({ children }: { children: React.ReactNode }) {
  useCartSync();
  return <>{children}</>;
}
