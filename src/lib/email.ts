import { Resend } from "resend";

type SendEmailInput = {
  to: string;
  subject: string;
  text: string;
  replyTo?: string;
};

// RESEND_API_KEY tanımlı değilse sessizce atlanır (bkz. .env.example) — çağıran taraf
// e-postayı "best-effort" bir ek katman olarak ele almalı, asıl işlemi (form kaydı,
// sipariş oluşturma) buna bağlamamalı.
export async function sendEmail({ to, subject, text, replyTo }: SendEmailInput): Promise<void> {
  const apiKey = process.env.RESEND_API_KEY;
  if (!apiKey) return;

  const resend = new Resend(apiKey);
  await resend.emails.send({
    from: process.env.RESEND_FROM_EMAIL || "Özcan Mobilya Web Sitesi <onboarding@resend.dev>",
    to,
    replyTo,
    subject,
    text,
  });
}
