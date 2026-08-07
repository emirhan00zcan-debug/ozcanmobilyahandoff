"use server";

import { prisma } from "@/lib/prisma";
import { createAndSendOrderVerification } from "@/lib/order-verification";

export type ResendVerificationState = { message: string | null };

// /siparis-dogrula sayfasında bağlantının süresi dolmuş/geçersiz çıkarsa gösterilen
// "Yeniden Gönder" formu için — sipariş sahibi olmayan birinin rastgele bir sipariş
// numarasına e-posta doğrulaması tetiklememesi için girilen e-postanın siparişteki
// adresle eşleşmesi şart; eşleşmese bile enumeration'ı önlemek için aynı genel mesaj döner.
export async function resendOrderVerificationAction(
  _prevState: ResendVerificationState,
  formData: FormData,
): Promise<ResendVerificationState> {
  const orderNumber = String(formData.get("orderNumber") ?? "").trim();
  const email = String(formData.get("email") ?? "").trim().toLowerCase();

  if (orderNumber && email) {
    const order = await prisma.order.findUnique({
      where: { orderNumber },
      include: { user: true, emailVerification: true },
    });
    const orderEmail = (order?.user?.email ?? order?.guestEmail)?.toLowerCase();

    if (order && orderEmail === email && !order.emailVerification?.verifiedAt) {
      await createAndSendOrderVerification(order.id, orderEmail, order.orderNumber);
    }
  }

  return {
    message: "Bu sipariş numarası ve e-posta eşleşiyorsa, yeni bir doğrulama bağlantısı gönderildi.",
  };
}
