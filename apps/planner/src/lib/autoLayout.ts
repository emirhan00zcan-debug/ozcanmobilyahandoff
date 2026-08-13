// Duvar-bazlı otomatik yerleşim: rapordaki "boş tuval korkusunu kaldırma"
// bulgusuna karşılık gelir (IKEA Kreativ / HomeByMe AutoDesign benzeri), ama
// hiçbir görsel/görüntü üretmiyor — tamamen deterministik bir yerleşim
// algoritması. Girdi ürün ölçüsü + oda poligonu, çıktı tam sayı mm konum;
// LLM/diffusion modeli yok, dolayısıyla üretken-model tutarsızlık riski
// taşımıyor.

import type { CatalogProduct } from "./catalog";
import { hasCollision, moduleFootprint, type Rect } from "./geometry";
import { inwardSign } from "./snap";
import type { PlannerModule, Point, Room, RotationDeg, Wall } from "./types";

const CANDIDATE_STEP_MM = 50; // geometry.snapToGrid ile tutarlı tarama aralığı
const OPENING_CLEARANCE_MM = 100; // kapı/pencere açıklığının hemen önü boş kalsın

export interface AutoLayoutResult {
  placed: PlannerModule[];
  unplaced: CatalogProduct[];
}

interface Placement {
  x: number;
  y: number;
  rotationDeg: RotationDeg;
}

// Bir duvar üzerindeki kapı/pencere açıklıklarının, clearance payıyla birlikte
// mutlak (x veya y) eksende kapladığı aralıklar — mobilya bu aralıklara
// taşamaz, aksi halde açıklığın önünü tamamen kapatır.
function blockedRangesOnWall(wall: Wall, room: Room, axis: "x" | "y"): Array<[number, number]> {
  const dir = axis === "x" ? Math.sign(wall.end.x - wall.start.x) : Math.sign(wall.end.y - wall.start.y);
  const origin = axis === "x" ? wall.start.x : wall.start.y;

  return room.openings
    .filter((o) => o.wallId === wall.id)
    .map((o): [number, number] => {
      const a = origin + dir * (o.offsetMm - OPENING_CLEARANCE_MM);
      const b = origin + dir * (o.offsetMm + o.widthMm + OPENING_CLEARANCE_MM);
      return a <= b ? [a, b] : [b, a];
    });
}

function overlapsAnyRange(min: number, max: number, ranges: Array<[number, number]>): boolean {
  return ranges.some(([a, b]) => min < b && max > a);
}

// Tek bir duvar boyunca, ürünün sığdığı ilk boş (çarpışmasız, açıklıktan uzak)
// konumu arar. Ürünün `w` ölçüsü her zaman duvar boyunca, `d` ölçüsü her zaman
// odaya doğru yerleşir — moduleFootprint'in rotasyon/genişlik-derinlik takas
// kuralıyla birebir tutarlı olacak şekilde yatay duvarda 0°, dikey duvarda 90°
// kullanılır (bkz. geometry.moduleFootprint).
function findPlacementOnWall(wall: Wall, room: Room, polygon: Point[], product: CatalogProduct, others: Rect[]): Placement | null {
  const horizontal = wall.start.y === wall.end.y;
  const vertical = wall.start.x === wall.end.x;
  if (!horizontal && !vertical) return null; // yalnızca dik açılı duvarlar destekleniyor (bkz. snap.ts)

  const alongWall = product.dimensionsMm.w;
  const intoRoom = product.dimensionsMm.d;

  if (horizontal) {
    const spanMin = Math.min(wall.start.x, wall.end.x);
    const spanMax = Math.max(wall.start.x, wall.end.x);
    if (alongWall > spanMax - spanMin) return null;

    const sign = inwardSign(wall, polygon, "y");
    const innerFaceY = wall.start.y + sign * wall.thicknessMm;
    const y = sign > 0 ? innerFaceY : innerFaceY - intoRoom;
    const blocked = blockedRangesOnWall(wall, room, "x");

    for (let x = spanMin; x <= spanMax - alongWall; x += CANDIDATE_STEP_MM) {
      if (overlapsAnyRange(x, x + alongWall, blocked)) continue;
      const rect: Rect = { x, y, w: alongWall, h: intoRoom };
      if (!hasCollision(rect, others)) return { x, y, rotationDeg: 0 };
    }
    return null;
  }

  const spanMin = Math.min(wall.start.y, wall.end.y);
  const spanMax = Math.max(wall.start.y, wall.end.y);
  if (alongWall > spanMax - spanMin) return null;

  const sign = inwardSign(wall, polygon, "x");
  const innerFaceX = wall.start.x + sign * wall.thicknessMm;
  const x = sign > 0 ? innerFaceX : innerFaceX - intoRoom;
  const blocked = blockedRangesOnWall(wall, room, "y");

  for (let y = spanMin; y <= spanMax - alongWall; y += CANDIDATE_STEP_MM) {
    if (overlapsAnyRange(y, y + alongWall, blocked)) continue;
    const rect: Rect = { x, y, w: intoRoom, h: alongWall };
    if (!hasCollision(rect, others)) return { x, y, rotationDeg: 90 };
  }
  return null;
}

// Seçilen ürünleri, en büyüğünden başlayarak (basit azalan-boyut sezgiseli)
// boş duvarlara sırayla yerleştirir. Bir ürün için hiçbir duvarda yer
// bulunamazsa `unplaced`'a düşer — kullanıcı onu elle sürükleyip yerleştirir.
export function autoPlaceProducts(room: Room, existingModules: PlannerModule[], products: CatalogProduct[]): AutoLayoutResult {
  const polygon = room.walls.map((w) => w.start);
  const placed: PlannerModule[] = [];
  const unplaced: CatalogProduct[] = [];

  const ordered = [...products].sort(
    (a, b) => Math.max(b.dimensionsMm.w, b.dimensionsMm.d) - Math.max(a.dimensionsMm.w, a.dimensionsMm.d),
  );

  for (const product of ordered) {
    const others = [...existingModules, ...placed].map(moduleFootprint);
    let placement: Placement | null = null;
    for (const wall of room.walls) {
      placement = findPlacementOnWall(wall, room, polygon, product, others);
      if (placement) break;
    }

    if (!placement) {
      unplaced.push(product);
      continue;
    }

    placed.push({
      id: crypto.randomUUID(),
      productId: product.productId,
      productVariationId: product.variations[0]?.id ?? null,
      position: { x: placement.x, y: placement.y, z: 0 },
      rotationDeg: placement.rotationDeg,
      dimensionsMm: product.dimensionsMm,
      meta: { name: product.name, colorHex: product.variations[0]?.hexColor ?? null },
    });
  }

  return { placed, unplaced };
}
