"use server";

import { revalidatePath } from "next/cache";
import { prisma } from "@/lib/prisma";
import { requireUser } from "@/lib/auth";

export type AddressActionState = { success: boolean; error: string | null };

function parseAddressForm(formData: FormData) {
  return {
    title: String(formData.get("title") ?? "").trim() || "Adres",
    fullName: String(formData.get("fullName") ?? "").trim(),
    phone: String(formData.get("phone") ?? "").trim(),
    city: String(formData.get("city") ?? "").trim(),
    district: String(formData.get("district") ?? "").trim(),
    addressLine: String(formData.get("addressLine") ?? "").trim(),
    postalCode: String(formData.get("postalCode") ?? "").trim() || null,
  };
}

function validateAddress(data: ReturnType<typeof parseAddressForm>): string | null {
  if (!data.fullName || !data.phone || !data.city || !data.district || !data.addressLine) {
    return "Lütfen tüm zorunlu alanları doldurun.";
  }
  return null;
}

export async function createAddressAction(
  _prevState: AddressActionState,
  formData: FormData,
): Promise<AddressActionState> {
  const session = await requireUser("/hesabim");
  const data = parseAddressForm(formData);
  const error = validateAddress(data);
  if (error) return { success: false, error };

  const isFirstAddress = (await prisma.address.count({ where: { userId: session.user.id } })) === 0;

  await prisma.address.create({
    data: { ...data, userId: session.user.id, isDefault: isFirstAddress },
  });

  revalidatePath("/hesabim");
  return { success: true, error: null };
}

export async function updateAddressAction(
  _prevState: AddressActionState,
  formData: FormData,
): Promise<AddressActionState> {
  const session = await requireUser("/hesabim");
  const addressId = String(formData.get("addressId") ?? "");
  const data = parseAddressForm(formData);
  const error = validateAddress(data);
  if (error) return { success: false, error };

  const existing = await prisma.address.findFirst({ where: { id: addressId, userId: session.user.id } });
  if (!existing) return { success: false, error: "Adres bulunamadı." };

  await prisma.address.update({ where: { id: addressId }, data });

  revalidatePath("/hesabim");
  return { success: true, error: null };
}

// Bir siparişte kullanılmış adres FK kısıtlaması nedeniyle silinemez (bkz. Order.addressId) —
// asıl engelleme /hesabim'in liste sorgusunda yapılıyor (kullanılan adreslerde "Sil" hiç
// gösterilmiyor); burası sadece savunma amaçlı ikinci bir kontrol.
export async function deleteAddressAction(formData: FormData) {
  const session = await requireUser("/hesabim");
  const addressId = String(formData.get("addressId") ?? "");
  if (!addressId) return;

  const existing = await prisma.address.findFirst({ where: { id: addressId, userId: session.user.id } });
  if (!existing) return;

  const usedInOrder = await prisma.order.findFirst({ where: { addressId } });
  if (usedInOrder) return;

  await prisma.address.delete({ where: { id: addressId } });

  if (existing.isDefault) {
    const next = await prisma.address.findFirst({
      where: { userId: session.user.id },
      orderBy: { createdAt: "asc" },
    });
    if (next) {
      await prisma.address.update({ where: { id: next.id }, data: { isDefault: true } });
    }
  }

  revalidatePath("/hesabim");
}

export async function setDefaultAddressAction(formData: FormData) {
  const session = await requireUser("/hesabim");
  const addressId = String(formData.get("addressId") ?? "");
  if (!addressId) return;

  const existing = await prisma.address.findFirst({ where: { id: addressId, userId: session.user.id } });
  if (!existing) return;

  await prisma.$transaction([
    prisma.address.updateMany({ where: { userId: session.user.id }, data: { isDefault: false } }),
    prisma.address.update({ where: { id: addressId }, data: { isDefault: true } }),
  ]);

  revalidatePath("/hesabim");
}
