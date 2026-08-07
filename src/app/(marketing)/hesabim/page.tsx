import Link from "next/link";
import type { Metadata } from "next";
import { FaBoxOpen } from "react-icons/fa";
import { prisma } from "@/lib/prisma";
import { requireUser, signOut } from "@/lib/auth";
import { ORDER_STATUS_LABELS } from "@/lib/order-labels";
import ProfileSection from "@/components/account/ProfileSection";
import AddressesSection from "@/components/account/AddressesSection";
import PaymentMethodsSection from "@/components/account/PaymentMethodsSection";

// Bu sayfa kullanıcıya özel, oturum gerektiren, herkese açık arama değeri olmayan bir
// panel — index'lenmesi hem gizlilik açısından yanlış hem de arama sonuçlarında değersiz
// "boş kabuk" sayfalar biriktirip sitenin SEO kalitesini düşürür. robots.ts'teki
// disallow'a ek olarak burada da açıkça noindex işaretleniyor (bkz. src/app/robots.ts).
export const metadata: Metadata = {
  title: "Hesabım | Özcan Mobilya",
  robots: { index: false, follow: false },
};

const NAV_LINKS = [
  { href: "#profil", label: "Profil Bilgilerim" },
  { href: "#adresler", label: "Adreslerim" },
  { href: "#odeme", label: "Ödeme Yöntemlerim" },
  { href: "#siparisler", label: "Siparişlerim" },
];

