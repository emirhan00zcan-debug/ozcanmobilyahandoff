import type { Rect } from "./geometry";
import type { Point, Wall } from "./types";

// Ekran-pikseli cinsinden sabit bir hedefleme eşiği (§3.3) — mm karşılığı
// çağıran taraftan (zoom seviyesine göre) hesaplanıp geçirilir. Faz 0'da
// zoom henüz yok, bu yüzden sabit bir mm değeriyle başlıyoruz.
export const DEFAULT_SNAP_THRESHOLD_MM = 15;

// Nokta-poligon testi (tek-çift kuralı / ray casting). `vertices` kapalı bir
// döngü olarak ele alınır (son nokta ilkine dolanır).
function pointInPolygon(point: Point, vertices: Point[]): boolean {
  let inside = false;
  for (let i = 0, j = vertices.length - 1; i < vertices.length; j = i++) {
    const vi = vertices[i];
    const vj = vertices[j];
    const crosses = vi.y > point.y !== vj.y > point.y;
    if (crosses && point.x < ((vj.x - vi.x) * (point.y - vi.y)) / (vj.y - vi.y) + vi.x) {
      inside = !inside;
    }
  }
  return inside;
}

// Bir duvar segmentinin "iç yüzü"nün hangi tarafta olduğunu belirler. Global
// bir merkez noktasına (centroid) göre karar vermek dışbükey/simetrik odalarda
// işe yarar ama L/T gibi içbükey biçimlerde merkez, bir duvarın yanlış
// tarafında kalabilir. Bunun yerine duvarın ortasından her iki normal yönde
// 1mm'lik bir "yoklama" noktası çıkarılıp hangisi poligonun içindeyse o taraf
// iç mekan kabul edilir — herhangi bir basit rektilineer poligon için doğru
// sonucu garanti eder.
function inwardSign(wall: Wall, polygon: Point[], axis: "x" | "y"): 1 | -1 {
  const midX = (wall.start.x + wall.end.x) / 2;
  const midY = (wall.start.y + wall.end.y) / 2;
  const probe: Point = axis === "y" ? { x: midX, y: midY + 1 } : { x: midX + 1, y: midY };
  return pointInPolygon(probe, polygon) ? 1 : -1;
}

// Serbest çizilmiş, rektilineer (yalnızca dik açılı) bir duvar poligonuna göre
// duvar-snap'i (§3.3). Yalnızca modülün o duvar boyunca gerçekten örtüştüğü
// (dolayısıyla "karşısında" olduğu) duvarlar aday sayılır.
export function snapToWalls(rect: Rect, walls: Wall[], thresholdMm = DEFAULT_SNAP_THRESHOLD_MM): Rect {
  if (walls.length === 0) return rect;
  const polygon = walls.map((w) => w.start);
  let { x, y } = rect;

  for (const wall of walls) {
    const isHorizontal = wall.start.y === wall.end.y;
    const isVertical = wall.start.x === wall.end.x;
    if (!isHorizontal && !isVertical) continue; // yalnızca dik açılı duvarlar destekleniyor

    if (isHorizontal) {
      const spanMin = Math.min(wall.start.x, wall.end.x);
      const spanMax = Math.max(wall.start.x, wall.end.x);
      const overlapsSpan = rect.x < spanMax && rect.x + rect.w > spanMin;
      if (!overlapsSpan) continue;

      const sign = inwardSign(wall, polygon, "y"); // +1: iç mekan aşağıda, -1: yukarıda
      const innerFaceY = wall.start.y + sign * wall.thicknessMm;
      const moduleEdge = sign > 0 ? rect.y : rect.y + rect.h;
      if (Math.abs(moduleEdge - innerFaceY) < thresholdMm) {
        y = sign > 0 ? innerFaceY : innerFaceY - rect.h;
      }
    } else {
      const spanMin = Math.min(wall.start.y, wall.end.y);
      const spanMax = Math.max(wall.start.y, wall.end.y);
      const overlapsSpan = rect.y < spanMax && rect.y + rect.h > spanMin;
      if (!overlapsSpan) continue;

      const sign = inwardSign(wall, polygon, "x"); // +1: iç mekan sağda, -1: solda
      const innerFaceX = wall.start.x + sign * wall.thicknessMm;
      const moduleEdge = sign > 0 ? rect.x : rect.x + rect.w;
      if (Math.abs(moduleEdge - innerFaceX) < thresholdMm) {
        x = sign > 0 ? innerFaceX : innerFaceX - rect.w;
      }
    }
  }

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
