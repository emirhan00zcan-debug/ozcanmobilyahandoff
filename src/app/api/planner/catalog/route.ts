import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";

// Planlayıcı SPA'sı (tasarla.ozcanmobilya.com — ayrı orijin) için salt-okunur
// katalog uç noktası. Kimlik doğrulama gerektirmez: döndürülen ölçü/fiyat verisi
// zaten ürün sayfalarında herkese açık gösteriliyor. Bkz. Mimari Doküman §1.3.
export async function GET(req: NextRequest) {
  const idsParam = req.nextUrl.searchParams.get("ids") ?? "";
  const ids = idsParam
    .split(",")
    .map((id) => id.trim())
    .filter(Boolean);

  if (ids.length === 0) {
    return withCors(NextResponse.json([]));
  }

  const products = await prisma.product.findMany({
    where: { id: { in: ids }, isActive: true },
    include: {
      images: { orderBy: { order: "asc" }, take: 1 },
      variations: {
        where: { isActive: true },
        include: {
          selectedOptions: { include: { variationOption: true } },
        },
      },
    },
  });

  const payload = products.map((p) => ({
    productId: p.id,
    name: p.name,
    dimensionsMm: {
      w: toMm(p.widthCm),
      h: toMm(p.heightCm),
      d: toMm(p.depthCm),
    },
    basePrice: Number(p.basePrice),
    images: p.images.map((img) => img.url),
    variations: p.variations.map((v) => ({
      id: v.id,
      sku: v.sku,
      price: Number(v.price),
      hexColor: v.selectedOptions.map((so) => so.variationOption.hexColor).find(Boolean) ?? null,
      heightOverrideCm: v.heightOverrideCm ? Number(v.heightOverrideCm) : null,
    })),
  }));

  return withCors(NextResponse.json(payload));
}

export async function OPTIONS() {
  return withCors(new NextResponse(null, { status: 204 }));
}

function toMm(cm: { toString(): string } | null): number {
  return cm ? Math.round(Number(cm.toString()) * 10) : 0;
}

function withCors(res: NextResponse) {
  res.headers.set("Access-Control-Allow-Origin", "*");
  res.headers.set("Access-Control-Allow-Methods", "GET, OPTIONS");
  return res;
}
