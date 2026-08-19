"use server";

import { prisma } from "@/lib/prisma";
import { sendEmail } from "@/lib/email";
import { requireAdmin } from "@/lib/auth";

export type NewsletterCampaignState =
  | { status: "idle" }
  | { status: "error"; error: string }
  | { status: "success"; sentCount: number; failedCount: number };

// Resend'in ücretsiz planı saniyede ~2 istekle sınırlı — çok sayıda aboneye
// art arda gönderirken 429 alıp sessizce e-posta kaybetmemek için istekler
// arasına kısa bir bekleme koyuyoruz.
const SEND_DELAY_MS = 600;

export async function sendNewsletterCampaignAction(
  _prevState: NewsletterCampaignState,
  formData: FormData,
): Promise<NewsletterCampaignState> {
  await requireAdmin();

  const subject = String(formData.get("subject") ?? "").trim();
  const message = String(formData.get("message") ?? "").trim();

  if (!subject || !message) {
    return { status: "error", error: "Konu ve mesaj alanları zorunludur." };
  }

  const subscribers = await prisma.newsletterSubscriber.findMany({ select: { email: true } });
  if (subscribers.length === 0) {
    return { status: "error", error: "Henüz bültene kayıtlı abone yok." };
  }

  let sentCount = 0;
  let failedCount = 0;

  for (const [index, { email }] of subscribers.entries()) {
    const ok = await sendEmail({ to: email, subject, text: message });
    if (ok) {
      sentCount++;
    } else {
      failedCount++;
    }
    if (index < subscribers.length - 1) {
      await new Promise((resolve) => setTimeout(resolve, SEND_DELAY_MS));
    }
  }

  return { status: "success", sentCount, failedCount };
}
