"use server";

import { headers } from "next/headers";
import { prisma } from "@/lib/prisma";
import { sendEmail } from "@/lib/email";
import { isRateLimited } from "@/lib/rate-limit";

// Çıkış-niyeti (exit-intent) popup'ının "%10 indirim" kuponu — bkz.
// src/components/layout/ExitIntentPopup.tsx. Kupon Coupon tablosunda yoksa
// kendiliğinden oluşturulur (idempotent) ki admin panelinden ayrıca
// tanımlanması gerekmesin.
const WELCOME_COUPON_CODE = "HOSGELDIN10";
const WELCOME_COUPON_VALIDITY_MS = 5 * 365 * 24 * 60 * 60 * 1000; // ~5 yıl

// Ticari elektronik ileti onay metninin sürümü (bkz. Footer.tsx / ExitIntentPopup.tsx'teki
// onay kutusu metni). NewsletterSubscriber.consentVersion'a yazılır; metin ileride
// değişirse burası da güncellenmeli ki hangi ifadeye onay verildiği ispatlanabilsin.
const NEWSLETTER_CONSENT_VERSION = "2026-08-26";

export type NewsletterActionState =
  | { success: true; couponCode: string }
  | { success: false; error: string | null };

export async function subscribeNewsletterAction(
  _prevState: NewsletterActionState,
  formData: FormData,
): Promise<NewsletterActionState> {
  const email = String(formData.get("email") ?? "").trim().toLowerCase();
  if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    return { success: false, error: "Geçerli bir e-posta adresi girin." };
  }
  if (formData.get("consent") !== "on") {
    return { success: false, error: "Devam etmek için kampanya e-postalarını almayı kabul etmelisiniz." };
  }
  if (await isRateLimited("newsletter-subscribe", 5, 600)) {
    return { success: false, error: "Çok fazla deneme yaptınız, lütfen biraz sonra tekrar deneyin." };
  }

  const headersList = await headers();
  const forwardedFor = headersList.get("x-forwarded-for");
  const consentIp = forwardedFor?.split(",")[0]?.trim() || headersList.get("x-real-ip") || null;

  try {
    await prisma.newsletterSubscriber.upsert({
      where: { email },
      update: { consentIp, consentVersion: NEWSLETTER_CONSENT_VERSION },
      create: { email, consentIp, consentVersion: NEWSLETTER_CONSENT_VERSION },
    });

    const coupon = await prisma.coupon.upsert({
      where: { code: WELCOME_COUPON_CODE },
      update: {},
      create: {
        code: WELCOME_COUPON_CODE,
        discountType: "PERCENTAGE",
        discountValue: 10,
        description: "Yeni üyelere özel hoş geldin indirimi",
        startsAt: new Date(),
        endsAt: new Date(Date.now() + WELCOME_COUPON_VALIDITY_MS),
        isActive: true,
      },
    });

    // Best-effort — RESEND_API_KEY tanımlı değilse sessizce atlanır (bkz. lib/email.ts),
    // e-posta gitmese bile kupon kodu zaten popup'ta gösteriliyor.
    sendEmail({
      to: email,
      subject: "İlk Siparişinize Özel %10 İndirim Kodunuz",
      text: `Merhaba,\n\nÖzcan Mobilya ailesine katıldığınız için teşekkür ederiz!\n\nİlk siparişinizde geçerli %10 indirim kodunuz: ${coupon.code}\n\nKoleksiyonumuza göz atmak için: ${process.env.NEXT_PUBLIC_SITE_URL || "https://ozcanmobilya.com"}/koleksiyon\n\nÖzcan Mobilya`,
    }).catch((err) => {
      console.error("[newsletter] hoş geldin e-postası gönderilemedi:", err);
    });

    return { success: true, couponCode: coupon.code };
  } catch (err) {
    console.error("subscribeNewsletterAction hata:", err);
    return { success: false, error: "Bir şeyler ters gitti, lütfen tekrar deneyin." };
  }
}
