"use server";

import { revalidatePath } from "next/cache";
import { prisma } from "@/lib/prisma";
import { requireAdmin } from "@/lib/auth";

export async function toggleMessageReadAction(formData: FormData) {
  await requireAdmin();
  const messageId = String(formData.get("messageId") ?? "");
  const currentlyRead = String(formData.get("isRead") ?? "") === "true";
  if (!messageId) return;

  await prisma.contactMessage.update({ where: { id: messageId }, data: { isRead: !currentlyRead } });
  revalidatePath("/admin/mesajlar");
  revalidatePath(`/admin/mesajlar/${messageId}`);
}
