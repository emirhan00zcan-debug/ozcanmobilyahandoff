import Link from "next/link";
import { FaRulerCombined, FaCube, FaMagic, FaShoppingBag } from "react-icons/fa";
import AboutHero from "@/components/layout/AboutHero";
import TrustMarquee from "@/components/layout/TrustMarquee";
import { absoluteUrl, truncateForMeta } from "@/lib/seo";

export const metadata = {
  title: "Oda & Mobilya Planlayıcı | Özcan Mobilya",
  description: truncateForMeta(
    "Odanızın gerçek ölçüleriyle mobilyalarınızı ücretsiz planlayın: milimetrik hassasiyette yerleşim, anlık 3D önizleme ve tasarımınızı doğrudan sepetinize aktarma.",
  ),
  alternates: { canonical: absoluteUrl("/planlayici") },
};

const FEATURES = [
  {
    title: "Milimetrik Hassasiyet",
    description:
      "Odanızın gerçek ölçülerini girin; mobilyalar duvara, kapıya ve pencereye göre 1 milimetre hassasiyetinde yerleşir.",
    icon: FaRulerCombined,
  },
  {
    title: "Anlık 3D Önizleme",
    description: "2D üzerinde kurduğunuz yerleşimi tek tıkla üç boyutlu görüntüleyin, odanızı satın almadan önce hayal edin.",
    icon: FaCube,
  },
  {
    title: "Akıllı Otomatik Yerleşim",
    description: "Beğendiğiniz ürünleri seçin, planlayıcı odanıza en uygun yerleşimi sizin için otomatik önersin.",
    icon: FaMagic,
  },
  {
    title: "Sepete Doğrudan Aktarım",
    description: "Tasarımınızı tamamlayın; kullandığınız ürünlerin tam listesi tek tıkla sepetinize aktarılsın.",
    icon: FaShoppingBag,
  },
];

const STEPS = [
  {
    title: "Odanızı Tanımlayın",
    description: "Genişlik, derinlik ve kapı/pencere konumlarını girerek odanızın sanal bir kopyasını oluşturun.",
  },
  {
    title: "Mobilyaları Yerleştirin",
    description: "Kataloğumuzdaki ürünleri sürükleyip bırakın ya da otomatik yerleşimi kullanın.",
  },
  {
    title: "Sepete Aktarın",
    description: "Tasarımınızı tamamlayın; ürün listesini sepetinize ekleyin veya ölçülü plan olarak indirin.",
  },
];

const PLANNER_URL = process.env.NEXT_PUBLIC_PLANNER_URL;

export default function PlanlayiciPage() {
  return (
    <>
      <div className="mx-auto max-w-7xl px-4 pt-6 sm:px-6 lg:px-8">
        <nav className="mb-6 flex items-center gap-2 font-body text-xs text-secondary-light">
          <Link href="/" className="font-medium text-secondary hover:text-primary">
            Ana sayfa
          </Link>
          <span>|</span>
          <span className="text-secondary-light">Planlayıcı</span>
        </nav>

        <AboutHero title="Odanızı Satın Almadan Önce Görün" imageUrl="/media/premium-bedroom.jpg" />
      </div>

      {/* Giriş */}
      <section className="mx-auto max-w-3xl px-4 py-16 text-center sm:px-6 lg:px-8">
        <h2 className="font-display text-2xl font-bold leading-snug text-secondary sm:text-3xl">
          Hayalinizdeki odayı kendi gözlerinizle görün.
        </h2>
        <p className="mt-5 font-body text-base leading-relaxed text-secondary-light">
          Özcan Mobilya&apos;nın geliştirdiği ücretsiz oda planlayıcısı ile odanızın gerçek ölçülerini girin,
          gardırop, dresuar, TV ünitesi gibi ürünlerimizi milimetrik hassasiyetle yerleştirin ve saniyeler içinde
          üç boyutlu önizlemesini alın. Tasarımınızı beğendiğinizde, kullandığınız ürünler tek tıkla sepetinize
          aktarılır.
        </p>
      </section>

      {/* Özellik grid'i */}
      <section className="mx-auto max-w-7xl px-4 py-6 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 gap-8 sm:grid-cols-2 lg:grid-cols-4">
          {FEATURES.map((feature) => (
            <div key={feature.title}>
              <div className="grid h-12 w-12 place-items-center rounded-full bg-primary-50">
                <feature.icon className="h-5 w-5 text-primary" />
              </div>
              <h3 className="mt-4 font-display text-base font-semibold text-secondary">{feature.title}</h3>
              <p className="mt-1.5 font-body text-sm leading-relaxed text-secondary-light">{feature.description}</p>
            </div>
          ))}
        </div>
      </section>

      {/* Nasıl çalışır */}
      <section className="mx-auto max-w-7xl px-4 py-16 sm:px-6 lg:px-8">
        <h2 className="text-center font-display text-2xl font-semibold text-secondary sm:text-3xl">Nasıl Çalışır</h2>
        <div className="mt-10 grid grid-cols-1 gap-10 sm:grid-cols-3">
          {STEPS.map((step, i) => (
            <div key={step.title} className="text-center">
              <span className="mx-auto grid h-10 w-10 place-items-center rounded-full border border-primary/30 font-display text-sm font-semibold text-primary">
                {i + 1}
              </span>
              <h3 className="mt-4 font-display text-base font-semibold text-secondary">{step.title}</h3>
              <p className="mt-1.5 font-body text-sm leading-relaxed text-secondary-light">{step.description}</p>
            </div>
          ))}
        </div>
      </section>

      {/* CTA banner */}
      <section className="bg-primary-50 py-16">
        <div className="mx-auto max-w-2xl px-4 text-center sm:px-6 lg:px-8">
          <h2 className="font-display text-2xl font-semibold text-secondary sm:text-3xl">
            Şimdi Kendi Odanızı Tasarlamaya Başlayın
          </h2>
          <p className="mt-3 font-body text-sm text-secondary-light">Ücretsiz, kayıt gerektirmeden deneyebilirsiniz.</p>

          {PLANNER_URL ? (
            <a
              href={PLANNER_URL}
              target="_blank"
              rel="noopener noreferrer"
              className="btn-sweep mt-7 inline-block rounded-full border border-primary/30 px-10 py-3.5 font-body text-sm font-semibold text-secondary hover:scale-105 active:scale-95"
            >
              Planlayıcıyı Aç
            </a>
          ) : (
            <>
              <span className="mt-7 inline-block cursor-not-allowed rounded-full border border-secondary/15 px-10 py-3.5 font-body text-sm font-semibold text-secondary-light">
                Çok Yakında
              </span>
              <p className="mt-4 font-body text-xs text-secondary-light">
                Planlayıcımız üzerinde çalışmaya devam ediyoruz. O sırada{" "}
                <Link href="/katalog" className="underline hover:text-primary">
                  kataloğumuza
                </Link>{" "}
                göz atabilirsiniz.
              </p>
            </>
          )}
        </div>
      </section>

      <TrustMarquee />
    </>
  );
}
