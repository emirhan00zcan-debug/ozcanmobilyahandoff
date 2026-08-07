import Link from "next/link";
import LegalPageHeader from "@/components/layout/LegalPageHeader";

export const metadata = { title: "Çerez Politikası | Özcan Mobilya" };

const ARTICLE_CLASS =
  "mx-auto max-w-3xl px-4 py-10 sm:px-6 lg:px-8 font-body text-sm leading-relaxed text-secondary-light " +
  "[&_h2]:mt-8 [&_h2]:mb-3 [&_h2]:font-display [&_h2]:text-lg [&_h2]:font-semibold [&_h2]:text-secondary " +
  "[&_p]:mt-3 [&_ul]:mt-3 [&_ul]:list-disc [&_ul]:pl-5 [&_li]:mt-1.5 [&_strong]:text-secondary [&_strong]:font-semibold " +
  "[&_table]:mt-3 [&_table]:w-full [&_table]:border-collapse [&_th]:border [&_th]:border-secondary/15 [&_th]:bg-secondary/[0.03] [&_th]:p-2.5 [&_th]:text-left [&_th]:font-semibold [&_th]:text-secondary [&_td]:border [&_td]:border-secondary/15 [&_td]:p-2.5";

export default function CerezPolitikasiPage() {
  return (
    <>
      <LegalPageHeader title="Çerez Politikası" />
      <article className={ARTICLE_CLASS}>
        <p>
          Bu politika, ozcanmobilya.com&apos;u ziyaret ettiğinizde tarayıcınıza yerleştirilen
          çerezleri (cookie), amaçlarını ve bunları nasıl yönetebileceğinizi açıklar. Kişisel
          verilerin işlenmesine ilişkin genel bilgi için{" "}
          <Link href="/gizlilik-politikasi" className="text-primary underline underline-offset-2">
            Gizlilik Politikası ve KVKK Aydınlatma Metni
          </Link>
          &apos;ni inceleyin.
        </p>

        <h2>1. Çerez Nedir?</h2>
        <p>
          Çerezler, bir web sitesini ziyaret ettiğinizde tarayıcınıza kaydedilen, siteyi bir
          sonraki ziyaretinizde sizi tanımaya, tercihlerinizi hatırlamaya veya site kullanımını
          analiz etmeye yarayan küçük metin dosyalarıdır.
        </p>

        <h2>2. Kullandığımız Çerez Kategorileri</h2>
        <table>
          <thead>
            <tr>
              <th>Kategori</th>
              <th>Amaç</th>
              <th>Örnek / Sağlayıcı</th>
              <th>Onay Gerekir mi?</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>Zorunlu</td>
              <td>Oturum yönetimi, sepet içeriğinin tarayıcınızda tutulması, güvenlik</td>
              <td>Site içi (next-auth, sepet deposu)</td>
              <td>Hayır — devre dışı bırakılırsa site çalışmaz</td>
            </tr>
            <tr>
              <td>Analitik</td>
              <td>Ziyaretçi sayısı, hangi ürünlerin görüntülendiği, sepet/ödeme adımlarında
                nerede vazgeçildiği gibi kullanım istatistikleri</td>
              <td>Google Analytics (_ga, _ga_*, _gid)</td>
              <td>Evet</td>
            </tr>
          </tbody>
        </table>
        <p>
          Şu an sitede pazarlama/yeniden hedefleme (Meta Pixel vb.) çerezi kullanılmamaktadır;
          kullanılmaya başlandığında bu tablo güncellenecektir.
        </p>

        <h2>3. Onay ve Tercih Yönetimi</h2>
        <p>
          Zorunlu çerezler siteyi kullanabilmeniz için her zaman aktiftir. Analitik çerezler
          ise yalnızca sayfanın altında beliren çerez bildirimini{" "}
          <strong>&quot;Kabul Et&quot;</strong> ile onayladığınızda etkinleşir; tercihinizi
          istediğiniz zaman tarayıcı ayarlarınızdan çerezleri silerek geri alabilirsiniz —
          bir sonraki ziyaretinizde bildirim yeniden görüntülenir.
        </p>

        <h2>4. Çerezleri Tarayıcınızdan Nasıl Silersiniz?</h2>
        <p>
          Çoğu tarayıcı, çerezleri görüntülemenize, tek tek silmenize veya belirli sitelerden
          gelen çerezleri tamamen engellemenize izin verir. Bu ayarlar genellikle tarayıcınızın
          &quot;Gizlilik ve Güvenlik&quot; menüsünde yer alır. Tüm çerezleri engellemeniz
          durumunda sitenin bazı bölümleri (örn. sepet) beklendiği gibi çalışmayabilir.
        </p>

        <h2>5. İletişim</h2>
        <p>
          Çerez kullanımıyla ilgili sorularınız için{" "}
          <Link href="/iletisim" className="text-primary underline underline-offset-2">
            bize ulaşabilirsiniz
          </Link>
          .
        </p>
      </article>
    </>
  );
}
