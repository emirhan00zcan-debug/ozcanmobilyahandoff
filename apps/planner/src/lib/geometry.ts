import type { PlannerModule } from "./types";

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
