"use client";

import { useEffect } from "react";
import { useCookieConsentStore } from "@/store/cookie-consent-store";

// use-cart-hydration.ts'teki aynı desen: `skipHydration: true` ile SSR/CSR hydration
// mismatch'i önlenir, localStorage'daki tercih client mount olduktan sonra okunur.
export function useCookieConsentHydration() {
  useEffect(() => {
    useCookieConsentStore.persist.rehydrate();
  }, []);
}
