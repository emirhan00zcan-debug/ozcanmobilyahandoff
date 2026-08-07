import { NextRequest, NextResponse } from "next/server";
import { auth } from "@/lib/auth";
import { prisma } from "@/lib/prisma";

export async function POST(req: NextRequest) {
    try {
        const session = await auth();
        if (!session?.user?.id) {
            return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
        }

        const body = await req.json();
        const clientItems: any[] = body.items || [];
        const mode = body.mode || "merge"; // 'merge' on initial load, 'overwrite' on client changes

        const userId = session.user.id;

        let cart = await prisma.cart.findUnique({
            where: { userId },
            include: { items: true },
        });

        if (!cart) {
            cart = await prisma.cart.create({
                data: { userId },
                include: { items: true },
            });
        }

        const serverItems = cart.items;

        if (mode === "overwrite") {
            // Delete server items that are not in client items
            for (const serverItem of serverItems) {
                const existsInClient = clientItems.find(
                    (ci) => ci.productId === serverItem.productId && (ci.productVariationId || null) === serverItem.productVariationId
                );
                if (!existsInClient) {
                    await prisma.cartItem.delete({ where: { id: serverItem.id } });
                }
            }

            // Update or add client items
            for (const clientItem of clientItems) {
                const existing = serverItems.find(
                    (si) => si.productId === clientItem.productId && si.productVariationId === (clientItem.productVariationId || null)
                );
                if (existing) {
                    if (existing.quantity !== clientItem.quantity) {
                        await prisma.cartItem.update({
                            where: { id: existing.id },
                            data: { quantity: clientItem.quantity },
                        });
                    }
                } else {
                    await prisma.cartItem.create({
                        data: {
                            cartId: cart.id,
                            productId: clientItem.productId,
                            productVariationId: clientItem.productVariationId || null,
                            quantity: clientItem.quantity,
                        },
                    });
                }
            }
        } else if (mode === "merge") {
            // Add or verify client items on server
            for (const clientItem of clientItems) {
                const existing = serverItems.find(
                    (si) => si.productId === clientItem.productId && si.productVariationId === (clientItem.productVariationId || null)
                );
                if (!existing) {
                    await prisma.cartItem.create({
                        data: {
                            cartId: cart!.id,
                            productId: clientItem.productId,
                            productVariationId: clientItem.productVariationId || null,
                            quantity: clientItem.quantity,
                        },
                    });
                }
            }
        }

        // Now return fully populated cart items so client can render them
        const updatedCart = await prisma.cart.findUnique({
            where: { userId },
            include: {
                items: {
                    include: {
                        product: {
                            include: { images: true, variationTypes: true }
                        },
                        productVariation: {
                            include: {
                                selectedOptions: {
                                    include: { variationOption: { include: { variationType: true } } }
                                }
                            }
                        }
                    }
                }
            },
        });

        const parsedItems = updatedCart?.items.map((item) => {
            // Construct selectedVariations
            const selectedVariations: Record<string, string> = {};
            if (item.productVariation) {
                item.productVariation.selectedOptions.forEach((opt) => {
                    const typeName = opt.variationOption.variationType.name.toLowerCase();
                    // Map backend variation names to frontend expected names
                    if (typeName.includes("ölçü") || typeName.includes("boyut") || typeName.includes("dimension")) {
                        selectedVariations.dimensions = opt.variationOption.value;
                    } else if (typeName.includes("kapak") || typeName.includes("door")) {
                        selectedVariations.doorType = opt.variationOption.value;
                    } else {
                        selectedVariations.colorDetails = opt.variationOption.value;
                    }
                });
            }

            // We need a stable lineId
            const v = selectedVariations;
            const normalized = [
                ["dimensions", v.dimensions ?? ""],
                ["doorType", v.doorType ?? ""],
                ["colorDetails", v.colorDetails ?? ""],
            ]
                .map(([key, value]) => `${key}:${value}`)
                .join("|");
            const lineId = `${item.productId}__${normalized}`;

            const basePrice = Number(item.product.basePrice);
            const unitPrice = item.productVariation ? Number(item.productVariation.price) : basePrice;

            // Use client item image if possible or fetch from product
            let image = item.product.images?.[0]?.url;
            if (!image) {
                const matchedClient = clientItems.find(
                    (ci) => ci.productId === item.productId && ci.productVariationId === (item.productVariationId || null)
                );
                if (matchedClient?.image) {
                    image = matchedClient.image;
                }
            }

            return {
                id: lineId,
                productId: item.productId,
                productVariationId: item.productVariationId,
                name: item.product.name,
                basePrice,
                unitPrice,
                totalPrice: unitPrice * item.quantity,
                quantity: item.quantity,
                image,
                selectedVariations,
            };
        });

        return NextResponse.json({ items: parsedItems });
    } catch (error) {
        console.error("Cart sync error:", error);
        return NextResponse.json({ error: "Internal Server Error" }, { status: 500 });
    }
}
