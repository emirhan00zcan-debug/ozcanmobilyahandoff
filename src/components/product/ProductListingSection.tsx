"use client";

import { useMemo, useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { FaFilter, FaThLarge, FaList, FaShoppingBag, FaPlus, FaMinus } from "react-icons/fa";
import ProductCard from "@/components/product/ProductCard";
import EmptyState from "@/components/layout/EmptyState";
import { toFeaturedProduct, type ProductDetail } from "@/lib/data/products";
import { useCartStore } from "@/store/cart-store";

type PromoTile = {
  eyebrow: string;
  title: string;
  ctaLabel: string;
  ctaHref: string;
  imageUrl: string;
};

type Props = {
  products: ProductDetail[];
  emptyMessage: string;
  promoTile?: PromoTile;
};

type SortOption = "relevant" | "newest" | "price-asc" | "price-desc" | "name-asc";
type StockFilter = "all" | "in-stock" | "sold-out";

function formatPrice(value: number) {
  return new Intl.NumberFormat("tr-TR", { minimumFractionDigits: 2 }).format(value) + "₺";
}

const STOCK_OPTIONS: { value: StockFilter; label: string }[] = [
  { value: "all", label: "Tümü" },
  { value: "in-stock", label: "Stokta Var" },
  { value: "sold-out", label: "Tükendi" },
];

export default function ProductListingSection({ products, emptyMessage, promoTile }: Props) {
  const [filterOpen, setFilterOpen] = useState(true);
  const [stockFacetOpen, setStockFacetOpen] = useState(false);
  const [priceFacetOpen, setPriceFacetOpen] = useState(false);
  const [widthFacetOpen, setWidthFacetOpen] = useState(false);
  const [stockFilter, setStockFilter] = useState<StockFilter>("all");
  const [sortBy, setSortBy] = useState<SortOption>("relevant");
  const [viewMode, setViewMode] = useState<"grid" | "list">("grid");
  const [compareMode, setCompareMode] = useState(false);
  const [compareSlugs, setCompareSlugs] = useState<string[]>([]);

  const prices = products.map((p) => p.basePrice);
  const minPrice = prices.length ? Math.min(...prices) : 0;
  const maxPrice = prices.length ? Math.max(...prices) : 0;
  const [maxPriceFilter, setMaxPriceFilter] = useState(maxPrice);

  // Ölçü (genişlik) filtresi — sadece genişliği kayıtlı ürünler dikkate alınır.
  const widths = products.map((p) => p.widthCm).filter((w): w is number => w != null);
  const minWidth = widths.length ? Math.min(...widths) : 0;
  const maxWidth = widths.length ? Math.max(...widths) : 0;
  const [maxWidthFilter, setMaxWidthFilter] = useState(maxWidth);

  const visibleProducts = useMemo(() => {
    let list = products.filter((p) => {
      if (stockFilter === "in-stock" && !p.inStock) return false;
      if (stockFilter === "sold-out" && p.inStock) return false;
      if (p.basePrice > maxPriceFilter) return false;
      if (p.widthCm != null && p.widthCm > maxWidthFilter) return false;
      return true;
    });

    if (sortBy === "newest") list = [...list].reverse();
    else if (sortBy === "price-asc") list = [...list].sort((a, b) => a.basePrice - b.basePrice);
    else if (sortBy === "price-desc") list = [...list].sort((a, b) => b.basePrice - a.basePrice);
    else if (sortBy === "name-asc") list = [...list].sort((a, b) => a.name.localeCompare(b.name, "tr"));

    return list;
  }, [products, stockFilter, sortBy, maxPriceFilter, maxWidthFilter]);

  const compareProducts = products.filter((p) => compareSlugs.includes(p.slug));

  const toggleCompareMode = () => {
    setCompareMode((v) => !v);
    setCompareSlugs([]);
  };

  const toggleCompareSlug = (slug: string) => {
    setCompareSlugs((current) =>
      current.includes(slug) ? current.filter((s) => s !== slug) : [...current, slug],
    );
  };

  if (products.length === 0) {
    return <EmptyState message={emptyMessage} />;
  }

  return (
    <div>
      {/* Filtrele / karşılaştır / sırala / görünüm araç çubuğu */}
      <div className="mb-8 flex flex-wrap items-center justify-between gap-4 border-b border-secondary/10 pb-5">
        <div className="flex items-center gap-4">
          <button
            onClick={() => setFilterOpen((v) => !v)}
            className="flex items-center gap-2 rounded-full border border-secondary/20 px-4 py-2.5 font-body text-sm font-medium text-secondary transition-colors hover:border-secondary/40"
          >
            <FaFilter className="h-3 w-3" />
            Filtrele
          </button>
          <span className="font-body text-sm text-secondary-light">{visibleProducts.length} ürün</span>
        </div>

        <div className="flex flex-wrap items-center gap-6">
          <div className="flex items-center gap-2.5">
            <span className="font-body text-sm font-medium text-secondary">Karşılaştır:</span>
            <button
              role="switch"
              aria-checked={compareMode}
              aria-label="Karşılaştırma modunu aç/kapat"
              onClick={toggleCompareMode}
              className={[
                "relative h-6 w-11 shrink-0 rounded-full transition-colors",
                compareMode ? "bg-primary" : "bg-secondary/20",
              ].join(" ")}
            >
              <span
                className={[
                  "absolute left-0.5 top-0.5 h-5 w-5 rounded-full bg-white shadow transition-transform",
                  compareMode ? "translate-x-5" : "translate-x-0",
                ].join(" ")}
              />
            </button>
          </div>

          <div className="flex items-center gap-2.5">
            <span className="font-body text-sm font-medium text-secondary">Sırala:</span>
            <select
              value={sortBy}
              onChange={(e) => setSortBy(e.target.value as SortOption)}
              className="rounded-full border border-secondary/20 bg-white px-4 py-2.5 font-body text-sm text-secondary focus:outline-none"
            >
              <option value="relevant">En alakalı</option>
              <option value="newest">En Yeni</option>
              <option value="price-asc">Fiyat: Artan</option>
              <option value="price-desc">Fiyat: Azalan</option>
              <option value="name-asc">İsim: A-Z</option>
            </select>
          </div>

          <div className="flex items-center gap-2.5">
            <span className="hidden font-body text-sm font-medium text-secondary sm:inline">Görünüm:</span>
            <div className="flex items-center gap-1 rounded-full border border-secondary/20 p-1">
              <button
                onClick={() => setViewMode("grid")}
                aria-label="Izgara görünümü"
                className={[
                  "rounded-full p-2 transition-colors",
                  viewMode === "grid" ? "bg-secondary text-white" : "text-secondary-light hover:text-secondary",
                ].join(" ")}
              >
                <FaThLarge className="h-3.5 w-3.5" />
              </button>
              <button
                onClick={() => setViewMode("list")}
                aria-label="Liste görünümü"
                className={[
                  "rounded-full p-2 transition-colors",
                  viewMode === "list" ? "bg-secondary text-white" : "text-secondary-light hover:text-secondary",
                ].join(" ")}
              >
                <FaList className="h-3.5 w-3.5" />
              </button>
            </div>
          </div>
        </div>
      </div>

      <div className="grid gap-8 md:grid-cols-[200px_1fr]">
        {/* Filtre kenar çubuğu — masaüstünde her zaman görünür, mobilde "Filtrele" ile açılır */}
        <aside className={filterOpen ? "block" : "hidden"}>
          {maxWidth > minWidth && (
            <FacetGroup title="Ölçü (Genişlik)" open={widthFacetOpen} onToggle={() => setWidthFacetOpen((v) => !v)}>
              <p className="mb-3 font-body text-xs text-secondary-light">
                {minWidth} cm – {maxWidthFilter} cm
              </p>
              <input
                type="range"
                min={minWidth}
                max={maxWidth}
                value={maxWidthFilter}
                onChange={(e) => setMaxWidthFilter(Number(e.target.value))}
                className="w-full accent-primary"
              />
            </FacetGroup>
          )}

          <FacetGroup title="Stok durumu" open={stockFacetOpen} onToggle={() => setStockFacetOpen((v) => !v)}>
            <div className="flex flex-col gap-2.5">
              {STOCK_OPTIONS.map((option) => (
                <label key={option.value} className="flex items-center gap-2 font-body text-sm text-secondary-light">
                  <input
                    type="radio"
                    name="stock"
                    checked={stockFilter === option.value}
                    onChange={() => setStockFilter(option.value)}
                    className="accent-primary"
                  />
                  {option.label}
                </label>
              ))}
            </div>
          </FacetGroup>

          {maxPrice > minPrice && (
            <FacetGroup title="Fiyat" open={priceFacetOpen} onToggle={() => setPriceFacetOpen((v) => !v)}>
              <p className="mb-3 font-body text-xs text-secondary-light">
                {formatPrice(minPrice)} – {formatPrice(maxPriceFilter)}
              </p>
              <input
                type="range"
                min={minPrice}
                max={maxPrice}
                value={maxPriceFilter}
                onChange={(e) => setMaxPriceFilter(Number(e.target.value))}
                className="w-full accent-primary"
              />
            </FacetGroup>
          )}
        </aside>

        <div>
          {/* Karşılaştırma tablosu — 2+ ürün seçilince otomatik belirir */}
          {compareMode && compareProducts.length >= 2 && <CompareTable products={compareProducts} />}

          {visibleProducts.length === 0 ? (
            <EmptyState message="Bu filtrelere uyan ürün bulunamadı." />
          ) : viewMode === "grid" ? (
            <div className="grid grid-cols-2 gap-6 sm:gap-8 md:grid-cols-3 lg:grid-cols-4">
              {promoTile && <PromoTileCard {...promoTile} />}
              {visibleProducts.map((product) => (
                <div key={product.slug} className="relative">
                  {compareMode && (
                    <label className="absolute right-3 top-3 z-20 flex h-6 w-6 cursor-pointer items-center justify-center rounded-md border border-secondary/20 bg-white shadow-sm">
                      <input
                        type="checkbox"
                        checked={compareSlugs.includes(product.slug)}
                        onChange={() => toggleCompareSlug(product.slug)}
                        className="h-4 w-4 accent-primary"
                      />
                    </label>
                  )}
                  <ProductCard product={toFeaturedProduct(product)} />
                </div>
              ))}
            </div>
          ) : (
            <div className="flex flex-col divide-y divide-secondary/10">
              {visibleProducts.map((product) => (
                <ProductListRow key={product.slug} product={product} />
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

function FacetGroup({
  title,
  open,
  onToggle,
  children,
}: {
  title: string;
  open: boolean;
  onToggle: () => void;
  children: React.ReactNode;
}) {
  return (
    <div className="border-b border-secondary/10 py-4 first:pt-0">
      <button onClick={onToggle} className="flex w-full items-center justify-between">
        <span className="font-body text-sm font-semibold text-secondary">{title}</span>
        {open ? (
          <FaMinus className="h-2.5 w-2.5 text-secondary" />
        ) : (
          <FaPlus className="h-2.5 w-2.5 text-secondary" />
        )}
      </button>
      {open && <div className="mt-4">{children}</div>}
    </div>
  );
}

function CompareTable({ products }: { products: ProductDetail[] }) {
  const dims = (p: ProductDetail) => p.dimensions[0];

  return (
    <div className="mb-8 overflow-x-auto rounded-xl border border-secondary/10">
      <table className="w-full min-w-[560px] font-body text-sm">
        <thead>
          <tr className="border-b border-secondary/10 bg-secondary/[0.02]">
            <th className="w-36 px-4 py-3 text-left font-semibold text-secondary">Karşılaştırma</th>
            {products.map((p) => (
              <th key={p.slug} className="px-4 py-3 text-left">
                <div className="flex items-center gap-2.5">
                  <Image
                    src={p.images[0]}
                    alt={p.name}
                    width={40}
                    height={40}
                    className="h-10 w-10 shrink-0 rounded object-cover"
                  />
                  <span className="line-clamp-2 font-medium text-secondary">{p.name}</span>
                </div>
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          <tr className="border-b border-secondary/10">
            <td className="px-4 py-3 font-medium text-secondary-light">Fiyat</td>
            {products.map((p) => (
              <td key={p.slug} className="px-4 py-3 font-semibold text-primary">
                {formatPrice(p.basePrice)}
              </td>
            ))}
          </tr>
          <tr className="border-b border-secondary/10">
            <td className="px-4 py-3 font-medium text-secondary-light">Genişlik (W)</td>
            {products.map((p) => (
              <td key={p.slug} className="px-4 py-3 text-secondary-light">
                {dims(p)?.widthCm ?? "-"}
              </td>
            ))}
          </tr>
          <tr className="border-b border-secondary/10">
            <td className="px-4 py-3 font-medium text-secondary-light">Yükseklik (H)</td>
            {products.map((p) => (
              <td key={p.slug} className="px-4 py-3 text-secondary-light">
                {dims(p)?.heightCm ?? "-"}
              </td>
            ))}
          </tr>
          <tr className="border-b border-secondary/10">
            <td className="px-4 py-3 font-medium text-secondary-light">Derinlik (D)</td>
            {products.map((p) => (
              <td key={p.slug} className="px-4 py-3 text-secondary-light">
                {dims(p)?.depthCm ?? "-"}
              </td>
            ))}
          </tr>
          <tr>
            <td className="px-4 py-3 align-top font-medium text-secondary-light">Özellikler</td>
            {products.map((p) => (
              <td key={p.slug} className="px-4 py-3 align-top text-secondary-light">
                <ul className="space-y-1">
                  {p.features.map((f) => (
                    <li key={f}>• {f}</li>
                  ))}
                </ul>
              </td>
            ))}
          </tr>
        </tbody>
      </table>
    </div>
  );
}

function PromoTileCard({ eyebrow, title, ctaLabel, ctaHref, imageUrl }: PromoTile) {
  const isExternal = ctaHref.startsWith("http");

  return (
    <Link
      href={ctaHref}
      target={isExternal ? "_blank" : undefined}
      rel={isExternal ? "noopener noreferrer" : undefined}
      className="group relative flex aspect-square flex-col justify-end overflow-hidden rounded-xl bg-secondary p-5"
    >
      <Image
        src={imageUrl}
        alt={title}
        fill
        sizes="(max-width: 640px) 50vw, (max-width: 1024px) 33vw, 25vw"
        className="object-cover transition-transform duration-500 ease-in-out group-hover:scale-105"
      />
      <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-black/15 to-transparent" />
      <div className="relative z-10 text-white">
        <p className="font-body text-xs font-medium uppercase tracking-[0.15em] text-white/70">{eyebrow}</p>
        <h3 className="mt-1.5 font-display text-xl font-semibold leading-snug">{title}</h3>
        <span className="mt-4 inline-block rounded-full bg-white px-5 py-2.5 font-body text-xs font-semibold text-secondary transition-all duration-200 group-hover:bg-primary group-hover:text-white">
          {ctaLabel}
        </span>
      </div>
    </Link>
  );
}

function ProductListRow({ product }: { product: ProductDetail }) {
  const addItem = useCartStore((state) => state.addItem);
  const isSoldOut = !product.inStock;

  return (
    <Link href={`/urun/${product.slug}`} className="group flex items-center gap-5 py-5">
      <div className="relative h-20 w-20 shrink-0 overflow-hidden rounded-lg bg-secondary/[0.04]">
        <Image
          src={product.images[0]}
          alt={product.name}
          fill
          sizes="80px"
          className={["object-cover", isSoldOut ? "opacity-60 grayscale" : ""].join(" ")}
        />
      </div>
      <div className="flex-1">
        <h3 className="font-body text-sm font-medium leading-snug text-secondary">{product.name}</h3>
        <div className="mt-1 flex items-baseline gap-2">
          <span className="font-body text-sm font-semibold text-primary">{formatPrice(product.basePrice)}</span>
          {product.compareAtPrice && (
            <span className="font-body text-xs text-secondary-light line-through">
              {formatPrice(product.compareAtPrice)}
            </span>
          )}
          {isSoldOut && <span className="font-body text-xs font-semibold text-secondary-light">Tükendi</span>}
        </div>
      </div>
      <button
        onClick={(e) => {
          e.preventDefault();
          if (isSoldOut) return;
          addItem({
            productId: product.slug,
            name: product.name,
            basePrice: product.basePrice,
            unitPrice: product.basePrice,
            image: product.images[0],
          });
        }}
        disabled={isSoldOut}
        className="hidden shrink-0 items-center gap-2 rounded-full bg-secondary px-5 py-2.5 font-body text-xs font-semibold text-white transition-colors hover:bg-primary disabled:cursor-not-allowed disabled:opacity-40 sm:flex"
      >
        <FaShoppingBag className="h-3 w-3" />
        Sepete Ekle
      </button>
    </Link>
  );
}
