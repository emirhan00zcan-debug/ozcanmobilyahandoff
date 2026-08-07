"use server";

import { prisma } from "@/lib/prisma";
import type { VariationTypeView, VariationOptionView, ProductVariationView } from "@/lib/data/products";

// Server action to return products for the comparison table based on slugs
export async function getProductsForCompare(slugs: string[]) {
    if (!slugs || slugs.length === 0) return [];

    const products = await prisma.product.findMany({
        where: { slug: { in: slugs }, isActive: true },
        include: {
            images: { orderBy: { order: "asc" }, take: 1 },
            category: true,
            variationTypes: {
                include: { options: true }
            }
        }
    });

    return products.map(p => ({
        id: p.id,
        slug: p.slug,
        name: p.name,
        basePrice: p.basePrice.toNumber(),
        compareAtPrice: p.compareAtPrice?.toNumber() ?? null,
        inStock: p.stock > 0,
        imageUrl: p.images[0]?.url || null,
        widthCm: p.widthCm?.toNumber() ?? null,
        heightCm: p.heightCm?.toNumber() ?? null,
        depthCm: p.depthCm?.toNumber() ?? null,
        features: p.features,
        categoryName: p.category?.name || "",
        variationTypes: p.variationTypes.map((vt) => ({
            name: vt.name,
            options: vt.options.map((opt) => opt.value)
        }))
    }));
}
