"use client";

import Script from "next/script";
import { useCookieConsentStore } from "@/store/cookie-consent-store";

const GA_MEASUREMENT_ID = process.env.NEXT_PUBLIC_GA_MEASUREMENT_ID;

// GA4 iki şart birden sağlanmadan ASLA yüklenmez:
// 1) NEXT_PUBLIC_GA_MEASUREMENT_ID tanımlı olmalı (Google/Apple girişindeki "eksik kimlik
//    bilgisiyle çökmeme, sessizce pasif kal" deseninin aynısı, bkz. src/lib/auth.ts),
// 2) kullanıcı çerez bildirimini "accepted" ile onaylamış olmalı (bkz. CookieConsentBanner,
//    /cerez-politikasi) — bu sadece kozmetik bir banner değil, script'i fiilen bloke eder.
export default function GoogleAnalytics() {
  const status = useCookieConsentStore((state) => state.status);
  const hasHydrated = useCookieConsentStore((state) => state.hasHydrated);

  if (!GA_MEASUREMENT_ID || !hasHydrated || status !== "accepted") return null;

  return (
    <>
      <Script src={`https://www.googletagmanager.com/gtag/js?id=${GA_MEASUREMENT_ID}`} strategy="afterInteractive" />
      <Script id="ga4-init" strategy="afterInteractive">
        {`
          window.dataLayer = window.dataLayer || [];
          function gtag(){dataLayer.push(arguments);}
          gtag('js', new Date());
          gtag('config', '${GA_MEASUREMENT_ID}');
        `}
      </Script>
    </>
  );
}
