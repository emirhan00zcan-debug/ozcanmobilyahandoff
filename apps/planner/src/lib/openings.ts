import type { Opening, Point, Room, Wall } from "./types";

export function wallLength(wall: Wall): number {
  return Math.hypot(wall.end.x - wall.start.x, wall.end.y - wall.start.y);
}

// Bir noktanın bir duvar SEGMENTİ üzerindeki en yakın izdüşümü — t=0 başlangıç,
// t=1 bitiş (aralık dışına taşarsa duvarın ucuna kenetlenir).
export function closestPointOnWall(point: Point, wall: Wall): { point: Point; t: number; distance: number } {
  const dx = wall.end.x - wall.start.x;
  const dy = wall.end.y - wall.start.y;
  const lengthSq = dx * dx + dy * dy || 1;
  const rawT = ((point.x - wall.start.x) * dx + (point.y - wall.start.y) * dy) / lengthSq;
  const t = Math.max(0, Math.min(1, rawT));
  const closest: Point = { x: wall.start.x + t * dx, y: wall.start.y + t * dy };
  return { point: closest, t, distance: Math.hypot(point.x - closest.x, point.y - closest.y) };
}

// Kapı/pencere yerleştirme tıklamasının hangi duvarı hedeflediğini bulur —
// segmente en yakın (ve tolerans içindeki) duvar kazanır.
export function findWallAt(point: Point, walls: Wall[], toleranceMm: number): Wall | null {
  let best: { wall: Wall; distance: number } | null = null;
  for (const wall of walls) {
    const { distance } = closestPointOnWall(point, wall);
    if (distance <= toleranceMm && (!best || distance < best.distance)) {
      best = { wall, distance };
    }
  }
  return best?.wall ?? null;
}

// Tıklanan noktanın üzerine geldiği mevcut açıklığı (varsa) bulur — "mevcut
// açıklığa tıkla, kaldır" etkileşimi için.
export function findOpeningAt(point: Point, room: Room, toleranceMm: number): Opening | null {
  for (const opening of room.openings) {
    const wall = room.walls.find((w) => w.id === opening.wallId);
    if (!wall) continue;
    const { t, distance } = closestPointOnWall(point, wall);
    if (distance > toleranceMm) continue;
    const offset = t * wallLength(wall);
    if (offset >= opening.offsetMm && offset <= opening.offsetMm + opening.widthMm) {
      return opening;
    }
  }
  return null;
}
