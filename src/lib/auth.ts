import { redirect } from "next/navigation";
import NextAuth from "next-auth";
import Credentials from "next-auth/providers/credentials";
import Google from "next-auth/providers/google";
import Apple from "next-auth/providers/apple";
import type { Provider } from "next-auth/providers";
import bcrypt from "bcryptjs";
import { PrismaAdapter } from "@auth/prisma-adapter";
import { prisma } from "@/lib/prisma";
import type { Role } from "@prisma/client";

// Kaba kuvvet (brute-force) koruması: art arda MAX_FAILED_ATTEMPTS başarısız denemeden
// sonra hesap LOCKOUT_MS boyunca kilitlenir. Sayaç User.failedLoginAttempts/lockedUntil'de
// tutulur (bkz. prisma/schema.prisma) — serverless/çoklu instance'ta da tutarlı kalması için
// bellek içi bir Map yerine DB kullanılıyor.
const MAX_FAILED_ATTEMPTS = 5;
const LOCKOUT_MS = 15 * 60 * 1000; // 15 dakika

// Credentials provider'ın authorize() callback'inden ayrıştırıldı ki NextAuth/Next.js
// request bağlamına ihtiyaç duymadan (script/test ortamında) doğrudan çağrılıp
// doğrulanabilsin.
export async function verifyLoginCredentials(email: string, password: string) {
  const user = await prisma.user.findUnique({ where: { email } });
  if (!user?.passwordHash) return null;

  // Kilitliyse şifreyi hiç kontrol etmeden reddet — ama hesabın var/kilitli olduğunu
  // sızdırmamak için hata mesajı (bkz. auth-actions.ts) yanlış şifreyle aynı kalır.
  if (user.lockedUntil && user.lockedUntil > new Date()) {
    return null;
  }

  const isValid = await bcrypt.compare(password, user.passwordHash);

  if (!isValid) {
    const attempts = user.failedLoginAttempts + 1;
    const isNowLocked = attempts >= MAX_FAILED_ATTEMPTS;
    await prisma.user.update({
      where: { id: user.id },
      data: {
        failedLoginAttempts: isNowLocked ? 0 : attempts,
        lockedUntil: isNowLocked ? new Date(Date.now() + LOCKOUT_MS) : null,
      },
    });
    return null;
  }

  if (user.failedLoginAttempts > 0 || user.lockedUntil) {
    await prisma.user.update({
      where: { id: user.id },
      data: { failedLoginAttempts: 0, lockedUntil: null },
    });
  }

  return { id: user.id, email: user.email, name: user.name, role: user.role };
}

const credentialsProvider = Credentials({
  credentials: {
    email: { label: "E-posta", type: "email" },
    password: { label: "Şifre", type: "password" },
  },
  async authorize(credentials) {
    const email = credentials?.email;
    const password = credentials?.password;
    if (typeof email !== "string" || typeof password !== "string") return null;
    return verifyLoginCredentials(email, password);
  },
});

// Google/Apple: env değişkenleri girilmediği sürece provider listesine hiç eklenmiyor —
// böylece kimlik bilgileri tanımlanana kadar "Google ile Giriş" butonu görünmez, uygulama
// eksik OAuth ayarları yüzünden çökmez.
const providers: Provider[] = [credentialsProvider];

// allowDangerousEmailAccountLinking: e-posta+şifre ile kayıtlı birinin aynı adresle
// Google/Apple ile giriş yapması, aksi halde OAuth hesabı bağlanmayıp Auth.js'in
// "OAuthAccountNotLinked" hatasıyla sessizce /giris'e geri dönmesine yol açıyordu
// (giriş "başarılı" görünüyor ama hiçbir profil/oturum oluşmuyordu). Google/Apple
// e-posta sahipliğini kendileri doğruladığı için bu ayarın "dangerous" riski (birinin
// sahibi olmadığı bir e-postayı iddia etmesi) burada geçerli değil.
if (process.env.GOOGLE_CLIENT_ID && process.env.GOOGLE_CLIENT_SECRET) {
  providers.push(
    Google({
      clientId: process.env.GOOGLE_CLIENT_ID,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET,
      allowDangerousEmailAccountLinking: true,
    }),
  );
}

