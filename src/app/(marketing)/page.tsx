import Link from "next/link";
import { prisma } from "@/lib/prisma";
import Reveal from "@/components/ui/Reveal";
import CategoryCircles from "@/components/layout/CategoryCircles";
import HeroSlider from "@/components/home/HeroSlider";
import FeaturedProducts from "@/components/home/FeaturedProducts";
import CountdownBar from "@/components/home/CountdownBar";
import ShowcaseGrid from "@/components/home/ShowcaseGrid";
import CollectionTabs from "@/components/home/CollectionTabs";
import PromoDuo from "@/components/home/PromoDuo";
import CategoryChips from "@/components/home/CategoryChips";
import AboutSection from "@/components/home/AboutSection";
import Testimonials from "@/components/home/Testimonials";
import InstagramStrip from "@/components/home/InstagramStrip";
import {
  getCategories,
  getRooms,
  heroSlides,
  featuredProductsBanner,
  showcaseTiles,
  collectionTabs,
  promoCards,
  quickFilterChips,
  aboutSection,
  testimonials,
  socialLinks,
} from "@/lib/data/homepage-mock";
import { getFeaturedProducts } from "@/lib/data/products";

export default async function HomePage() {
  // Kampanya sayacı, veritabanındaki aktif Coupon kaydının gerçek `endsAt` tarihine bağlı;
  // süresi geçmiş veya pasif kuponlarda banner hiç gösterilmez.
  const [activeCoupon, categories, rooms, featuredProducts] = await Promise.all([
    prisma.coupon.findFirst({
      where: { code: "FLAS20", isActive: true, endsAt: { gt: new Date() } },
    }),
    getCategories(),
    getRooms(),
    getFeaturedProducts(),
  ]);

  return (
    <>
      {/* 2. Kategori çemberi navigasyonu */}
      <CategoryCircles items={categories} basePath="/kategori" size="sm" />

      {/* 3. Ana görsel & slogan */}
      <HeroSlider slides={heroSlides} />

      {/* 4. Öne Çıkan Modeller */}
      <Reveal>
        <FeaturedProducts
          title="Öne Çıkan Modeller"
          description="Özcan Mobilya kalitesiyle evinizin havasını değiştirecek en popüler tasarımlar."
          tabs={[
            { label: "Ana sayfa", products: featuredProducts },
            { label: "Yeni Tarz", products: [...featuredProducts].reverse() },
          ]}
          allHref="/koleksiyon/yeni-tarz"
          banner={featuredProductsBanner}
        />
      </Reveal>

      {/* 5. Kampanya sayacı barı — kupon aktif ve süresi dolmamışsa gösterilir */}
      {activeCoupon && (
        <Reveal>
          <CountdownBar targetDate={activeCoupon.endsAt} couponCode={activeCoupon.code} />
        </Reveal>
      )}

      {/* 6. Büyük banner'lı ürün ızgarası (2x2 / 4'lü tek sıra) */}
      <Reveal>
        <ShowcaseGrid tiles={showcaseTiles} />
      </Reveal>

      {/* 7. Yaşam Alanına Göre Alışveriş — üstteki kategori çemberleriyle aynı yuvarlak stil */}
      <Reveal>
        <section className="mx-auto max-w-7xl px-4 py-20 sm:px-6 lg:px-8">
          <div className="mb-6 flex items-center justify-between">
            <h2 className="font-display text-3xl font-semibold text-secondary">
              Yaşam Alanına Göre Alışveriş
            </h2>
            <Link
              href="/koleksiyon"
              className="font-body text-sm font-medium text-secondary underline underline-offset-4 hover:text-primary"
            >
              Tüm Ürünler
            </Link>
          </div>
          <div className="grid grid-cols-3 gap-x-4 gap-y-8 sm:grid-cols-4 lg:grid-cols-6">
            {rooms.map((room) => (
              <Link
                key={room.id}
                href={`/oda/${room.slug}`}
                className="group flex flex-col items-center gap-3"
              >
                <div className="h-24 w-24 overflow-hidden rounded-full border border-secondary/10 bg-secondary/[0.04] transition-transform duration-300 group-hover:-translate-y-1 lg:h-28 lg:w-28">
                  {room.imageUrl ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img
                      src={room.imageUrl}
                      alt={room.name}
                      className="h-full w-full object-cover transition-transform duration-300 group-hover:scale-110"
                    />
                  ) : (
                    <div className="flex h-full w-full items-center justify-center font-display text-lg text-secondary/25">
                      {room.name.charAt(0)}
                    </div>
                  )}
                </div>
                <span className="max-w-[110px] text-center font-body text-sm font-medium leading-tight text-secondary">
                  {room.name}
                </span>
              </Link>
            ))}
          </div>
        </section>
      </Reveal>

      {/* 8. Sizin İçin Seçtiklerimiz — sekmeli vitrin */}
      <Reveal>
        <CollectionTabs tabs={collectionTabs} />
      </Reveal>

      {/* 9. Kategori hızlı filtre çipleri */}
      <Reveal>
        <CategoryChips chips={quickFilterChips} />
      </Reveal>

      {/* 10. Kaçırılmayacak Fırsatlar — ikinci ürün vitrin */}
      <Reveal>
        <FeaturedProducts
          title="Kaçırılmayacak Fırsatlar"
          description="Fabrikadan doğrudan satışa özel, kısa süreliğine fiyatta dip yapmış demonte mobilya ürünlerimiz."
          tabs={[{ label: "Tümü", products: featuredProducts }]}
          allHref="/koleksiyon/firsatlar"
        />
      </Reveal>

      {/* 11. Biz Kimiz? */}
      <Reveal>
        <AboutSection data={aboutSection} />
      </Reveal>

      {/* 12. TV Üniteleri %40 / Gardroplar %30 kampanya kartları */}
      <Reveal>
        <PromoDuo cards={promoCards} />
      </Reveal>

      {/* 13. Müşteri Deneyimleri */}
      <Reveal>
        <Testimonials items={testimonials} />
      </Reveal>

      {/* 14. Instagram şeridi */}
      <Reveal>
        <InstagramStrip social={socialLinks} />
      </Reveal>
    </>
  );
}
