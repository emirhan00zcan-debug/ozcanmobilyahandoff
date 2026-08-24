import { NextRequest, NextResponse } from "next/server";
import { getNeighbourhoods } from "@/lib/data/neighbourhoods";

// Checkout'taki İl/İlçe seçimine bağlı Mahalle dropdown'ı için — bkz. lib/data/neighbourhoods.ts
export async function GET(request: NextRequest) {
  const city = request.nextUrl.searchParams.get("il") ?? "";
  const district = request.nextUrl.searchParams.get("ilce") ?? "";
  if (!city || !district) {
    return NextResponse.json({ neighbourhoods: [] });
  }

  const neighbourhoods = getNeighbourhoods(city, district);
  return NextResponse.json({ neighbourhoods });
}
