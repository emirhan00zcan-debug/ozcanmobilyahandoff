"use server";

import { revalidatePath } from "next/cache";
import { prisma } from "@/lib/prisma";
import { requireUser } from "@/lib/auth";

export type ReviewActionState = { success: boolean; error: string | null };

// Sadece teslim edilmiş bir siparişte geçen ürünler için yorum yapılabilir — sipariş
// sahipliği ve teslimat durumu burada, sunucu tarafında yeniden doğrulanır (bkz.
// OrderItemReview bileşeni, ürün sayfasındaki "Sizden Gelenler" bölümüne düşer).
export async function submitReviewAction(
  _prevState: ReviewActionState,
  formData: FormData,
): Promise<ReviewActionState> {
  const session = await requireUser("/hesabim");
  const userId = session.user.id;

  const productId = String(formData.get("productId") ?? "");
  const rating = Number(formData.get("rating"));
  const comment = String(formData.get("comment") ?? "").trim();

  if (!productId) return { success: false, error: "Ürün bulunamadı." };
  if (!Number.isInteger(rating) || rating < 1 || rating > 5) {
    return { success: false, error: "Lütfen 1 ile 5 arasında bir puan seçin." };
  }
  if (!comment) return { success: false, error: "Lütfen yorumunuzu yazın." };

  const purchased = await prisma.orderItem.findFirst({
    where: { productId, order: { userId, status: "DELIVERED" } },
  });
  if (!purchased) {
    return {
      success: false,
      error: "Bu ürünü yalnızca teslim aldığınız bir siparişte satın aldıysanız değerlendirebilirsiniz.",
    };
  }

  const existing = await prisma.review.findUnique({
    where: { userId_productId: { userId, productId } },
  });
  if (existing) {
    return { success: false, error: "Bu ürünü daha önce değerlendirdiniz." };
  }

  await prisma.review.create({
    data: { productId, userId, rating, comment },
  });

  revalidatePath("/hesabim");
  revalidatePath("/urun/[slug]", "page");

  return { success: true, error: null };
}
