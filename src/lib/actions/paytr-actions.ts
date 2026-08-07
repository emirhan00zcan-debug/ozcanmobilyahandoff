"use server";

import { headers } from "next/headers";
import { getPaytrIframeToken, type PaytrBasketItem } from "@/lib/payment/paytr";

export type RequestPaytrTokenInput = {
  orderId: string;
  amount: number;
  customerName: string;
  customerEmail: string;
  customerPhone: string;
  customerAddress: string;
  basket: PaytrBasketItem[];
};

export type RequestPaytrTokenResult = { success: true; token: string } | { success: false; error: string };

// CheckoutClient'ın "Kredi Kartı" seçilip PENDING sipariş oluşturulduktan sonra çağırdığı ince
// katman — PayTR'ın paytr_token hash'i için zorunlu olan kullanıcı IP'sini istek başlıklarından
// okuyup asıl işi yapan lib/payment/paytr.ts'e devreder.
export async function requestPaytrIframeTokenAction(input: RequestPaytrTokenInput): Promise<RequestPaytrTokenResult> {
  const headersList = await headers();
  const forwardedFor = headersList.get("x-forwarded-for");
  const userIp = forwardedFor?.split(",")[0]?.trim() || headersList.get("x-real-ip") || "127.0.0.1";

  try {
    return await getPaytrIframeToken({
      orderId: input.orderId,
      amount: input.amount,
      userIp,
      email: input.customerEmail,
      userName: input.customerName,
      userAddress: input.customerAddress,
      userPhone: input.customerPhone,
      basket: input.basket,
    });
  } catch (err) {
    console.error("requestPaytrIframeTokenAction hata:", err);
    const message = err instanceof Error ? err.message : "Ödeme sayfası oluşturulamadı.";
    return { success: false, error: message };
  }
}
