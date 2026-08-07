"use server";

import { prisma } from "@/lib/prisma";
import { sendEmail } from "@/lib/email";

export type ContactActionState = { success: boolean; error: string | null };

export async function sendContactMessageAction(
  _prevState: ContactActionState,
  formData: FormData,
): Promise<ContactActionState> {
  const name = String(formData.get("name") ?? "").trim();
  const email = String(formData.get("email") ?? "").trim();
  const phone = String(formData.get("phone") ?? "").trim();
  const subject = String(formData.get("subject") ?? "").trim();
  const message = String(formData.get("message") ?? "").trim();

  if (!name || !email || !message) {
    return { success: false, error: "Lütfen ad, e-posta ve mesaj alanlarını doldurun." };
  }
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    return { success: false, error: "Lütfen geçerli bir e-posta adresi girin." };
  }

  // Kalıcı kayıt asıl güvence — e-posta bildirimi (aşağıda) opsiyonel bir ek katman.
  // Bu adım başarısız olursa kullanıcıya gerçekten "gönderilemedi" denir.
  try {
    await prisma.contactMessage.create({
      data: { name, email, phone: phone || null, subject: subject || null, message },
    });
  } catch (err) {
    console.error("[iletisim] Mesaj veritabanına kaydedilemedi:", err);
    return { success: false, error: "Mesajınız gönderilemedi, lütfen daha sonra tekrar deneyin." };
  }

  // E-posta bildirimi: RESEND_API_KEY tanımlıysa gönderilir (bkz. .env.example).
  // Tanımlı değilse veya gönderim başarısız olursa sessizce atlanır — mesaj zaten
  // veritabanında (bkz. /admin/mesajlar) ve kaybolmuyor.
  const notifyEmail = process.env.ADMIN_EMAIL;
  if (notifyEmail) {
    try {
      await sendEmail({
        to: notifyEmail,
        replyTo: email,
        subject: `[İletişim Formu] ${subject || "Yeni mesaj"} — ${name}`,
        text: `Ad Soyad: ${name}\nE-posta: ${email}\nTelefon: ${phone || "-"}\nKonu: ${subject || "-"}\n\nMesaj:\n${message}`,
      });
    } catch (err) {
      console.error("[iletisim] E-posta bildirimi gönderilemedi (mesaj yine de kaydedildi):", err);
    }
  }

  return { success: true, error: null };
}
