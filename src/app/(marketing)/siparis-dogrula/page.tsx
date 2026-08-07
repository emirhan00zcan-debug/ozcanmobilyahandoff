import Link from "next/link";
import { FaCheckCircle, FaExclamationCircle } from "react-icons/fa";
import { confirmOrderVerification } from "@/lib/order-verification";
import ResendVerificationForm from "@/components/checkout/ResendVerificationForm";

export const metadata = { title: "E-posta Doğrulama | Özcan Mobilya" };

export default async function SiparisDogrulaPage({
  searchParams,
}: {
  searchParams: Promise<{ order?: string; code?: string }>;
}) {
  const { order: orderNumber, code } = await searchParams;

  if (!orderNumber || !code) {
    return (
      <div className="mx-auto flex max-w-lg flex-col items-center px-4 py-24 text-center sm:px-6 lg:px-8">
        <FaExclamationCircle className="h-14 w-14 text-secondary-light" />
        <h1 className="mt-5 font-display text-2xl font-bold text-secondary sm:text-3xl">Geçersiz Bağlantı</h1>
        <p className="mt-2 font-body text-sm text-secondary-light">
          Doğrulama bağlantısı eksik veya bozuk görünüyor.
        </p>
        <Link
          href="/"
          className="mt-6 rounded-full bg-secondary px-8 py-3.5 font-body text-sm font-semibold text-white transition-all duration-200 hover:bg-primary"
        >
          Ana Sayfa
        </Link>
      </div>
    );
  }

  const result = await confirmOrderVerification(orderNumber, code);

  if (result.success) {
    return (
      <div className="mx-auto flex max-w-lg flex-col items-center px-4 py-24 text-center sm:px-6 lg:px-8">
        <FaCheckCircle className="h-14 w-14 text-primary" />
        <h1 className="mt-5 font-display text-2xl font-bold text-secondary sm:text-3xl">E-postanız Doğrulandı</h1>
        <p className="mt-2 font-body text-sm text-secondary-light">
          {result.alreadyVerified
            ? `${result.orderNumber} numaralı siparişinizin onay e-postası daha önce gönderilmişti.`
            : `${result.orderNumber} numaralı siparişinizin detaylarını içeren onay e-postası gönderildi — gelen kutunuzu kontrol edin.`}
        </p>
        <div className="mt-6 flex gap-3">
          <Link
            href="/"
            className="rounded-full border border-secondary/20 px-6 py-3 font-body text-sm font-semibold text-secondary transition-colors hover:border-primary hover:text-primary"
          >
            Ana Sayfa
          </Link>
          <Link
            href="/hesabim"
            className="rounded-full bg-secondary px-6 py-3 font-body text-sm font-semibold text-white transition-all duration-200 hover:bg-primary"
          >
            Siparişlerim
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="mx-auto flex max-w-lg flex-col items-center px-4 py-24 text-center sm:px-6 lg:px-8">
      <FaExclamationCircle className="h-14 w-14 text-primary" />
      <h1 className="mt-5 font-display text-2xl font-bold text-secondary sm:text-3xl">Doğrulama Başarısız</h1>
      <p className="mt-2 font-body text-sm text-secondary-light">{result.error}</p>
      {result.orderNumber && <ResendVerificationForm orderNumber={result.orderNumber} />}
    </div>
  );
}
