"use client";

import { useState } from "react";
import Link from "next/link";
import {
  FaCheck,
  FaMinus,
  FaPlus,
  FaTruck,
  FaUndoAlt,
  FaBolt,
  FaTimes,
  FaFacebookF,
  FaTwitter,
  FaPinterestP,
} from "react-icons/fa";
import { useCartStore } from "@/store/cart-store";
import type { ProductDetail } from "@/lib/data/products";

type Props = { product: ProductDetail };

function formatPrice(value: number) {
  return (
    new Intl.NumberFormat("tr-TR", {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    }).format(value) + "TL"
  );
}

export default function ProductDetailClient({ product }: Props) {
  const addItem = useCartStore((state) => state.addItem);

  const [activeImageIndex, setActiveImageIndex] = useState(0);
  const [quantity, setQuantity] = useState(1);
  const [isFeaturesOpen, setIsFeaturesOpen] = useState(true); // "Ürünün Özellikleri" varsayılan açık
  const [isMaterialOpen, setIsMaterialOpen] = useState(false);
  const [showOfferBox, setShowOfferBox] = useState(true);

  const hasDiscount = !!product.compareAtPrice;
  const discountPct = hasDiscount
    ? Math.floor((1 - product.basePrice / product.compareAtPrice!) * 100)
    : 0;

  const handleAddToCart = () => {
    if (!product.inStock) return;
    addItem({
      productId: product.slug,
      name: product.name,
      basePrice: product.basePrice,
      unitPrice: product.basePrice,
      image: product.images[0],
      quantity,
    });
  };

  return (
    <div className="mx-auto max-w-7xl px-4 py-6 sm:px-6 lg:px-8">
      {/* Breadcrumb */}
      <nav className="mb-6 flex items-center gap-2 font-body text-xs text-secondary-light">
        <Link href="/" className="font-medium text-secondary hover:text-primary">
          Home
        </Link>
        <span>|</span>
        <Link href="/" className="hover:text-primary">
          Ana sayfa
        </Link>
        <span>|</span>
        <span className="text-secondary-light">{product.name}</span>
      </nav>

      <div className="grid grid-cols-1 gap-10 lg:grid-cols-2">
        {/* ================= SOL BLOK: GALERİ ================= */}
        <div className="flex gap-4">
          {/* Dikey thumbnail şeridi */}
          <div className="flex flex-col gap-3">
            {product.images.map((img, i) => (
              <button
                key={img}
                onClick={() => setActiveImageIndex(i)}
                aria-label={`Görsel ${i + 1}`}
                className={[
                  "h-20 w-16 shrink-0 overflow-hidden rounded-md border-2 transition-colors",
                  i === activeImageIndex
                    ? "border-secondary"
                    : "border-secondary/10 hover:border-secondary/30",
                ].join(" ")}
              >
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img src={img} alt={`${product.name} ${i + 1}`} className="h-full w-full object-cover" />
              </button>
            ))}
          </div>

          {/* Ana görsel */}
          <div className="relative flex-1 overflow-hidden rounded-lg bg-secondary/[0.04]">
            <div className="aspect-[4/5] w-full">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img
                key={activeImageIndex}
                src={product.images[activeImageIndex]}
                alt={product.name}
                className="h-full w-full animate-fade-in object-cover"
              />
            </div>
          </div>
        </div>

        {/* ================= SAĞ BLOK: ÜRÜN BİLGİLERİ ================= */}
        <div>
          {/* İndirim rozeti */}
          {hasDiscount && (
            <span className="inline-block rounded-md bg-primary px-2.5 py-1 font-body text-xs font-semibold text-white">
              Save {discountPct}%
            </span>
          )}

          <h1 className="mt-3 font-display text-3xl font-bold leading-snug text-secondary">
            {product.name}
          </h1>

          <p className="mt-2 font-body text-sm text-secondary-light">
            Vendor:{" "}
            <Link href="/" className="text-primary underline underline-offset-2">
              {product.vendor}
            </Link>
          </p>

          {/* Fiyat alanı */}
          <div className="mt-4 flex items-baseline gap-3">
            <span className="font-body text-3xl font-bold text-primary">
              {formatPrice(product.basePrice)}
            </span>
            {hasDiscount && (
              <span className="font-body text-lg text-secondary-light line-through">
                {formatPrice(product.compareAtPrice!)}
              </span>
            )}
          </div>
          <p className="mt-1 font-body text-xs text-secondary-light">Tax included.</p>

          {!product.inStock && (
            <p className="mt-3 font-body text-xs font-bold uppercase tracking-wide text-primary">
              Out of stock
            </p>
          )}

          {/* Check ikonlu özellikler */}
          <div className="mt-4 flex flex-wrap gap-x-6 gap-y-2">
            {product.features.map((feature) => (
              <span
                key={feature}
                className="flex items-center gap-1.5 font-body text-[13px] font-medium text-secondary"
              >
                <FaCheck className="h-3 w-3 text-secondary" />
                {feature}
              </span>
            ))}
          </div>

          {/* ============ ÖLÇÜ TABLOSU ============ */}
          <div className="mt-6 overflow-hidden rounded-md border border-secondary/15">
            <table className="w-full font-body text-[13px]">
              <thead>
                <tr className="border-b border-secondary/15 bg-secondary/[0.02] text-left">
                  <th className="px-4 py-2.5 font-semibold text-secondary">Ölçü Alanı</th>
                  <th className="px-4 py-2.5 font-semibold text-secondary">Genişlik (W)</th>
                  <th className="px-4 py-2.5 font-semibold text-secondary">Yükseklik (H)</th>
                  <th className="px-4 py-2.5 font-semibold text-secondary">Derinlik (D)</th>
                </tr>
              </thead>
              <tbody>
                {product.dimensions.map((row, i) => (
                  <tr key={row.label} className={i < product.dimensions.length - 1 ? "border-b border-secondary/15" : ""}>
                    <td className="px-4 py-3 font-semibold text-secondary">{row.label}</td>
                    <td className="px-4 py-3 text-secondary-light">{row.widthCm}</td>
                    <td className="px-4 py-3 text-secondary-light">{row.heightCm}</td>
                    <td className="px-4 py-3 text-secondary-light">{row.depthCm}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {/* Kısa açıklama */}
          <p className="mt-4 font-body text-[13px] leading-relaxed text-secondary-light">
            {product.description}
          </p>

          {/* ============ SATIN ALMA ALANI ============ */}
          <div className="mt-6 flex items-center gap-3">
            {/* Adet seçici */}
            <div className="flex items-center rounded-full border border-secondary/20">
              <button
                onClick={() => setQuantity((q) => Math.max(1, q - 1))}
                aria-label="Adedi azalt"
                disabled={!product.inStock}
                className="px-4 py-3 text-secondary transition-colors hover:text-primary disabled:opacity-40"
              >
                <FaMinus className="h-3 w-3" />
              </button>
              <span className="w-8 text-center font-body text-sm font-semibold text-secondary tabular-nums">
                {quantity}
              </span>
              <button
                onClick={() => setQuantity((q) => q + 1)}
                aria-label="Adedi artır"
                disabled={!product.inStock}
                className="px-4 py-3 text-secondary transition-colors hover:text-primary disabled:opacity-40"
              >
                <FaPlus className="h-3 w-3" />
              </button>
            </div>

            {/* Sepete Ekle / Sold out */}
            <button
              onClick={handleAddToCart}
              disabled={!product.inStock}
              className={[
                "flex-1 rounded-full py-3.5 font-body text-sm font-semibold text-white transition-colors duration-200",
                product.inStock
                  ? "bg-primary hover:bg-primary-600"
                  : "cursor-not-allowed bg-secondary-light",
              ].join(" ")}
            >
              {product.inStock ? "Sepete Ekle" : "Sold out"}
            </button>
          </div>

          {/* Hemen Satın Al */}
          {product.inStock && (
            <button className="mt-3 w-full rounded-full bg-secondary/60 py-3.5 font-body text-sm font-semibold text-white transition-colors duration-200 hover:bg-secondary">
              Hemen Satın Alın
            </button>
          )}

          {/* Bilgi ikonları */}
          <div className="mt-5 space-y-2.5">
            <p className="flex items-center gap-2.5 font-body text-[13px] text-secondary">
              <FaTruck className="h-4 w-4 text-secondary-light" />
              Kapıya Teslim
            </p>
            <p className="flex items-center gap-2.5 font-body text-[13px] text-secondary">
              <FaUndoAlt className="h-4 w-4 text-secondary-light" />
              30 gün içerisinde koşulsuz iade
            </p>
          </div>

          {/* Yeşil fırsat kutusu */}
          {showOfferBox && (
            <div className="relative mt-5 rounded-lg bg-emerald-50 p-4">
              <button
                onClick={() => setShowOfferBox(false)}
                aria-label="Teklifi kapat"
                className="absolute right-3 top-3 text-emerald-700 hover:text-emerald-900"
              >
                <FaTimes className="h-3.5 w-3.5" />
              </button>
              <p className="flex items-center gap-2 font-body text-[13px] font-semibold text-emerald-800">
                <FaBolt className="h-3.5 w-3.5" />
                Sınırlı Süreli Teklif
              </p>
              <p className="mt-1.5 pr-6 font-body text-xs leading-relaxed text-emerald-700">
                20.000 TL ve üzeri alışverişlerinizde bir sonraki alışverişinizde
                kullanacağınız 2.000 TL kazanma fırsatı
              </p>
            </div>
          )}

          {/* Paylaş */}
          <div className="mt-5 flex items-center gap-3">
            <span className="font-body text-[13px] font-medium text-secondary">Share:</span>
            {[FaFacebookF, FaTwitter, FaPinterestP].map((Icon, i) => (
              <button
                key={i}
                className="flex h-8 w-8 items-center justify-center rounded-full border border-secondary/15 text-secondary transition-colors hover:border-primary hover:text-primary"
              >
                <Icon className="h-3 w-3" />
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* ================= ALT BLOK: AKORDEONLAR ================= */}
      <div className="mt-12 max-w-2xl">
        {/* Ürünün Özellikleri — varsayılan açık */}
        <div className="border-b border-secondary/15">
          <button
            onClick={() => setIsFeaturesOpen((v) => !v)}
            className="flex w-full items-center justify-between py-4"
          >
            <span className="font-display text-lg font-semibold text-secondary">
              Ürünün Özellikleri
            </span>
            {isFeaturesOpen ? (
              <FaMinus className="h-3.5 w-3.5 text-secondary" />
            ) : (
              <FaPlus className="h-3.5 w-3.5 text-secondary" />
            )}
          </button>
          {isFeaturesOpen && (
            <ul className="space-y-2 pb-5">
              {product.featureList.map((item) => (
                <li key={item} className="font-body text-[13px] leading-relaxed text-secondary-light">
                  - {item}
                </li>
              ))}
            </ul>
          )}
        </div>

        {/* Malzeme Bilgisi — varsayılan kapalı */}
        <div className="border-b border-secondary/15">
          <button
            onClick={() => setIsMaterialOpen((v) => !v)}
            className="flex w-full items-center justify-between py-4"
          >
            <span className="font-display text-lg font-semibold text-secondary">
              Malzeme Bilgisi
            </span>
            {isMaterialOpen ? (
              <FaMinus className="h-3.5 w-3.5 text-secondary" />
            ) : (
              <FaPlus className="h-3.5 w-3.5 text-secondary" />
            )}
          </button>
          {isMaterialOpen && (
            <ul className="space-y-2 pb-5">
              {product.materialInfo.map((item) => (
                <li key={item.label} className="font-body text-[13px] leading-relaxed text-secondary-light">
                  <span className="font-semibold text-secondary">{item.label}</span> {item.text}
                </li>
              ))}
            </ul>
          )}
        </div>

        {/* Ödeme & Güvenlik — bilgi kutusu */}
        <div className="mt-6 rounded-lg bg-indigo-50/70 p-5">
          <p className="font-body text-sm font-semibold text-secondary">Ödeme &amp; Güvenlik</p>
          <p className="mt-1.5 font-body text-[13px] leading-relaxed text-secondary-light">
            Ödeme bilgileriniz güvenli bir şekilde işlenir. Kredi kartı bilgilerinizi
            saklamıyoruz ve bu bilgilere erişimimiz bulunmuyor
          </p>
        </div>
      </div>
    </div>
  );
}
