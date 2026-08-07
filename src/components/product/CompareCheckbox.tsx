"use client";

import { useCompareStore } from "@/store/compare-store";

export default function CompareCheckbox({
    product
}: {
    product: { id: string, slug: string, name: string, imageUrl?: string, categorySlug?: string }
}) {
    const { compareItems, toggleCompare } = useCompareStore();
    const isCompared = compareItems.some((item) => item.slug === product.slug);

    const handleToggle = (e: React.MouseEvent) => {
        e.preventDefault();
        e.stopPropagation();
        toggleCompare({
            slug: product.slug,
            name: product.name,
            imageUrl: product.imageUrl || "",
            categorySlug: product.categorySlug || "kategori-yok"
        });
    };

    return (
        <button
            onClick={handleToggle}
            className={`absolute right-3 top-3 z-10 flex h-7 items-center justify-center gap-1.5 rounded-full px-2.5 font-body text-[10px] font-semibold transition-all backdrop-blur-sm sm:h-8 sm:px-3 sm:text-[11px] ${isCompared
                    ? "bg-secondary text-white shadow-md ring-1 ring-secondary"
                    : "bg-white/80 text-secondary-light ring-1 ring-secondary/20 hover:bg-white hover:text-secondary hover:ring-secondary/50"
                }`}
            aria-label="Ürünü karşılaştır"
        >
            <div
                className={`flex h-3 w-3 items-center justify-center rounded-[3px] ring-1 transition-colors ${isCompared ? "bg-primary ring-primary" : "bg-white ring-secondary/30"
                    }`}
            >
                {isCompared && (
                    <svg className="h-2 w-2 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={3}>
                        <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
                    </svg>
                )}
            </div>
            <span className="hidden sm:inline-block">Karşılaştır</span>
        </button>
    );
}
