import Link from "next/link";
import { prisma } from "@/lib/prisma";
import { requireAdmin } from "@/lib/auth";
import { ORDER_STATUS_LABELS } from "@/lib/order-labels";
import type { OrderStatus } from "@prisma/client";

function formatPrice(value: number) {
  return new Intl.NumberFormat("tr-TR", { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(value) + " TL";
}

function formatDate(date: Date) {
  return new Intl.DateTimeFormat("tr-TR", { dateStyle: "medium", timeStyle: "short" }).format(date);
}

export default async function AdminOrdersPage({
  searchParams,
}: {
  searchParams: Promise<{ status?: string }>;
}) {
  await requireAdmin();
  const { status } = await searchParams;
  const activeStatus = status && status in ORDER_STATUS_LABELS ? (status as OrderStatus) : undefined;

  const orders = await prisma.order.findMany({
    where: activeStatus ? { status: activeStatus } : undefined,
    include: { user: true, items: true },
    orderBy: { createdAt: "desc" },
  });

  return (
    <div>
      <h1 className="font-display text-2xl font-bold text-secondary">Siparişler</h1>

      <div className="mt-5 flex flex-wrap gap-2">
        <Link
          href="/admin/siparisler"
          className={[
            "rounded-full px-4 py-1.5 font-body text-xs font-medium transition-colors",
            !activeStatus ? "bg-secondary text-white" : "bg-secondary/[0.06] text-secondary hover:bg-secondary/10",
          ].join(" ")}
        >
          Tümü
        </Link>
        {(Object.entries(ORDER_STATUS_LABELS) as [OrderStatus, string][]).map(([key, label]) => (
          <Link
            key={key}
            href={`/admin/siparisler?status=${key}`}
            className={[
              "rounded-full px-4 py-1.5 font-body text-xs font-medium transition-colors",
              activeStatus === key ? "bg-secondary text-white" : "bg-secondary/[0.06] text-secondary hover:bg-secondary/10",
            ].join(" ")}
          >
            {label}
          </Link>
        ))}
      </div>

      <div className="mt-6 overflow-x-auto rounded-2xl border border-secondary/10 bg-white">
        <table className="w-full min-w-[720px] font-body text-sm">
          <thead>
            <tr className="border-b border-secondary/10 text-left text-xs font-medium uppercase tracking-wide text-secondary-light">
              <th className="px-5 py-3">Sipariş No</th>
              <th className="px-5 py-3">Müşteri</th>
              <th className="px-5 py-3">Tarih</th>
              <th className="px-5 py-3">Ürün</th>
              <th className="px-5 py-3">Tutar</th>
              <th className="px-5 py-3">Durum</th>
              <th className="px-5 py-3" />
            </tr>
          </thead>
          <tbody>
            {orders.map((order) => (
              <tr key={order.id} className="border-b border-secondary/5 last:border-0 hover:bg-secondary/[0.02]">
                <td className="px-5 py-4 font-semibold text-secondary">{order.orderNumber}</td>
                <td className="px-5 py-4">
                  <p className="text-secondary">
                    {order.user?.name ?? "Misafir"}
                    {!order.user && (
                      <span className="ml-1.5 rounded-full bg-secondary/[0.06] px-2 py-0.5 text-[10px] font-medium text-secondary-light">
                        Hesapsız
                      </span>
                    )}
                  </p>
                  <p className="text-xs text-secondary-light">{order.user?.email ?? order.guestEmail}</p>
                </td>
                <td className="px-5 py-4 text-secondary-light">{formatDate(order.createdAt)}</td>
                <td className="px-5 py-4 text-secondary-light">{order.items.length} ürün</td>
                <td className="px-5 py-4 font-medium text-secondary">{formatPrice(Number(order.totalAmount))}</td>
                <td className="px-5 py-4">
                  <span className="rounded-full bg-primary/10 px-3 py-1 text-xs font-medium text-primary">
                    {ORDER_STATUS_LABELS[order.status]}
                  </span>
                </td>
                <td className="px-5 py-4 text-right">
                  <Link href={`/admin/siparisler/${order.id}`} className="font-medium text-primary hover:underline">
                    Detay
                  </Link>
                </td>
              </tr>
            ))}
            {orders.length === 0 && (
              <tr>
                <td colSpan={7} className="px-5 py-10 text-center text-secondary-light">
                  Bu filtreyle eşleşen sipariş yok.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
