import { NextRequest, NextResponse } from "next/server";
import { auth } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import { signHandoffToken } from "@/lib/planner-handoff";

// Planlayıcı SPA'sına (ayrı orijin) geçiş için kısa ömürlü (60sn) imzalı
// devir token'ı üretir — bkz. Mimari Doküman §1.2. Yalnızca oturum açmış
// kullanıcılar içindir; misafir akışı bu fazda kapsam dışı (bkz. proje
// notları — misafir sepeti bugün yalnızca istemci tarafında/localStorage'da
// yaşıyor, sunucu tarafında karşılığı yok). Ürün sayfası, oturumsuz
// kullanıcıyı "Hemen Satın Al" ile aynı desende zaten /giris'e yönlendiriyor.
//
// `product_slug` alır (id değil): ürün sayfasındaki ProductDetail tipi
// yalnızca slug taşıyor (bkz. src/lib/data/products.ts) — sırf bu buton için
// paylaşılan veri katmanına id eklemek yerine gerçek Prisma id'sini burada,
// sunucu tarafında çözüyoruz ve yanıtta geri döndürüyoruz.
export async function GET(req: NextRequest) {
  const session = await auth();
  if (!session?.user?.id) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const productSlug = req.nextUrl.searchParams.get("product_slug");
  if (!productSlug) {
    return NextResponse.json({ error: "product_slug gerekli" }, { status: 400 });
  }

  const product = await prisma.product.findUnique({ where: { slug: productSlug }, select: { id: true, isActive: true } });
  if (!product || !product.isActive) {
    return NextResponse.json({ error: "Ürün bulunamadı" }, { status: 404 });
  }

  const token = signHandoffToken({ userId: session.user.id, productId: product.id });
  return NextResponse.json({ token, productId: product.id });
}
