import type { Metadata } from "next";
import { notFound } from "next/navigation";
import ProductDetailClient from "@/components/product/ProductDetailClient";
import ProductReviews from "@/components/product/ProductReviews";
import ProductBrandTabs from "@/components/product/ProductBrandTabs";
import { getAllProductSlugs, getProductBySlug } from "@/lib/data/products";
import { absoluteUrl, truncateForMeta } from "@/lib/seo";

export async function generateStaticParams() {
  const slugs = await getAllProductSlugs();
  return slugs.map((slug) => ({ slug }));
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}): Promise<Metadata> {
  const { slug } = await params;
  const product = await getProductBySlug(slug);

  if (!product) {
    return { title: "Ürün Bulunamadı | Özcan Mobilya" };
  }

  const title = `${product.name} | Özcan Mobilya`;
  const description = truncateForMeta(product.description);
  const url = absoluteUrl(`/urun/${product.slug}`);
  const image = product.images[0];

  return {
    title,
    description,
    alternates: { canonical: url },
    openGraph: {
      title,
      description,
      url,
      siteName: "Özcan Mobilya",
      images: image ? [{ url: image }] : undefined,
    },
  };
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

  const productJsonLd = {
    "@context": "https://schema.org",
    "@type": "Product",
    name: product.name,
    description: product.description,
    image: product.images.map((img) => absoluteUrl(img)),
    sku: product.slug,
    brand: { "@type": "Brand", name: product.vendor },
    offers: {
      "@type": "Offer",
      url: absoluteUrl(`/urun/${product.slug}`),
      priceCurrency: "TRY",
      price: product.basePrice.toFixed(2),
      availability: product.inStock ? "https://schema.org/InStock" : "https://schema.org/OutOfStock",
    },
  };

  return (
    <>
      <script
        type="application/ld+json"
        // </script> içeren bir açıklama HTML'i erken kapatamasın diye JSON çıktısında "<" kaçırılıyor.
        dangerouslySetInnerHTML={{ __html: JSON.stringify(productJsonLd).replace(/</g, "\\u003c") }}
      />
      <ProductDetailClient product={product} />
      <ProductReviews productSlug={product.slug} />
      <ProductBrandTabs />
    </>
  );
}
