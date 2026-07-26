"use client";

import { useState } from "react";
import Link from "next/link";
import { FaCheck, FaShoppingBag } from "react-icons/fa";
import type { FeaturedProduct } from "@/lib/data/homepage-mock";
import { useCartStore } from "@/store/cart-store";

type Props = { product: FeaturedProduct };

function formatPrice(value: number) {
  return new Intl.NumberFormat("tr-TR", { minimumFractionDigits: 2 }).format(value) + "₺";
}

export default function ProductCard({ product }: Props) {
  const addItem = useCartStore((state) => state.addItem);
  const [justAdded, setJustAdded] = useState(false);

  const isSoldOut = product.inStock === false;
  const hasDiscount = !!product.compareAtPrice;
  const discountPct = hasDiscount
    ? Math.round((1 - product.price / product.compareAtPrice!) * 100)
    : 0;

  const handleAddToCart = (e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    if (isSoldOut) return;
    addItem({
      productId: product.id,
      name: product.name,
      basePrice: product.price,
      unitPrice: product.price,
      image: product.imageUrl,
    });
    setJustAdded(true);
    setTimeout(() => setJustAdded(false), 1500);
  };

  return (
    <Link href={`/urun/${product.slug}`} className="group flex flex-col">
      {/* Görsel alanı: iki katmanlı (görsel 1 / görsel 2) hover cross-fade + hafif zoom */}
      <div className="relative aspect-square overflow-hidden rounded-xl bg-secondary/[0.04]">
        {isSoldOut ? (
          <span className="absolute left-3 top-3 z-10 rounded-full bg-secondary-light px-2.5 py-1 font-body text-[11px] font-semibold text-white">
            Tükendi
          </span>
        ) : (
          hasDiscount && (
            <span className="absolute left-3 top-3 z-10 rounded-full bg-primary px-2.5 py-1 font-body text-[11px] font-semibold text-white">
              %{discountPct} İndirim
            </span>
          )
        )}

        {/* Görsel 1 (varsayılan) */}
        {product.imageUrl ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={product.imageUrl}
            alt={product.name}
            className={[
              "absolute inset-0 h-full w-full object-cover transition-all duration-500 ease-in-out group-hover:scale-105 group-hover:opacity-0",
              isSoldOut ? "opacity-60 grayscale" : "",
            ].join(" ")}
          />
        ) : (
          <div className="absolute inset-0 flex items-center justify-center bg-secondary/[0.04] font-display text-4xl text-secondary/15 transition-all duration-500 ease-in-out group-hover:scale-105 group-hover:opacity-0">
            {product.name.charAt(0)}
          </div>
        )}

        {/* Görsel 2 (hover'da beliren "iç görünüm" görseli) */}
        {product.hoverImageUrl ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={product.hoverImageUrl}
            alt={product.name}
            className="absolute inset-0 h-full w-full object-cover opacity-0 transition-opacity duration-300 ease-in-out group-hover:opacity-100"
          />
        ) : (
          <div className="absolute inset-0 flex items-center justify-center bg-secondary/[0.06] font-display text-4xl text-secondary/20 opacity-0 transition-opacity duration-300 ease-in-out group-hover:opacity-100">
            {product.name.charAt(0)}
          </div>
        )}

        {/* Hover'da dipten yukarı beliren "Sepete Ekle" butonu — tıklayınca basma efekti + onay animasyonu */}
        {!isSoldOut && (
          <div className="absolute inset-x-3 bottom-3 translate-y-4 opacity-0 transition-all duration-300 ease-in-out group-hover:translate-y-0 group-hover:opacity-100">
            <button
              onClick={handleAddToCart}
              className={[
                "flex w-full items-center justify-center gap-2 rounded-full py-2.5 font-body text-xs font-semibold shadow-sm transition-all duration-200 active:scale-95",
                justAdded ? "bg-primary text-white" : "bg-secondary text-white hover:scale-[1.03] hover:bg-primary",
              ].join(" ")}
            >
              {justAdded ? (
                <>
                  <FaCheck className="h-3 w-3" /> Eklendi
                </>
              ) : (
                <>
                  <FaShoppingBag className="h-3 w-3" /> Sepete Ekle
                </>
              )}
            </button>
          </div>
        )}
      </div>

      {/* Ürün bilgisi */}
      <div className="mt-3.5 space-y-1">
        <h3 className="font-body text-sm font-medium leading-snug text-secondary line-clamp-2">
          {product.name}
        </h3>
        <div className="flex items-baseline gap-2">
          <span className="font-body text-sm font-semibold text-primary">
            {formatPrice(product.price)}
          </span>
          {hasDiscount && (
            <span className="font-body text-xs text-secondary-light line-through">
              {formatPrice(product.compareAtPrice!)}
            </span>
          )}
        </div>
      </div>
    </Link>
  );
}
