import ResetPasswordClient from "@/components/auth/ResetPasswordClient";

export const metadata = { title: "Şifre Sıfırla | Özcan Mobilya" };

export default async function SifremiSifirlaPage({
  searchParams,
}: {
  searchParams: Promise<{ token?: string }>;
}) {
  const { token } = await searchParams;
  return <ResetPasswordClient token={token ?? ""} />;
}
