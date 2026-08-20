import LegalPageHeader from "@/components/layout/LegalPageHeader";

export const metadata = { title: "Hizmet Şartları | Özcan Mobilya" };

const ARTICLE_CLASS =
  "mx-auto max-w-3xl px-4 py-10 sm:px-6 lg:px-8 font-body text-sm leading-relaxed text-secondary-light " +
  "[&_h2]:mt-8 [&_h2]:mb-3 [&_h2]:font-display [&_h2]:text-lg [&_h2]:font-semibold [&_h2]:text-secondary " +
  "[&_p]:mt-3 [&_ul]:mt-3 [&_ul]:list-disc [&_ul]:pl-5 [&_li]:mt-1.5 [&_strong]:text-secondary [&_strong]:font-semibold";

export default function HizmetSartlariPage() {
  return (
    <>
      <LegalPageHeader title="Hizmet Şartları" />
      <article className={ARTICLE_CLASS}>
        <p>
          ozcanmobilya.com&apos;u (&quot;Site&quot;) kullanarak aşağıdaki şartları kabul etmiş
          olursunuz. Satın alma işlemlerine özgü hükümler için ayrıca{" "}
          <strong>Mesafeli Satış Sözleşmesi</strong>&apos;ne bakınız.
        </p>

        <h2>1. Sitenin Kullanımı</h2>
        <p>
          Site içeriği yalnızca kişisel, ticari olmayan kullanım içindir. Sitedeki metin,
          görsel ve tasarım öğeleri Özcan Mobilya - Hüseyin Özcan&apos;a aittir; izinsiz kopyalanamaz,
          çoğaltılamaz.
        </p>

        <h2>2. Hesap Sorumluluğu</h2>
        <p>
          Üyelik oluşturduğunuzda verdiğiniz bilgilerin doğruluğundan ve hesap
          bilgilerinizin (şifre dahil) gizliliğinden siz sorumlusunuz. Hesabınız üzerinden
          gerçekleştirilen işlemler size ait kabul edilir.
        </p>

        <h2>3. Ürün Bilgileri ve Fiyatlar</h2>
        <p>
          Ürün görselleri temsili olabilir; ekran kalibrasyonuna bağlı küçük renk farklılıkları
          oluşabilir. Fiyatlar Türk Lirası ve KDV dahildir; ilan edilen kampanya/indirimler
          belirtilen süre ve stokla sınırlıdır.
        </p>

        <h2>4. Sorumluluğun Sınırlandırılması</h2>
        <p>
          Site, mücbir sebepler (doğal afet, kargo/nakliye kesintisi, sistem arızası vb.)
          nedeniyle oluşabilecek gecikme veya aksaklıklardan sorumlu tutulamaz. Bu durum,
          tüketicinin yasal haklarını (cayma hakkı, ayıplı mal hükümleri vb.) ortadan
          kaldırmaz.
        </p>

        <h2>5. Değişiklikler</h2>
        <p>
          Özcan Mobilya - Hüseyin Özcan, bu şartları ve site içeriğini önceden bildirmeksizin güncelleme
          hakkını saklı tutar. Güncel sürüm bu sayfada yayınlandığı andan itibaren geçerlidir.
        </p>

        <h2>6. İletişim</h2>
        <p>
          Sorularınız için ozcan.mobilya.sinop@gmail.com adresinden veya +90 505 442 3809
          numarasından bize ulaşabilirsiniz.
        </p>
      </article>
    </>
  );
}
