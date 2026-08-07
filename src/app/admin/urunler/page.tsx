import Link from "next/link";
import Image from "next/image";
import { prisma } from "@/lib/prisma";
import { requireAdmin } from "@/lib/auth";

function formatPrice(value: number) {
  return new Intl.NumberFormat("tr-TR", { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(value) + " TL";
}

export default async function AdminProductsPage() {
  await requireAdmin();

  const products = await prisma.product.findMany({
    include: { category: true, images: { orderBy: { order: "asc" }, take: 1 } },
    orderBy: { createdAt: "desc" },
  });

  return (
    <div>
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="font-display text-2xl font-bold text-secondary">Ürünler</h1>
        <Link
          href="/admin/urunler/yeni"
          className="rounded-full bg-secondary px-6 py-2.5 font-body text-sm font-semibold text-white transition-colors hover:bg-primary"
        >
          + Yeni Ürün
        </Link>
      </div>

      <div className="mt-6 overflow-x-auto rounded-2xl border border-secondary/10 bg-white">
        <table className="w-full min-w-[720px] font-body text-sm">
          <thead>
            <tr className="border-b border-secondary/10 text-left text-xs font-medium uppercase tracking-wide text-secondary-light">
              <th className="px-5 py-3">Ürün</th>
              <th className="px-5 py-3">Kategori</th>
              <th className="px-5 py-3">Fiyat</th>
              <th className="px-5 py-3">Stok</th>
              <th className="px-5 py-3">Durum</th>
              <th className="px-5 py-3" />
            </tr>
          </thead>
          <tbody>
            {products.map((product) => (
              <tr key={product.id} className="border-b border-secondary/5 last:border-0 hover:bg-secondary/[0.02]">
                <td className="px-5 py-4">
                  <div className="flex items-center gap-3">
                    <span className="h-10 w-10 shrink-0 overflow-hidden rounded-lg bg-secondary/[0.04]">
                      {product.images[0] ? (
                        <Image
                          src={product.images[0].url}
                          alt=""
                          width={40}
                          height={40}
                          className="h-full w-full object-cover"
                        />
                      ) : null}
                    </span>
                    <span className="font-medium text-secondary">{product.name}</span>
                  </div>
                </td>
                <td className="px-5 py-4 text-secondary-light">{product.category.name}</td>
                <td className="px-5 py-4">
                  <span className="font-medium text-secondary">{formatPrice(Number(product.basePrice))}</span>
                  {product.compareAtPrice && (
                    <span className="ml-2 text-xs text-secondary-light line-through">
                      {formatPrice(Number(product.compareAtPrice))}
                    </span>
                  )}
                </td>
                <td className="px-5 py-4">
                  <span className={product.stock > 0 ? "text-secondary" : "font-medium text-red-600"}>
                    {product.stock > 0 ? product.stock : "Tükendi"}
                  </span>
                </td>
                <td className="px-5 py-4">
                  <span
                    className={[
                      "rounded-full px-3 py-1 text-xs font-medium",
                      product.isActive ? "bg-primary/10 text-primary" : "bg-secondary/10 text-secondary-light",
                    ].join(" ")}
                  >
                    {product.isActive ? "Yayında" : "Pasif"}
                  </span>
                </td>
                <td className="px-5 py-4 text-right">
                  <Link href={`/admin/urunler/${product.id}`} className="font-medium text-primary hover:underline">
                    Düzenle
                  </Link>
                </td>
              </tr>
            ))}
            {products.length === 0 && (
              <tr>
                <td colSpan={6} className="px-5 py-10 text-center text-secondary-light">
                  Henüz ürün eklenmemiş.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
