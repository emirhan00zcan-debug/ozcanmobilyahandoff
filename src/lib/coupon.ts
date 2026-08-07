import { prisma } from "@/lib/prisma";

export type CouponCartItem = {
  productId: string; // sepette tutulan değer — product.slug (bkz. CheckoutItemInput)
  unitPrice: number;
  quantity: number;
};

export type CouponValidationResult =
  | {
      success: true;
      coupon: { id: string; code: string; description: string | null };
      discountAmount: number;
    }
  | { success: false; error: string };

// Ödeme adımındaki "Uygula" tıklamasında ve sipariş oluşturulurken (yeniden,
// sunucu tarafında) aynı kuralları uygulamak için tek bir yerden okunur —
// istemciden gelen indirim tutarına güvenilmez.
export async function resolveCoupon(
  code: string,
  items: CouponCartItem[],
): Promise<CouponValidationResult> {
  const normalizedCode = code.trim().toUpperCase();
  if (!normalizedCode) {
    return { success: false, error: "Kupon kodu giriniz." };
  }

  const coupon = await prisma.coupon.findUnique({ where: { code: normalizedCode } });
  if (!coupon || !coupon.isActive) {
    return { success: false, error: "Geçersiz kupon kodu." };
  }

  const now = new Date();
  if (now < coupon.startsAt || now > coupon.endsAt) {
    return { success: false, error: "Bu kuponun süresi dolmuş." };
  }
  if (coupon.usageLimit !== null && coupon.usedCount >= coupon.usageLimit) {
    return { success: false, error: "Bu kupon kullanım limitine ulaştı." };
  }

  const fullSubtotal = items.reduce((sum, item) => sum + item.unitPrice * item.quantity, 0);

  // Kategori kısıtlaması varsa (örn. FLAS20 -> sadece gardırop), indirim sadece
  // o kategorideki satırlar üzerinden hesaplanır.
  let eligibleSubtotal = fullSubtotal;
  if (coupon.categoryId) {
    const products = await prisma.product.findMany({
      where: { slug: { in: items.map((item) => item.productId) } },
      select: { slug: true, categoryId: true },
    });
    const categoryBySlug = new Map(products.map((p) => [p.slug, p.categoryId]));
    eligibleSubtotal = items.reduce(
      (sum, item) =>
        categoryBySlug.get(item.productId) === coupon.categoryId
          ? sum + item.unitPrice * item.quantity
          : sum,
      0,
    );
    if (eligibleSubtotal <= 0) {
      return { success: false, error: "Bu kupon sepetinizdeki ürünler için geçerli değil." };
    }
  }

  if (coupon.minOrderAmount && fullSubtotal < Number(coupon.minOrderAmount)) {
    return {
      success: false,
      error: `Bu kupon en az ${Number(coupon.minOrderAmount).toLocaleString("tr-TR")} TL'lik siparişlerde geçerlidir.`,
    };
  }

  let discountAmount =
    coupon.discountType === "PERCENTAGE"
      ? (eligibleSubtotal * Number(coupon.discountValue)) / 100
      : Number(coupon.discountValue);

  if (coupon.maxDiscountAmount) {
    discountAmount = Math.min(discountAmount, Number(coupon.maxDiscountAmount));
  }
  discountAmount = Math.round(Math.min(discountAmount, eligibleSubtotal) * 100) / 100;

  return {
    success: true,
    coupon: { id: coupon.id, code: coupon.code, description: coupon.description },
    discountAmount,
  };
}
