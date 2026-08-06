"use client";

import { useEffect, useMemo, useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useSession } from "next-auth/react";
import {
  FaCheck,
  FaMinus,
  FaPlus,
  FaTruck,
  FaUndoAlt,
  FaTimes, // <-- put this back!
  FaFacebookF,
  FaTwitter,
  FaPinterestP,
  FaChevronLeft,
  FaChevronRight,
  FaSearchPlus,
} from "react-icons/fa";
import { useCartStore } from "@/store/cart-store";
import type { SelectedVariations } from "@/store/cart-store";
import { trackViewItem } from "@/lib/analytics";
import type { ProductDetail } from "@/lib/data/products";
import RoomFitCalculator from "./RoomFitCalculator";

type Props = { product: ProductDetail };

function formatPrice(value: number) {
  return (
    new Intl.NumberFormat("tr-TR", {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    }).format(value) + "TL"
  );
}

// Varyasyon tipi adına göre sepet özetindeki hangi alana (kapak tipi / ölçü / diğer)
// yazılacağına karar verir — bkz. store/cart-store.ts SelectedVariations.
function isDoorTypeVariation(name: string) {
  return /kapak|kapı/i.test(name);
}
function isFootVariation(name: string) {
  return /ayak/i.test(name);
}

// Gerçek banka/kart taksit oranları bir ödeme sağlayıcısı (iyzico, PayTR vb.) entegre
// edilmeden bilinemez — bu yüzden burada saf aritmetikle (fiyat / taksit sayısı) hesaplanan,
// faizsiz ve bilgilendirme amaçlı bir taksit dökümü gösteriliyor.
const INSTALLMENT_COUNTS = [1, 3, 6, 9];
const MAX_INSTALLMENT_COUNT = Math.max(...INSTALLMENT_COUNTS);

type SharePlatform = "facebook" | "twitter" | "pinterest";

const SHARE_PLATFORMS: { platform: SharePlatform; Icon: typeof FaFacebookF; label: string }[] = [
  { platform: "facebook", Icon: FaFacebookF, label: "Facebook'ta paylaş" },
  { platform: "twitter", Icon: FaTwitter, label: "Twitter'da paylaş" },
  { platform: "pinterest", Icon: FaPinterestP, label: "Pinterest'te paylaş" },
];

function buildShareUrl(platform: SharePlatform, pageUrl: string, text: string, imageUrl?: string) {
  switch (platform) {
    case "facebook":
      return `https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(pageUrl)}`;
    case "twitter":
      return `https://twitter.com/intent/tweet?text=${encodeURIComponent(text)}&url=${encodeURIComponent(pageUrl)}`;
    case "pinterest":
      return `https://pinterest.com/pin/create/button/?url=${encodeURIComponent(pageUrl)}&description=${encodeURIComponent(text)}${imageUrl ? `&media=${encodeURIComponent(imageUrl)}` : ""}`;
  }
}

