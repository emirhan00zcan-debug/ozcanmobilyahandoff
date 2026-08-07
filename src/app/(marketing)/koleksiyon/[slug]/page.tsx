import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import CategoryHero from "@/components/layout/CategoryHero";
import CategoryCircles from "@/components/layout/CategoryCircles";
import ProductListingSection from "@/components/product/ProductListingSection";
import MaterialQualitySection from "@/components/layout/MaterialQualitySection";
import CategoryChips from "@/components/home/CategoryChips";
import TrustMarquee from "@/components/layout/TrustMarquee";
import { getCategories, quickFilterChips } from "@/lib/data/homepage-mock";
import { getAllProducts, getDiscountedProducts, type ProductDetail } from "@/lib/data/products";
import { absoluteUrl } from "@/lib/seo";

// Anasayfa ("Öne Çıkan Modeller" -> Yeni Tarz, "Kaçırılmayacak Fırsatlar") ve footer
// ("Yeni Gelenler") vitrinlerindeki "Tümünü Gör" linklerinin gittiği koleksiyonlar.
// Kategori/oda gibi ayrı bir DB taksonomisi değiller, bu yüzden burada sabit tanımlı.
const COLLECTIONS: Record<
  string,
  { title: string; description: string; emptyMessage: string; getProducts: () => Promise<ProductDetail[]> }
> = {
  "yeni-tarz": {
    title: "Yeni Tarz",
    description: "Özcan Mobilya'nın yeni tarz koleksiyonu — modern çizgiler, size özel ölçü ve renk seçenekleri.",
    emptyMessage: "Yeni tarz ürünler yakında burada olacak.",
    getProducts: async () => [...(await getAllProducts())].reverse(),
  },
  "yeni-gelenler": {
    title: "Yeni Gelenler",
    description: "Özcan Mobilya kataloğuna en son eklenen modeller — gardırop, TV ünitesi, dresuar ve daha fazlası.",
    emptyMessage: "Yeni gelen ürünler yakında burada olacak.",
    getProducts: async () => [...(await getAllProducts())].reverse(),
  },
  firsatlar: {
    title: "Kaçırılmayacak Fırsatlar",
    description: "Özcan Mobilya'da indirimdeki ürünler — sınırlı süreli fırsat fiyatlarıyla.",
    emptyMessage: "Şu an indirimde ürün yok, yakında yeni fırsatlar burada olacak.",
    getProducts: getDiscountedProducts,
  },
};

export async function generateStaticParams() {
  return Object.keys(COLLECTIONS).map((slug) => ({ slug }));
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}): Promise<Metadata> {
  const { slug } = await params;
  const collection = COLLECTIONS[slug];

  if (!collection) {
    return { title: "Koleksiyon Bulunamadı | Özcan Mobilya" };
  }

  const title = `${collection.title} | Özcan Mobilya`;
  const url = absoluteUrl(`/koleksiyon/${slug}`);

  return {
    title,
    description: collection.description,
    alternates: { canonical: url },
    openGraph: { title, description: collection.description, url, siteName: "Özcan Mobilya" },
  };
}

export default async function KoleksiyonDetailPage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const collection = COLLECTIONS[slug];
  if (!collection) {
    notFound();
  }

  const [categories, products] = await Promise.all([getCategories(), collection.getProducts()]);

  return (
    <>
      <div className="mx-auto max-w-7xl px-4 pt-6 sm:px-6 lg:px-8">
        <nav className="mb-6 flex items-center gap-2 font-body text-xs text-secondary-light">
          <Link href="/" className="font-medium text-secondary hover:text-primary">
            Ana sayfa
          </Link>
          <span>|</span>
          <Link href="/koleksiyon" className="hover:text-primary">
            Koleksiyon
          </Link>
          <span>|</span>
          <span className="text-secondary-light">{collection.title}</span>
        </nav>

        <CategoryHero title={collection.title} imageUrl="/media/y5_pro_1769512354644.jpg" />
      </div>

      <div className="mt-10">
        <CategoryCircles items={categories} basePath="/kategori" size="sm" />
      </div>

      <div className="mx-auto max-w-7xl px-4 py-10 sm:px-6 lg:px-8">
        <ProductListingSection products={products} emptyMessage={collection.emptyMessage} />
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
