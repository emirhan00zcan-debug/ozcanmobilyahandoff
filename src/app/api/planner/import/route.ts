import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { HandoffTokenError, verifyHandoffToken } from "@/lib/planner-handoff";

interface ImportItem {
  productId: string;
  productVariationId: string | null;
  quantity: number;
}

// Planlayıcının ürettiği BOM'u gerçek sepete yazar — bkz. Mimari Doküman
// §1.4. Kimlik doğrulaması çerezle değil, Authorization: Bearer <handoff JWT>
// ile yapılır (planlayıcı ayrı orijinde olduğundan çerez paylaşımı mümkün
// değil). Birleştirme mantığı /api/cart/sync'in "merge" modasıyla birebir
// aynı: sepette zaten olan bir satırın miktarına dokunulmaz, yalnızca
// eksik olan ürün/varyasyon satırları eklenir — kullanıcı sepette elle
// yaptığı bir değişikliği sessizce kaybetmesin diye.
export async function POST(req: NextRequest) {
  const authHeader = req.headers.get("authorization") ?? "";
  const token = authHeader.startsWith("Bearer ") ? authHeader.slice("Bearer ".length) : null;
  if (!token) {
    return withCors(NextResponse.json({ error: "Authorization: Bearer <token> gerekli" }, { status: 401 }));
  }

  let userId: string;
  try {
    userId = verifyHandoffToken(token).sub;
  } catch (e) {
    const message = e instanceof HandoffTokenError ? e.message : "Token doğrulanamadı";
    return withCors(NextResponse.json({ error: message }, { status: 401 }));
  }

  const body = await req.json().catch(() => null);
  const items: unknown = body?.items;
  if (!Array.isArray(items) || items.length === 0) {
    return withCors(NextResponse.json({ error: "items (dolu bir dizi) gerekli" }, { status: 400 }));
  }

  const parsedItems: ImportItem[] = [];
  for (const raw of items) {
    if (
      typeof raw !== "object" ||
      raw === null ||
      typeof (raw as { productId?: unknown }).productId !== "string" ||
      !Number.isInteger((raw as { quantity?: unknown }).quantity) ||
      (raw as { quantity: number }).quantity < 1
    ) {
      return withCors(NextResponse.json({ error: "Geçersiz BOM satırı" }, { status: 400 }));
    }
    const item = raw as { productId: string; productVariationId?: string | null; quantity: number };
    parsedItems.push({
      productId: item.productId,
      productVariationId: item.productVariationId ?? null,
      quantity: item.quantity,
    });
  }

  let cart = await prisma.cart.findUnique({ where: { userId }, include: { items: true } });
  if (!cart) {
    cart = await prisma.cart.create({ data: { userId }, include: { items: true } });
  }

  try {
    for (const item of parsedItems) {
      const existing = cart.items.find(
        (ci) => ci.productId === item.productId && ci.productVariationId === item.productVariationId,
      );
      if (!existing) {
        await prisma.cartItem.create({
          data: {
            cartId: cart.id,
            productId: item.productId,
            productVariationId: item.productVariationId,
            quantity: item.quantity,
          },
        });
      }
    }
  } catch {
    // En olası neden: planlayıcıdan geçersiz/artık var olmayan bir productId
    // gelmesi (FK ihlali) — 500 yerine anlamlı bir 400 döndürülür.
    return withCors(NextResponse.json({ error: "Bir veya daha fazla ürün eklenemedi" }, { status: 400 }));
  }

  return withCors(NextResponse.json({ ok: true }));
}

export async function OPTIONS() {
  return withCors(new NextResponse(null, { status: 204 }));
}

function withCors(res: NextResponse) {
  res.headers.set("Access-Control-Allow-Origin", "*");
  res.headers.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.headers.set("Access-Control-Allow-Headers", "Authorization, Content-Type");
  return res;
}
