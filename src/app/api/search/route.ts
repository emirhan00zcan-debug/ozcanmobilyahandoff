import { NextRequest, NextResponse } from "next/server";
import { searchProductSuggestions } from "@/lib/data/products";

// Navbar'daki "yazarken ara" kutusu için — /arama sayfasındaki tam sonuç
// listesinin aksine, burada sadece dropdown'da gösterilecek küçük bir öneri
// seti dönüyor (bkz. lib/data/products.ts searchProductSuggestions).
export async function GET(request: NextRequest) {
  const q = request.nextUrl.searchParams.get("q") ?? "";
  const products = await searchProductSuggestions(q);
  return NextResponse.json({ products });
}
