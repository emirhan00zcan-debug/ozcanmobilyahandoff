import Link from "next/link";
import { notFound } from "next/navigation";
import { prisma } from "@/lib/prisma";
import { requireUser } from "@/lib/auth";
import { ORDER_STATUS_LABELS, PAYMENT_STATUS_LABELS } from "@/lib/order-labels";
import OrderItemReview from "@/components/account/OrderItemReview";

export const metadata = { title: "Sipariş Detayı | Özcan Mobilya" };

function formatPrice(value: number) {
  return new Intl.NumberFormat("tr-TR", { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(value) + " TL";
}

function formatDate(date: Date) {
  return new Intl.DateTimeFormat("tr-TR", { dateStyle: "long", timeStyle: "short" }).format(date);
}

export default async function OrderDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const session = await requireUser("/hesabim");
  const { id } = await params;

  // userId eşleşmesi sahiplik kontrolü — başka bir müşterinin siparişi bu URL üzerinden görülemez.
  const order = await prisma.order.findFirst({
    where: { id, userId: session.user.id },
    include: { items: true, address: true, coupon: true },
  });
  if (!order) notFound();

  // Bu siparişteki ürünlerden hangilerini kullanıcı zaten değerlendirmiş — teslim edilmiş
  // siparişlerde her satırın altında "Ürünü Değerlendir" formu/mevcut yorumu gösterebilmek için.
  const productIds = [...new Set(order.items.map((item) => item.productId))];
  const existingReviews = productIds.length
    ? await prisma.review.findMany({
        where: { userId: session.user.id, productId: { in: productIds } },
      })
    : [];
  const reviewByProductId = new Map(existingReviews.map((r) => [r.productId, r]));

  return (
    <div className="mx-auto max-w-3xl px-4 py-10 sm:px-6 lg:px-8">
      <Link href="/hesabim" className="font-body text-xs text-secondary-light hover:text-primary">
        ← Hesabıma Dön
      </Link>

      <div className="mt-4 flex flex-wrap items-center justify-between gap-3">
        <h1 className="font-display text-2xl font-bold text-secondary">{order.orderNumber}</h1>
        <span className="rounded-full bg-primary/10 px-3 py-1 font-body text-xs font-medium text-primary">
          {ORDER_STATUS_LABELS[order.status]}
        </span>
      </div>
      <p className="mt-1 font-body text-xs text-secondary-light">{formatDate(order.createdAt)}</p>

      <div className="mt-6 rounded-2xl border border-secondary/10 bg-white p-6">
        <h2 className="font-display text-sm font-semibold uppercase tracking-wide text-secondary-light">
          Ürünler
        </h2>
        <ul className="mt-3 divide-y divide-secondary/10">
          {order.items.map((item) => {
            const existing = reviewByProductId.get(item.productId);
            return (
              <li key={item.id} className="py-3">
                <div className="flex items-center justify-between gap-4">
                  <div>
                    <p className="font-body text-sm font-medium text-secondary">{item.productNameSnapshot}</p>
                    {item.variationSnapshot && (
                      <p className="font-body text-xs text-secondary-light">{item.variationSnapshot}</p>
                    )}
                    <p className="font-body text-xs text-secondary-light">
                      {item.quantity} adet × {formatPrice(Number(item.unitPrice))}
                    </p>
                  </div>
                  <p className="shrink-0 font-body text-sm font-semibold text-secondary">
                    {formatPrice(Number(item.unitPrice) * item.quantity)}
                  </p>
                </div>
                <OrderItemReview
                  productId={item.productId}
                  canReview={order.status === "DELIVERED"}
                  existingReview={existing ? { rating: existing.rating, comment: existing.comment } : null}
                />
              </li>
            );
          })}
        </ul>

        <div className="mt-4 space-y-1.5 border-t border-secondary/10 pt-4 font-body text-sm">
          <div className="flex justify-between">
            <span className="text-secondary-light">Ara Toplam</span>
            <span className="text-secondary">{formatPrice(Number(order.subtotal))}</span>
          </div>
          {Number(order.discountAmount) > 0 && (
            <div className="flex justify-between text-primary">
              <span>İndirim{order.coupon ? ` (${order.coupon.code})` : ""}</span>
              <span>-{formatPrice(Number(order.discountAmount))}</span>
            </div>
          )}
          {Number(order.shippingCost) > 0 && (
            <div className="flex justify-between">
              <span className="text-secondary-light">Kargo</span>
              <span className="text-secondary">{formatPrice(Number(order.shippingCost))}</span>
            </div>
          )}
          <div className="flex justify-between border-t border-secondary/10 pt-1.5 font-semibold">
            <span className="text-secondary">Toplam</span>
            <span className="text-secondary">{formatPrice(Number(order.totalAmount))}</span>
          </div>
        </div>
      </div>

      <div className="mt-6 grid grid-cols-1 gap-6 sm:grid-cols-2">
        <div className="rounded-2xl border border-secondary/10 bg-white p-6">
          <h2 className="font-display text-sm font-semibold uppercase tracking-wide text-secondary-light">
            Teslimat Adresi
          </h2>
          <p className="mt-3 font-body text-sm text-secondary">{order.address.fullName}</p>
          <p className="font-body text-sm text-secondary-light">{order.address.phone}</p>
          <p className="mt-1 font-body text-sm text-secondary-light">
            {order.address.addressLine}, {order.address.district}/{order.address.city}
            {order.address.postalCode ? ` (${order.address.postalCode})` : ""}
          </p>
        </div>

        <div className="rounded-2xl border border-secondary/10 bg-white p-6">
          <h2 className="font-display text-sm font-semibold uppercase tracking-wide text-secondary-light">
            Sipariş Bilgileri
          </h2>
          <dl className="mt-3 space-y-2 font-body text-sm">
            <div className="flex justify-between">
              <dt className="text-secondary-light">Ödeme Durumu</dt>
              <dd className="text-secondary">{PAYMENT_STATUS_LABELS[order.paymentStatus]}</dd>
            </div>
            {order.trackingNumber && (
              <div className="flex justify-between">
                <dt className="text-secondary-light">Kargo Takip No</dt>
                <dd className="text-secondary">{order.trackingNumber}</dd>
              </div>
            )}
            {order.note && (
              <div>
                <dt className="text-secondary-light">Sipariş Notu</dt>
                <dd className="mt-1 text-secondary">{order.note}</dd>
              </div>
            )}
          </dl>
        </div>
      </div>
    </div>
  );
}
