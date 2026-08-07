import Link from "next/link";
import Image from "next/image";
import { FaCheck } from "react-icons/fa";
import AboutHero from "@/components/layout/AboutHero";
import AboutSplit from "@/components/layout/AboutSplit";
import AboutFaq from "@/components/layout/AboutFaq";
import TrustMarquee from "@/components/layout/TrustMarquee";

export const metadata = { title: "Hakkımızda | Özcan Mobilya" };

const PRINCIPLES = ["E1 Sertifikalı Malzeme", "2 Yıl Garanti", "Size Özel Ölçü", "Fabrikadan Doğrudan"];

const FEATURES = [
  {
    title: "Rahat Kullanım",
    description: "Yumuşak kapanma menteşe ve çekmece sistemleriyle günlük kullanım kolaylığı.",
    imageUrl: "/media/k602_closed_studio_1782831490167.jpg",
  },
  {
    title: "Şeffaf Fiyatlandırma",
    description: "Aracıları aradan çıkararak fabrikadan doğrudan, dürüst fiyat.",
    imageUrl: "/media/k88_closed_studio_1782832274292.jpg",
  },
  {
    title: "Sertifikalı Kalite",
    description: "E1 standardında, çocuk ve çevre dostu malzemelerle üretim.",
    imageUrl: "/media/k83_closed_studio_1782833640405.jpg",
  },
  {
    title: "Sürdürülebilirlik",
    description: "Uzun ömürlü tasarımlarla daha az atık, daha uzun kullanım.",
    imageUrl: "/media/k37_closed_studio_1782841086991.jpg",
  },
];

export default function HakkimizdaPage() {
  return (
    <>
      <div className="mx-auto max-w-7xl px-4 pt-6 sm:px-6 lg:px-8">
        <nav className="mb-6 flex items-center gap-2 font-body text-xs text-secondary-light">
          <Link href="/" className="font-medium text-secondary hover:text-primary">
            Ana sayfa
          </Link>
          <span>|</span>
          <span className="text-secondary-light">Hakkımızda</span>
        </nav>

        <AboutHero title="Yarım Asırlık Zanaat, Modern Bir Vizyon" imageUrl="/media/ozcan-marka-kimligi.jpg" />
      </div>

      {/* Misyon */}
      <section className="mx-auto max-w-3xl px-4 py-16 text-center sm:px-6 lg:px-8">
        <h2 className="font-display text-2xl font-bold leading-snug text-secondary sm:text-3xl">
          Mobilyayı bir eşya değil, evinizin bir parçası olarak görüyoruz.
        </h2>
        <p className="mt-5 font-body text-base leading-relaxed text-secondary-light">
          Özcan Mobilya olarak amacımız sadece dolap ya da ünite satmak değil; ailelerin yıllarca güvenle
          kullanacağı, evlerinin ruhuna uyum sağlayan parçalar üretmek. Sinop&apos;taki üretim tesisimizde her
          adımı kendimiz kontrol ederek, aracısız ve dürüst bir fiyatlandırmayla kaliteyi kapınıza kadar
          getiriyoruz.
        </p>
      </section>

      <AboutSplit
        eyebrow="Zanaatkarlık"
        title="Elle Dokunan Detaylar, Makine Hassasiyeti"
        body="Her kapak, zımparadan boyaya kadar titiz bir işçilikten geçer. 1. sınıf E1 kalitesinde, nem ve çizilmeye dayanıklı yüksek yoğunluklu MDF kullanıyor, yüzeyleri elle kontrol ederek pürüzsüz bir kaplama garanti ediyoruz."
        imageUrl="/media/el-iscisi-zimparalama.png"
      />

      {/* Prensip rozetleri */}
      <section className="mx-auto max-w-7xl px-4 py-6 text-center sm:px-6 lg:px-8">
        <h2 className="font-display text-2xl font-semibold text-secondary sm:text-3xl">
          Bu titizlik bizi bugünkü kalite standardımıza taşıdı
        </h2>
        <div className="mt-8 flex flex-wrap items-center justify-center gap-3">
          {PRINCIPLES.map((item) => (
            <span
              key={item}
              className="flex items-center gap-2 rounded-full border border-secondary/15 px-4 py-2.5 font-body text-xs font-medium text-secondary"
            >
              <FaCheck className="h-2.5 w-2.5 text-primary" />
              {item}
            </span>
          ))}
        </div>
      </section>

      {/* Özellik grid'i */}
      <section className="mx-auto max-w-7xl px-4 py-16 sm:px-6 lg:px-8">
        <div className="grid grid-cols-2 gap-6 sm:gap-8 lg:grid-cols-4">
          {FEATURES.map((feature, i) => (
            <div key={feature.title}>
              <div className="relative aspect-square overflow-hidden rounded-xl bg-secondary/[0.04]">
                <Image
                  src={feature.imageUrl}
                  alt={feature.title}
                  fill
                  sizes="(max-width: 640px) 50vw, 25vw"
                  className="object-cover"
                />
              </div>
              <p className="mt-4 font-body text-xs font-semibold text-primary">{i + 1}.</p>
              <h3 className="mt-1 font-display text-base font-semibold text-secondary">{feature.title}</h3>
              <p className="mt-1.5 font-body text-sm leading-relaxed text-secondary-light">{feature.description}</p>
            </div>
          ))}
        </div>
      </section>

      {/* Alıntı banner */}
      <section className="bg-primary-50 py-16">
        <div className="mx-auto max-w-3xl px-4 text-center sm:px-6 lg:px-8">
          <p className="font-display text-xl font-semibold italic leading-relaxed text-secondary sm:text-2xl">
            &ldquo;Fark yarattığımız yer burası: aracı yok, gizli maliyet yok — sadece dürüst işçilik ve dürüst
            fiyat.&rdquo;
          </p>
          <p className="mt-4 font-body text-sm font-medium text-secondary-light">— Özcan Mobilya</p>
        </div>
      </section>

      <AboutSplit
        eyebrow="Atölyeden Evinize"
        title="Sinop'tan Türkiye'nin Her Yerine"
        body="Sağlam paketleme ve kolay kurulum şemalarıyla ürünlerimiz hiçbir hasar almadan kapınıza kadar ulaşıyor. Montaj deneyiminizi kolaylaştırmak için her parçayı numaralandırıyor, adım adım kurulum şeması ekliyoruz."
        imageUrl="/media/y5_pro_1769512354644.jpg"
        reverse
        cta={{ label: "Koleksiyonu Gör", href: "/koleksiyon" }}
      />

      <AboutFaq />

      <TrustMarquee />
    </>
  );
}
