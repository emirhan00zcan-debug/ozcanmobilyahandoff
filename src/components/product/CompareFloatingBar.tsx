"use client";

import Link from "next/link";
import Image from "next/image";
import { useCompareStore } from "@/store/compare-store";
import { FaTimes, FaExchangeAlt, FaTrash } from "react-icons/fa";

export default function CompareFloatingBar() {
    const { compareItems, removeCompare, clearCompare } = useCompareStore();

    if (compareItems.length === 0) return null;

    return (
        <div className="fixed inset-x-0 bottom-0 z-50 p-4 pointer-events-none md:p-6 lg:ml-64">
            <div className="pointer-events-auto mx-auto flex max-w-4xl flex-col gap-4 rounded-2xl bg-white p-4 shadow-2xl ring-1 ring-secondary/10 sm:flex-row sm:items-center sm:p-5">

                {/* Sol metin alanı */}
                <div className="flex flex-col">
                    <div className="flex items-center gap-2">
                        <div className="flex h-6 w-6 items-center justify-center rounded-full bg-secondary/10 text-secondary">
                            <FaExchangeAlt className="h-3 w-3" />
                        </div>
                        <h4 className="font-display text-sm font-semibold text-secondary sm:text-base">
                            Ürün Karşılaştırma
                        </h4>
                    </div>
                    <p className="mt-1 font-body text-xs text-secondary-light">
                        En fazla 4 ürün karşılaştırabilirsiniz ({compareItems.length}/4).
                    </p>
                </div>

                {/* Seçilen ürünler thumbgrid */}
                <div className="flex flex-1 items-center gap-3 overflow-x-auto py-1 sm:justify-center">
                    {compareItems.map((item) => (
                        <div key={item.slug} className="group relative flex h-14 w-14 shrink-0 flex-col items-center sm:h-16 sm:w-16">
                            <div className="relative h-full w-full overflow-hidden rounded-lg bg-secondary/5 ring-1 ring-secondary/10">
                                {item.imageUrl ? (
                                    <Image src={item.imageUrl} alt={item.name} fill className="object-cover" />
                                ) : (
                                    <div className="flex h-full w-full items-center justify-center text-xs text-secondary/30">{item.name.charAt(0)}</div>
                                )}
                            </div>
                            <button
                                onClick={() => removeCompare(item.slug)}
                                className="absolute -right-1.5 -top-1.5 z-10 hidden h-5 w-5 items-center justify-center rounded-full bg-red-500 text-white shadow-sm hover:scale-110 group-hover:flex"
                            >
                                <FaTimes className="h-2.5 w-2.5" />
                            </button>
                        </div>
                    ))}
                    {/* Boş slotlar */}
                    {Array.from({ length: Math.max(0, 4 - compareItems.length) }).map((_, i) => (
                        <div key={`empty-${i}`} className="flex h-14 w-14 shrink-0 items-center justify-center rounded-lg border-2 border-dashed border-secondary/15 bg-secondary/5 sm:h-16 sm:w-16">
                            <span className="text-xl text-secondary/20">+</span>
                        </div>
                    ))}
                </div>

                {/* Aksiyon Butonları */}
                <div className="flex flex-col gap-2 sm:flex-row sm:items-center">
                    <button
                        onClick={clearCompare}
                        className="flex items-center justify-center gap-1.5 rounded-xl px-4 py-2 font-body text-xs font-semibold text-secondary-light transition-colors hover:bg-secondary/5 hover:text-red-500"
                    >
                        <FaTrash className="h-3 w-3" />
                        <span className="sr-only sm:not-sr-only">Temizle</span>
                    </button>

                    <Link
                        href="/karsilastir"
                        className={`btn-sweep flex items-center justify-center gap-2 rounded-xl border border-primary/30 px-6 py-2.5 font-body text-sm font-semibold text-secondary active:scale-95 ${compareItems.length < 2 ? "pointer-events-none opacity-50" : ""
                            }`}
                    >
                        Karşılaştır <span className="hidden sm:inline">({compareItems.length})</span>
                    </Link>
                </div>

            </div>
        </div>
    );
}
