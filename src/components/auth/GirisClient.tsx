"use client";

import { useActionState, useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import Image from "next/image";
import Link from "next/link";
import { signIn, useSession } from "next-auth/react";
import { FaGoogle, FaApple } from "react-icons/fa";
import {
  loginAction,
  registerAction,
  verifyRegisterCodeAction,
  type AuthActionState,
} from "@/lib/actions/auth-actions";

const TABS = [
  { id: "signin", label: "Giriş Yap" },
  { id: "signup", label: "Kayıt Ol" },
] as const;

type TabId = (typeof TABS)[number]["id"];

// Auth.js, özel giriş sayfası kullanan uygulamalarda OAuth hatalarını (Google/Apple akışı
// tamamlanamadığında) ?error=<kod> ile bu sayfaya geri yönlendirir — kod okunup
// gösterilmezse kullanıcı hiçbir açıklama olmadan giriş formunun başına döner.
const AUTH_ERROR_MESSAGES: Record<string, string> = {
  OAuthAccountNotLinked:
    "Bu e-posta adresi zaten e-posta/şifre ile kayıtlı. Lütfen önce e-posta ve şifrenizle giriş yapın.",
  OAuthSignin: "Google/Apple ile giriş başlatılamadı. Lütfen tekrar deneyin.",
  OAuthCallback: "Google/Apple girişi tamamlanamadı. Lütfen tekrar deneyin.",
  AccessDenied: "Giriş izni verilmedi.",
  Configuration: "Giriş yapılandırmasında bir sorun var. Lütfen daha sonra tekrar deneyin.",
  CredentialsSignin: "E-posta veya şifre hatalı.",
  NoAccountFound:
    "Bu Google/Apple hesabıyla eşleşen bir üyelik bulunamadı. Lütfen önce e-posta ile kayıt olun.",
};

type Props = {
  callbackUrl: string;
  googleEnabled: boolean;
  appleEnabled: boolean;
  authErrorCode?: string;
};

export default function GirisClient({ callbackUrl, googleEnabled, appleEnabled, authErrorCode }: Props) {
  const [activeTab, setActiveTab] = useState<TabId>("signin");
  const showOAuthSection = googleEnabled || appleEnabled;
  const authError = authErrorCode
    ? (AUTH_ERROR_MESSAGES[authErrorCode] ?? "Giriş sırasında bir sorun oluştu. Lütfen tekrar deneyin.")
    : null;

  return (
    <section className="relative flex min-h-[calc(100vh-140px)] items-center justify-center overflow-hidden px-4 py-16">
      {/* Arka plan: atmosferik yaşam alanı fotoğrafı + koyu gradyan */}
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

        <p className="mt-6 text-center font-body text-sm text-secondary-light">
          {activeTab === "signin"
            ? "Hesabınıza giriş yaparak alışverişe devam edin."
            : "Saniyeler içinde ücretsiz hesap oluşturun."}
        </p>

        {authError && (
          <p className="mt-4 rounded-xl bg-red-50 px-4 py-3 text-center font-body text-xs font-medium text-red-600">
            {authError}
          </p>
        )}

        {/* Google/Apple sadece var olan bir hesaba giriş için çalışıyor (bkz. auth.ts signIn
            callback'i) — hesabı olmayanı kayıt edemediği için bu buton "Kayıt Ol" sekmesinde
            değil, yalnızca "Giriş Yap" sekmesinde gösteriliyor. */}
        {showOAuthSection && activeTab === "signin" && (
          <div className="mt-6 space-y-2.5">
            {googleEnabled && <OAuthButton provider="google" callbackUrl={callbackUrl} />}
            {appleEnabled && <OAuthButton provider="apple" callbackUrl={callbackUrl} />}

            <div className="flex items-center gap-3 pt-1">
              <span className="h-px flex-1 bg-secondary/10" />
              <span className="font-body text-[11px] font-medium uppercase tracking-wider text-secondary-light">
                veya e-posta ile
              </span>
              <span className="h-px flex-1 bg-secondary/10" />
            </div>
          </div>
        )}

        {/* Kayan kapsül sekme geçişi */}
        <div className="relative mt-5 flex rounded-full bg-secondary/[0.06] p-1">
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

        <div className="mt-8">
          {activeTab === "signin" ? (
            <SignInForm callbackUrl={callbackUrl} />
          ) : (
            <SignUpForm callbackUrl={callbackUrl} />
          )}
        </div>
      </div>
    </section>
  );
}

function OAuthButton({ provider, callbackUrl }: { provider: "google" | "apple"; callbackUrl: string }) {
  const [isPending, setIsPending] = useState(false);
  const isGoogle = provider === "google";

  const handleClick = () => {
    setIsPending(true);
    signIn(provider, { callbackUrl });
  };

  return (
    <button
      type="button"
      onClick={handleClick}
      disabled={isPending}
      className="flex w-full items-center justify-center gap-3 rounded-xl border border-secondary/15 bg-white py-3 font-body text-sm font-semibold text-secondary transition-all duration-200 hover:border-secondary/30 hover:bg-secondary/[0.03] disabled:opacity-60"
    >
      {isGoogle ? <FaGoogle className="h-4 w-4 text-[#EA4335]" /> : <FaApple className="h-4 w-4" />}
      {isPending ? "Yönlendiriliyor..." : isGoogle ? "Google ile devam et" : "Apple ile devam et"}
    </button>
  );
}

function FloatingField({
  id,
  name,
  label,
  type = "text",
  onChange,
}: {
  id: string;
  name: string;
  label: string;
  type?: string;
  onChange?: (value: string) => void;
}) {
  return (
    <div className="relative">
      <input
        id={id}
        name={name}
        type={type}
        required
        placeholder=" "
        onChange={onChange ? (e) => onChange(e.target.value) : undefined}
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

// signIn() server action'ı artık kendi içinde redirect() çağırmıyor (redirect: false —
// bkz. auth-actions.ts), bu yüzden action başarıyla dönünce SessionProvider'ın oturumu
// haberdar olması için client'ta update() ile senkronize edip ardından yönlendiriyoruz.
// Aksi halde Navbar'daki giriş durumu sayfa yenilenene kadar eskisi gibi kalıyordu.
//
// Dikkat: bağımlılık dizisinde state.error yerine state'in kendisi kullanılıyor — ilk
// denemede başarılı girişte error hem öncesinde hem sonrasında null kalıyor (Object.is
// null === null), state.error'a bağlı bir effect bu durumda hiç yeniden çalışmazdı.
// useActionState her action tamamlandığında YENİ bir state referansı döndürdüğü için
// (içerik aynı olsa bile) state'in kendisine bağlanmak bunu güvenilir şekilde yakalıyor.
function useAuthRedirect(state: AuthActionState, callbackUrl: string) {
  const { update } = useSession();
  const router = useRouter();
  const isFirstRun = useRef(true);

  useEffect(() => {
    if (isFirstRun.current) {
      isFirstRun.current = false;
      return;
    }
    if (state.error === null) {
      update().then(() => router.push(callbackUrl));
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [state]);
}

function SignInForm({ callbackUrl }: { callbackUrl: string }) {
  const [state, formAction, isPending] = useActionState(loginAction, { error: null });
  useAuthRedirect(state, callbackUrl);

  return (
    <form action={formAction} className="animate-fade-in space-y-4">
      <input type="hidden" name="callbackUrl" value={callbackUrl} />
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
        className="btn-sweep w-full rounded-full border border-primary/30 py-3.5 font-body text-sm font-semibold text-secondary hover:scale-[1.02] active:scale-95 disabled:opacity-60 disabled:hover:scale-100"
      >
        {isPending ? "Giriş yapılıyor..." : "Giriş Yap"}
      </button>
    </form>
  );
}

function SignUpForm({ callbackUrl }: { callbackUrl: string }) {
  const [state, formAction, isPending] = useActionState(registerAction, { error: null, codeSent: false });
  const [verifyState, verifyFormAction, isVerifyPending] = useActionState(verifyRegisterCodeAction, {
    error: null,
  });
  // Kod doğrulama adımında signIn() için tekrar gerekiyor — e-posta/şifre burada,
  // sadece bu form içinde (component state'te) tutuluyor, hiçbir yere persist edilmiyor.
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  useAuthRedirect(verifyState, callbackUrl);

  if (state.codeSent) {
    return (
      <form action={verifyFormAction} className="animate-fade-in space-y-4">
        <input type="hidden" name="email" value={email} />
        <input type="hidden" name="password" value={password} />
        <p className="font-body text-sm text-secondary-light">
          <strong className="text-secondary">{email}</strong> adresine gönderdiğimiz 6 haneli kodu girin.
        </p>
        <FloatingField id="signup-code" name="code" label="Doğrulama Kodu" />

        {verifyState.error && <p className="font-body text-xs font-medium text-red-600">{verifyState.error}</p>}

        <button
          type="submit"
          disabled={isVerifyPending}
          className="btn-sweep w-full rounded-full border border-primary/30 py-3.5 font-body text-sm font-semibold text-secondary hover:scale-[1.02] active:scale-95 disabled:opacity-60 disabled:hover:scale-100"
        >
          {isVerifyPending ? "Doğrulanıyor..." : "Doğrula ve Giriş Yap"}
        </button>
      </form>
    );
  }

  return (
    <form action={formAction} className="animate-fade-in space-y-4">
      <input type="hidden" name="callbackUrl" value={callbackUrl} />
      <FloatingField id="signup-name" name="name" label="Ad Soyad" />
      <FloatingField id="signup-email" name="email" label="E-posta" type="email" onChange={setEmail} />
      <FloatingField id="signup-password" name="password" label="Şifre" type="password" onChange={setPassword} />

      {state.error && <p className="font-body text-xs font-medium text-red-600">{state.error}</p>}

      <button
        type="submit"
        disabled={isPending}
        className="btn-sweep w-full rounded-full border border-primary/30 py-3.5 font-body text-sm font-semibold text-secondary hover:scale-[1.02] active:scale-95 disabled:opacity-60 disabled:hover:scale-100"
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
