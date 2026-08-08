"use server";

// WhatsApp Cloud API (Meta for Developers) üzerinden, sitedeki "Kararsız mısınız?" widget'ına
// (bkz. WhatsAppButton.tsx) yazılan mesajı doğrudan işletmenin WhatsApp numarasına iletir —
// ziyaretçi WhatsApp uygulamasını/sitesini hiç açmadan mesaj gönderebilir.
const GRAPH_API_VERSION = "v21.0";
const BUSINESS_WHATSAPP_NUMBER = "905054423809"; // Özcan Mobilya'nın gerçek WhatsApp numarası

export type WhatsAppActionState = { success: boolean; error: string | null };

export async function sendWhatsAppMessageAction(message: string): Promise<WhatsAppActionState> {
  const trimmed = message.trim();
  if (!trimmed) {
    return { success: false, error: "Lütfen bir mesaj yazın." };
  }

  const token = process.env.WHATSAPP_ACCESS_TOKEN;
  const phoneNumberId = process.env.WHATSAPP_PHONE_NUMBER_ID;

  if (!token || !phoneNumberId) {
    console.error(
      "[whatsapp-widget] WHATSAPP_ACCESS_TOKEN / WHATSAPP_PHONE_NUMBER_ID tanımlı değil (bkz. .env.example)."
    );
    return { success: false, error: "Mesaj şu anda gönderilemiyor, lütfen daha sonra tekrar deneyin." };
  }

  try {
    const res = await fetch(`https://graph.facebook.com/${GRAPH_API_VERSION}/${phoneNumberId}/messages`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        messaging_product: "whatsapp",
        to: BUSINESS_WHATSAPP_NUMBER,
        type: "text",
        text: { body: `[Web sitesi ziyaretçisi]\n${trimmed}` },
      }),
    });

    if (!res.ok) {
      console.error("[whatsapp-widget] Graph API hatası:", res.status, await res.text());
      return { success: false, error: "Mesaj gönderilemedi, lütfen daha sonra tekrar deneyin." };
    }
  } catch (err) {
    console.error("[whatsapp-widget] Mesaj gönderilirken hata:", err);
    return { success: false, error: "Mesaj gönderilemedi, lütfen daha sonra tekrar deneyin." };
  }

  return { success: true, error: null };
}
