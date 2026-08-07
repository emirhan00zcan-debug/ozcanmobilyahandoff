import { redirect } from "next/navigation";
import { auth, isGoogleAuthEnabled, isAppleAuthEnabled } from "@/lib/auth";
import GirisClient from "@/components/auth/GirisClient";

export const metadata = { title: "Giriş Yap | Özcan Mobilya" };

export default async function GirisPage({
  searchParams,
}: {
  searchParams: Promise<{ callbackUrl?: string; error?: string }>;
}) {
  const [session, params] = await Promise.all([auth(), searchParams]);
  const callbackUrl = params.callbackUrl || "/";

  // Zaten giriş yapmış birinin /giris'i tekrar görmesine gerek yok — varsa dönüş
  // adresine (örn. sepetten gelindiyse /odeme), yoksa ana sayfaya yönlendir.
  if (session?.user) {
    redirect(callbackUrl);
  }

  return (
    <GirisClient
      callbackUrl={callbackUrl}
      googleEnabled={isGoogleAuthEnabled}
      appleEnabled={isAppleAuthEnabled}
      authErrorCode={params.error}
    />
  );
}
