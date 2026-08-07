import Link from "next/link";
import { prisma } from "@/lib/prisma";
import { requireAdmin } from "@/lib/auth";
import { toggleCouponActiveAction } from "@/lib/actions/admin-coupon-actions";

function formatDate(date: Date) {
  return new Intl.DateTimeFormat("tr-TR", { dateStyle: "medium" }).format(date);
}

export default async function AdminCouponsPage() {
  await requireAdmin();

  const coupons = await prisma.coupon.findMany({
    include: { category: true },
    orderBy: { createdAt: "desc" },
  });

  return (
    <div>
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="font-display text-2xl font-bold text-secondary">Kuponlar</h1>
        <Link
          href="/admin/kuponlar/yeni"
          className="rounded-full bg-secondary px-6 py-2.5 font-body text-sm font-semibold text-white transition-colors hover:bg-primary"
        >
          + Yeni Kupon
        </Link>
      </div>

      <div className="mt-6 overflow-x-auto rounded-2xl border border-secondary/10 bg-white">
        <table className="w-full min-w-[720px] font-body text-sm">
          <thead>
            <tr className="border-b border-secondary/10 text-left text-xs font-medium uppercase tracking-wide text-secondary-light">
              <th className="px-5 py-3">Kod</th>
              <th className="px-5 py-3">İndirim</th>
              <th className="px-5 py-3">Kapsam</th>
              <th className="px-5 py-3">Geçerlilik</th>
              <th className="px-5 py-3">Kullanım</th>
              <th className="px-5 py-3">Durum</th>
              <th className="px-5 py-3" />
            </tr>
          </thead>
          <tbody>
            {coupons.map((coupon) => (
              <tr key={coupon.id} className="border-b border-secondary/5 last:border-0 hover:bg-secondary/[0.02]">
                <td className="px-5 py-4 font-semibold text-secondary">{coupon.code}</td>
                <td className="px-5 py-4 text-secondary-light">
                  {coupon.discountType === "PERCENTAGE"
                    ? `%${Number(coupon.discountValue)}`
                    : `${Number(coupon.discountValue).toLocaleString("tr-TR")} TL`}
                </td>
                <td className="px-5 py-4 text-secondary-light">{coupon.category?.name ?? "Tüm Site"}</td>
                <td className="px-5 py-4 text-secondary-light">
                  {formatDate(coupon.startsAt)} – {formatDate(coupon.endsAt)}
                </td>
                <td className="px-5 py-4 text-secondary-light">
                  {coupon.usedCount}
                  {coupon.usageLimit ? ` / ${coupon.usageLimit}` : ""}
                </td>
                <td className="px-5 py-4">
                  <form action={toggleCouponActiveAction}>
                    <input type="hidden" name="couponId" value={coupon.id} />
                    <input type="hidden" name="isActive" value={String(coupon.isActive)} />
                    <button
                      type="submit"
                      className={[
                        "rounded-full px-3 py-1 text-xs font-medium transition-colors",
                        coupon.isActive
                          ? "bg-primary/10 text-primary hover:bg-primary/20"
                          : "bg-secondary/10 text-secondary-light hover:bg-secondary/20",
                      ].join(" ")}
                    >
                      {coupon.isActive ? "Aktif" : "Pasif"}
                    </button>
                  </form>
                </td>
                <td className="px-5 py-4 text-right">
                  <Link href={`/admin/kuponlar/${coupon.id}`} className="font-medium text-primary hover:underline">
                    Düzenle
                  </Link>
                </td>
              </tr>
            ))}
            {coupons.length === 0 && (
              <tr>
                <td colSpan={7} className="px-5 py-10 text-center text-secondary-light">
                  Henüz kupon eklenmemiş.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
