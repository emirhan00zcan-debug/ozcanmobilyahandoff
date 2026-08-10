import type { PlannerModule, Point } from "./types";

export interface Rect {
  x: number;
  y: number;
  w: number;
  h: number;
}

// Rotasyon yalnızca 90°'nin katlarıyla sınırlı olduğundan (gerçek mobilya
// yerleşim pratiğiyle uyumlu bir tasarım kararı — bkz. §3.1) döndürülmüş bir
// modülün sınırlayıcı kutusu her zaman eksen-hizalıdır: genişlik/derinlik yer
// değiştirir, açı hesaba hiç girmez. Bu, OBB/SAT yerine basit AABB testine
// izin verir.
export function moduleFootprint(m: PlannerModule): Rect {
  const swapped = m.rotationDeg === 90 || m.rotationDeg === 270;
  return {
    x: m.position.x,
    y: m.position.y,
    w: swapped ? m.dimensionsMm.d : m.dimensionsMm.w,
    h: swapped ? m.dimensionsMm.w : m.dimensionsMm.d,
  };
}

export function overlaps(a: Rect, b: Rect): boolean {
  return a.x < b.x + b.w && a.x + a.w > b.x && a.y < b.y + b.h && a.y + a.h > b.y;
}

export function hasCollision(target: Rect, others: Rect[]): boolean {
  return others.some((o) => overlaps(target, o));
}

// Duvar çizerken dik açı dayatması (§Faz 1 kapsamı: yalnızca dikdörtgensel/
// rektilineer oda biçimleri destekleniyor — serbest açılı duvarlar hem AABB
// çarpışmasını hem de duvar-snap'ini geçersiz kılar). İki noktadan hangi eksen
// baskınsa o eksene kilitler.
export function orthoLock(from: Point, to: Point): Point {
  const dx = Math.abs(to.x - from.x);
  const dy = Math.abs(to.y - from.y);
  return dx >= dy ? { x: to.x, y: from.y } : { x: from.x, y: to.y };
}

export function snapToGrid(p: Point, gridMm = 50): Point {
  return { x: Math.round(p.x / gridMm) * gridMm, y: Math.round(p.y / gridMm) * gridMm };
}
