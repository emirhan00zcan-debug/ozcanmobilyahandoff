import { create } from "zustand";
import { autoPlaceProducts } from "./autoLayout";
import type { CatalogProduct } from "./catalog";
import { hasCollision, moduleFootprint, type Rect } from "./geometry";
import { closestPointOnWall, findOpeningAt, findWallAt, wallLength } from "./openings";
import { snapToNeighbors, snapToWalls } from "./snap";
import type { Opening, OpeningType, Point, PlannerModule, Room, RotationDeg, Wall } from "./types";

const WALL_THICKNESS_MM = 100;

const OPENING_DEFAULTS: Record<OpeningType, { widthMm: number; heightMm: number; sillHeightMm: number }> = {
  door: { widthMm: 900, heightMm: 2100, sillHeightMm: 0 },
  window: { widthMm: 1200, heightMm: 1200, sillHeightMm: 900 },
};

const DEFAULT_ROOM: Room = {
  id: "demo-room",
  dimensionsMm: { width: 3600, depth: 4200, height: 2500 },
  walls: [
    { id: "w-top", start: { x: 0, y: 0 }, end: { x: 3600, y: 0 }, thicknessMm: WALL_THICKNESS_MM },
    { id: "w-right", start: { x: 3600, y: 0 }, end: { x: 3600, y: 4200 }, thicknessMm: WALL_THICKNESS_MM },
    { id: "w-bottom", start: { x: 3600, y: 4200 }, end: { x: 0, y: 4200 }, thicknessMm: WALL_THICKNESS_MM },
    { id: "w-left", start: { x: 0, y: 4200 }, end: { x: 0, y: 0 }, thicknessMm: WALL_THICKNESS_MM },
  ],
  openings: [],
};

export interface MoveResult {
  x: number;
  y: number;
  blocked: boolean;
  snapTarget: "wall" | "neighbor" | null;
  // Kullanıcının bırakmaya çalıştığı, snap/çakışma öncesi ham mm konumu —
  // engellendiğinde çakışma uyarı arayüzünün (§Faz 4) "buraya koymaya
  // çalıştın ama olmuyor" hayalet dikdörtgenini çizebilmesi için.
  attemptedX: number;
  attemptedY: number;
}

interface PlannerState {
  room: Room;
  modules: PlannerModule[];
  selectedModuleIds: string[];
  addModule: (m: PlannerModule) => void;
  addModuleFromCatalog: (product: CatalogProduct) => void;
  autoArrangeProducts: (products: CatalogProduct[]) => { placedCount: number; unplacedCount: number };
  selectModule: (id: string | null) => void;
  toggleSelectModule: (id: string) => void;
  moveModule: (id: string, x: number, y: number, snapThresholdMm?: number) => MoveResult | null;
  // Birden fazla modül seçiliyken (§Faz 4 grup taşıma) herhangi birini (anchorId)
  // sürüklemek tüm grubu aynı delta kadar katı bir cisim gibi kaydırır.
  moveModuleGroup: (anchorId: string, x: number, y: number, snapThresholdMm?: number) => MoveResult | null;
  // true: konum uygulandı. false: çarpışma nedeniyle reddedildi (§Faz 4 çakışma uyarısı bunu kullanır).
  setModulePosition: (id: string, x: number, y: number) => boolean;
  rotateModule: (id: string) => void;

  drawMode: boolean;
  draftPoints: Point[];
  toggleDrawMode: () => void;
  addDraftPoint: (p: Point) => void;
  finishRoom: () => void;
  cancelDraft: () => void;

  openingMode: OpeningType | null;
  toggleOpeningMode: (type: OpeningType) => void;
  placeOrRemoveOpening: (point: Point) => void;
}

