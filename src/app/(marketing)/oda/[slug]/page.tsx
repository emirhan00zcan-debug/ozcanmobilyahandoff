import Link from "next/link";
import { notFound } from "next/navigation";
import CategoryHero from "@/components/layout/CategoryHero";
import CategoryCircles from "@/components/layout/CategoryCircles";
import ProductListingSection from "@/components/product/ProductListingSection";
import MaterialQualitySection from "@/components/layout/MaterialQualitySection";
import CategoryChips from "@/components/home/CategoryChips";
import TrustMarquee from "@/components/layout/TrustMarquee";
import { getRooms, getRoomBySlug, quickFilterChips } from "@/lib/data/homepage-mock";
import { getProductsByRoom } from "@/lib/data/products";

export async function generateStaticParams() {
  const rooms = await getRooms();
  return rooms.map((r) => ({ slug: r.slug }));
}

export default async function OdaDetailPage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const [room, rooms] = await Promise.all([getRoomBySlug(slug), getRooms()]);

  if (!room) {
    notFound();
  }

  const gridProducts = await getProductsByRoom(slug);

  return (
    <>
      <div className="mx-auto max-w-7xl px-4 pt-6 sm:px-6 lg:px-8">
        <nav className="mb-6 flex items-center gap-2 font-body text-xs text-secondary-light">
          <Link href="/" className="font-medium text-secondary hover:text-primary">
            Ana sayfa
          </Link>
          <span>|</span>
          <Link href="/oda" className="hover:text-primary">
            Odalara Göre
          </Link>
          <span>|</span>
          <span className="text-secondary-light">{room.name}</span>
        </nav>

        <CategoryHero title={room.name} imageUrl={room.imageUrl} />
      </div>

      <div className="mt-10">
        <CategoryCircles items={rooms} basePath="/oda" size="sm" />
      </div>

      <div className="mx-auto max-w-7xl px-4 py-10 sm:px-6 lg:px-8">
        <ProductListingSection
          products={gridProducts}
          emptyMessage={`${room.name} için henüz ürün eklenmedi, yakında burada olacak.`}
          promoTile={{
            eyebrow: "Home & Decor",
            title: "Kulplar için en iyisi",
            ctaLabel: "Göz atın",
            ctaHref: "https://www.eryildiz.net/kategori/dolap-kulplari",
            imageUrl: "/media/Gemini_Generated_Image_8jyuzm8jyuzm8jyu.png",
          }}
        />
      </div>

      <MaterialQualitySection />

      <div>
        <h2 className="mx-auto max-w-7xl px-4 pt-4 font-display text-2xl font-semibold text-secondary sm:px-6 lg:px-8">
          Trend
        </h2>
        <CategoryChips chips={quickFilterChips} />
      </div>

      <TrustMarquee />
    </>
  );
}
