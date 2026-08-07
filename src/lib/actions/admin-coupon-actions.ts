"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { prisma } from "@/lib/prisma";
import { requireAdmin } from "@/lib/auth";
import type { DiscountType } from "@prisma/client";

export type CouponFormState = { error: string | null };

type ParsedCouponForm =
  | { ok: false; error: string }
  | {
      ok: true;
      data: {
        code: string;
        discountType: DiscountType;
        discountValue: number;
        description: string | null;
        minOrderAmount: number | null;
        maxDiscountAmount: number | null;
        categoryId: string | null;
        startsAt: Date;
        endsAt: Date;
        usageLimit: number | null;
        isActive: boolean;
      };
    };

function parseCouponForm(formData: FormData): ParsedCouponForm {
  const code = String(formData.get("code") ?? "").trim().toUpperCase();
  const discountType = String(formData.get("discountType") ?? "") as DiscountType;
  const discountValueRaw = String(formData.get("discountValue") ?? "").trim();
  const description = String(formData.get("description") ?? "").trim();
  const minOrderAmountRaw = String(formData.get("minOrderAmount") ?? "").trim();
  const maxDiscountAmountRaw = String(formData.get("maxDiscountAmount") ?? "").trim();
  const categoryId = String(formData.get("categoryId") ?? "").trim();
  const startsAtRaw = String(formData.get("startsAt") ?? "").trim();
  const endsAtRaw = String(formData.get("endsAt") ?? "").trim();
  const usageLimitRaw = String(formData.get("usageLimit") ?? "").trim();
  const isActive = formData.get("isActive") === "on";

  if (!code || !discountType || !discountValueRaw || !startsAtRaw || !endsAtRaw) {
    return { ok: false, error: "Lütfen kod, indirim tipi, değer ve tarih alanlarını doldurun." };
  }
  if (discountType !== "PERCENTAGE" && discountType !== "FIXED_AMOUNT") {
    return { ok: false, error: "Geçersiz indirim tipi." };
  }

  const discountValue = Number(discountValueRaw);
  if (!Number.isFinite(discountValue) || discountValue <= 0) {
    return { ok: false, error: "Geçerli bir indirim değeri girin." };
  }

  const startsAt = new Date(startsAtRaw);
  const endsAt = new Date(endsAtRaw);
  if (Number.isNaN(startsAt.getTime()) || Number.isNaN(endsAt.getTime())) {
    return { ok: false, error: "Geçerli bir tarih girin." };
  }
  if (endsAt <= startsAt) {
    return { ok: false, error: "Bitiş tarihi başlangıç tarihinden sonra olmalı." };
  }

  const minOrderAmount = minOrderAmountRaw ? Number(minOrderAmountRaw) : null;
  if (minOrderAmount !== null && (!Number.isFinite(minOrderAmount) || minOrderAmount < 0)) {
    return { ok: false, error: "Geçerli bir minimum sepet tutarı girin." };
  }

  const maxDiscountAmount = maxDiscountAmountRaw ? Number(maxDiscountAmountRaw) : null;
  if (maxDiscountAmount !== null && (!Number.isFinite(maxDiscountAmount) || maxDiscountAmount < 0)) {
    return { ok: false, error: "Geçerli bir üst sınır tutarı girin." };
  }

  const usageLimit = usageLimitRaw ? Number.parseInt(usageLimitRaw, 10) : null;
  if (usageLimit !== null && (!Number.isFinite(usageLimit) || usageLimit <= 0)) {
    return { ok: false, error: "Geçerli bir kullanım limiti girin." };
  }

  return {
    ok: true,
    data: {
      code,
      discountType,
      discountValue,
      description: description || null,
      minOrderAmount,
      maxDiscountAmount,
      categoryId: categoryId || null,
      startsAt,
      endsAt,
      usageLimit,
      isActive,
    },
  };
}

export async function createCouponAction(
  _prevState: CouponFormState,
  formData: FormData,
): Promise<CouponFormState> {
  await requireAdmin();
  const parsed = parseCouponForm(formData);
  if (!parsed.ok) return { error: parsed.error };

  const existing = await prisma.coupon.findUnique({ where: { code: parsed.data.code } });
  if (existing) return { error: `"${parsed.data.code}" kodu zaten kullanılıyor.` };

  const coupon = await prisma.coupon.create({ data: parsed.data });

  revalidatePath("/admin/kuponlar");
  redirect(`/admin/kuponlar/${coupon.id}`);
}

export async function updateCouponAction(
  couponId: string,
  _prevState: CouponFormState,
  formData: FormData,
): Promise<CouponFormState> {
  await requireAdmin();
  const parsed = parseCouponForm(formData);
  if (!parsed.ok) return { error: parsed.error };

  const codeOwner = await prisma.coupon.findUnique({ where: { code: parsed.data.code } });
  if (codeOwner && codeOwner.id !== couponId) {
    return { error: `"${parsed.data.code}" kodu başka bir kuponda kullanılıyor.` };
  }

  await prisma.coupon.update({ where: { id: couponId }, data: parsed.data });

  revalidatePath("/admin/kuponlar");
  revalidatePath(`/admin/kuponlar/${couponId}`);
  return { error: null };
}

export async function toggleCouponActiveAction(formData: FormData) {
  await requireAdmin();
  const couponId = String(formData.get("couponId") ?? "");
  const currentlyActive = String(formData.get("isActive") ?? "") === "true";
  if (!couponId) return;

  await prisma.coupon.update({ where: { id: couponId }, data: { isActive: !currentlyActive } });
  revalidatePath("/admin/kuponlar");
}
