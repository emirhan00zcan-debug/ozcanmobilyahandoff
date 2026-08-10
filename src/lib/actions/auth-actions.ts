"use server";

import { randomBytes, randomInt } from "crypto";
import bcrypt from "bcryptjs";
import { Prisma } from "@prisma/client";
import { prisma } from "@/lib/prisma";
import { signIn } from "@/lib/auth";
import { AuthError } from "next-auth";
import { sendEmail } from "@/lib/email";
import { absoluteUrl } from "@/lib/seo";

export type AuthActionState = { error: string | null };

const REGISTER_CODE_EXPIRY_MS = 15 * 60 * 1000; // 15 dakika

function generateSixDigitCode(): string {
  return randomInt(0, 1_000_000).toString().padStart(6, "0");
}

export type RegisterActionState = { error: string | null; codeSent: boolean };

// Hesap hemen oluşturulur ama e-posta doğrulanana kadar oturum açılmaz — bunun yerine
// e-postaya 6 haneli bir kod gönderilir (VerificationToken'da tutulur, bkz.
// requestPasswordResetAction'daki aynı desen). Kod GirisClient.tsx'te verifyRegisterCodeAction'a
// gönderilince asıl signIn() orada tetiklenir.
export async function registerAction(
  _prevState: RegisterActionState,
  formData: FormData,
): Promise<RegisterActionState> {
  const name = String(formData.get("name") ?? "").trim();
  const email = String(formData.get("email") ?? "").trim().toLowerCase();
  const password = String(formData.get("password") ?? "");

  if (!name || !email || !password) {
    return { error: "Lütfen tüm alanları doldurun.", codeSent: false };
  }
  if (password.length < 6) {
    return { error: "Şifre en az 6 karakter olmalı.", codeSent: false };
  }

  // Önce ayrı bir "var mı?" sorgusu atmak yerine doğrudan create deneyip e-posta
  // unique constraint'ini yakalıyoruz — kayıt akışındaki DB round-trip sayısını
  // (ve bununla birlikte gecikmeyi) bire indiriyor.
  const passwordHash = await bcrypt.hash(password, 10);
  try {
    await prisma.user.create({ data: { name, email, passwordHash } });
  } catch (err) {
    if (err instanceof Prisma.PrismaClientKnownRequestError && err.code === "P2002") {
      return { error: "Bu e-posta adresi zaten kayıtlı.", codeSent: false };
    }
    throw err;
  }

  const code = generateSixDigitCode();
  await prisma.verificationToken.deleteMany({ where: { identifier: email } });
  await prisma.verificationToken.create({
    data: { identifier: email, token: code, expires: new Date(Date.now() + REGISTER_CODE_EXPIRY_MS) },
  });

  await sendEmail({
    to: email,
    subject: "Hesabınızı Doğrulayın - Özcan Mobilya",
    text: `Merhaba ${name},\n\nHesabınızı doğrulamak için aşağıdaki kodu girin:\n\n${code}\n\nBu kod 15 dakika boyunca geçerlidir. Eğer bu işlemi siz yapmadıysanız, bu e-postayı dikkate almayabilirsiniz.`,
  });

  return { error: null, codeSent: true };
}

export type VerifyCodeState = { error: string | null };

export async function verifyRegisterCodeAction(
  _prevState: VerifyCodeState,
  formData: FormData,
): Promise<VerifyCodeState> {
  const email = String(formData.get("email") ?? "").trim().toLowerCase();
  const password = String(formData.get("password") ?? "");
  const code = String(formData.get("code") ?? "").trim();

  if (!code) {
    return { error: "Lütfen doğrulama kodunu girin." };
  }

  const record = await prisma.verificationToken.findUnique({ where: { token: code } });
  if (!record || record.identifier !== email || record.expires < new Date()) {
    return { error: "Kod hatalı veya süresinin dolmuş, lütfen tekrar kayıt olun." };
  }

  await prisma.verificationToken.delete({ where: { token: code } });
  await prisma.user.update({ where: { email }, data: { emailVerified: new Date() } });

  try {
    // redirect: false — yönlendirmeyi burada değil, client'ta (session'ı senkronize
    // ettikten sonra) yapıyoruz; bkz. GirisClient.tsx.
    await signIn("credentials", { email, password, redirect: false });
  } catch (err) {
    if (err instanceof AuthError) return { error: "Hesap doğrulandı ama giriş yapılamadı, lütfen giriş yapın." };
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
