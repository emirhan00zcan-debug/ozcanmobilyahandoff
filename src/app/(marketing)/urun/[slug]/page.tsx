import { notFound } from "next/navigation";
import ProductDetailClient from "@/components/product/ProductDetailClient";
import ProductReviews from "@/components/product/ProductReviews";
import ProductBrandTabs from "@/components/product/ProductBrandTabs";
import { getAllProductSlugs, getProductBySlug } from "@/lib/data/products";

export async function generateStaticParams() {
  const slugs = await getAllProductSlugs();
  return slugs.map((slug) => ({ slug }));
}

export default async function ProductPage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const product = await getProductBySlug(slug);

  if (!product) {
    notFound();
  }

  return (
    <>
      <ProductDetailClient product={product} />
      <ProductReviews />
      <ProductBrandTabs />
    </>
  );
}
