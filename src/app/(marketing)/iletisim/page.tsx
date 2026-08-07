import Link from "next/link";
import Image from "next/image";
import { FaPhone, FaEnvelope, FaMapMarkerAlt, FaClock } from "react-icons/fa";
import AboutHero from "@/components/layout/AboutHero";
import TrustMarquee from "@/components/layout/TrustMarquee";
import ContactForm from "@/components/contact/ContactForm";
import LocationMapCard from "@/components/contact/LocationMapCard";
import InstagramProfileCard from "@/components/contact/InstagramProfileCard";
import FacebookPageEmbed from "@/components/contact/FacebookPageEmbed";
import { contactInfo, socialLinks } from "@/lib/data/homepage-mock";

export const metadata = { title: "İletişim | Özcan Mobilya" };

const INFO_ICONS = [FaClock, FaPhone, FaEnvelope, FaMapMarkerAlt];

// Gerçek koordinatlar — showroom Camikebir Mahallesi'nde (mevcut "Adres" kaydıyla aynı
// nokta), atölye Korucuk Mahallesi'nde (OpenStreetMap ters coğrafi kodlamayla doğrulandı).
const LOCATIONS = [
  {
    title: "Showroom",
    address: "Camikebir Mahallesi Tütüncü sokak no 6 /A Sinop/Merkez",
    lat: 42.02616509824038,
    lon: 35.14729428370316,
  },
  {
    title: "Üretim Atölyesi",
    address: "Korucuk Mahallesi, Sinop/Merkez",
    lat: 41.99701970166003,
    lon: 35.09030347603661,
  },
];

// Gerçek profilden alınan bilgiler (instagram.com/sinop_ozcan_mobilya) — biyografi,
// takipçi/takip sayıları ve öne çıkanlar başlıkları, sahte veri değil.
const INSTAGRAM_BIO =
  "İletişim Numaralarımız; Tel/Fax➡️03682604885 Hüseyin ÖZCAN➡️05443109756 Osman ÖZCAN➡️05458985757";
const INSTAGRAM_HIGHLIGHTS = ["TAŞINIYORUZ!", "İNDİRİM!!", "AKSESUAR", "İNDİRİMLİ ÜRÜN", "ANKASTRE"];
const INSTAGRAM_PREVIEW_IMAGES = [
  "/media/k602_lifestyle_1782831673363.jpg",
  "/media/y5_pro_1769512354644.jpg",
  "/media/d9_pro_1769533007384.jpg",
  "/media/premium-bedroom.jpg",
  "/media/k88_lifestyle_1782832301685.jpg",
  "/media/t3_pro_1769533120140.jpg",
];

export default function IletisimPage() {
  return (
    <>
      <div className="mx-auto max-w-7xl px-4 pt-6 sm:px-6 lg:px-8">
        <nav className="mb-6 flex items-center gap-2 font-body text-xs text-secondary-light">
          <Link href="/" className="font-medium text-secondary hover:text-primary">
            Ana sayfa
          </Link>
          <span>|</span>
          <span className="text-secondary-light">İletişim</span>
        </nav>

        <AboutHero title="Bize Ulaşın" imageUrl="/media/d7_pro_1769532976156.jpg" />
      </div>

      {/* Misyon paragrafına karşılık gelen kısa giriş — Hakkımızda sayfasıyla aynı ritim */}
      <section className="mx-auto max-w-3xl px-4 py-16 text-center sm:px-6 lg:px-8">
        <h2 className="font-display text-2xl font-bold leading-snug text-secondary sm:text-3xl">
          Sorularınız mı var? Size yardımcı olmaktan mutluluk duyarız.
        </h2>
        <p className="mt-5 font-body text-base leading-relaxed text-secondary-light">
          Sipariş, ölçü, malzeme veya kurulumla ilgili aklınıza takılan her şey için aşağıdaki
          formu doldurabilir ya da doğrudan telefon veya e-posta ile bize ulaşabilirsiniz.
        </p>
      </section>

      <section className="mx-auto max-w-7xl px-4 pb-20 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 gap-10 lg:grid-cols-3">
          {/* Form */}
          <div className="rounded-2xl border border-secondary/10 p-6 sm:p-8 lg:col-span-2">
            <h3 className="font-display text-lg font-semibold text-secondary">Mesaj Gönderin</h3>
            <div className="mt-6">
              <ContactForm />
            </div>
          </div>

          {/* Bilgi kartı */}
          <div className="flex flex-col gap-6">
            <div className="relative h-44 w-full overflow-hidden rounded-2xl">
              <Image
                src="/media/ozcan-marka-kimligi.jpg"
                alt="Özcan Mobilya atölyesi"
                fill
                sizes="(max-width: 1024px) 100vw, 33vw"
                className="object-cover"
              />
            </div>

            <div className="rounded-2xl border border-secondary/10 p-6">
              <ul className="space-y-5">
                {contactInfo.map((item, i) => {
                  const Icon = INFO_ICONS[i % INFO_ICONS.length];
                  return (
                    <li key={item.label} className="flex items-start gap-3">
                      <Icon className="mt-0.5 h-4 w-4 shrink-0 text-primary" />
                      <div>
                        <p className="font-body text-sm font-semibold text-secondary">{item.label}</p>
                        <p className="mt-0.5 font-body text-xs leading-relaxed text-secondary-light">
                          {item.value}
                        </p>
                      </div>
                    </li>
                  );
                })}
              </ul>
            </div>
          </div>
        </div>
      </section>

      {/* Showroom + Atölye konumları */}
      <section className="mx-auto max-w-7xl px-4 pb-20 sm:px-6 lg:px-8">
        <h2 className="font-display text-2xl font-semibold text-secondary sm:text-3xl">
          Bizi Ziyaret Edin
        </h2>
        <p className="mt-2 font-body text-sm text-secondary-light">
          Showroom&apos;umuzda ürünlerimizi yerinde inceleyebilir, üretim atölyemizde nasıl
          hayat bulduklarını görebilirsiniz.
        </p>
        <div className="mt-8 grid grid-cols-1 gap-8 md:grid-cols-2">
          {LOCATIONS.map((location) => (
            <LocationMapCard key={location.title} {...location} />
          ))}
        </div>
      </section>

      {/* Sosyal medya — Facebook resmi Page Plugin ile gerçekten gömülü/gezilebilir;
          Instagram tam profili gömmeye izin vermediği için gerçek biyografi/istatistiklerle
          birebir arayüz kopyası, telefon ekranı içinde kaydırılabilir */}
      <section className="mx-auto max-w-7xl px-4 pb-20 sm:px-6 lg:px-8">
        <h2 className="text-center font-display text-2xl font-semibold text-secondary sm:text-3xl">
          Sosyal Medyada Takip Edin
        </h2>
        <div className="mt-10 flex flex-wrap justify-center gap-12">
          <InstagramProfileCard
            href={socialLinks.instagram}
            handle={socialLinks.instagramHandle}
            bio={INSTAGRAM_BIO}
            followers={541}
            following={23}
            highlights={INSTAGRAM_HIGHLIGHTS}
            images={INSTAGRAM_PREVIEW_IMAGES}
          />
          <FacebookPageEmbed pageUrl={socialLinks.facebook} />
        </div>
      </section>

      <TrustMarquee />
    </>
  );
}
