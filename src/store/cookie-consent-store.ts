import { create } from "zustand";
import { persist, createJSONStorage } from "zustand/middleware";

// Zorunlu olmayan (analitik) çerezler için tercih durumu — bkz. /cerez-politikasi.
// "pending" iken CookieConsentBanner gösterilir ve GoogleAnalytics hiç yüklenmez;
// "accepted" olmadan gtag.js hiçbir zaman devreye girmez (bkz. GoogleAnalytics.tsx).
export type ConsentStatus = "pending" | "accepted" | "rejected";

type CookieConsentState = {
  status: ConsentStatus;
  setStatus: (status: ConsentStatus) => void;

  // Persist hydration takibi — cart-store.ts'teki aynı desen (SSR/CSR uyuşmazlığını önler).
  hasHydrated: boolean;
  setHasHydrated: (state: boolean) => void;
};

export const useCookieConsentStore = create<CookieConsentState>()(
  persist(
    (set) => ({
      status: "pending",
      setStatus: (status) => set({ status }),
      hasHydrated: false,
      setHasHydrated: (state) => set({ hasHydrated: state }),
    }),
    {
      name: "ozcan-cookie-consent",
      storage: createJSONStorage(() => localStorage),
      skipHydration: true,
      onRehydrateStorage: () => (state) => {
        state?.setHasHydrated(true);
      },
    },
  ),
);
