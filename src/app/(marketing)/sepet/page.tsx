"use client";

import Link from "next/link";
import Image from "next/image";
import { useRouter } from "next/navigation";
import { useSession } from "next-auth/react";
import { FaMinus, FaPlus, FaTrash } from "react-icons/fa";
import {
  useCartItems,
  useCartSubtotal,
  useCartStore,
} from "@/store/cart-store";
import type { SelectedVariations } from "@/store/cart-store";

function formatPrice(value: number) {
  return (
    new Intl.NumberFormat("tr-TR", {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    }).format(value) + " TL"
  );
}

function variationSummary(variations: SelectedVariations) {
  return [variations.dimensions, variations.doorType, variations.colorDetails]
    .filter(Boolean)
    .join(" · ");
}

export default function SepetPage() {
  const items = useCartItems();
  const subtotal = useCartSubtotal();
  const hasHydrated = useCartStore((state) => state.hasHydrated);
  const updateQuantity = useCartStore((state) => state.updateQuantity);
  const removeItem = useCartStore((state) => state.removeItem);

  const { status } = useSession();
  const router = useRouter();

  // Sipariş vermek için giriş şart değil — misafir olarak da doğrudan ödeme adımına geçilir
  // (bkz. createOrderAction). Hesap, isteğe bağlı bir kolaylık.
  const handleCheckout = () => {
    router.push("/odeme");
  };

  // Persist middleware'i client mount olduktan sonra localStorage'dan doluyor (bkz.
  // useCartHydration); o ana kadar boş sepet gösterip "sepetiniz boş" yanılgısını önlüyoruz.
  if (!hasHydrated) {
    return <div className="mx-auto max-w-7xl px-4 py-24 sm:px-6 lg:px-8" />;
  }

  if (items.length === 0) {
    return (
      <div className="mx-auto flex max-w-7xl flex-col items-center px-4 py-24 text-center sm:px-6 lg:px-8">
        <h1 className="font-display text-2xl font-bold text-secondary">Sepetiniz boş</h1>
        <p className="mt-2 font-body text-sm text-secondary-light">
          Beğendiğiniz ürünleri sepetinize ekleyerek alışverişe başlayabilirsiniz.
        </p>
        <Link
          href="/kategori"
          className="mt-6 rounded-full bg-secondary px-8 py-3.5 font-body text-sm font-semibold text-white transition-all duration-200 hover:scale-105 hover:bg-primary active:scale-95"
        >
          Kategorilere Göz At
        </Link>
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
      <nav className="mb-6 flex items-center gap-2 font-body text-xs text-secondary-light">
        <Link href="/" className="font-medium text-secondary hover:text-primary">
          Ana sayfa
        </Link>
        <span>|</span>
        <span className="text-secondary-light">Sepetim</span>
      </nav>

      <h1 className="font-display text-2xl font-bold text-secondary sm:text-3xl">Sepetim</h1>

      <div className="mt-8 grid grid-cols-1 gap-10 lg:grid-cols-3">
        {/* Ürün listesi */}
        <ul className="space-y-5 lg:col-span-2">
          {items.map((item) => (
            <li
              key={item.id}
              className="flex gap-4 rounded-2xl border border-secondary/10 p-4 sm:gap-6 sm:p-5"
            >
              <div className="h-24 w-20 shrink-0 overflow-hidden rounded-lg bg-secondary/[0.04] sm:h-28 sm:w-24">
                {item.image ? (
                  <Image
                    src={item.image}
                    alt={item.name}
                    width={80}
                    height={96}
                    className="h-full w-full object-cover"
                  />
                ) : null}
              </div>

              <div className="flex flex-1 flex-col justify-between">
                <div>
                  <p className="font-display text-sm font-semibold leading-snug text-secondary sm:text-base">
                    {item.name}
                  </p>
                  {variationSummary(item.selectedVariations) && (
                    <p className="mt-1 font-body text-xs text-secondary-light">
                      {variationSummary(item.selectedVariations)}
                    </p>
                  )}
                  {item.installationRequested && (
                    <p className="mt-1 font-body text-xs text-secondary-light">
                      + Kurulum/Montaj Hizmeti (+{formatPrice(item.installationPrice ?? 0)})
                    </p>
                  )}
                  <p className="mt-1.5 font-body text-sm font-semibold text-primary">
                    {formatPrice(item.unitPrice)}
                  </p>
                </div>

                <div className="mt-3 flex items-center justify-between">
                  <div className="flex items-center rounded-full border border-secondary/20">
                    <button
                      onClick={() => updateQuantity(item.id, item.quantity - 1)}
                      aria-label="Adedi azalt"
                      className="px-3 py-2 text-secondary transition-colors hover:text-primary"
                    >
                      <FaMinus className="h-2.5 w-2.5" />
                    </button>
                    <span className="w-7 text-center font-body text-sm font-semibold text-secondary tabular-nums">
                      {item.quantity}
                    </span>
                    <button
                      onClick={() => updateQuantity(item.id, item.quantity + 1)}
                      aria-label="Adedi artır"
                      disabled={item.maxStock !== undefined && item.quantity >= item.maxStock}
                      className="px-3 py-2 text-secondary transition-colors hover:text-primary disabled:opacity-40"
                    >
                      <FaPlus className="h-2.5 w-2.5" />
                    </button>
                  </div>

                  <button
                    onClick={() => removeItem(item.id)}
                    aria-label="Üründen kaldır"
                    className="flex items-center gap-1.5 font-body text-xs font-medium text-secondary-light transition-colors hover:text-primary"
                  >
                    <FaTrash className="h-3 w-3" />
                    Kaldır
                  </button>
                </div>
              </div>

              <p className="hidden shrink-0 self-start font-body text-sm font-semibold text-secondary sm:block">
                {formatPrice(item.totalPrice)}
              </p>
            </li>
          ))}
        </ul>

        {/* Özet kutusu */}
        <div className="h-fit rounded-2xl border border-secondary/10 p-6">
          <h2 className="font-display text-lg font-semibold text-secondary">Sipariş Özeti</h2>

          <div className="mt-4 flex items-center justify-between font-body text-sm text-secondary-light">
            <span>Ara Toplam</span>
            <span className="font-semibold text-secondary">{formatPrice(subtotal)}</span>
          </div>
          <p className="mt-1 font-body text-xs text-secondary-light">
            Kargo ve varsa indirimler ödeme adımında hesaplanır.
          </p>

          <button
            onClick={handleCheckout}
            className="mt-6 flex w-full items-center justify-center gap-2 rounded-full bg-secondary py-3.5 font-body text-sm font-semibold text-white transition-all duration-200 hover:scale-[1.02] hover:bg-primary active:scale-95"
          >
            Sipariş Ver
          </button>

          {status !== "authenticated" && (
            <p className="mt-3 text-center font-body text-xs text-secondary-light">
              Hesap açmadan, misafir olarak sipariş verebilirsiniz. Siparişlerinizi takip etmek
              isterseniz{" "}
              <Link href="/giris?callbackUrl=%2Fodeme" className="font-medium text-primary hover:underline">
                giriş yapabilirsiniz
              </Link>
              .
            </p>
          )}
        </div>
      </div>
    </div>
  );
}