export const usePlannerStore = create<PlannerState>((set, get) => ({
  room: DEFAULT_ROOM,
  modules: [],
  selectedModuleIds: [],
  drawMode: false,
  draftPoints: [],
  openingMode: null,

  addModule: (m) => set((s) => ({ modules: [...s.modules, m] })),

  // Kütüphaneden "Ekle" — çakışmayı kesin bir kısıt olarak korumak için
  // (§3.4) varsayılan konumdan başlayıp boş bir yer bulana kadar 50mm'lik
  // adımlarla çapraz kaydırır (çoklu ekleme yığılmasın diye).
  addModuleFromCatalog: (product) => {
    const { modules } = get();
    const others = modules.map(moduleFootprint);
    const { w, d } = product.dimensionsMm;

    let pos = { x: 150, y: 150 };
    for (let i = 0; i < 40 && hasCollision({ ...pos, w, h: d }, others); i++) {
      pos = { x: pos.x + 50, y: pos.y + 50 };
    }

    const newModule: PlannerModule = {
      id: crypto.randomUUID(),
      productId: product.productId,
      productVariationId: product.variations[0]?.id ?? null,
      position: { x: pos.x, y: pos.y, z: 0 },
      rotationDeg: 0,
      dimensionsMm: product.dimensionsMm,
      meta: { name: product.name, colorHex: product.variations[0]?.hexColor ?? null },
    };
    set({ modules: [...modules, newModule] });
  },

  // Seçili katalog ürünlerini boş duvarlara otomatik yerleştirir (bkz.
  // autoLayout.ts) — deterministik geometri, üretken/görsel AI değil.
  autoArrangeProducts: (products) => {
    const { room, modules } = get();
    const { placed, unplaced } = autoPlaceProducts(room, modules, products);
    if (placed.length > 0) set({ modules: [...modules, ...placed] });
    return { placedCount: placed.length, unplacedCount: unplaced.length };
  },

  selectModule: (id) => set({ selectedModuleIds: id ? [id] : [] }),

  // Shift+tık: tekli seçimi bozmadan bir modülü seçime ekler/çıkarır (§Faz 4
  // grup taşıma) — mevcut tek-tık davranışı (selectModule) değişmeden kalır.
  toggleSelectModule: (id) =>
    set((s) => ({
      selectedModuleIds: s.selectedModuleIds.includes(id)
        ? s.selectedModuleIds.filter((x) => x !== id)
        : [...s.selectedModuleIds, id],
    })),

  // Snap bir öneridir, çarpışma ise kesin bir kısıttır: kilitlenmiş konum
  // başka bir modülle çakışıyorsa taşıma tamamen reddedilir (§3.4). Eşik,
  // zoom seviyesine göre çağıran taraftan (PlannerCanvas, ekran-pikseli
  // sabit ≈8px karşılığı) geçirilir (§3.3); verilmezse varsayılan mm kullanılır.
  // Dönüş değeri, sürükleme büyüteci (§4.2) için canlı mm/snap-hedefi bilgisini taşır.
  moveModule: (id, x, y, snapThresholdMm) => {
    const { room, modules } = get();
    const target = modules.find((m) => m.id === id);
    if (!target) return null;

    // Gerçek kaynak veri her zaman tam sayı mm'dir (bkz. types.ts) — pointer'dan
    // gelen px/scale bölmesi ondalıklı değer üretir, burada kesin olarak tamsayıya
    // yuvarlanır (ör. "503,3190571mm" gibi göstergelerin nedeni buradaki yuvarlamanın
    // eksik olmasıydı).
    x = Math.round(x);
    y = Math.round(y);

    const others = modules.filter((m) => m.id !== id).map(moduleFootprint);
    const desired: Rect = { ...moduleFootprint(target), x, y };
    const afterWallSnap = snapToWalls(desired, room.walls, snapThresholdMm);
    const snapped = snapToNeighbors(afterWallSnap, others, snapThresholdMm);
    const blocked = hasCollision(snapped, others);

    if (!blocked) {
      set({
        modules: modules.map((m) =>
          m.id === id ? { ...m, position: { ...m.position, x: snapped.x, y: snapped.y } } : m,
        ),
      });
    }

    const wallSnapped = afterWallSnap.x !== desired.x || afterWallSnap.y !== desired.y;
    const neighborSnapped = snapped.x !== afterWallSnap.x || snapped.y !== afterWallSnap.y;

    return {
      blocked,
      x: blocked ? target.position.x : snapped.x,
      y: blocked ? target.position.y : snapped.y,
      snapTarget: blocked ? null : neighborSnapped ? "neighbor" : wallSnapped ? "wall" : null,
      attemptedX: x,
      attemptedY: y,
    };
  },

  // Grup taşıma (§Faz 4): birden fazla modül seçiliyse, herhangi birini
  // (anchor) sürüklemek tüm grubu aynı miktar (delta) kaydırır — göreli
  // yerleşim korunur. Snap yalnızca anchor'a uygulanır (grup üyelerine karşı
  // değil, aksi halde grup kendi kendine tuhaf şekilde yapışır); sonuçtaki
  // delta tüm üyelere aynen uygulanır. Çarpışma testi grup-dışı her modüle
  // karşı ayrı ayrı ama atomik yapılır — biri bile çakışırsa TÜM grup
  // reddedilir, kısmi taşıma yok (moveModule'daki "çarpışma kesin bir
  // kısıttır" ilkesiyle aynı, §3.4).
  moveModuleGroup: (anchorId, x, y, snapThresholdMm) => {
    const { room, modules, selectedModuleIds } = get();
    const anchor = modules.find((m) => m.id === anchorId);
    if (!anchor) return null;

    x = Math.round(x);
    y = Math.round(y);

    const groupIds = new Set(selectedModuleIds.includes(anchorId) ? selectedModuleIds : [anchorId]);
    const others = modules.filter((m) => !groupIds.has(m.id)).map(moduleFootprint);

    const desired: Rect = { ...moduleFootprint(anchor), x, y };
    const afterWallSnap = snapToWalls(desired, room.walls, snapThresholdMm);
    const snapped = snapToNeighbors(afterWallSnap, others, snapThresholdMm);

    const dx = snapped.x - anchor.position.x;
    const dy = snapped.y - anchor.position.y;

    const groupMembers = modules.filter((m) => groupIds.has(m.id));
    const translated = groupMembers.map((m) => {
      const fp = moduleFootprint(m);
      return { ...fp, x: fp.x + dx, y: fp.y + dy };
    });
    const blocked = translated.some((rect) => hasCollision(rect, others));

    if (!blocked && (dx !== 0 || dy !== 0)) {
      set({
        modules: modules.map((m) =>
          groupIds.has(m.id) ? { ...m, position: { ...m.position, x: m.position.x + dx, y: m.position.y + dy } } : m,
        ),
      });
    }

    const wallSnapped = afterWallSnap.x !== desired.x || afterWallSnap.y !== desired.y;
    const neighborSnapped = snapped.x !== afterWallSnap.x || snapped.y !== afterWallSnap.y;

    return {
      blocked,
      x: blocked ? anchor.position.x : anchor.position.x + dx,
      y: blocked ? anchor.position.y : anchor.position.y + dy,
      snapTarget: blocked ? null : neighborSnapped ? "neighbor" : wallSnapped ? "wall" : null,
      attemptedX: x,
      attemptedY: y,
    };
  },

  // Sayısal panelden gelen giriş kesin bir komuttur — snap uygulanmaz (§3.4),
  // yalnızca çarpışma hâlâ ihlal edilemez bir fiziksel kısıttır. Dönüş değeri
  // arayüzün (ModuleInspector) reddi kullanıcıya göstermesini sağlar — önceden
  // sessizce yok sayılıyordu.
  setModulePosition: (id, x, y) => {
    x = Math.round(x);
    y = Math.round(y);

    const { modules } = get();
    const target = modules.find((m) => m.id === id);
    if (!target) return false;

    const others = modules.filter((m) => m.id !== id).map(moduleFootprint);
    const rect: Rect = { ...moduleFootprint(target), x, y };
    if (hasCollision(rect, others)) return false;

    set({
      modules: modules.map((m) => (m.id === id ? { ...m, position: { ...m.position, x, y } } : m)),
    });
    return true;
  },

  rotateModule: (id) => {
    const { modules } = get();
    const target = modules.find((m) => m.id === id);
    if (!target) return;

    const nextRotation = (((target.rotationDeg + 90) % 360) as RotationDeg);
    const rotated = { ...target, rotationDeg: nextRotation };
    const others = modules.filter((m) => m.id !== id).map(moduleFootprint);
    if (hasCollision(moduleFootprint(rotated), others)) return;

    set({ modules: modules.map((m) => (m.id === id ? rotated : m)) });
  },

  toggleDrawMode: () => set((s) => ({ drawMode: !s.drawMode, draftPoints: [] })),

  addDraftPoint: (p) => set((s) => ({ draftPoints: [...s.draftPoints, p] })),

  cancelDraft: () => set({ drawMode: false, draftPoints: [] }),

  // Taslak noktaları kapalı bir poligona (son nokta -> ilk nokta) çevirir ve
  // duvarları oluşturur. Poligon (0,0)'a normalize edilir — mm koordinat
  // sisteminin her yerde odanın sol-üst köşesinden başladığı varsayımı
  // (modül snap'i, canvas boyutlandırması) böylece korunur. Yeni oda eski
  // modüllerle uyumsuz olabileceğinden (farklı boyut/şekil) sahne temizlenir.
  finishRoom: () => {
    const { draftPoints } = get();
    if (draftPoints.length < 3) return;

    const minX = Math.min(...draftPoints.map((p) => p.x));
    const minY = Math.min(...draftPoints.map((p) => p.y));
    const normalized = draftPoints.map((p) => ({ x: p.x - minX, y: p.y - minY }));
    const closedLoop = [...normalized, normalized[0]];

    const walls: Wall[] = closedLoop.slice(0, -1).map((start, i) => ({
      id: `wall-${i}`,
      start,
      end: closedLoop[i + 1],
      thicknessMm: WALL_THICKNESS_MM,
    }));

    const maxX = Math.max(...normalized.map((p) => p.x));
    const maxY = Math.max(...normalized.map((p) => p.y));

    set({
      room: { id: "custom-room", dimensionsMm: { width: maxX, depth: maxY, height: 2500 }, walls, openings: [] },
      modules: [],
      selectedModuleIds: [],
      drawMode: false,
      draftPoints: [],
    });
  },

  toggleOpeningMode: (type) => set((s) => ({ openingMode: s.openingMode === type ? null : type })),

  // Mevcut bir açıklığa tıklanırsa kaldırır; boş bir duvara tıklanırsa aktif
  // moda (kapı/pencere) göre varsayılan ölçülerle, tıklanan noktayı ortalayacak
  // şekilde yeni bir açıklık ekler. Duvarın uzunluğunu aşmayacak şekilde kenarlara
  // kelepçelenir.
  placeOrRemoveOpening: (point) => {
    const { room, openingMode } = get();
    if (!openingMode) return;

    const existing = findOpeningAt(point, room, 150);
    if (existing) {
      set({ room: { ...room, openings: room.openings.filter((o) => o.id !== existing.id) } });
      return;
    }

    const wall = findWallAt(point, room.walls, 150);
    if (!wall) return;

    const defaults = OPENING_DEFAULTS[openingMode];
    const wallLen = wallLength(wall);
    const { t } = closestPointOnWall(point, wall);
    const rawOffset = t * wallLen - defaults.widthMm / 2;
    const offsetMm = Math.round(Math.max(0, Math.min(wallLen - defaults.widthMm, rawOffset)));

    const opening: Opening = { id: crypto.randomUUID(), wallId: wall.id, type: openingMode, offsetMm, ...defaults };
    set({ room: { ...room, openings: [...room.openings, opening] } });
  },
}));