function formatPrice(value: number) {
  return new Intl.NumberFormat("tr-TR", { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(value) + " TL";
}

function formatDate(date: Date) {
  return new Intl.DateTimeFormat("tr-TR", { dateStyle: "medium", timeStyle: "short" }).format(date);
}

export default async function HesabimPage() {
  const session = await requireUser("/hesabim");
  const userId = session.user.id;

  const [user, addresses, paymentMethods, orders] = await Promise.all([
    prisma.user.findUniqueOrThrow({ where: { id: userId } }),
    prisma.address.findMany({ where: { userId }, orderBy: [{ isDefault: "desc" }, { createdAt: "desc" }] }),
    prisma.paymentMethod.findMany({ where: { userId }, orderBy: [{ isDefault: "desc" }, { createdAt: "desc" }] }),
    prisma.order.findMany({ where: { userId }, include: { items: true }, orderBy: { createdAt: "desc" } }),
  ]);

  // Bir siparişte kullanılmış adres FK kısıtlaması yüzünden silinemez (bkz. Order.addressId) —
  // bu adreslerde "Sil" butonu hiç gösterilmiyor.
  const usedAddressIds = new Set(orders.map((o) => o.addressId));

  const displayName = user.name?.trim() || "Özcan Mobilya Müşterisi";
  const avatarInitial = (user.name?.trim()?.[0] ?? user.email[0]).toUpperCase();
  const memberSinceYear = new Intl.DateTimeFormat("tr-TR", { year: "numeric" }).format(user.createdAt);

  async function handleSignOut() {
    "use server";
    await signOut({ redirectTo: "/" });
  }

  return (
    <div className="mx-auto max-w-6xl px-4 py-10 sm:px-6 lg:px-8">
      <nav className="mb-6 flex items-center gap-2 font-body text-xs text-secondary-light">
        <Link href="/" className="font-medium text-secondary hover:text-primary">
          Ana sayfa
        </Link>
        <span>|</span>
        <span className="text-secondary-light">Hesabım</span>
      </nav>

      {/* Karşılama şeridi: avatar + isim/e-posta + hızlı istatistikler */}
      <div className="mb-8 flex flex-wrap items-center gap-5 rounded-2xl border border-secondary/10 bg-secondary/[0.02] p-6">
        <div className="flex h-16 w-16 shrink-0 items-center justify-center rounded-full bg-primary font-display text-2xl font-bold text-white">
          {avatarInitial}
        </div>
        <div className="min-w-0 flex-1">
          <h1 className="truncate font-display text-2xl font-bold text-secondary sm:text-3xl">
            Merhaba, {displayName}
          </h1>
          <p className="mt-1 font-body text-sm text-secondary-light">{user.email}</p>
        </div>
        <div className="flex shrink-0 gap-3">
          <div className="rounded-xl border border-secondary/10 bg-white px-4 py-2.5 text-center">
            <p className="font-display text-lg font-bold text-secondary">{orders.length}</p>
            <p className="font-body text-[11px] text-secondary-light">Sipariş</p>
          </div>
          <div className="rounded-xl border border-secondary/10 bg-white px-4 py-2.5 text-center">
            <p className="font-display text-lg font-bold text-secondary">{memberSinceYear}</p>
            <p className="font-body text-[11px] text-secondary-light">Üyelik Yılı</p>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-[220px_1fr]">
        {/* Kenar çubuğu — bölümler arası çapa navigasyonu, sadece masaüstünde (mobilde
            sayfa zaten tek parça olarak aşağı kayıyor) */}
        <aside className="hidden lg:block">
          <nav className="sticky top-24 flex flex-col gap-1 rounded-2xl border border-secondary/10 bg-white p-3">
            {NAV_LINKS.map((link) => (
              <a
                key={link.href}
                href={link.href}
                className="rounded-lg px-4 py-2.5 font-body text-sm font-medium text-secondary transition-colors hover:bg-secondary/[0.05] hover:text-primary"
              >
                {link.label}
              </a>
            ))}
            <form action={handleSignOut} className="mt-2 border-t border-secondary/10 pt-2">
              <button
                type="submit"
                className="w-full rounded-lg px-4 py-2.5 text-left font-body text-sm font-medium text-secondary-light transition-colors hover:text-primary"
              >
                Çıkış Yap
              </button>
            </form>
          </nav>
        </aside>

        <div className="min-w-0 space-y-6">
          <div id="profil" className="scroll-mt-24">
            <ProfileSection name={user.name ?? ""} email={user.email} phone={user.phone ?? ""} />
          </div>

          <div id="adresler" className="scroll-mt-24">
            <AddressesSection
              addresses={addresses.map((a) => ({
                id: a.id,
                title: a.title,
                fullName: a.fullName,
                phone: a.phone,
                city: a.city,
                district: a.district,
                addressLine: a.addressLine,
                postalCode: a.postalCode,
                isDefault: a.isDefault,
                isUsedInOrder: usedAddressIds.has(a.id),
              }))}
            />
          </div>

          <div id="odeme" className="scroll-mt-24">
            <PaymentMethodsSection
              methods={paymentMethods.map((m) => ({
                id: m.id,
                type: m.type,
                label: m.label,
                isDefault: m.isDefault,
                cardLast4: m.cardLast4,
                cardBrand: m.cardBrand,
              }))}
            />
          </div>

          <div id="siparisler" className="scroll-mt-24 rounded-2xl border border-secondary/10 bg-white p-6">
            <h2 className="font-display text-lg font-semibold text-secondary">Siparişlerim</h2>

            {orders.length === 0 ? (
              <div className="mt-4 flex flex-col items-center gap-3 rounded-xl border border-dashed border-secondary/15 py-10 text-center">
                <span className="flex h-12 w-12 items-center justify-center rounded-full bg-secondary/[0.04] text-secondary-light">
                  <FaBoxOpen className="h-5 w-5" />
                </span>
                <p className="font-body text-sm text-secondary-light">
                  Henüz bir siparişiniz yok.{" "}
                  <Link href="/koleksiyon" className="font-medium text-primary underline underline-offset-4">
                    Alışverişe başlayın
                  </Link>
                  .
                </p>
              </div>
            ) : (
              <div className="mt-4 overflow-x-auto rounded-xl border border-secondary/10">
                <table className="w-full min-w-[600px] font-body text-sm">
                  <thead>
                    <tr className="border-b border-secondary/10 bg-secondary/[0.02] text-left text-xs font-medium uppercase tracking-wide text-secondary-light">
                      <th className="px-5 py-3">Sipariş No</th>
                      <th className="px-5 py-3">Tarih</th>
                      <th className="px-5 py-3">Ürün</th>
                      <th className="px-5 py-3">Tutar</th>
                      <th className="px-5 py-3">Durum</th>
                      <th className="px-5 py-3" />
                    </tr>
                  </thead>
                  <tbody>
                    {orders.map((order) => (
                      <tr key={order.id} className="border-b border-secondary/5 last:border-0">
                        <td className="px-5 py-4 font-semibold text-secondary">{order.orderNumber}</td>
                        <td className="px-5 py-4 text-secondary-light">{formatDate(order.createdAt)}</td>
                        <td className="px-5 py-4 text-secondary-light">{order.items.length} ürün</td>
                        <td className="px-5 py-4 font-medium text-secondary">{formatPrice(Number(order.totalAmount))}</td>
                        <td className="px-5 py-4">
                          <span className="rounded-full bg-primary/10 px-3 py-1 text-xs font-medium text-primary">
                            {ORDER_STATUS_LABELS[order.status]}
                          </span>
                        </td>
                        <td className="px-5 py-4 text-right">
                          <Link
                            href={`/hesabim/siparisler/${order.id}`}
                            className="font-medium text-primary hover:underline"
                          >
                            Detay
                          </Link>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
