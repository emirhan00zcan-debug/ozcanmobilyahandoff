import Link from "next/link";
import { notFound } from "next/navigation";
import { prisma } from "@/lib/prisma";
import { requireAdmin } from "@/lib/auth";
import { ORDER_STATUS_LABELS, PAYMENT_STATUS_LABELS, PAYMENT_METHOD_LABELS } from "@/lib/order-labels";
import {
  updateOrderStatusAction,
  updateOrderPaymentStatusAction,
  updateOrderTrackingAction,
} from "@/lib/actions/admin-order-actions";
import type { OrderStatus, PaymentStatus } from "@prisma/client";

function formatPrice(value: number) {
  return new Intl.NumberFormat("tr-TR", { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(value) + " TL";
}

function formatDate(date: Date) {
  return new Intl.DateTimeFormat("tr-TR", { dateStyle: "medium", timeStyle: "short" }).format(date);
}

export default async function AdminOrderDetailPage({ params }: { params: Promise<{ id: string }> }) {
  await requireAdmin();
  const { id } = await params;

  const order = await prisma.order.findUnique({
    where: { id },
    include: {
      user: true,
      address: true,
      coupon: true,
      items: true,
    },
  });
  if (!order) notFound();

  return (
    <div className="max-w-4xl">
      <Link href="/admin/siparisler" className="font-body text-xs text-secondary-light hover:text-primary">
        ← Siparişlere Dön
      </Link>
      <div className="mt-2 flex flex-wrap items-center justify-between gap-3">
        <h1 className="font-display text-2xl font-bold text-secondary">{order.orderNumber}</h1>
        <span className="font-body text-xs text-secondary-light">{formatDate(order.createdAt)}</span>
      </div>

      <div className="mt-6 grid grid-cols-1 gap-6 lg:grid-cols-3">
        <div className="space-y-6 lg:col-span-2">
          <section className="rounded-2xl border border-secondary/10 bg-white p-5">
            <h2 className="font-display text-base font-semibold text-secondary">Ürünler</h2>
            <ul className="mt-3 divide-y divide-secondary/5 font-body">
              {order.items.map((item) => (
                <li key={item.id} className="flex items-center justify-between gap-4 py-3 text-sm">
                  <div>
                    <p className="font-medium text-secondary">{item.productNameSnapshot}</p>
                    {item.variationSnapshot && (
                      <p className="text-xs text-secondary-light">{item.variationSnapshot}</p>
                    )}
                    <p className="text-xs text-secondary-light">
                      {item.quantity} adet × {formatPrice(Number(item.unitPrice))}
                    </p>
                    {item.installationRequested && (
                      <p className="text-xs text-secondary-light">
                        Kurulum/Montaj: {formatPrice(Number(item.installationPrice))}
                      </p>
                    )}
                  </div>
                  <p className="shrink-0 font-medium text-secondary">
                    {formatPrice(Number(item.unitPrice) * item.quantity)}
                  </p>
                </li>
              ))}
            </ul>
            <div className="mt-4 space-y-1.5 border-t border-secondary/10 pt-4 font-body text-sm">
              <div className="flex justify-between">
                <span className="text-secondary-light">Ara Toplam</span>
                <span className="text-secondary">{formatPrice(Number(order.subtotal))}</span>
              </div>
              {Number(order.discountAmount) > 0 && (
                <div className="flex justify-between text-primary">
                  <span>İndirim {order.coupon ? `(${order.coupon.code})` : ""}</span>
                  <span>-{formatPrice(Number(order.discountAmount))}</span>
                </div>
              )}
              <div className="flex justify-between">
                <span className="text-secondary-light">Kargo</span>
                <span className="text-secondary">{formatPrice(Number(order.shippingCost))}</span>
              </div>
              {Number(order.installationTotal) > 0 && (
                <div className="flex justify-between">
                  <span className="text-secondary-light">Kurulum/Montaj</span>
                  <span className="text-secondary">{formatPrice(Number(order.installationTotal))}</span>
                </div>
              )}
              <div className="flex justify-between pt-1 font-semibold text-secondary">
                <span>Toplam</span>
                <span>{formatPrice(Number(order.totalAmount))}</span>
              </div>
            </div>
          </section>

          <section className="rounded-2xl border border-secondary/10 bg-white p-5">
            <h2 className="font-display text-base font-semibold text-secondary">Teslimat Adresi</h2>
            <p className="mt-2 font-body text-sm text-secondary">
              {order.address.fullName} · {order.address.phone}
            </p>
            <p className="font-body text-sm text-secondary-light">
              {order.address.addressLine}, {order.address.district}/{order.address.city}{" "}
              {order.address.postalCode ?? ""}
            </p>
            {order.note && (
              <p className="mt-3 rounded-lg bg-secondary/[0.04] p-3 font-body text-sm text-secondary-light">
                <span className="font-medium text-secondary">Sipariş Notu: </span>
                {order.note}
              </p>
            )}
          </section>
        </div>

        <div className="space-y-6">
          <section className="rounded-2xl border border-secondary/10 bg-white p-5">
            <h2 className="font-display text-base font-semibold text-secondary">Müşteri</h2>
            <p className="mt-2 font-body text-sm text-secondary">
              {order.user?.name ?? order.address.fullName}
              {!order.user && (
                <span className="ml-1.5 rounded-full bg-secondary/[0.06] px-2 py-0.5 text-[10px] font-medium text-secondary-light">
                  Hesapsız (Misafir)
                </span>
              )}
            </p>
            <p className="font-body text-sm text-secondary-light">{order.user?.email ?? order.guestEmail}</p>
            {order.user?.phone && <p className="font-body text-sm text-secondary-light">{order.user.phone}</p>}
          </section>

          <section className="rounded-2xl border border-secondary/10 bg-white p-5">
            <h2 className="font-display text-base font-semibold text-secondary">Sipariş Durumu</h2>
            <form action={updateOrderStatusAction} className="mt-3 flex gap-2">
              <input type="hidden" name="orderId" value={order.id} />
              <select
                name="status"
                defaultValue={order.status}
                className="w-full rounded-lg border border-secondary/15 px-3 py-2 font-body text-sm text-secondary focus:border-primary focus:outline-none"
              >
                {(Object.entries(ORDER_STATUS_LABELS) as [OrderStatus, string][]).map(([key, label]) => (
                  <option key={key} value={key}>
                    {label}
                  </option>
                ))}
              </select>
              <button
                type="submit"
                className="shrink-0 rounded-lg bg-secondary px-4 py-2 font-body text-xs font-semibold text-white transition-colors hover:bg-primary"
              >
                Kaydet
              </button>
            </form>
          </section>

          <section className="rounded-2xl border border-secondary/10 bg-white p-5">
            <h2 className="font-display text-base font-semibold text-secondary">Ödeme Durumu</h2>
            <p className="mt-1 font-body text-xs text-secondary-light">
              Ödeme Yöntemi: <span className="font-medium text-secondary">{PAYMENT_METHOD_LABELS[order.paymentMethod]}</span>
            </p>
            <form action={updateOrderPaymentStatusAction} className="mt-3 flex gap-2">
              <input type="hidden" name="orderId" value={order.id} />
              <select
                name="paymentStatus"
                defaultValue={order.paymentStatus}
                className="w-full rounded-lg border border-secondary/15 px-3 py-2 font-body text-sm text-secondary focus:border-primary focus:outline-none"
              >
                {(Object.entries(PAYMENT_STATUS_LABELS) as [PaymentStatus, string][]).map(([key, label]) => (
                  <option key={key} value={key}>
                    {label}
                  </option>
                ))}
              </select>
              <button
                type="submit"
                className="shrink-0 rounded-lg bg-secondary px-4 py-2 font-body text-xs font-semibold text-white transition-colors hover:bg-primary"
              >
                Kaydet
              </button>
            </form>
          </section>

          <section className="rounded-2xl border border-secondary/10 bg-white p-5">
            <h2 className="font-display text-base font-semibold text-secondary">Kargo Takip No</h2>
            <form action={updateOrderTrackingAction} className="mt-3 flex gap-2">
              <input type="hidden" name="orderId" value={order.id} />
              <input
                type="text"
                name="trackingNumber"
                defaultValue={order.trackingNumber ?? ""}
                placeholder="Takip numarası"
                className="w-full rounded-lg border border-secondary/15 px-3 py-2 font-body text-sm text-secondary focus:border-primary focus:outline-none"
              />
              <button
                type="submit"
                className="shrink-0 rounded-lg bg-secondary px-4 py-2 font-body text-xs font-semibold text-white transition-colors hover:bg-primary"
              >
                Kaydet
              </button>
            </form>
          </section>
        </div>
      </div>
    </div>
  );
}
