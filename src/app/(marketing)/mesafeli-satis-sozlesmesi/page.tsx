import Link from "next/link";
import LegalPageHeader from "@/components/layout/LegalPageHeader";

export const metadata = { title: "Mesafeli Satış Sözleşmesi | Özcan Mobilya" };

const ARTICLE_CLASS =
  "mx-auto max-w-3xl px-4 py-10 sm:px-6 lg:px-8 font-body text-sm leading-relaxed text-secondary-light " +
  "[&_h2]:mt-8 [&_h2]:mb-3 [&_h2]:font-display [&_h2]:text-lg [&_h2]:font-semibold [&_h2]:text-secondary " +
  "[&_p]:mt-3 [&_ul]:mt-3 [&_ul]:list-disc [&_ul]:pl-5 [&_li]:mt-1.5 [&_strong]:text-secondary [&_strong]:font-semibold";

export default function MesafeliSatisSozlesmesiPage() {
  return (
    <>
      <LegalPageHeader title="Mesafeli Satış Sözleşmesi ve Ön Bilgilendirme Formu" />
      <article className={ARTICLE_CLASS}>
        <div className="rounded-xl border border-secondary/15 bg-secondary/[0.03] p-4">
          <p className="text-xs">
            <strong>Özellikle dikkat:</strong> Bu taslak, Mesafeli Sözleşmeler Yönetmeliği
            madde 15/1-(a) uyarınca &quot;tüketicinin istekleri veya kişisel ihtiyaçları
            doğrultusunda hazırlanan mallarda&quot; cayma hakkının kullanılamayacağını
            varsayar. Kataloğunuzda hem stoktan (hazır) hem de <strong>size özel ölçü</strong>{" "}
            ile üretilen ürünler bulunduğundan, hangi ürünlerin bu istisna kapsamına girdiğini
            bir hukuk danışmanıyla netleştirip 6. maddeyi ona göre kesinleştirin — bu, iade
            politikanızı doğrudan etkileyen en kritik karardır.
          </p>
        </div>

        <h2>1. Taraflar</h2>
        <p>
          <strong>Satıcı:</strong> Özcan Mobilya - Hüseyin Özcan
          <br />
          <strong>Adres:</strong> Camikebir Mahallesi Tütüncü Sokak No:6/A, Sinop/Merkez
          <br />
          <strong>Esnaf Sicil No:</strong> Sinop Esnaf ve Sanatkarlar Sicil Müdürlüğü / 19153
          <br />
          <strong>Vergi Dairesi / No:</strong> Sinop Vergi Dairesi Müdürlüğü / 6690465105
          <br />
          <strong>E-posta:</strong> ozcan.mobilya.sinop@gmail.com
          <br />
          <strong>Telefon:</strong> +90 505 442 3809
          <br />
          (bundan böyle &quot;Satıcı&quot;)
          <br />
          <br />
          <strong>Alıcı:</strong> Sitede üyelik oluşturarak veya sipariş vererek işbu
          sözleşmenin tarafı olan kişi (&quot;Alıcı&quot;)
        </p>

        <h2>2. Sözleşmenin Konusu</h2>
        <p>
          İşbu sözleşme, Alıcı&apos;nın Satıcı&apos;ya ait ozcanmobilya.com üzerinden elektronik
          ortamda siparişini verdiği, sitede cinsi, türü, miktarı, marka/modeli, satış bedeli,
          ödeme şekli ile teslimata ilişkin bilgileri belirtilen ürünün satışı ve teslimine
          ilişkin olarak 6502 sayılı Tüketicinin Korunması Hakkında Kanun ve Mesafeli
          Sözleşmeler Yönetmeliği hükümleri gereğince tarafların hak ve yükümlülüklerini
          düzenler.
        </p>

        <h2>3. Ön Bilgilendirme</h2>
        <p>
          Alıcı, sipariş vermeden önce ürünün temel nitelikleri, satış fiyatı (KDV dahil),
          ödeme şekli, teslimat bilgileri ve cayma hakkına ilişkin ön bilgilendirmeyi ödeme
          sayfasında ve bu sözleşmede açıkça görmüş ve elektronik ortamda onaylamış sayılır.
        </p>

        <h2>4. Teslimat</h2>
        <p>
          Sipariş, sitede/ürün sayfasında belirtilen tahmini teslim süresi içinde, Alıcı&apos;nın
          bildirdiği adrese, Satıcı&apos;nın anlaşmalı olduğu nakliye/kargo firması ile teslim
          edilir. Büyük hacimli mobilya ürünlerinde teslimat süresi ve montaj/kurulum
          hizmetinin sözleşme kapsamında olup olmadığı ürün sayfasında ayrıca belirtilir.
        </p>

        <h2 id="cayma-hakki">5. Cayma Hakkı (Genel Kural)</h2>
        <p>
          Alıcı, hiçbir hukuki ve cezai sorumluluk üstlenmeksizin ve hiçbir gerekçe göstermeksizin,
          ürünü teslim aldığı tarihten itibaren <strong>14 (on dört) gün</strong> içinde cayma
          hakkını kullanarak sözleşmeden dönebilir. Cayma hakkının kullanılması için bu süre
          içinde Satıcı&apos;ya{" "}
          <Link href="/cayma-formu" className="text-primary underline underline-offset-2">
            Cayma Formu
          </Link>{" "}
          ile yazılı bildirimde bulunulması ve ürünün kullanılmamış, yeniden satılabilir
          durumda olması gerekir.
        </p>

        <h2>6. Cayma Hakkının İstisnaları</h2>
        <p>
          Mesafeli Sözleşmeler Yönetmeliği m.15 uyarınca, <strong>tüketicinin istekleri veya
          kişisel ihtiyaçları doğrultusunda hazırlanan</strong> (örn. özel ölçüye/renge göre
          üretilen) ürünlerde cayma hakkı kullanılamaz. Aşağıdaki ürün kategorileri
          <em> [hukuki onay sonrası netleştirilecek]</em> bu kapsamda değerlendirilir:
        </p>
        <ul>
          <li>Standart ölçü dışında, alıcının talebiyle özel ölçüde üretilen ürünler</li>
          <li>Alıcının seçtiği özel renk/kumaş kombinasyonuyla üretime alınan ürünler</li>
        </ul>
        <p>
          Stoktan (hazır) teslim edilen, standart ölçü ve renkteki ürünlerde cayma hakkı 5.
          maddedeki genel kural çerçevesinde geçerlidir.
        </p>

        <h2>7. Ödeme ve Güvenlik</h2>
        <p>
          Ödemeler, PayTR güvenli ödeme altyapısı üzerinden gerçekleştirilir. Kart bilgileri
          Satıcı sunucularında saklanmaz. Taksit seçenekleri ödeme adımında Alıcı&apos;nın
          kartına tanımlı bankaya göre görüntülenir.
        </p>

        <h2>8. Uyuşmazlıkların Çözümü</h2>
        <p>
          İşbu sözleşmeden doğan uyuşmazlıklarda, Ticaret Bakanlığı&apos;nca her yıl ilan
          edilen parasal sınırlar dahilinde Alıcı&apos;nın yerleşim yerindeki İl/İlçe Tüketici
          Hakem Heyetleri, bu sınırları aşan uyuşmazlıklarda ise Tüketici Mahkemeleri
          yetkilidir.
        </p>
      </article>
    </>
  );
}
