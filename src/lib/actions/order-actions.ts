"use server";

import { prisma } from "@/lib/prisma";
import { auth } from "@/lib/auth";
import { resolveCoupon } from "@/lib/coupon";
import { resolveAuthoritativePrice } from "@/lib/product-pricing";
import { sendEmail } from "@/lib/email";
import { buildCustomerOrderEmail, buildAdminOrderAlertEmail } from "@/lib/order-email";
import { createAndSendOrderVerification } from "@/lib/order-verification";
import type { PaymentMethodType } from "@prisma/client";

export type CheckoutAddressInput = {
  email: string; // misafir siparişte iletişim/takip için zorunlu; giriş yapmışsa oturumdaki e-posta esas alınır
  title: string;
  fullName: string;
  phone: string;
  city: string;
  district: string;
  neighborhood?: string;
  addressLine: string;
  postalCode?: string;
};

export type CheckoutItemInput = {
  productId: string; // sepette tutulan değer — üründen product.slug (bkz. ProductDetailClient)
  productVariationId?: string;
  name: string;
  unitPrice: number; // sadece sepet önizlemesi için — sipariş tutarı burada DEĞİL, DB'den yeniden hesaplanır
  quantity: number;
  // Müşterinin bu satır için kurulum/montaj hizmeti istediği — sunucuda ürünün
  // gerçekten bu hizmeti sunup sunmadığı ve gerçek fiyatı yeniden doğrulanır
  // (bkz. resolveAuthoritativePrice), istemciden gelen fiyata güvenilmez.
  installationRequested?: boolean;
};

export type CreateOrderResult =
  | { success: true; orderNumber: string; orderId: string; emailVerificationRequired: boolean }
  | { success: false; error: string };

