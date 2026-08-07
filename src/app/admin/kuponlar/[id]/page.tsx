import Link from "next/link";
import { notFound } from "next/navigation";
import { prisma } from "@/lib/prisma";
import { requireAdmin } from "@/lib/auth";
import CouponForm from "@/components/admin/CouponForm";

// datetime-local input'un beklediği "YYYY-MM-DDTHH:mm" biçimi — yerel saat bileşenleriyle
// (UTC'ye çevirmeden), çünkü tarayıcı da bu değeri yerel saat olarak yorumluyor.
function toDateTimeLocal(date: Date): string {
  const pad = (n: number) => String(n).padStart(2, "0");
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(date.getMinutes())}`;
}

export default async function EditCouponPage({ params }: { params: Promise<{ id: string }> }) {
  await requireAdmin();
  const { id } = await params;

  const [coupon, categories] = await Promise.all([
    prisma.coupon.findUnique({ where: { id } }),
    prisma.category.findMany({ orderBy: { name: "asc" } }),
  ]);
  if (!coupon) notFound();

  return (
    <div>
      <Link href="/admin/kuponlar" className="font-body text-xs text-secondary-light hover:text-primary">
        ← Kuponlara Dön
      </Link>
      <h1 className="mt-2 font-display text-2xl font-bold text-secondary">{coupon.code}</h1>
      <CouponForm
        mode="edit"
        categories={categories}
        coupon={{
          id: coupon.id,
          code: coupon.code,
          discountType: coupon.discountType,
          discountValue: Number(coupon.discountValue),
          description: coupon.description ?? "",
          minOrderAmount: coupon.minOrderAmount ? Number(coupon.minOrderAmount) : null,
          maxDiscountAmount: coupon.maxDiscountAmount ? Number(coupon.maxDiscountAmount) : null,
          categoryId: coupon.categoryId ?? "",
          startsAt: toDateTimeLocal(coupon.startsAt),
          endsAt: toDateTimeLocal(coupon.endsAt),
          usageLimit: coupon.usageLimit,
          isActive: coupon.isActive,
        }}
      />
    </div>
  );
}
