"use server";

import { revalidatePath } from "next/cache";
import { prisma } from "@/lib/prisma";
import { requireUser } from "@/lib/auth";
import type { PaymentMethodType } from "@prisma/client";

export type PaymentMethodActionState = { success: boolean; error: string | null };

// PayTR entegrasyonu tamamlanana kadar sadece kart gerektirmeyen tipler eklenebilir —
// CARD arayüzde "yakında" olarak gösteriliyor, seçilemiyor; buraya CARD ile gelinmesi
// beklenmez ama yine de reddedilir.
const ALLOWED_TYPES: PaymentMethodType[] = ["CASH_ON_DELIVERY", "BANK_TRANSFER"];

export async function createPaymentMethodAction(
  _prevState: PaymentMethodActionState,
  formData: FormData,
): Promise<PaymentMethodActionState> {
  const session = await requireUser("/hesabim");
  const type = String(formData.get("type") ?? "") as PaymentMethodType;
  const label = String(formData.get("label") ?? "").trim();

  if (!ALLOWED_TYPES.includes(type)) {
    return { success: false, error: "Geçersiz ödeme yöntemi." };
  }

  const isFirst = (await prisma.paymentMethod.count({ where: { userId: session.user.id } })) === 0;

  await prisma.paymentMethod.create({
    data: { userId: session.user.id, type, label: label || null, isDefault: isFirst },
  });

  revalidatePath("/hesabim");
  return { success: true, error: null };
}

export async function deletePaymentMethodAction(formData: FormData) {
  const session = await requireUser("/hesabim");
  const id = String(formData.get("paymentMethodId") ?? "");
  if (!id) return;

  const existing = await prisma.paymentMethod.findFirst({ where: { id, userId: session.user.id } });
  if (!existing) return;

  await prisma.paymentMethod.delete({ where: { id } });

  if (existing.isDefault) {
    const next = await prisma.paymentMethod.findFirst({
      where: { userId: session.user.id },
      orderBy: { createdAt: "asc" },
    });
    if (next) {
      await prisma.paymentMethod.update({ where: { id: next.id }, data: { isDefault: true } });
    }
  }

  revalidatePath("/hesabim");
}

export async function setDefaultPaymentMethodAction(formData: FormData) {
  const session = await requireUser("/hesabim");
  const id = String(formData.get("paymentMethodId") ?? "");
  if (!id) return;

  const existing = await prisma.paymentMethod.findFirst({ where: { id, userId: session.user.id } });
  if (!existing) return;

  await prisma.$transaction([
    prisma.paymentMethod.updateMany({ where: { userId: session.user.id }, data: { isDefault: false } }),
    prisma.paymentMethod.update({ where: { id }, data: { isDefault: true } }),
  ]);

  revalidatePath("/hesabim");
}
