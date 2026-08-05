import Link from "next/link";
import CategoryGrid from "@/components/layout/CategoryGrid";
import { getCategories } from "@/lib/data/homepage-mock";

export const metadata = { title: "Kategoriler | Özcan Mobilya" };

export default async function KategorilerPage() {
  const categories = await getCategories();

  return (
    <div className="mx-auto max-w-7xl px-4 py-10 sm:px-6 lg:px-8">
      <nav className="mb-6 flex items-center gap-2 font-body text-xs text-secondary-light">
        <Link href="/" className="font-medium text-secondary hover:text-primary">
          Ana sayfa
        </Link>
        <span>|</span>
        <span className="text-secondary-light">Kategoriler</span>
      </nav>

      <h1 className="mb-10 font-display text-3xl font-semibold text-secondary">Kategoriler</h1>

      <CategoryGrid items={categories} basePath="/kategori" />
    </div>
  );
}
