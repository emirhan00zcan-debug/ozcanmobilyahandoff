import type { Rect } from "./geometry";
import type { Room } from "./types";

// Ekran-pikseli cinsinden sabit bir hedefleme eşiği (§3.3) — mm karşılığı
// çağıran taraftan (zoom seviyesine göre) hesaplanıp geçirilir. Faz 0'da
// zoom henüz yok, bu yüzden sabit bir mm değeriyle başlıyoruz.
export const DEFAULT_SNAP_THRESHOLD_MM = 15;

// Faz 0 kapsamı: oda dikdörtgen bir sınır kutusu olarak ele alınır ve modül
// bu kutunun iç yüzeyine kilitlenir. Serbest biçimli duvar segmentlerine göre
// kenetlenme (keyfi açılı/parçalı duvarlar) Faz 1'in "duvar çizimi" kapsamında.
export function snapToWalls(rect: Rect, room: Room, thresholdMm = DEFAULT_SNAP_THRESHOLD_MM): Rect {
  const wallThickness = room.walls[0]?.thicknessMm ?? 0;

  const left = wallThickness;
  const top = wallThickness;
  const right = room.dimensionsMm.width - wallThickness - rect.w;
  const bottom = room.dimensionsMm.depth - wallThickness - rect.h;

  let { x, y } = rect;
  if (Math.abs(rect.x - left) < thresholdMm) x = left;
  if (Math.abs(rect.x - right) < thresholdMm) x = right;
  if (Math.abs(rect.y - top) < thresholdMm) y = top;
  if (Math.abs(rect.y - bottom) < thresholdMm) y = bottom;

  return { ...rect, x, y };
}

// Modül-modül kenetlenmesi (§3.3): iki modül kenarı eşik altına yaklaşınca
// kenar hizalanır. Yalnızca ilgili eksende "komşu" sayılacak kadar örtüşen
// çiftler için uygulanır — aksi halde odanın öbür ucundaki bir modül bile
// hizalama önerisi üretir.
export function snapToNeighbors(rect: Rect, others: Rect[], thresholdMm = DEFAULT_SNAP_THRESHOLD_MM): Rect {
  let { x, y } = rect;

  for (const other of others) {
    const verticallyAdjacent = rect.y < other.y + other.h && rect.y + rect.h > other.y;
    const horizontallyAdjacent = rect.x < other.x + other.w && rect.x + rect.w > other.x;

    if (verticallyAdjacent) {
      if (Math.abs(rect.x + rect.w - other.x) < thresholdMm) x = other.x - rect.w; // sağ kenar -> komşunun sol kenarı
      if (Math.abs(rect.x - (other.x + other.w)) < thresholdMm) x = other.x + other.w; // sol kenar -> komşunun sağ kenarı
    }
    if (horizontallyAdjacent) {
      if (Math.abs(rect.y + rect.h - other.y) < thresholdMm) y = other.y - rect.h; // alt kenar -> komşunun üst kenarı
      if (Math.abs(rect.y - (other.y + other.h)) < thresholdMm) y = other.y + other.h; // üst kenar -> komşunun alt kenarı
    }
  }

  return { ...rect, x, y };
}
