"use server";

import { resolveCoupon } from "@/lib/coupon";
import { resolveAuthoritativePrice } from "@/lib/product-pricing";

export type ApplyCouponItemInput = {
  productId: string; // product.slug
  productVariationId?: string;
  name: string;
  quantity: number;
};

export type ApplyCouponResult =
  | { success: true; code: string; description: string | null; discountAmount: number }
  | { success: false; error: string };

export async function applyCouponAction(
  code: string,
  items: ApplyCouponItemInput[],
): Promise<ApplyCouponResult> {
  // İndirim önizlemesi de istemciden gelen unitPrice yerine DB'deki gerçek fiyatla
  // hesaplanır — aksi halde "Uygula" adımında gösterilen tutar, siparişte gerçekte
  // uygulanacak tutardan farklı (ve manipüle edilebilir) olurdu.
  let resolvedItems;
  try {
    resolvedItems = await Promise.all(
      items.map(async (item) => {
        const { unitPrice } = await resolveAuthoritativePrice({
          productId: item.productId,
          productVariationId: item.productVariationId,
          name: item.name,
        });
        return { productId: item.productId, unitPrice, quantity: item.quantity };
      }),
    );
  } catch (err) {
    const message = err instanceof Error ? err.message : "Sepet doğrulanamadı.";
    return { success: false, error: message };
  }

  const result = await resolveCoupon(code, resolvedItems);
  if (!result.success) return result;

  return {
    success: true,
    code: result.coupon.code,
    description: result.coupon.description,
    discountAmount: result.discountAmount,
  };
}
