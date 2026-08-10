import { create } from "zustand";
import { hasCollision, moduleFootprint, type Rect } from "./geometry";
import { snapToNeighbors, snapToWalls } from "./snap";
import type { Point, PlannerModule, Room, RotationDeg, Wall } from "./types";

const WALL_THICKNESS_MM = 100;

const DEFAULT_ROOM: Room = {
  id: "demo-room",
  dimensionsMm: { width: 3600, depth: 4200, height: 2500 },
  walls: [
    { id: "w-top", start: { x: 0, y: 0 }, end: { x: 3600, y: 0 }, thicknessMm: WALL_THICKNESS_MM },
    { id: "w-right", start: { x: 3600, y: 0 }, end: { x: 3600, y: 4200 }, thicknessMm: WALL_THICKNESS_MM },
    { id: "w-bottom", start: { x: 3600, y: 4200 }, end: { x: 0, y: 4200 }, thicknessMm: WALL_THICKNESS_MM },
    { id: "w-left", start: { x: 0, y: 4200 }, end: { x: 0, y: 0 }, thicknessMm: WALL_THICKNESS_MM },
  ],
};

interface PlannerState {
  room: Room;
  modules: PlannerModule[];
  selectedModuleId: string | null;
  addModule: (m: PlannerModule) => void;
  selectModule: (id: string | null) => void;
  moveModule: (id: string, x: number, y: number) => void;
  setModulePosition: (id: string, x: number, y: number) => void;
  rotateModule: (id: string) => void;

  drawMode: boolean;
  draftPoints: Point[];
  toggleDrawMode: () => void;
  addDraftPoint: (p: Point) => void;
  finishRoom: () => void;
  cancelDraft: () => void;
}

export const usePlannerStore = create<PlannerState>((set, get) => ({
  room: DEFAULT_ROOM,
  modules: [],
  selectedModuleId: null,
  drawMode: false,
  draftPoints: [],

  addModule: (m) => set((s) => ({ modules: [...s.modules, m] })),

  selectModule: (id) => set({ selectedModuleId: id }),

  // Snap bir öneridir, çarpışma ise kesin bir kısıttır: kilitlenmiş konum
  // başka bir modülle çakışıyorsa taşıma tamamen reddedilir (§3.4).
  moveModule: (id, x, y) => {
    const { room, modules } = get();
    const target = modules.find((m) => m.id === id);
    if (!target) return;

    const others = modules.filter((m) => m.id !== id).map(moduleFootprint);
    const desired: Rect = { ...moduleFootprint(target), x, y };
    const snapped = snapToNeighbors(snapToWalls(desired, room.walls), others);

    if (hasCollision(snapped, others)) return;

    set({
      modules: modules.map((m) =>
        m.id === id ? { ...m, position: { ...m.position, x: snapped.x, y: snapped.y } } : m,
      ),
    });
  },

  // Sayısal panelden gelen giriş kesin bir komuttur — snap uygulanmaz (§3.4),
  // yalnızca çarpışma hâlâ ihlal edilemez bir fiziksel kısıttır.
  setModulePosition: (id, x, y) => {
    const { modules } = get();
    const target = modules.find((m) => m.id === id);
    if (!target) return;

    const others = modules.filter((m) => m.id !== id).map(moduleFootprint);
    const rect: Rect = { ...moduleFootprint(target), x, y };
    if (hasCollision(rect, others)) return;

    set({
      modules: modules.map((m) => (m.id === id ? { ...m, position: { ...m.position, x, y } } : m)),
    });
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
      room: { id: "custom-room", dimensionsMm: { width: maxX, depth: maxY, height: 2500 }, walls },
      modules: [],
      selectedModuleId: null,
      drawMode: false,
      draftPoints: [],
    });
  },
}));
