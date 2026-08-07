import Link from "next/link";
import { prisma } from "@/lib/prisma";
import { requireAdmin } from "@/lib/auth";
import ProductForm from "@/components/admin/ProductForm";

export default async function NewProductPage() {
  await requireAdmin();

  const [categories, rooms] = await Promise.all([
    prisma.category.findMany({ orderBy: { name: "asc" } }),
    prisma.room.findMany({ orderBy: { order: "asc" } }),
  ]);

  return (
    <div>
      <Link href="/admin/urunler" className="font-body text-xs text-secondary-light hover:text-primary">
        ← Ürünlere Dön
      </Link>
      <h1 className="mt-2 font-display text-2xl font-bold text-secondary">Yeni Ürün</h1>
      <ProductForm mode="create" categories={categories} rooms={rooms} />
    </div>
  );
}
