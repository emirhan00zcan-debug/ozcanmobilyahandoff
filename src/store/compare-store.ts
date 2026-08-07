import { create } from "zustand";
import { persist } from "zustand/middleware";
import type { ProductDetail } from "@/lib/data/products";
// We want to store actual data or just slugs? Slugs + basic info is safer for localStorage,
// but storing just slugs requires fetching. For simplicity, we can store a shallow version of the products.
// Even better: since Zustand runs on client, we can fetch their full object when rendered, 
// or simply store { slug, name, image } and fetch the full product on the compare page.
// Let's store slugs and a small cache.

interface CompareState {
    compareItems: { slug: string; name: string; imageUrl: string; categorySlug: string }[];
    toggleCompare: (product: { slug: string; name: string; imageUrl: string; categorySlug: string }) => void;
    removeCompare: (slug: string) => void;
    clearCompare: () => void;
}

export const useCompareStore = create<CompareState>()(
    persist(
        (set) => ({
            compareItems: [],
            toggleCompare: (product) =>
                set((state) => {
                    // You can only compare items from the same category generally, but we can just restrict by 4 items max.
                    const exists = state.compareItems.some((item) => item.slug === product.slug);
                    if (exists) {
                        return { compareItems: state.compareItems.filter((i) => i.slug !== product.slug) };
                    }
                    // Max 4 items allowed
                    if (state.compareItems.length >= 4) {
                        return { compareItems: state.compareItems };
                    }
                    return { compareItems: [...state.compareItems, product] };
                }),
            removeCompare: (slug) =>
                set((state) => ({
                    compareItems: state.compareItems.filter((item) => item.slug !== slug),
                })),
            clearCompare: () => set({ compareItems: [] }),
        }),
        {
            name: "ozcan-compare-storage",
        }
    )
);