if (process.env.APPLE_CLIENT_ID && process.env.APPLE_CLIENT_SECRET) {
  providers.push(
    Apple({
      clientId: process.env.APPLE_CLIENT_ID,
      clientSecret: process.env.APPLE_CLIENT_SECRET,
      allowDangerousEmailAccountLinking: true,
    }),
  );
}

// /giris sayfasının "Google ile Giriş"/"Apple ile Giriş" butonlarını sadece ilgili
// kimlik bilgileri tanımlıysa göstermesi için — sunucu env'ine client bundle'ından
// erişilemez, bu yüzden bu iki boolean'ı ayrıca dışa açıyoruz.
export const isGoogleAuthEnabled = Boolean(process.env.GOOGLE_CLIENT_ID && process.env.GOOGLE_CLIENT_SECRET);
export const isAppleAuthEnabled = Boolean(process.env.APPLE_CLIENT_ID && process.env.APPLE_CLIENT_SECRET);

export const { handlers, auth, signIn, signOut } = NextAuth({
  // Credentials sağlayıcısı "database" oturum stratejisini desteklemediği için strategy
  // hep "jwt" kalıyor — adapter yine de Google/Apple ile girenler için User/Account
  // kayıtlarını Prisma'ya yazmaya devam eder (bkz. Auth.js "Credentials + OAuth" deseni).
  adapter: PrismaAdapter(prisma),
  session: { strategy: "jwt" },
  pages: { signIn: "/giris" },
  providers,
  callbacks: {
    // Google/Apple sadece VAR OLAN bir hesaba giriş için kullanılabilir — adapter'ın
    // varsayılan davranışı olan "ilk OAuth girişinde otomatik hesap oluşturma"yı burada
    // engelliyoruz. Hesabı olmayan biri "Google ile devam et"e tıklarsa önce e-posta/
    // şifreyle (Kayıt Ol) kayıt olması gerektiği söylenir.
    async signIn({ user, account, profile }) {
      if (account?.type === "oauth") {
        if (!user.email) return false;
        const existingUser = await prisma.user.findUnique({ where: { email: user.email } });
        if (!existingUser) {
          return "/giris?error=NoAccountFound";
        }

        // Google, e-postanın sahipliğini kendisi doğruladığı için (OIDC email_verified
        // claim'i) hesabı burada doğrulanmış işaretliyoruz — sipariş onay e-postasının
        // ek bir kod istemeden gönderilebilmesi için (bkz. lib/actions/order-actions.ts
        // ve lib/order-verification.ts). Apple henüz aynı şekilde ele alınmıyor.
        if (account.provider === "google" && profile?.email_verified && !existingUser.emailVerified) {
          await prisma.user.update({ where: { id: existingUser.id }, data: { emailVerified: new Date() } });
        }
      }
      return true;
    },
    jwt({ token, user }) {
      // "user" sadece ilk girişte dolu gelir (credentials'ta authorize'ın döndürdüğü,
      // OAuth'ta adapter'ın DB'den okuduğu kayıt) — role bu anda token'a kopyalanıp
      // sonraki isteklerde JWT üzerinden taşınır.
      if (user) {
        token.id = user.id;
        token.role = (user as { role: Role }).role;
      }
      return token;
    },
    session({ session, token }) {
      if (session.user) {
        session.user.id = token.id as string;
        session.user.role = token.role as Role;
      }
      return session;
    },
  },
});

// Admin sayfaları/server action'ları için ortak yetki kontrolü — oturum yoksa veya
// ADMIN değilse /giris'e (dönüşte /admin'e gelecek şekilde) yönlendirir.
export async function requireAdmin() {
  const session = await auth();
  if (session?.user?.role !== "ADMIN") {
    redirect("/giris?callbackUrl=/admin");
  }
  return session;
}

// Giriş yapmış herhangi bir müşteri gerektiren sayfalar (örn. /hesabim) için — oturum
// yoksa dönüşte aynı sayfaya gelecek şekilde /giris'e yönlendirir.
export async function requireUser(callbackUrl: string) {
  const session = await auth();
  if (!session?.user) {
    redirect(`/giris?callbackUrl=${encodeURIComponent(callbackUrl)}`);
  }
  return session;
}
