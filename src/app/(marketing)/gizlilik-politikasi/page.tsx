import Link from "next/link";
import LegalPageHeader from "@/components/layout/LegalPageHeader";

export const metadata = { title: "Gizlilik Politikası ve KVKK Aydınlatma Metni | Özcan Mobilya" };

const ARTICLE_CLASS =
  "mx-auto max-w-3xl px-4 py-10 sm:px-6 lg:px-8 font-body text-sm leading-relaxed text-secondary-light " +
  "[&_h2]:mt-8 [&_h2]:mb-3 [&_h2]:font-display [&_h2]:text-lg [&_h2]:font-semibold [&_h2]:text-secondary " +
  "[&_p]:mt-3 [&_ul]:mt-3 [&_ul]:list-disc [&_ul]:pl-5 [&_li]:mt-1.5 [&_strong]:text-secondary [&_strong]:font-semibold";

export default function GizlilikPolitikasiPage() {
  return (
    <>
      <LegalPageHeader title="Gizlilik Politikası ve KVKK Aydınlatma Metni" />
      <article className={ARTICLE_CLASS}>
        <p>
          Bu metin, <strong>[Özcan Mobilya — Ticari Unvan]</strong> (&quot;Şirket&quot;) tarafından
          6698 sayılı Kişisel Verilerin Korunması Kanunu (&quot;KVKK&quot;) uyarınca veri sorumlusu
          sıfatıyla, ozcanmobilya.com üzerinden topladığı kişisel verilerin işlenmesine ilişkin
          ziyaretçi ve müşterileri aydınlatmak amacıyla hazırlanmıştır.
        </p>

        <h2>1. Veri Sorumlusu</h2>
        <p>
          <strong>Unvan:</strong> [Ticari Unvan — vergi levhası onaylandığında güncellenecek]
          <br />
          <strong>Adres:</strong> Camikebir Mahallesi Tütüncü Sokak No:6/A, Sinop/Merkez
          <br />
          <strong>E-posta:</strong> ozcan.mobilya.sinop@gmail.com
          <br />
          <strong>Telefon:</strong> +90 505 442 3809
          <br />
          <strong>Vergi Dairesi / No:</strong> [ ]
        </p>

        <h2>2. İşlenen Kişisel Veriler</h2>
        <p>Sitemiz üzerinden aşağıdaki kişisel veri kategorileri işlenebilir:</p>
        <ul>
          <li>Kimlik bilgileri (ad, soyad)</li>
          <li>İletişim bilgileri (e-posta, telefon, teslimat/fatura adresi)</li>
          <li>Müşteri işlem bilgileri (sipariş geçmişi, sepet içeriği)</li>
          <li>İşlem güvenliği bilgileri (giriş kayıtları, IP adresi, çerezler)</li>
          <li>
            Ödeme sürecine ilişkin veriler — kart bilgileri Şirket sunucularında saklanmaz,
            doğrudan ödeme kuruluşu (ör. PayTR) altyapısında işlenir
          </li>
        </ul>

        <h2>3. İşleme Amaçları</h2>
        <ul>
          <li>Sipariş oluşturma, teslimat ve satış sonrası hizmet süreçlerinin yürütülmesi</li>
          <li>Üyelik/hesap oluşturma ve oturum yönetimi</li>
          <li>Müşteri talep ve şikâyetlerinin (iletişim formu) yanıtlanması</li>
          <li>Yasal yükümlülüklerin (fatura, muhasebe kaydı) yerine getirilmesi</li>
          <li>Açık rıza verilmesi hâlinde kampanya/e-bülten iletişimi</li>
        </ul>

        <h2>4. Kişisel Verilerin Aktarılması</h2>
        <p>
          Kişisel verileriniz; ödeme işlemlerinin yürütülmesi için ödeme kuruluşuna (PayTR),
          kargo/teslimat için anlaşmalı kargo firmasına ve yasal zorunluluk hâllerinde yetkili
          kamu kurumlarına, KVKK&apos;nın 8. ve 9. maddelerinde belirtilen şartlarla sınırlı
          olarak aktarılabilir. Verileriniz yurt dışına aktarılmaz
          <em> [barındırma/e-posta altyapısı yurt dışı sunucu kullanıyorsa bu madde güncellenmelidir]</em>.
        </p>

        <h2>5. Saklama Süresi</h2>
        <p>
          Kişisel veriler, ilgili işleme amacının gerektirdiği süre ve Türk Ticaret Kanunu,
          Vergi Usul Kanunu gibi mevzuatın öngördüğü yasal saklama süreleri boyunca (genellikle
          10 yıla kadar, ticari/mali kayıtlar için) muhafaza edilir.
        </p>

        <h2>6. Çerezler (Cookies)</h2>
        <p>
          Site; oturum yönetimi ve sepet bilgisinin tarayıcınızda tutulması için zorunlu
          çerezler/yerel depolama, tercihinize bağlı olarak da ziyaret istatistiklerini ölçmek
          için Google Analytics çerezlerini kullanır. Çerez kategorileri, kullanım amaçları ve
          onayınızı nasıl geri alabileceğiniz için{" "}
          <Link href="/cerez-politikasi" className="text-primary underline underline-offset-2">
            Çerez Politikası
          </Link>{" "}
          sayfasına bakınız.
        </p>

        <h2>7. Veri Sahibinin Hakları (KVKK m.11)</h2>
        <p>İlgili kişi, veri sorumlusuna başvurarak;</p>
        <ul>
          <li>Kişisel verisinin işlenip işlenmediğini öğrenme,</li>
          <li>İşlenmişse buna ilişkin bilgi talep etme,</li>
          <li>İşlenme amacını ve amacına uygun kullanılıp kullanılmadığını öğrenme,</li>
          <li>Yurt içi/yurt dışında aktarıldığı üçüncü kişileri bilme,</li>
          <li>Eksik/yanlış işlenmişse düzeltilmesini isteme,</li>
          <li>KVKK&apos;da öngörülen şartlarda silinmesini/yok edilmesini isteme,</li>
          <li>İşlemlerin aktarıldığı üçüncü kişilere bildirilmesini isteme,</li>
          <li>Otomatik sistemlerle analiz sonucu aleyhine bir sonuç çıkmasına itiraz etme,</li>
          <li>Kanuna aykırı işlenme nedeniyle zararın giderilmesini talep etme haklarına sahiptir.</li>
        </ul>
        <p>
          Bu haklara ilişkin taleplerinizi yukarıdaki e-posta adresine yazılı olarak
          iletebilirsiniz.
        </p>
      </article>
    </>
  );
}
