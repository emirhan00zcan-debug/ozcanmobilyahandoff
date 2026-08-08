"use client";

import Link from "next/link";
import { useCookieConsentStore } from "@/store/cookie-consent-store";

// Sadece analitik çerezler (Google Analytics) için onay ister — oturum/sepet gibi zorunlu
// çerezler siteyi kullanabilmek için zaten aktiftir ve onaya tabi değildir (bkz. /cerez-politikasi).
export default function CookieConsentBanner() {
  const status = useCookieConsentStore((state) => state.status);
  const hasHydrated = useCookieConsentStore((state) => state.hasHydrated);
  const setStatus = useCookieConsentStore((state) => state.setStatus);

  // GA4 hiç yapılandırılmadıysa onay isteyecek bir şey yok — banner'ı hiç gösterme
  // (bkz. GoogleAnalytics.tsx'teki aynı NEXT_PUBLIC_GA_MEASUREMENT_ID kontrolü).
  if (!process.env.NEXT_PUBLIC_GA_MEASUREMENT_ID) return null;
  if (!hasHydrated || status !== "pending") return null;

  return (
    <div className="fixed inset-x-0 bottom-0 z-50 border-t border-secondary/10 bg-white/95 px-4 py-4 shadow-[0_-4px_16px_rgba(0,0,0,0.06)] backdrop-blur-sm sm:px-6 lg:px-8">
      <div className="mx-auto flex max-w-7xl flex-col items-center gap-3 sm:flex-row sm:justify-between">
        <p className="font-body text-xs text-secondary-light sm:max-w-2xl">
          Deneyiminizi iyileştirmek için zorunlu çerezlerin yanında, izniniz dahilinde analitik
          çerezler de kullanıyoruz.{" "}
          <Link href="/cerez-politikasi" className="font-medium text-primary underline underline-offset-2">
            Çerez Politikası
          </Link>
          &apos;nı inceleyebilirsiniz.
        </p>
        <div className="flex shrink-0 items-center gap-2.5">
          <button
            type="button"
            onClick={() => setStatus("rejected")}
            className="btn-sweep rounded-full border border-primary/30 px-4 py-2.5 font-body text-xs font-semibold text-secondary"
          >
            Sadece Zorunlu
          </button>
          <button
            type="button"
            onClick={() => setStatus("accepted")}
            className="btn-sweep rounded-full border border-primary/30 px-5 py-2.5 font-body text-xs font-semibold text-secondary"
          >
            Kabul Et
          </button>
        </div>
      </div>
    </div>
  );
}
