import { Resend } from "resend";

type SendEmailInput = {
  to: string;
  subject: string;
  text: string;
  replyTo?: string;
};

// RESEND_API_KEY tanımlı değilse atlanır (bkz. .env.example) — çağıran taraf e-postayı
// "best-effort" bir ek katman olarak ele almalı, asıl işlemi (form kaydı, sipariş
// oluşturma) buna bağlamamalı. Ama sessizce yutmak yerine console.error ile logluyoruz —
// aksi halde RESEND_API_KEY eksik/geçersiz olduğunda ("kod mailime gelmiyor" gibi
// şikayetler) Vercel loglarında hiçbir iz kalmıyordu.
export type SendEmailResult = { success: boolean; error?: string };

export async function sendEmail({ to, subject, text, replyTo }: SendEmailInput): Promise<SendEmailResult> {
  const apiKey = process.env.RESEND_API_KEY;
  if (!apiKey) {
    const error = "RESEND_API_KEY tanımlı değil";
    console.error(`[sendEmail] ${error}, e-posta gönderilmedi (to: ${to}, subject: ${subject})`);
    return { success: false, error };
  }

  const resend = new Resend(apiKey);
  const { error } = await resend.emails.send({
    from: process.env.RESEND_FROM_EMAIL || "Özcan Mobilya Web Sitesi <onboarding@resend.dev>",
    to,
    replyTo,
    subject,
    text,
  });

  if (error) {
    console.error(`[sendEmail] Resend gönderim hatası (to: ${to}, subject: ${subject}):`, error);
    return { success: false, error: error.message };
  }

  return { success: true };
}
