"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import Image from "next/image";
import { useCompareStore } from "@/store/compare-store";
import { getProductsForCompare } from "@/lib/actions/product-actions";
import { FaTimes, FaCheck, FaTimesCircle, FaArrowLeft } from "react-icons/fa";

type CompareProductData = Awaited<ReturnType<typeof getProductsForCompare>>[number];

export default function ComparePageClient() {
    const { compareItems, removeCompare } = useCompareStore();
    const [data, setData] = useState<CompareProductData[]>([]);
    const [isLoading, setIsLoading] = useState(true);

    useEffect(() => {
        async function fetchData() {
            if (compareItems.length > 0) {
                setIsLoading(true);
                const slugs = compareItems.map((item) => item.slug);
                const result = await getProductsForCompare(slugs);
                // Preserve the order of selection
                const ordered = slugs
                    .map(slug => result.find(p => p.slug === slug))
                    .filter((p): p is CompareProductData => p !== undefined);
                setData(ordered);
            } else {
                setData([]);
            }
            setIsLoading(false);
        }
        fetchData();
    }, [compareItems]);

    const handleRemove = (slug: string) => {
        removeCompare(slug);
        setData(prev => prev.filter(p => p.slug !== slug));
    };


    if (isLoading) {
        return (
            <div className="flex min-h-[50vh] items-center justify-center">
                <div className="h-8 w-8 animate-spin rounded-full border-4 border-primary border-t-transparent" />
            </div>
        );
    }

    if (data.length === 0) {
        return (
            <div className="mx-auto flex min-h-[50vh] max-w-2xl flex-col items-center justify-center px-4 text-center">
                <div className="flex h-20 w-20 items-center justify-center rounded-full bg-secondary/5 text-secondary/30 mb-6">
                    <FaTimesCircle className="h-8 w-8" />
                </div>
                <h2 className="font-display text-2xl font-bold text-secondary">Karşılaştırılacak Ürün Yok</h2>
                <p className="mt-2 text-secondary-light font-body">Listede henüz bir ürün bulunmuyor. Ürün sayfası veya liste görünümlerinden ürün kartlarında bulunan karşılaştır butonuna tıklayarak ürün ekleyebilirsiniz.</p>
                <Link href="/kategori" className="mt-8 rounded-full bg-primary px-8 py-3 text-sm font-semibold text-white transition-opacity hover:opacity-90">
                    Kategorilere Göz At
                </Link>
            </div>
        );
    }

    // Find all unique features across compared items
    const allFeatures = Array.from(new Set(data.flatMap(p => p.features)));
    // Find all unique variation types (e.g. "Gövde Rengi", "Kapak Tipi")
    const allVariationTypes = Array.from(new Set(data.flatMap(p => p.variationTypes.map(vt => vt.name))));

    return (
        <div className="mx-auto max-w-7xl px-4 py-12 sm:px-6 lg:px-8">
            <div className="mb-8 flex items-center justify-between">
                <div>
                    <h1 className="font-display text-3xl font-bold text-secondary">Ürün Karşılaştırma</h1>
                    <p className="mt-2 font-body text-sm text-secondary-light">Seçtiğiniz ürünleri özelliklerine ve fiyatlarına göre yan yana inceleyin.</p>
                </div>
                <Link href="/kategori" className="flex items-center gap-2 font-body text-sm font-semibold text-primary transition-colors hover:text-secondary">
                    <FaArrowLeft className="h-3 w-3" />
                    Alışverişe Dön
                </Link>
            </div>

            <div className="overflow-x-auto pb-6">
                <div className="min-w-[800px] border border-secondary/10 rounded-2xl bg-white shadow-sm overflow-hidden">
                    {/* Header Row: Products */}
                    <div className="flex">
                        <div className="w-48 shrink-0 bg-slate-50 p-6 border-r border-b border-secondary/10 flex flex-col justify-end">
                            <span className="font-display font-semibold text-secondary">Ürün Özeti</span>
                        </div>
                        {data.map((product) => (
                            <div key={product.id} className="relative flex-1 min-w-[200px] p-6 border-r border-b border-secondary/10 flex flex-col group">
                                <button
                                    onClick={() => handleRemove(product.slug)}
                                    className="absolute right-4 top-4 z-10 flex h-7 w-7 items-center justify-center rounded-full bg-red-50 text-red-500 opacity-0 transition-all hover:bg-red-500 hover:text-white group-hover:opacity-100"
                                >
                                    <FaTimes className="h-3 w-3" />
                                </button>
                                <div className="relative aspect-square w-full rounded-xl overflow-hidden bg-secondary/5 mb-4">
                                    {product.imageUrl ? (
                                        <Image src={product.imageUrl} alt={product.name} fill className="object-cover" />
                                    ) : null}
                                </div>
                                <h3 className="font-display text-base font-semibold text-secondary leading-tight mt-auto">
                                    <Link href={`/urun/${product.slug}`} className="hover:text-primary transition-colors">
                                        {product.name}
                                    </Link>
                                </h3>
                                <div className="mt-2 text-primary font-body font-semibold">
                                    {new Intl.NumberFormat("tr-TR", { minimumFractionDigits: 2 }).format(product.basePrice)}₺
                                </div>
                            </div>
                        ))}
                    </div>

                    {/* Temel Bilgiler Section */}
                    <div className="flex bg-slate-100/50">
                        <div className="w-48 shrink-0 p-4 border-r border-b border-secondary/10 font-body text-sm font-bold text-secondary-light uppercase tracking-wider">
                            Temel Bilgiler
                        </div>
                        {data.map((product) => (
                            <div key={`basic-${product.id}`} className="flex-1 min-w-[200px] border-r border-b border-secondary/10"></div>
                        ))}
                    </div>

                    {/* Ölçüler (G x Y x D) */}
                    <div className="flex hover:bg-slate-50/50 transition-colors">
                        <div className="w-48 shrink-0 bg-slate-50 p-4 border-r border-b border-secondary/10 font-body text-sm font-semibold text-secondary">
                            Ölçüler (G x Y x D)
                        </div>
                        {data.map((product) => (
                            <div key={`dim-${product.id}`} className="flex-1 min-w-[200px] p-4 border-r border-b border-secondary/10 font-body text-sm text-secondary-light">
                                {product.widthCm || product.heightCm || product.depthCm ? (
                                    <>{product.widthCm || "-"} x {product.heightCm || "-"} x {product.depthCm || "-"} cm</>
                                ) : (
                                    "-"
                                )}
                            </div>
                        ))}
                    </div>

                    {/* Kategori */}
                    <div className="flex hover:bg-slate-50/50 transition-colors">
                        <div className="w-48 shrink-0 bg-slate-50 p-4 border-r border-b border-secondary/10 font-body text-sm font-semibold text-secondary">
                            Kategori
                        </div>
                        {data.map((product) => (
                            <div key={`cat-${product.id}`} className="flex-1 min-w-[200px] p-4 border-r border-b border-secondary/10 font-body text-sm text-secondary-light">
                                {product.categoryName}
                            </div>
                        ))}
                    </div>

                    {/* Stok Durumu */}
                    <div className="flex hover:bg-slate-50/50 transition-colors">
                        <div className="w-48 shrink-0 bg-slate-50 p-4 border-r border-b border-secondary/10 font-body text-sm font-semibold text-secondary">
                            Stok
                        </div>
                        {data.map((product) => (
                            <div key={`stock-${product.id}`} className="flex-1 min-w-[200px] p-4 border-r border-b border-secondary/10 font-body text-sm">
                                {product.inStock ? (
                                    <span className="inline-flex items-center gap-1.5 text-emerald-600 font-medium">
                                        <FaCheck className="h-3 w-3" /> Stokta Var
                                    </span>
                                ) : (
                                    <span className="inline-flex items-center gap-1.5 text-red-500 font-medium">
                                        <FaTimes className="h-3 w-3" /> Tükendi
                                    </span>
                                )}
                            </div>
                        ))}
                    </div>

                    {/* Özellikler Section */}
                    {allFeatures.length > 0 && (
                        <>
                            <div className="flex bg-slate-100/50">
                                <div className="w-48 shrink-0 p-4 border-r border-b border-secondary/10 font-body text-sm font-bold text-secondary-light uppercase tracking-wider">
                                    Öne Çıkan Özellikler
                                </div>
                                {data.map((product) => (
                                    <div key={`feat-head-${product.id}`} className="flex-1 min-w-[200px] border-r border-b border-secondary/10"></div>
                                ))}
                            </div>

                            {allFeatures.map(feature => (
                                <div key={feature} className="flex hover:bg-slate-50/50 transition-colors">
                                    <div className="w-48 shrink-0 bg-slate-50 p-4 border-r border-b border-secondary/10 font-body text-sm font-semibold text-secondary">
                                        {feature}
                                    </div>
                                    {data.map((product) => (
                                        <div key={`${feature}-${product.id}`} className="flex-1 flex items-center justify-center min-w-[200px] p-4 border-r border-b border-secondary/10 text-secondary-light">
                                            {product.features.includes(feature) ? (
                                                <FaCheck className="h-4 w-4 text-emerald-500" />
                                            ) : (
                                                <span className="text-slate-300">-</span>
                                            )}
                                        </div>
                                    ))}
                                </div>
                            ))}
                        </>
                    )}

                    {/* Varyantlar Section */}
                    {allVariationTypes.length > 0 && (
                        <>
                            <div className="flex bg-slate-100/50">
                                <div className="w-48 shrink-0 p-4 border-r border-b border-secondary/10 font-body text-sm font-bold text-secondary-light uppercase tracking-wider">
                                    Özelleştirmeler
                                </div>
                                {data.map((product) => (
                                    <div key={`var-head-${product.id}`} className="flex-1 min-w-[200px] border-r border-b border-secondary/10"></div>
                                ))}
                            </div>

                            {allVariationTypes.map(varName => (
                                <div key={varName} className="flex hover:bg-slate-50/50 transition-colors">
                                    <div className="w-48 shrink-0 bg-slate-50 p-4 border-r border-b border-secondary/10 font-body text-sm font-semibold text-secondary">
                                        {varName}
                                    </div>
                                    {data.map((product) => {
                                        const match = product.variationTypes.find(v => v.name === varName);
                                        return (
                                            <div key={`${varName}-${product.id}`} className="flex-1 min-w-[200px] p-4 border-r border-b border-secondary/10 font-body text-[13px] text-secondary-light leading-relaxed">
                                                {match ? match.options.join(", ") : <span className="text-slate-300">-</span>}
                                            </div>
                                        );
                                    })}
                                </div>
                            ))}
                        </>
                    )}

                    <div className="flex border-t border-secondary/10 bg-white">
                        <div className="w-48 shrink-0 bg-slate-50 p-4 border-r border-secondary/10"></div>
                        {data.map((product) => (
                            <div key={`btn-${product.id}`} className="flex-1 min-w-[200px] p-4 border-r border-secondary/10">
                                <Link
                                    href={`/urun/${product.slug}`}
                                    className="block w-full text-center rounded-xl bg-secondary py-3 font-body text-sm font-semibold text-white transition-colors hover:bg-primary"
                                >
                                    Detayları İncele
                                </Link>
                            </div>
                        ))}
                    </div>

                </div>
            </div>
        </div>
    );
}
