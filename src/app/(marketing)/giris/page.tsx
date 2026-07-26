"use client";

import { useActionState, useState } from "react";
import Link from "next/link";
import { loginAction, registerAction } from "@/lib/actions/auth-actions";

const TABS = [
  { id: "signin", label: "Giriş Yap" },
  { id: "signup", label: "Kayıt Ol" },
] as const;

type TabId = (typeof TABS)[number]["id"];

export default function GirisPage() {
  const [activeTab, setActiveTab] = useState<TabId>("signin");

  return (
    <section className="relative flex min-h-[calc(100vh-140px)] items-center justify-center overflow-hidden px-4 py-16">
      {/* Arka plan: atmosferik yaşam alanı fotoğrafı + koyu gradyan */}
      <div className="absolute inset-0 -z-10">
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img
          src="/media/k602_lifestyle_1782831673363.jpg"
          alt=""
          className="h-full w-full object-cover"
        />
        <div className="absolute inset-0 bg-gradient-to-b from-secondary/80 via-secondary/50 to-secondary/80" />
      </div>

      {/* Yüzen cam kart */}
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

        {/* Kayan kapsül sekme geçişi */}
        <div className="relative mt-8 flex rounded-full bg-secondary/[0.06] p-1">
          <div
            className={[
              "absolute inset-y-1 left-1 w-[calc(50%-4px)] rounded-full bg-white shadow-sm transition-transform duration-300 ease-out",
              activeTab === "signup" ? "translate-x-full" : "translate-x-0",
            ].join(" ")}
          />
          {TABS.map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={[
                "relative z-10 flex-1 py-2.5 font-body text-sm font-semibold transition-colors",
                activeTab === tab.id ? "text-secondary" : "text-secondary-light",
              ].join(" ")}
            >
              {tab.label}
            </button>
          ))}
        </div>

        <div className="mt-8">{activeTab === "signin" ? <SignInForm /> : <SignUpForm />}</div>
      </div>
    </section>
  );
}

function FloatingField({
  id,
  name,
  label,
  type = "text",
}: {
  id: string;
  name: string;
  label: string;
  type?: string;
}) {
  return (
    <div className="relative">
      <input
        id={id}
        name={name}
        type={type}
        required
        placeholder=" "
        className="peer w-full rounded-xl border border-secondary/15 bg-white px-4 pb-2.5 pt-5 font-body text-sm text-secondary placeholder-transparent transition-colors focus:border-primary focus:outline-none"
      />
      <label
        htmlFor={id}
        className="pointer-events-none absolute left-4 top-1/2 -translate-y-1/2 font-body text-sm text-secondary-light transition-all peer-focus:top-3.5 peer-focus:text-[11px] peer-focus:text-primary peer-[:not(:placeholder-shown)]:top-3.5 peer-[:not(:placeholder-shown)]:text-[11px]"
      >
        {label}
      </label>
    </div>
  );
}

function SignInForm() {
  const [state, formAction, isPending] = useActionState(loginAction, { error: null });

  return (
    <form action={formAction} className="animate-fade-in space-y-4">
      <FloatingField id="signin-email" name="email" label="E-posta" type="email" />
      <FloatingField id="signin-password" name="password" label="Şifre" type="password" />

      {state.error && <p className="font-body text-xs font-medium text-red-600">{state.error}</p>}

      <div className="flex items-center justify-between pt-1">
        <label className="flex items-center gap-2 font-body text-xs text-secondary-light">
          <input type="checkbox" className="accent-primary" />
          Beni hatırla
        </label>
        <Link href="/sifremi-unuttum" className="font-body text-xs font-medium text-primary hover:underline">
          Şifremi unuttum
        </Link>
      </div>

      <button
        type="submit"
        disabled={isPending}
        className="w-full rounded-full bg-secondary py-3.5 font-body text-sm font-semibold text-white transition-all duration-200 hover:scale-[1.02] hover:bg-primary active:scale-95 disabled:opacity-60 disabled:hover:scale-100"
      >
        {isPending ? "Giriş yapılıyor..." : "Giriş Yap"}
      </button>
    </form>
  );
}

function SignUpForm() {
  const [state, formAction, isPending] = useActionState(registerAction, { error: null });

  return (
    <form action={formAction} className="animate-fade-in space-y-4">
      <FloatingField id="signup-name" name="name" label="Ad Soyad" />
      <FloatingField id="signup-email" name="email" label="E-posta" type="email" />
      <FloatingField id="signup-password" name="password" label="Şifre" type="password" />

      {state.error && <p className="font-body text-xs font-medium text-red-600">{state.error}</p>}

      <button
        type="submit"
        disabled={isPending}
        className="w-full rounded-full bg-secondary py-3.5 font-body text-sm font-semibold text-white transition-all duration-200 hover:scale-[1.02] hover:bg-primary active:scale-95 disabled:opacity-60 disabled:hover:scale-100"
      >
        {isPending ? "Hesap oluşturuluyor..." : "Hesap Oluştur"}
      </button>

      <p className="font-body text-xs text-secondary-light">
        Kayıt olarak{" "}
        <Link href="/hizmet-sartlari" className="underline">
          Hizmet Şartları&apos;nı
        </Link>{" "}
        ve{" "}
        <Link href="/gizlilik-politikasi" className="underline">
          Gizlilik Politikası&apos;nı
        </Link>{" "}
        kabul etmiş olursunuz.
      </p>
    </form>
  );
}
