import Link from "next/link";
import LegalPageHeader from "@/components/layout/LegalPageHeader";

export const metadata = { title: "Cayma Formu | Özcan Mobilya" };

const ARTICLE_CLASS =
  "mx-auto max-w-3xl px-4 py-10 sm:px-6 lg:px-8 font-body text-sm leading-relaxed text-secondary-light " +
  "[&_h2]:mt-8 [&_h2]:mb-3 [&_h2]:font-display [&_h2]:text-lg [&_h2]:font-semibold [&_h2]:text-secondary " +
  "[&_p]:mt-3 [&_ul]:mt-3 [&_ul]:list-disc [&_ul]:pl-5 [&_li]:mt-1.5 [&_strong]:text-secondary [&_strong]:font-semibold";

export default function CaymaFormuPage() {
  return (
    <>
      <LegalPageHeader title="Cayma Formu" />
      <article className={ARTICLE_CLASS}>
        <p>
          Bu form, Mesafeli Sözleşmeler Yönetmeliği Ek-1&apos;deki &quot;Cayma Formu
          Örneği&quot;ne dayanır ve sadece{" "}
          <Link href="/mesafeli-satis-sozlesmesi#cayma-hakki" className="text-primary underline underline-offset-2">
            cayma hakkınızın
          </Link>{" "}
          bulunduğu siparişler için kullanılabilir — alıcının özel isteğiyle özel ölçü/renkte
          üretilen ürünlerde cayma hakkı uygulanmayabilir (bkz. Mesafeli Satış Sözleşmesi
          madde 6).
        </p>
        <p>
          Cayma hakkınızı kullanmak istiyorsanız, aşağıdaki formu doldurup{" "}
          <Link href="/iletisim" className="text-primary underline underline-offset-2">
            iletişim sayfamızdan
          </Link>{" "}
          veya ozcan.mobilya.sinop@gmail.com adresine e-posta ile gönderebilirsiniz. Cayma
          süresi (14 gün), ürünü teslim aldığınız tarihte başlar.
        </p>

        <div className="mt-8 rounded-xl border border-secondary/20 p-6">
          <p className="text-center font-display text-base font-semibold text-secondary">
            CAYMA FORMU
          </p>
          <p className="mt-1 text-center text-xs italic text-secondary-light">
            (Bu formu, yalnızca sözleşmeden cayma hakkınızı kullanmak istediğinizde doldurup
            gönderiniz.)
          </p>

          <p className="mt-6">
            <strong>Kime:</strong>
            <br />
            Özcan Mobilya - Hüseyin Özcan
            <br />
            Camikebir Mahallesi Tütüncü Sokak No:6/A, Sinop/Merkez
            <br />
            E-posta: ozcan.mobilya.sinop@gmail.com — Telefon: +90 505 442 3809
          </p>

          <p className="mt-4">
            Aşağıda belirtilen malın satışına ilişkin sözleşmeden cayma hakkımı kullandığımı
            beyan ederim:
          </p>

          <dl className="mt-4 space-y-3">
            {[
              "Sipariş tarihi",
              "Teslim tarihi",
              "Cayma hakkına konu ürün(ler)",
              "Sipariş numarası",
            ].map((label) => (
              <div key={label} className="flex flex-wrap items-baseline gap-2 border-b border-secondary/10 pb-2">
                <dt className="font-semibold text-secondary">{label}:</dt>
                <dd className="flex-1 text-secondary-light">&nbsp;</dd>
              </div>
            ))}
          </dl>

          <p className="mt-6">
            Tüketicinin adı-soyadı:
            <br />
            <br />
            Tüketicinin adresi:
            <br />
            <br />
            <br />
            Tarih:
            <br />
            <br />
            Tüketicinin imzası <span className="italic">(kağıt üzerinde gönderilmesi hâlinde)</span>:
          </p>
        </div>

        <h2>Cayma Hakkı Sonrası Süreç</h2>
        <ul>
          <li>Formunuz elimize ulaştığında en geç 3 gün içinde onay e-postası gönderilir.</li>
          <li>Ürünü kullanılmamış, orijinal ambalajıyla ve varsa tüm aksesuarlarıyla iade etmeniz gerekir.</li>
          <li>
            Ürün bedeli, tarafımıza ulaştığı ve kontrol edildiği tarihten itibaren yasal süre
            içinde ödeme yönteminize iade edilir (bkz.{" "}
            <Link href="/kargo-iade" className="text-primary underline underline-offset-2">
              Kargo &amp; İade
            </Link>
            ).
          </li>
        </ul>
      </article>
    </>
  );
}
