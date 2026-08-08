"use client";

import { useActionState } from "react";
import Image from "next/image";
import Link from "next/link";
import { resetPasswordAction } from "@/lib/actions/auth-actions";

type Props = { token: string };

export default function ResetPasswordClient({ token }: Props) {
  const [state, formAction, isPending] = useActionState(resetPasswordAction, {
    error: null,
    success: false,
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

        {state.success ? (
          <>
            <p className="mt-8 rounded-xl bg-primary/10 p-4 text-center font-body text-sm text-secondary">
              Şifreniz güncellendi. Artık yeni şifrenizle giriş yapabilirsiniz.
            </p>
            <Link
              href="/giris"
              className="btn-sweep mt-6 block w-full rounded-full border border-primary/30 py-3.5 text-center font-body text-sm font-semibold text-secondary"
            >
              Giriş Yap
            </Link>
          </>
        ) : (
          <>
            <h1 className="mt-6 text-center font-display text-xl font-semibold text-secondary">
              Yeni Şifre Belirle
            </h1>

            {!token ? (
              <p className="mt-8 rounded-xl bg-red-50 p-4 text-center font-body text-sm text-red-700">
                Geçersiz veya süresi dolmuş bağlantı. Lütfen şifre sıfırlamayı yeniden başlatın.
              </p>
            ) : (
              <form action={formAction} className="mt-8 space-y-4">
                <input type="hidden" name="token" value={token} />
                <input
                  type="password"
                  name="password"
                  required
                  placeholder="Yeni şifre"
                  className="w-full rounded-xl border border-secondary/15 bg-white px-4 py-3.5 font-body text-sm text-secondary placeholder:text-secondary-light focus:border-primary focus:outline-none"
                />

                {state.error && <p className="font-body text-xs font-medium text-red-600">{state.error}</p>}

                <button
                  type="submit"
                  disabled={isPending}
                  className="btn-sweep w-full rounded-full border border-primary/30 py-3.5 font-body text-sm font-semibold text-secondary hover:scale-[1.02] active:scale-95 disabled:opacity-60 disabled:hover:scale-100"
                >
                  {isPending ? "Kaydediliyor..." : "Şifreyi Güncelle"}
                </button>
              </form>
            )}

            <p className="mt-6 text-center font-body text-xs text-secondary-light">
              <Link href="/sifremi-unuttum" className="font-medium text-primary hover:underline">
                Yeni bağlantı iste
              </Link>
            </p>
          </>
        )}
      </div>
    </section>
  );
}