export default function ProductDetailClient({ product }: Props) {
  const addItem = useCartStore((state) => state.addItem);
  const { status } = useSession();
  const router = useRouter();

  const [activeImageIndex, setActiveImageIndex] = useState(0);
  const [quantity, setQuantity] = useState(1);
  const [isFeaturesOpen, setIsFeaturesOpen] = useState(true); // "Ürünün Özellikleri" varsayılan açık
  const [isMaterialOpen, setIsMaterialOpen] = useState(false);
  const [isFullscreen, setIsFullscreen] = useState(false);
  const [isInstallmentOpen, setIsInstallmentOpen] = useState(false);

  // Lightbox açıkken sayfa kaydırılmasını (scroll) önle
  useEffect(() => {
    if (isFullscreen) {
      document.body.style.overflow = "hidden";
    } else {
      document.body.style.overflow = "unset";
    }
    return () => {
      document.body.style.overflow = "unset";
    };
  }, [isFullscreen]);

  // Lightbox kapalıyken Esc'ye basılırsa kapat ve yön tuşlarıyla resimler arası gezin
  useEffect(() => {
    if (!isFullscreen) return;

    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        setIsFullscreen(false);
      } else if (e.key === "ArrowLeft") {
        setActiveImageIndex((prev) => (prev > 0 ? prev - 1 : product.images.length - 1));
      } else if (e.key === "ArrowRight") {
        setActiveImageIndex((prev) => (prev < product.images.length - 1 ? prev + 1 : 0));
      }
    };

    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [isFullscreen, product.images.length]);

  // Her varyasyon tipi için varsayılan olarak ilk seçenek seçili gelir (tipik e-ticaret UX'i).
  const [selectedOptions, setSelectedOptions] = useState<Record<string, string>>(() =>
    Object.fromEntries(
      product.variationTypes
        .filter((vt) => vt.options.length > 0)
        .map((vt) => [vt.id, vt.options[0].id]),
    ),
  );

  // Ürün sayfası açıldığında bir kez — "hangi ürünün ilgi çektiği" verisinin kaynağı.
  useEffect(() => {
    trackViewItem({ item_id: product.slug, item_name: product.name, price: product.basePrice });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [product.slug]);

  const hasVariations = product.variationTypes.length > 0;

  // Seçili tüm opsiyon id'lerine tam olarak uyan ProductVariation (fiyat/stok/ölçü kaynağı).
  const resolvedVariation = useMemo(() => {
    if (!hasVariations) return null;
    const selectedIds = product.variationTypes.map((vt) => selectedOptions[vt.id]);
    if (selectedIds.some((id) => !id)) return null;
    return (
      product.variations.find(
        (v) => v.optionIds.length === selectedIds.length && selectedIds.every((id) => v.optionIds.includes(id)),
      ) ?? null
    );
  }, [hasVariations, product.variationTypes, product.variations, selectedOptions]);

  const effectivePrice = resolvedVariation ? resolvedVariation.price : product.basePrice;
  const effectiveInStock = hasVariations ? (resolvedVariation?.stock ?? 0) > 0 : product.inStock;

  const hasDiscount = !!product.compareAtPrice && effectivePrice < product.compareAtPrice;
  const discountPct = hasDiscount
    ? Math.floor((1 - effectivePrice / product.compareAtPrice!) * 100)
    : 0;

  // Ayak Tipi gibi ölçü değiştiren bir varyasyon seçiliyse ölçü tablosunu güncel değerle göster.
  const displayDimensions = useMemo(() => {
    if (!resolvedVariation) return product.dimensions;
    return product.dimensions.map((row) => {
      if (row.label === "Ayak Yüksekliği" && resolvedVariation.footHeightOverrideCm != null) {
        return { ...row, heightCm: `${resolvedVariation.footHeightOverrideCm} cm` };
      }
      if (row.label === "Dış Ölçüler" && resolvedVariation.heightOverrideCm != null) {
        return { ...row, heightCm: `${resolvedVariation.heightOverrideCm} cm` };
      }
      return row;
    });
  }, [product.dimensions, resolvedVariation]);

  const selectedVariationsSummary = useMemo<SelectedVariations>(() => {
    const summary: SelectedVariations = {};
    const otherLabels: string[] = [];
    for (const vt of product.variationTypes) {
      const option = vt.options.find((o) => o.id === selectedOptions[vt.id]);
      if (!option) continue;
      if (isDoorTypeVariation(vt.name)) {
        summary.doorType = option.value;
      } else if (!isFootVariation(vt.name)) {
        otherLabels.push(option.value);
      }
    }
    if (otherLabels.length > 0) summary.colorDetails = otherLabels.join(" - ");
    if (resolvedVariation?.footHeightOverrideCm != null) {
      summary.dimensions = `Ayak Yüksekliği: ${resolvedVariation.footHeightOverrideCm} cm`;
    } else if (resolvedVariation?.heightOverrideCm != null) {
      summary.dimensions = `Yükseklik: ${resolvedVariation.heightOverrideCm} cm`;
    }
    return summary;
  }, [product.variationTypes, resolvedVariation, selectedOptions]);

  const handleAddToCart = () => {
    if (!effectiveInStock) return;
    addItem({
      productId: product.slug,
      productVariationId: resolvedVariation?.id,
      name: product.name,
      basePrice: product.basePrice,
      unitPrice: effectivePrice,
      image: product.images[0],
      quantity,
      selectedVariations: selectedVariationsSummary,
    });
  };

  // Sepete ekleyip doğrudan ödeme adımına yönlendirir (bkz. SepetPage'deki aynı desen) —
  // oturum yoksa /giris'e, dönüş adresi /odeme olarak yönlendirilir.
  const handleBuyNow = () => {
    if (!effectiveInStock) return;
    addItem({
      productId: product.slug,
      productVariationId: resolvedVariation?.id,
      name: product.name,
      basePrice: product.basePrice,
      unitPrice: effectivePrice,
      image: product.images[0],
      quantity,
      selectedVariations: selectedVariationsSummary,
    });
    router.push(status === "authenticated" ? "/odeme" : "/giris?callbackUrl=%2Fodeme");
  };

  const handleShare = (platform: SharePlatform) => {
    const pageUrl = window.location.href;
    const image = product.images[0] ? `${window.location.origin}${product.images[0]}` : undefined;
    const shareUrl = buildShareUrl(platform, pageUrl, product.name, image);
    window.open(shareUrl, "_blank", "noopener,noreferrer,width=600,height=500");
  };

  return (
    <div className="mx-auto max-w-7xl px-4 py-6 sm:px-6 lg:px-8">
      {/* Breadcrumb */}
      <nav className="mb-6 flex items-center gap-2 font-body text-xs text-secondary-light">
        <Link href="/" className="font-medium text-secondary hover:text-primary">
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
                  "relative h-20 w-16 shrink-0 overflow-hidden rounded-md border-2 transition-colors",
                  i === activeImageIndex
                    ? "border-secondary"
                    : "border-secondary/10 hover:border-secondary/30",
                ].join(" ")}
              >
                <Image
                  src={img}
                  alt={`${product.name} ${i + 1}`}
                  fill
                  sizes="64px"
                  className="object-cover"
                />
              </button>
            ))}
          </div>

          {/* Ana görsel */}
          <button
            type="button"
            onClick={() => setIsFullscreen(true)}
            aria-label="Görseli büyüt"
            className="group relative flex-1 cursor-zoom-in overflow-hidden rounded-lg bg-secondary/[0.04]"
          >
            <div className="relative aspect-[4/5] w-full">
              <Image
                key={activeImageIndex}
                src={product.images[activeImageIndex]}
                alt={product.name}
                fill
                sizes="(max-width: 768px) 100vw, 50vw"
                priority
                className="animate-fade-in object-cover transition-transform duration-300 group-hover:scale-[1.02]"
              />
              {/* Büyüteç ikonu "Hover" efekti olarak hafifçe görünür */}
              <div className="absolute inset-0 flex items-center justify-center bg-black/0 opacity-0 transition-all duration-300 group-hover:bg-black/5 group-hover:opacity-100">
                <span className="flex h-12 w-12 items-center justify-center rounded-full bg-white/90 text-secondary shadow-lg">
                  <FaSearchPlus className="h-5 w-5" />
                </span>
              </div>
            </div>
          </button>
        </div>

        {/* ================= SAĞ BLOK: ÜRÜN BİLGİLERİ ================= */}
        <div>
          {/* İndirim rozeti */}
          {hasDiscount && (
            <span className="inline-block rounded-md bg-primary px-2.5 py-1 font-body text-xs font-semibold text-white">
              %{discountPct} İndirim
            </span>
          )}

          <h1 className="mt-3 font-display text-3xl font-bold leading-snug text-secondary">
            {product.name}
          </h1>

          <p className="mt-2 font-body text-sm text-secondary-light">
            Üretici:{" "}
            <Link href="/" className="text-primary underline underline-offset-2">
              {product.vendor}
            </Link>
          </p>

          {/* Fiyat alanı */}
          <div className="mt-4 flex items-baseline gap-3">
            <span className="font-body text-3xl font-bold text-primary">
              {formatPrice(effectivePrice)}
            </span>
            {hasDiscount && (
              <span className="font-body text-lg text-secondary-light line-through">
                {formatPrice(product.compareAtPrice!)}
              </span>
            )}
          </div>
          <p className="mt-1 font-body text-xs text-secondary-light">KDV Dahildir.</p>

          {/* Taksit bilgisi — bkz. INSTALLMENT_COUNTS yorumu, ödeme sağlayıcısı entegre olana kadar bilgilendirme amaçlı */}
          <div className="mt-3">
            <button
              type="button"
              onClick={() => setIsInstallmentOpen((v) => !v)}
              aria-expanded={isInstallmentOpen}
              className="inline-flex items-center gap-1.5 rounded-full bg-secondary/[0.06] px-3 py-1.5 font-body text-xs font-semibold text-secondary transition-colors hover:bg-secondary/10"
            >
              Kredi kartına {MAX_INSTALLMENT_COUNT} taksit imkanı
              {isInstallmentOpen ? <FaMinus className="h-2.5 w-2.5" /> : <FaPlus className="h-2.5 w-2.5" />}
            </button>

            {isInstallmentOpen && (
              <div className="mt-3 max-w-sm overflow-hidden rounded-md border border-secondary/15">
                <table className="w-full font-body text-[13px]">
                  <thead>
                    <tr className="border-b border-secondary/15 bg-secondary/[0.02] text-left">
                      <th className="px-4 py-2.5 font-semibold text-secondary">Taksit Sayısı</th>
                      <th className="px-4 py-2.5 font-semibold text-secondary">Aylık Tutar</th>
                    </tr>
                  </thead>
                  <tbody>
                    {INSTALLMENT_COUNTS.map((count, i) => (
                      <tr
                        key={count}
                        className={i < INSTALLMENT_COUNTS.length - 1 ? "border-b border-secondary/15" : ""}
                      >
                        <td className="px-4 py-2.5 text-secondary-light">
                          {count === 1 ? "Tek Çekim" : `${count} Taksit`}
                        </td>
                        <td className="px-4 py-2.5 font-medium text-secondary">
                          {formatPrice(effectivePrice / count)}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
                <p className="border-t border-secondary/15 bg-secondary/[0.02] px-4 py-2.5 font-body text-[11px] leading-relaxed text-secondary-light">
                  Gösterilen taksit tutarları bilgilendirme amaçlıdır; ödeme adımında bankanızın güncel
                  kampanyalarına göre değişebilir.
                </p>
              </div>
            )}
          </div>

          {!effectiveInStock && (
            <p className="mt-3 font-body text-xs font-bold uppercase tracking-wide text-primary">
              Tükendi
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
                {displayDimensions.map((row, i) => (
                  <tr key={row.label} className={i < displayDimensions.length - 1 ? "border-b border-secondary/15" : ""}>
                    <td className="px-4 py-3 font-semibold text-secondary">{row.label}</td>
                    <td className="px-4 py-3 text-secondary-light">{row.widthCm}</td>
                    <td className="px-4 py-3 text-secondary-light">{row.heightCm}</td>
                    <td className="px-4 py-3 text-secondary-light">{row.depthCm}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <RoomFitCalculator dimensions={displayDimensions} />

          {/* Kısa açıklama */}
          <p className="mt-4 font-body text-[13px] leading-relaxed text-secondary-light">
            {product.description}
          </p>

          {/* ============ VARYASYON SEÇİCİ (renk/kumaş, kapak tipi, ölçü) ============ */}
          {hasVariations && (
            <div className="mt-5 space-y-5">
              {product.variationTypes.map((vt) => {
                const selectedOption = vt.options.find((o) => o.id === selectedOptions[vt.id]);
                return (
                  <div key={vt.id}>
                    <p className="mb-2 font-body text-xs font-semibold text-secondary">
                      {vt.name}
                      {selectedOption && (
                        <span className="ml-1.5 font-normal text-secondary-light">
                          — {selectedOption.value}
                        </span>
                      )}
                    </p>
                    <div className="flex flex-wrap gap-2">
                      {vt.options.map((option) => {
                        const isSelected = selectedOptions[vt.id] === option.id;
                        const handleSelect = () =>
                          setSelectedOptions((prev) => ({ ...prev, [vt.id]: option.id }));

                        if (option.hexColor || option.swatchImageUrl) {
                          return (
                            <button
                              key={option.id}
                              type="button"
                              onClick={handleSelect}
                              aria-label={option.value}
                              aria-pressed={isSelected}
                              title={option.value}
                              className={[
                                "relative h-9 w-9 shrink-0 overflow-hidden rounded-full border-2 transition-all duration-150",
                                isSelected
                                  ? "border-primary ring-2 ring-primary/30 ring-offset-2"
                                  : "border-secondary/20 hover:border-secondary/50",
                              ].join(" ")}
                              style={option.hexColor ? { backgroundColor: option.hexColor } : undefined}
                            >
                              {option.swatchImageUrl ? (
                                <Image
                                  src={option.swatchImageUrl}
                                  alt={option.value}
                                  fill
                                  sizes="36px"
                                  className="object-cover"
                                />
                              ) : null}
                            </button>
                          );
                        }

                        return (
                          <button
                            key={option.id}
                            type="button"
                            onClick={handleSelect}
                            aria-pressed={isSelected}
                            className={[
                              "rounded-full border px-4 py-2 font-body text-xs font-medium transition-colors duration-150",
                              isSelected
                                ? "border-primary bg-primary/10 text-primary"
                                : "border-secondary/20 text-secondary hover:border-secondary/50",
                            ].join(" ")}
                          >
                            {option.value}
                            {option.priceModifier > 0 && (
                              <span className="ml-1 text-secondary-light">
                                (+{formatPrice(option.priceModifier)})
                              </span>
                            )}
                          </button>
                        );
                      })}
                    </div>
                  </div>
                );
              })}
            </div>
          )}

          {/* ============ SATIN ALMA ALANI ============ */}
          <div className="mt-6 flex items-center gap-3">
            {/* Adet seçici */}
            <div className="flex items-center rounded-full border border-secondary/20">
              <button
                onClick={() => setQuantity((q) => Math.max(1, q - 1))}
                aria-label="Adedi azalt"
                disabled={!effectiveInStock}
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
                disabled={!effectiveInStock}
                className="px-4 py-3 text-secondary transition-colors hover:text-primary disabled:opacity-40"
              >
                <FaPlus className="h-3 w-3" />
              </button>
            </div>

            {/* Sepete Ekle / Tükendi */}
            <button
              onClick={handleAddToCart}
              disabled={!effectiveInStock}
              className={[
                "flex-1 rounded-full py-3.5 font-body text-sm font-semibold text-white transition-colors duration-200",
                effectiveInStock
                  ? "bg-primary hover:bg-primary-600"
                  : "cursor-not-allowed bg-secondary-light",
              ].join(" ")}
            >
              {effectiveInStock ? "Sepete Ekle" : "Tükendi"}
            </button>
          </div>

          {/* Hemen Satın Al */}
          {effectiveInStock && (
            <button
              type="button"
              onClick={handleBuyNow}
              className="mt-3 w-full rounded-full bg-secondary/60 py-3.5 font-body text-sm font-semibold text-white transition-colors duration-200 hover:bg-secondary"
            >
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

          {/* Paylaş */}
          <div className="mt-5 flex items-center gap-3">
            <span className="font-body text-[13px] font-medium text-secondary">Paylaş:</span>
            {SHARE_PLATFORMS.map(({ platform, Icon, label }) => (
              <button
                key={platform}
                type="button"
                onClick={() => handleShare(platform)}
                aria-label={label}
                title={label}
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

      {/* ================= LIGHTBOX OVERLAY ================= */}
      {isFullscreen && (
        <div
          className="fixed inset-0 z-[100] flex animate-fade-in items-center justify-center bg-black/95 p-4 sm:p-8"
          onClick={() => setIsFullscreen(false)} // Dışarı tıklayınca da kapansın
        >
          {/* Kapat Butonu */}
          <button
            onClick={() => setIsFullscreen(false)}
            aria-label="Kapat"
            className="absolute right-4 top-4 z-[110] flex h-12 w-12 items-center justify-center rounded-full bg-white/10 text-white backdrop-blur-md transition-colors hover:bg-white/25 sm:right-8 sm:top-8"
          >
            <FaTimes className="h-5 w-5" />
          </button>

          {/* Sol/Sağ Navigasyon (Birden fazla görsel varsa) */}
          {product.images.length > 1 && (
            <>
              <button
                onClick={(e) => {
                  e.stopPropagation();
                  setActiveImageIndex((i) => (i > 0 ? i - 1 : product.images.length - 1));
                }}
                aria-label="Önceki"
                className="absolute left-2 z-[110] flex h-12 w-12 items-center justify-center rounded-full bg-white/10 text-white backdrop-blur-md transition-colors hover:bg-white/25 sm:left-8"
              >
                <FaChevronLeft className="h-5 w-5" />
              </button>
              <button
                onClick={(e) => {
                  e.stopPropagation();
                  setActiveImageIndex((i) => (i < product.images.length - 1 ? i + 1 : 0));
                }}
                aria-label="Sonraki"
                className="absolute right-2 z-[110] flex h-12 w-12 items-center justify-center rounded-full bg-white/10 text-white backdrop-blur-md transition-colors hover:bg-white/25 sm:right-8"
              >
                <FaChevronRight className="h-5 w-5" />
              </button>
            </>
          )}

          {/* Ortadaki Büyük Görsel: Tıklandığında tıklamanın yayılıp (bubbling) lightbox'ı kapatmasını engelliyoruz */}
          <div
            className="relative h-full w-full max-w-6xl cursor-default"
            onClick={(e) => e.stopPropagation()}
          >
            <Image
              src={product.images[activeImageIndex]}
              alt={product.name}
              fill
              sizes="100vw"
              priority
              quality={90}
              className="object-contain"
            />
          </div>
        </div>
      )}
    </div>
  );
}
