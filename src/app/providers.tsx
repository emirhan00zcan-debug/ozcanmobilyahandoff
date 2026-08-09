"use client";

import { SessionProvider } from "next-auth/react";
import type { Session } from "next-auth";
import { useCartHydration } from "@/hooks/use-cart-hydration";
import { useCartSync } from "@/hooks/use-cart-sync";
import { useCookieConsentHydration } from "@/hooks/use-cookie-consent-hydration";

export default function Providers({
  children,
  session,
}: {
  children: React.ReactNode;
  session: Session | null;
}) {
  useCartHydration();
  useCookieConsentHydration();

  // session, root layout'taki auth()'tan geliyor: server action ile giriş yapıldığında
  // (redirectTo ile) hedef sayfa yeniden render edilirken layout da taze session'ı okuyup
  // buraya prop olarak geçiyor — SessionProvider bunu görünce useSession()'ı client'ta
  // sayfa yenilemeden günceller (aksi halde ilk mount'taki client fetch'e kilitli kalıyordu).
  return (
    <SessionProvider session={session}>
      <CartSyncWrapper>{children}</CartSyncWrapper>
    </SessionProvider>
  );
}

function CartSyncWrapper({ children }: { children: React.ReactNode }) {
  useCartSync();
  return <>{children}</>;
}
