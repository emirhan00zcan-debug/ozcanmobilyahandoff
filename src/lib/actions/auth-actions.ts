"use server";

import { randomBytes } from "crypto";
import bcrypt from "bcryptjs";
import { Prisma } from "@prisma/client";
import { prisma } from "@/lib/prisma";
import { signIn } from "@/lib/auth";
import { AuthError } from "next-auth";
import { sendEmail } from "@/lib/email";
import { absoluteUrl } from "@/lib/seo";

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

  // Önce ayrı bir "var mı?" sorgusu atmak yerine doğrudan create deneyip e-posta
  // unique constraint'ini yakalıyoruz — kayıt akışındaki DB round-trip sayısını
  // (ve bununla birlikte gecikmeyi) bire indiriyor.
  const passwordHash = await bcrypt.hash(password, 10);
  try {
    await prisma.user.create({ data: { name, email, passwordHash } });
  } catch (err) {
    if (err instanceof Prisma.PrismaClientKnownRequestError && err.code === "P2002") {
      return { error: "Bu e-posta adresi zaten kayıtlı." };
    }
    throw err;
  }

  try {
    // redirect: false — yönlendirmeyi burada değil, client'ta (session'ı senkronize
    // ettikten sonra) yapıyoruz; bkz. GirisClient.tsx.
    await signIn("credentials", { email, password, redirect: false });
  } catch (err) {
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
    // redirect: false — yönlendirmeyi burada değil, client'ta (session'ı senkronize
    // ettikten sonra) yapıyoruz; bkz. GirisClient.tsx.
    await signIn("credentials", { email, password, redirect: false });
  } catch (err) {
    if (err instanceof AuthError) {
      return { error: "E-posta veya şifre hatalı." };
    }
    throw err;
  }

  return { error: null };
}

export type RequestResetState = { error: string | null; message: string | null };

export async function requestPasswordResetAction(
  _prevState: RequestResetState,
  formData: FormData,
): Promise<RequestResetState> {
  const email = String(formData.get("email") ?? "").trim().toLowerCase();
  if (!email) {
    return { error: "Lütfen e-posta adresinizi girin.", message: null };
  }

  const user = await prisma.user.findUnique({ where: { email } });
  // Hesap var mı yok mu bilgisini sızdırmamak (e-posta enumeration) için kullanıcı
  // bulunsun bulunmasın aynı genel mesaj döner; token sadece kullanıcı gerçekten varsa üretilir.
  if (user?.passwordHash) {
    const token = randomBytes(32).toString("hex");
    await prisma.verificationToken.deleteMany({ where: { identifier: email } });
    await prisma.verificationToken.create({
      data: { identifier: email, token, expires: new Date(Date.now() + 60 * 60 * 1000) },
    });

    const resetLink = absoluteUrl(`/sifremi-sifirla?token=${token}`);
    await sendEmail({
      to: email,
      subject: "Şifre Sıfırlama Bağlantısı - Özcan Mobilya",
      text: `Şifrenizi sıfırlamak için aşağıdaki bağlantıya tıklayın:\n\n${resetLink}\n\nBu bağlantı 1 saat boyunca geçerlidir. Eğer bu işlemi siz yapmadıysanız, bu e-postayı dikkate almayabilirsiniz.`,
    });
  }

  return {
    error: null,
    message: "Bu e-posta adresi sistemimizde kayıtlıysa, şifre sıfırlama bağlantısı gönderildi.",
  };
}

export type ResetPasswordState = { error: string | null; success: boolean };

export async function resetPasswordAction(
  _prevState: ResetPasswordState,
  formData: FormData,
): Promise<ResetPasswordState> {
  const token = String(formData.get("token") ?? "");
  const password = String(formData.get("password") ?? "");

  if (!token) {
    return { error: "Geçersiz veya süresi dolmuş bağlantı.", success: false };
  }
  if (password.length < 6) {
    return { error: "Şifre en az 6 karakter olmalı.", success: false };
  }

  const record = await prisma.verificationToken.findUnique({ where: { token } });
  if (!record || record.expires < new Date()) {
    return { error: "Geçersiz veya süresi dolmuş bağlantı.", success: false };
  }

  const passwordHash = await bcrypt.hash(password, 10);
  await prisma.user.update({ where: { email: record.identifier }, data: { passwordHash } });
  await prisma.verificationToken.delete({ where: { token } });

  return { error: null, success: true };
}