export async function createOrderAction(
  address: CheckoutAddressInput,
  items: CheckoutItemInput[],
  note?: string,
  couponCode?: string,
  paymentMethod: PaymentMethodType = "BANK_TRANSFER",
): Promise<CreateOrderResult> {
  const session = await auth();
  const userId = session?.user?.id;
  // Misafir sipariş: giriş şart değil, ama sipariş onayı/takibi için bir e-posta gerekir.
  const contactEmail = (session?.user?.email ?? address.email).trim();
  if (!contactEmail) {
    return { success: false, error: "Sipariş onayı için e-posta adresi gerekli." };
  }
  if (items.length === 0) {
    return { success: false, error: "Sepetiniz boş." };
  }

  try {
    // Satır fiyatları istemciden alınmaz; her satır için DB'deki güncel ürün/varyasyon
    // fiyatı yeniden okunur (bkz. resolveAuthoritativePrice) — devtools'tan unitPrice
    // değiştirilerek ödeme tutarının düşürülmesini engeller.
    const resolvedPrices = await Promise.all(
      items.map((item) =>
        resolveAuthoritativePrice({
          productId: item.productId,
          productVariationId: item.productVariationId,
          name: item.name,
        }),
      ),
    );

    const resolvedItems = items.map((item, i) => {
      // İstemci kurulum istese bile ürün bu hizmeti sunmuyorsa yok sayılır — fiyat her
      // zaman DB'deki Product.installationPrice'tan okunur (bkz. resolveAuthoritativePrice).
      const installationRequested = Boolean(item.installationRequested) && resolvedPrices[i].installationAvailable;
      const installationPrice = installationRequested ? resolvedPrices[i].installationPrice ?? 0 : 0;

      return {
        productId: resolvedPrices[i].productDbId,
        productVariationId: item.productVariationId,
        quantity: item.quantity,
        unitPrice: resolvedPrices[i].unitPrice,
        installationRequested,
        installationPrice,
        productNameSnapshot: item.name,
      };
    });

    const subtotal = resolvedItems.reduce((sum, item) => sum + item.unitPrice * item.quantity, 0);
    const installationTotal = resolvedItems.reduce(
      (sum, item) => sum + (item.installationRequested ? item.installationPrice * item.quantity : 0),
      0,
    );

    // İndirim tutarı istemciden alınmaz; kupon burada sunucu tarafında, az önce
    // doğrulanan gerçek fiyatlarla yeniden hesaplanır (süre, limit, kategori vb.
    // arada değişmiş olabilir).
    let couponId: string | undefined;
    let discountAmount = 0;
    if (couponCode) {
      const couponItems = items.map((item, i) => ({
        productId: item.productId,
        unitPrice: resolvedPrices[i].unitPrice,
        quantity: item.quantity,
      }));
      const couponResult = await resolveCoupon(couponCode, couponItems);
      if (!couponResult.success) {
        return { success: false, error: couponResult.error };
      }
      couponId = couponResult.coupon.id;
      discountAmount = couponResult.discountAmount;
    }

    const orderNumber = `OZ-${Date.now().toString(36).toUpperCase()}`;

    // Address modelinde email alanı yok — sadece teslimat bilgileri kaydedilir.
    const createdAddress = await prisma.address.create({
      data: {
        title: address.title,
        fullName: address.fullName,
        phone: address.phone,
        city: address.city,
        district: address.district,
        neighborhood: address.neighborhood,
        addressLine: address.addressLine,
        postalCode: address.postalCode,
        userId,
      },
    });

    const order = await prisma.$transaction(async (tx) => {
      // Stok düşümü — devtools'tan iki farklı sekmede aynı son ürünün satın alınmaya
      // çalışılması gibi durumlarda satışa kapanmasın diye koşullu update kullanılır:
      // stok yeterliyse satır etkilenir, değilse count 0 döner ve işlem geri alınır.
      for (const item of resolvedItems) {
        const result = item.productVariationId
          ? await tx.productVariation.updateMany({
              where: { id: item.productVariationId, stock: { gte: item.quantity } },
              data: { stock: { decrement: item.quantity } },
            })
          : await tx.product.updateMany({
              where: { id: item.productId, stock: { gte: item.quantity } },
              data: { stock: { decrement: item.quantity } },
            });
        if (result.count === 0) {
          throw new Error(`"${item.productNameSnapshot}" için yeterli stok kalmadı.`);
        }
      }

      const created = await tx.order.create({
        data: {
          orderNumber,
          userId,
          guestEmail: userId ? null : contactEmail,
          addressId: createdAddress.id,
          note,
          paymentMethod,
          subtotal,
          couponId,
          discountAmount,
          installationTotal,
          totalAmount: subtotal - discountAmount + installationTotal,
          items: { create: resolvedItems },
        },
      });

      if (couponId) {
        await tx.coupon.update({ where: { id: couponId }, data: { usedCount: { increment: 1 } } });
      }

      return created;
    });

    // Sipariş bildirimleri: müşteriye onay, işletme sahibine yeni sipariş uyarısı.
    // Best-effort — gönderim başarısız olsa bile sipariş zaten oluşturuldu, kullanıcıya
    // hata dönülmez (RESEND_API_KEY tanımlı değilse sendEmail sessizce atlar, bkz. lib/email.ts).
    const emailData = {
      orderNumber: order.orderNumber,
      status: order.status,
      items: resolvedItems.map((item) => ({
        name: item.productNameSnapshot,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        installationRequested: item.installationRequested,
        installationPrice: item.installationPrice,
      })),
      subtotal,
      discountAmount,
      installationTotal,
      totalAmount: Number(order.totalAmount),
      address,
      customerName: session?.user?.name ?? address.fullName,
      customerEmail: contactEmail,
      note,
    };

    // Google ile giriş yapan kullanıcının e-postası sağlayıcı tarafından zaten doğrulanmıştır
    // (bkz. lib/auth.ts signIn callback'i); diğer tüm durumlarda (misafir sipariş, şifreyle
    // kayıtlı henüz doğrulanmamış hesap) sipariş detaylarını içeren tam e-posta yerine önce
    // bir doğrulama bağlantısı gönderilir — detaylar ancak doğrulandıktan sonra iletilir
    // (bkz. lib/order-verification.ts, /siparis-dogrula).
    const dbUser = userId ? await prisma.user.findUnique({ where: { id: userId }, select: { emailVerified: true } }) : null;
    const isTrustedEmail = Boolean(dbUser?.emailVerified);

    await Promise.allSettled([
      isTrustedEmail
        ? sendEmail({ to: contactEmail, ...buildCustomerOrderEmail(emailData) })
        : createAndSendOrderVerification(order.id, contactEmail, order.orderNumber),
      process.env.ADMIN_EMAIL
        ? sendEmail({ to: process.env.ADMIN_EMAIL, ...buildAdminOrderAlertEmail(emailData) })
        : Promise.resolve(),
    ]).then((results) => {
      for (const result of results) {
        if (result.status === "rejected") {
          console.error("[sipariş bildirimi] E-posta gönderilemedi:", result.reason);
        }
      }
    });

    return { success: true, orderNumber: order.orderNumber, orderId: order.id, emailVerificationRequired: !isTrustedEmail };
  } catch (err) {
    console.error("createOrderAction hata:", err);
    const message = err instanceof Error ? err.message : "Sipariş oluşturulamadı.";
    return { success: false, error: message };
  }
}
