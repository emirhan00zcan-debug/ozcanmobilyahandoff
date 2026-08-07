"use client";

import { useActionState } from "react";
import Image from "next/image";
import Link from "next/link";
import { requestPasswordResetAction } from "@/lib/actions/auth-actions";

export default function ForgotPasswordClient() {
  const [state, formAction, isPending] = useActionState(requestPasswordResetAction, {
    error: null,
    message: null,
  });

  return (
    <section className="relative flex min-h-[calc(100vh-140px)] items-center justify-center overflow-hidden px-4 py-16">
      <div className="absolute inset-0 -z-10">
        <Image
          src="/media/k602_lifestyle_1782831673363.jpg"
          alt=""
          fill
          sizes="100vw"
          className="object-cover"
        />
        <div className="absolute inset-0 bg-gradient-to-b from-secondary/80 via-secondary/50 to-secondary/80" />
      </div>

      <div className="w-full max-w-md rounded-3xl bg-white/95 p-8 shadow-2xl backdrop-blur-xl sm:p-10">
        <Link href="/" className="flex flex-col items-center">
          <span className="whitespace-nowrap">
            <span className="font-display text-2xl font-bold tracking-wide text-brand">ÖZCAN</span>
            <span className="ml-1.5 font-body text-[10px] font-medium tracking-[0.25em] text-secondary">
              MOBİLYA
            </span>
          </span>
          <span className="font-script text-xl leading-none text-brand/80">&ldquo;Hayallerinizi Tasarlar&rdquo;</span>
        </Link>

        <h1 className="mt-6 text-center font-display text-xl font-semibold text-secondary">
          Şifremi Unuttum
        </h1>
        <p className="mt-2 text-center font-body text-sm text-secondary-light">
          Hesabınıza kayıtlı e-posta adresini girin, şifre sıfırlama bağlantısı gönderelim.
        </p>

        {state.message ? (
          <p className="mt-8 rounded-xl bg-primary/10 p-4 text-center font-body text-sm text-secondary">
            {state.message}
          </p>
        ) : (
          <form action={formAction} className="mt-8 space-y-4">
            <input
              type="email"
              name="email"
              required
              placeholder="E-posta adresiniz"
              className="w-full rounded-xl border border-secondary/15 bg-white px-4 py-3.5 font-body text-sm text-secondary placeholder:text-secondary-light focus:border-primary focus:outline-none"
            />

            {state.error && <p className="font-body text-xs font-medium text-red-600">{state.error}</p>}

            <button
              type="submit"
              disabled={isPending}
              className="w-full rounded-full bg-secondary py-3.5 font-body text-sm font-semibold text-white transition-all duration-200 hover:scale-[1.02] hover:bg-primary active:scale-95 disabled:opacity-60 disabled:hover:scale-100"
            >
              {isPending ? "Gönderiliyor..." : "Sıfırlama Bağlantısı Gönder"}
            </button>
          </form>
        )}

        <p className="mt-6 text-center font-body text-xs text-secondary-light">
          <Link href="/giris" className="font-medium text-primary hover:underline">
            Giriş sayfasına dön
          </Link>
        </p>
      </div>
    </section>
  );
}
