"use client";

import { SessionProvider } from "next-auth/react";
import { useCartHydration } from "@/hooks/use-cart-hydration";
import { useCartSync } from "@/hooks/use-cart-sync";
import { useCookieConsentHydration } from "@/hooks/use-cookie-consent-hydration";

export default function Providers({ children }: { children: React.ReactNode }) {
  useCartHydration();
  useCookieConsentHydration();

  // Create a separate component inside SessionProvider for useCartSync since it needs useSession
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
