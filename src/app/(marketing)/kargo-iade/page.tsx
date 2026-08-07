import Link from "next/link";
import LegalPageHeader from "@/components/layout/LegalPageHeader";

export const metadata = { title: "Kargo & İade | Özcan Mobilya" };

const ARTICLE_CLASS =
  "mx-auto max-w-3xl px-4 py-10 sm:px-6 lg:px-8 font-body text-sm leading-relaxed text-secondary-light " +
  "[&_h2]:mt-8 [&_h2]:mb-3 [&_h2]:font-display [&_h2]:text-lg [&_h2]:font-semibold [&_h2]:text-secondary " +
  "[&_p]:mt-3 [&_ul]:mt-3 [&_ul]:list-disc [&_ul]:pl-5 [&_li]:mt-1.5 [&_strong]:text-secondary [&_strong]:font-semibold";

export default function KargoIadePage() {
  return (
    <>
      <LegalPageHeader title="Kargo & İade" />
      <article className={ARTICLE_CLASS}>
        <p>
          Bu sayfa, teslimat ve iade süreçlerini müşteri diliyle özetler. Bağlayıcı hükümler
          için bkz.{" "}
          <Link href="/mesafeli-satis-sozlesmesi" className="text-primary underline underline-offset-2">
            Mesafeli Satış Sözleşmesi
          </Link>
          .
        </p>

        <h2>Teslimat Süresi</h2>
        <p>
          Stoktan teslim edilen ürünler <strong>[ ] iş günü</strong>, size özel ölçü/renkte
          üretilen ürünler ise üretim süresine bağlı olarak <strong>[ ] iş günü</strong>{" "}
          içinde kargoya/nakliyeye verilir. Kesin süre, sipariş onayı sonrası tarafınıza
          bildirilir.
        </p>

        <h2>Kargo Ücreti</h2>
        <p>
          [Kargo ücreti sabit mi, ürün hacmine göre mi, belirli tutar üzeri ücretsiz mi —
          politika netleşince buraya eklenecek.]
        </p>

        <h2>Teslim Alırken Kontrol Edin</h2>
        <ul>
          <li>Paketi teslim almadan önce dış ambalajda hasar olup olmadığını kontrol edin.</li>
          <li>Hasarlı görünen paketleri, kargo görevlisi yanındayken tutanakla teslim alın.</li>
          <li>
            Ürünü açtıktan sonra bir sorun fark ederseniz 48 saat içinde{" "}
            <Link href="/iletisim" className="text-primary underline underline-offset-2">
              bize ulaşın
            </Link>
            .
          </li>
        </ul>

        <h2>Montaj / Kurulum</h2>
        <p>
          Ürünle birlikte adım adım kurulum şeması gönderilir. Profesyonel kurulum hizmeti
          [şu an sunulmuyor / ek ücretle sunulmaktadır — netleşince güncellenecek].
        </p>

        <h2>İade Süreci</h2>
        <p>
          İadesi mümkün ürünlerde (bkz. Mesafeli Satış Sözleşmesi madde 5-6) şu adımları izleyin:
        </p>
        <ul>
          <li>
            Teslim tarihinden itibaren 14 gün içinde{" "}
            <Link href="/cayma-formu" className="text-primary underline underline-offset-2">
              Cayma Formu
            </Link>{" "}
            ile, iletişim formu veya e-posta yoluyla bildirin.
          </li>
          <li>Ürünü kullanılmamış, orijinal ambalajıyla ve varsa tüm aksesuarlarıyla birlikte hazırlayın.</li>
          <li>Anlaşmalı kargo ile gönderim bilgisi tarafınıza iletilir.</li>
          <li>Ürün kontrolü sonrası bedel, yasal süre içinde ödeme yönteminize iade edilir.</li>
        </ul>
        <p>
          Alıcının özel isteğiyle özel ölçü/renkte üretilen ürünlerde cayma hakkı
          uygulanmayabilir; sipariş öncesi ürün sayfasında bu durum ayrıca belirtilir.
        </p>
      </article>
    </>
  );
}
