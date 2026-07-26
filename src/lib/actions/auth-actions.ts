"use server";

import bcrypt from "bcryptjs";
import { prisma } from "@/lib/prisma";
import { signIn } from "@/lib/auth";
import { AuthError } from "next-auth";

export type AuthActionState = { error: string | null };

export async function registerAction(
  _prevState: AuthActionState,
  formData: FormData,
): Promise<AuthActionState> {
  const name = String(formData.get("name") ?? "").trim();
  const email = String(formData.get("email") ?? "").trim().toLowerCase();
  const password = String(formData.get("password") ?? "");

  if (!name || !email || !password) {
    return { error: "Lütfen tüm alanları doldurun." };
  }
  if (password.length < 6) {
    return { error: "Şifre en az 6 karakter olmalı." };
  }

  const existing = await prisma.user.findUnique({ where: { email } });
  if (existing) {
    return { error: "Bu e-posta adresi zaten kayıtlı." };
  }

  const passwordHash = await bcrypt.hash(password, 10);
  await prisma.user.create({ data: { name, email, passwordHash } });

  try {
    await signIn("credentials", { email, password, redirectTo: "/" });
  } catch (err) {
    // NEXT_REDIRECT, signIn başarılı olduğunda fırlatılan normal bir kontrol akışı hatasıdır — yeniden fırlat.
    if (err instanceof AuthError) return { error: "Hesap oluşturuldu ama giriş yapılamadı, lütfen giriş yapın." };
    throw err;
  }

  return { error: null };
}

export async function loginAction(
  _prevState: AuthActionState,
  formData: FormData,
): Promise<AuthActionState> {
  const email = String(formData.get("email") ?? "").trim().toLowerCase();
  const password = String(formData.get("password") ?? "");

  if (!email || !password) {
    return { error: "Lütfen e-posta ve şifrenizi girin." };
  }

  try {
    await signIn("credentials", { email, password, redirectTo: "/" });
  } catch (err) {
    if (err instanceof AuthError) {
      return { error: "E-posta veya şifre hatalı." };
    }
    throw err;
  }

  return { error: null };
}
