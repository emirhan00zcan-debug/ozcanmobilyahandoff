import productAnchors from "../config/productAnchors.json";
import { moduleFootprint } from "./geometry";
import type { Point, PlannerModule, RotationDeg } from "./types";

// Faz 4 "akıllı montaj noktaları": DB şemasında henüz bir anchor/panel-joint
// alanı yok (kök uygulamanın Product/VariationOption modelleri de dahil) ve
// bu sandbox'tan migration uygulanamıyor — Faz 3'teki PlannerDesign tablosuyla
// aynı engel. Bu yüzden ürün-anchor eşlemesi geçici olarak yerel bir JSON
// dosyasında tutuluyor (productId -> Anchor[]); DB izinleri açıldığında bu
// dosyanın içeriği doğrudan yeni bir tabloya taşınabilir, kod tarafında
// yalnızca `getAnchors` içindeki kaynak değişir.
//
// productId anahtarı SKU değil — SKU (ProductVariation.sku) renk/varyasyon
// bazlı, montaj noktaları ise fiziksel ürün geometrisine ait ve tüm
// varyasyonlarda aynı; bu yüzden bu kod tabanında her yerde kullanılan
// üst-düzey ürün kimliği (CatalogProduct.productId / PlannerModule.productId)
// anahtar olarak seçildi.
//
// position/rotation Three.js ekseniyle tutarlı [x, y(dikey), z(derinlik)]
// sırasıyla, MERKEZ-göreli (Scene3D.tsx'in modül mesh'lerini merkezden
// konumlandırmasıyla aynı kural) — ama bu dosyanın geri kalanının aksine
// (bkz. types.ts) METRE değil TAM SAYI MİLİMETRE: tek bir dosyada iki birim
// sistemi taşımak yerine, kod tabanının tamamındaki "kaynak veri her zaman
// mm'dir" kuralına uyuluyor.
export interface Anchor {
  id: string;
  type: string;
  position: [number, number, number];
  // Şimdilik yalnızca saklanıyor — v1 eşleşmesi yalnızca `type`'a bakıyor.
  // Gelecekte "iki anchor yalnızca ters yöne bakıyorsa eşleşir" gibi bir yön
  // uyumluluğu kontrolü eklenmek istenirse buraya girilecek veri hazır olur.
  rotation: [number, number, number];
}

// JSON'dan gelen dizi tipleri TS tarafından geniş `number[]` olarak çıkarımlanır
// (sabit uzunluklu tuple değil) — `unknown` üzerinden iddialı bir dönüşüm
// gerekiyor. Veri kaynağı bu dosyanın kendisi olduğundan (kullanıcı girdisi
// değil) şema doğrulaması eklemek gerekmiyor.
const ANCHORS_BY_PRODUCT = productAnchors as unknown as Record<string, Anchor[]>;

export function getAnchors(productId: string): Anchor[] {
  return ANCHORS_BY_PRODUCT[productId] ?? [];
}

// Yerel (modülün döndürülmemiş hâlindeki) bir [x,z] ofsetini, modülün
// rotationDeg'ine göre oda düzlemine çevirir. Kod tabanının başka hiçbir
// yerinde gerçek bir rotasyon matrisi yok — moduleFootprint rotasyonu yalnızca
// w/h takasıyla (AABB için) ele alıyor (bkz. geometry.ts) çünkü yön o hesap
// için önemsiz. Anchor'larda yön ÖNEMLİ (bir "sol" bağlantı noktası
// döndürülünce gerçekten başka bir kenara gitmeli), bu yüzden bu, kasıtlı
// olarak gerçek trigonometri gerektiren tek yer. Yön kuralı keyfi ama
// tutarlı: 90° saat yönünün tersi.
function rotateLocal(x: number, z: number, rotationDeg: RotationDeg): Point {
  switch (rotationDeg) {
    case 0:
      return { x, y: z };
    case 90:
      return { x: -z, y: x };
    case 180:
      return { x: -x, y: -z };
    case 270:
      return { x: z, y: -x };
  }
}

// Bir anchor'ın oda-mm koordinatındaki mutlak konumu. `moduleFootprint` zaten
// geçerli rotasyona göre doğru genişlik/derinliği verdiği için merkez, o
// footprint'ten hesaplanır (bkz. rotateModule: rotasyon değişince sol-üst
// köşe sabit kalır, bu yüzden merkez rotasyona bağlıdır — burada her zaman
// "şu anki" merkez kullanılıyor, iki rotasyon arasında süreklilik varsayılmıyor).
export function anchorWorldPosition(mod: PlannerModule, anchor: Anchor): Point {
  const fp = moduleFootprint(mod);
  const centerX = fp.x + fp.w / 2;
  const centerY = fp.y + fp.h / 2;
  const [localX, , localZ] = anchor.position;
  const rotated = rotateLocal(localX, localZ, mod.rotationDeg);
  return { x: centerX + rotated.x, y: centerY + rotated.y };
}
