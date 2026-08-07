import Link from "next/link";
import CategoryHero from "@/components/layout/CategoryHero";
import CategoryCircles from "@/components/layout/CategoryCircles";
import ProductListingSection from "@/components/product/ProductListingSection";
import MaterialQualitySection from "@/components/layout/MaterialQualitySection";
import CategoryChips from "@/components/home/CategoryChips";
import TrustMarquee from "@/components/layout/TrustMarquee";
import { getCategories, quickFilterChips } from "@/lib/data/homepage-mock";
import { getDiscountedProducts } from "@/lib/data/products";

export const metadata = { title: "İndirimdekiler | Özcan Mobilya" };

export default async function IndirimlerPage() {
  const [categories, products] = await Promise.all([getCategories(), getDiscountedProducts()]);

  return (
    <>
      <div className="mx-auto max-w-7xl px-4 pt-6 sm:px-6 lg:px-8">
        <nav className="mb-6 flex items-center gap-2 font-body text-xs text-secondary-light">
          <Link href="/" className="font-medium text-secondary hover:text-primary">
            Ana sayfa
          </Link>
          <span>|</span>
          <span className="text-secondary-light">İndirimdekiler</span>
        </nav>

        <CategoryHero title="İndirimdekiler" imageUrl="/media/y5_pro_1769512354644.jpg" />
      </div>

      <div className="mt-10">
        <CategoryCircles items={categories} basePath="/kategori" size="sm" />
      </div>

      <div className="mx-auto max-w-7xl px-4 py-10 sm:px-6 lg:px-8">
        <ProductListingSection
          products={products}
          emptyMessage="Şu an indirimde ürün yok, yakında yeni fırsatlar burada olacak."
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
