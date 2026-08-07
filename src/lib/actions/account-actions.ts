"use server";

import { revalidatePath } from "next/cache";
import { prisma } from "@/lib/prisma";
import { requireUser } from "@/lib/auth";

export type UpdateProfileState = { success: boolean; error: string | null };

export async function updateProfileAction(
  _prevState: UpdateProfileState,
  formData: FormData,
): Promise<UpdateProfileState> {
  const session = await requireUser("/hesabim");

  const name = String(formData.get("name") ?? "").trim();
  const phone = String(formData.get("phone") ?? "").trim();

  if (!name) {
    return { success: false, error: "Ad Soyad boş olamaz." };
  }

  await prisma.user.update({
    where: { id: session.user.id },
    data: { name, phone: phone || null },
  });

  revalidatePath("/hesabim");
  return { success: true, error: null };
}
