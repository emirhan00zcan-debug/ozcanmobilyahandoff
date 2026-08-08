import Link from "next/link";
import { notFound } from "next/navigation";
import { FaCheckCircle, FaClock, FaExclamationCircle } from "react-icons/fa";
import { prisma } from "@/lib/prisma";

export const metadata = { title: "Sipariş Durumu | Özcan Mobilya" };

// PayTR iFrame API'nin merchant_ok_url/merchant_fail_url'i — kart ödemesi tamamlandığında
// (başarılı veya başarısız) kullanıcı buraya yönlendirilir. Gerçek ödeme onayı asenkron
// olarak PayTR'ın sunucudan sunucuya bildiriminden (bkz. api/odeme/paytr-bildirim) gelir,
// bu yüzden burada anlık kesin bir sonuç garanti edilemez — paymentStatus henüz PENDING'se
// dürüstçe "onaylanıyor" mesajı gösterilir.
export default async function SiparisDurumuPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;

  const order = await prisma.order.findUnique({
    where: { id },
    select: { orderNumber: true, paymentStatus: true },
  });

  if (!order) notFound();

  let icon = <FaClock className="h-14 w-14 text-secondary-light" />;
  let title = "Ödemeniz Onaylanıyor";
  let message = `${order.orderNumber} numaralı siparişinizin ödeme onayı bekleniyor — sonuç kesinleştiğinde e-posta ile bilgilendirileceksiniz.`;

  if (order.paymentStatus === "PAID") {
    icon = <FaCheckCircle className="h-14 w-14 text-primary" />;
    title = "Ödemeniz Onaylandı";
    message = `${order.orderNumber} numaralı siparişinizin ödemesi alındı, siparişiniz hazırlanıyor.`;
  } else if (order.paymentStatus === "FAILED") {
    icon = <FaExclamationCircle className="h-14 w-14 text-red-500" />;
    title = "Ödeme Alınamadı";
    message = `${order.orderNumber} numaralı siparişiniz için ödeme tamamlanamadı. Tekrar denemek veya farklı bir ödeme yöntemi seçmek isterseniz bizimle iletişime geçebilirsiniz.`;
  }

  return (
    <div className="mx-auto flex max-w-2xl flex-col items-center px-4 py-24 text-center sm:px-6 lg:px-8">
      {/* PayTR iFrame API'de ödeme sonucu yönlendirmesi iframe içinde gerçekleşir — bu sayfa
          iframe içinde açıldıysa üst pencereye çıkılır, aksi halde kullanıcı checkout
          sayfasındaki küçük iframe kutusunun içinde bu sayfayla baş başa kalır. */}
      <script
        dangerouslySetInnerHTML={{
          __html: "if(window.top!==window.self){window.top.location.href=window.self.location.href;}",
        }}
      />
      {icon}
      <h1 className="mt-5 font-display text-2xl font-bold text-secondary sm:text-3xl">{title}</h1>
      <p className="mt-2 max-w-sm font-body text-sm text-secondary-light">{message}</p>
      <div className="mt-6 flex gap-3">
        <Link
          href="/"
          className="btn-sweep rounded-full border border-primary/30 px-6 py-3 font-body text-sm font-semibold text-secondary"
        >
          Ana Sayfa
        </Link>
        <Link
          href="/hesabim"
          className="btn-sweep rounded-full border border-primary/30 px-6 py-3 font-body text-sm font-semibold text-secondary"
        >
          Siparişlerim
        </Link>
      </div>
    </div>
  );
}
