import Link from "next/link";
import { prisma } from "@/lib/prisma";
import { requireAdmin } from "@/lib/auth";
import CouponForm from "@/components/admin/CouponForm";

export default async function NewCouponPage() {
  await requireAdmin();

  const categories = await prisma.category.findMany({ orderBy: { name: "asc" } });

  return (
    <div>
      <Link href="/admin/kuponlar" className="font-body text-xs text-secondary-light hover:text-primary">
        ← Kuponlara Dön
      </Link>
      <h1 className="mt-2 font-display text-2xl font-bold text-secondary">Yeni Kupon</h1>
      <CouponForm mode="create" categories={categories} />
    </div>
  );
}
