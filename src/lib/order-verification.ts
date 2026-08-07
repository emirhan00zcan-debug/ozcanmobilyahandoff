// Sipariş onay e-postasının gönderilmesi için gereken e-posta doğrulama akışı — Google ile
// giriş yapan kullanıcılar hariç (bkz. lib/auth.ts signIn callback'i, User.emailVerified),
// misafir siparişlerde ve şifreyle kayıtlı henüz doğrulanmamış hesaplarda devreye girer.
// bkz. lib/actions/order-actions.ts (tetikleme) ve app/(marketing)/siparis-dogrula (tüketim).

import { randomInt } from "crypto";
import { prisma } from "@/lib/prisma";
import { sendEmail } from "@/lib/email";
import { absoluteUrl } from "@/lib/seo";
import { buildCustomerOrderEmail, type OrderEmailData } from "@/lib/order-email";

const CODE_EXPIRY_MS = 30 * 60 * 1000; // 30 dakika

function generateCode(): string {
  return randomInt(0, 1_000_000).toString().padStart(6, "0");
}

// Var olan bir kod satırını (ilk gönderim veya "yeniden gönder") üzerine yazar — sipariş
// başına tek aktif kod olur (bkz. schema.prisma EmailVerificationCode.orderId @unique).
export async function createAndSendOrderVerification(
  orderId: string,
  email: string,
  orderNumber: string,
): Promise<void> {
  const code = generateCode();
  const expires = new Date(Date.now() + CODE_EXPIRY_MS);

  await prisma.emailVerificationCode.upsert({
    where: { orderId },
    update: { email, code, expires, verifiedAt: null },
    create: { orderId, email, code, expires },
  });

  const verifyUrl = absoluteUrl(`/siparis-dogrula?order=${encodeURIComponent(orderNumber)}&code=${code}`);

  await sendEmail({
    to: email,
    subject: `E-postanızı Doğrulayın — Sipariş ${orderNumber}`,
    text: `Merhaba,

${orderNumber} numaralı siparişinizin detaylarını bu adrese gönderebilmemiz için e-posta adresinizi doğrulamanız gerekiyor.

Doğrulama bağlantısı (30 dakika geçerlidir):
${verifyUrl}

Bu isteği siz yapmadıysanız bu e-postayı yok sayabilirsiniz.

Özcan Mobilya`,
  });
}

export type ConfirmOrderVerificationResult =
  | { success: true; orderNumber: string; alreadyVerified: boolean }
  | { success: false; error: string; orderNumber?: string };

// /siparis-dogrula sayfasından çağrılır — kod doğruysa hesabı (varsa) kalıcı olarak
// doğrulanmış işaretler ve o ana kadar bekletilen tam sipariş onay e-postasını gönderir.
export async function confirmOrderVerification(
  orderNumber: string,
  code: string,
): Promise<ConfirmOrderVerificationResult> {
  const order = await prisma.order.findUnique({
    where: { orderNumber },
    include: { emailVerification: true, user: true, items: true, address: true },
  });

  if (!order || !order.emailVerification) {
    return { success: false, error: "Doğrulama bağlantısı geçersiz." };
  }

  const record = order.emailVerification;

  // Bağlantıya tekrar tıklanmış olabilir (örn. e-posta önizlemesi) — hata göstermek yerine
  // zaten doğrulandığını bildir.
  if (record.verifiedAt) {
    return { success: true, orderNumber: order.orderNumber, alreadyVerified: true };
  }
  if (record.expires < new Date()) {
    return { success: false, error: "Doğrulama bağlantısının süresi dolmuş.", orderNumber: order.orderNumber };
  }
  if (record.code !== code) {
    return { success: false, error: "Doğrulama kodu hatalı.", orderNumber: order.orderNumber };
  }

  await prisma.emailVerificationCode.update({
    where: { orderId: order.id },
    data: { verifiedAt: new Date() },
  });

  if (order.userId) {
    await prisma.user.update({ where: { id: order.userId }, data: { emailVerified: new Date() } });
  }

  const emailData: OrderEmailData = {
    orderNumber: order.orderNumber,
    status: order.status,
    items: order.items.map((item) => ({
      name: item.productNameSnapshot,
      quantity: item.quantity,
      unitPrice: Number(item.unitPrice),
      installationRequested: item.installationRequested,
      installationPrice: Number(item.installationPrice),
    })),
    subtotal: Number(order.subtotal),
    discountAmount: Number(order.discountAmount),
    installationTotal: Number(order.installationTotal),
    totalAmount: Number(order.totalAmount),
    address: {
      fullName: order.address.fullName,
      phone: order.address.phone,
      city: order.address.city,
      district: order.address.district,
      addressLine: order.address.addressLine,
    },
    customerName: order.user?.name ?? order.address.fullName,
    customerEmail: record.email,
  };

  await sendEmail({ to: record.email, ...buildCustomerOrderEmail(emailData) });

  return { success: true, orderNumber: order.orderNumber, alreadyVerified: false };
}
