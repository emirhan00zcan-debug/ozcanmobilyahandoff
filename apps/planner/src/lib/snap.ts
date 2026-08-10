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
