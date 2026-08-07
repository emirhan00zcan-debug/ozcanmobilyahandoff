import Link from "next/link";
import { notFound } from "next/navigation";
import { prisma } from "@/lib/prisma";
import { requireAdmin } from "@/lib/auth";
import ProductForm from "@/components/admin/ProductForm";

export default async function EditProductPage({ params }: { params: Promise<{ id: string }> }) {
  await requireAdmin();
  const { id } = await params;

  const [product, categories, rooms] = await Promise.all([
    prisma.product.findUnique({
      where: { id },
      include: { images: { orderBy: { order: "asc" } } },
    }),
    prisma.category.findMany({ orderBy: { name: "asc" } }),
    prisma.room.findMany({ orderBy: { order: "asc" } }),
  ]);
  if (!product) notFound();

  return (
    <div>
      <Link href="/admin/urunler" className="font-body text-xs text-secondary-light hover:text-primary">
        ← Ürünlere Dön
      </Link>
      <h1 className="mt-2 font-display text-2xl font-bold text-secondary">{product.name}</h1>
      <p className="font-body text-xs text-secondary-light">/urun/{product.slug}</p>
      <ProductForm
        mode="edit"
        categories={categories}
        rooms={rooms}
        product={{
          id: product.id,
          name: product.name,
          slug: product.slug,
          shortDescription: product.shortDescription ?? "",
          description: product.description,
          basePrice: Number(product.basePrice),
          compareAtPrice: product.compareAtPrice ? Number(product.compareAtPrice) : null,
          stock: product.stock,
          categoryId: product.categoryId,
          roomId: product.roomId ?? "",
          isActive: product.isActive,
          isFeatured: product.isFeatured,
          installationAvailable: product.installationAvailable,
          installationPrice: product.installationPrice ? Number(product.installationPrice) : null,
          images: product.images.map((image) => image.url),
        }}
      />
    </div>
  );
}
