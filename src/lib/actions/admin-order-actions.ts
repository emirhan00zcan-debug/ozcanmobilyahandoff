"use server";

import { revalidatePath } from "next/cache";
import { prisma } from "@/lib/prisma";
import { requireAdmin } from "@/lib/auth";
import type { OrderStatus, PaymentStatus } from "@prisma/client";

export async function updateOrderStatusAction(formData: FormData) {
  await requireAdmin();
  const orderId = String(formData.get("orderId") ?? "");
  const status = String(formData.get("status") ?? "") as OrderStatus;
  if (!orderId || !status) return;

  await prisma.order.update({ where: { id: orderId }, data: { status } });
  revalidatePath("/admin/siparisler");
  revalidatePath(`/admin/siparisler/${orderId}`);
}

export async function updateOrderPaymentStatusAction(formData: FormData) {
  await requireAdmin();
  const orderId = String(formData.get("orderId") ?? "");
  const paymentStatus = String(formData.get("paymentStatus") ?? "") as PaymentStatus;
  if (!orderId || !paymentStatus) return;

  await prisma.order.update({ where: { id: orderId }, data: { paymentStatus } });
  revalidatePath("/admin/siparisler");
  revalidatePath(`/admin/siparisler/${orderId}`);
}

export async function updateOrderTrackingAction(formData: FormData) {
  await requireAdmin();
  const orderId = String(formData.get("orderId") ?? "");
  if (!orderId) return;
  const trackingNumber = String(formData.get("trackingNumber") ?? "").trim();

  await prisma.order.update({
    where: { id: orderId },
    data: { trackingNumber: trackingNumber || null },
  });
  revalidatePath(`/admin/siparisler/${orderId}`);
}
