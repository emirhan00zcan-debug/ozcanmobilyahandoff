import { create } from "zustand";
import { hasCollision, moduleFootprint, type Rect } from "./geometry";
import { snapToWalls } from "./snap";
import type { PlannerModule, Room } from "./types";

const DEFAULT_ROOM: Room = {
  id: "demo-room",
  dimensionsMm: { width: 3600, depth: 4200, height: 2500 },
  walls: [
    { id: "w-top", start: { x: 0, y: 0 }, end: { x: 3600, y: 0 }, thicknessMm: 100 },
    { id: "w-right", start: { x: 3600, y: 0 }, end: { x: 3600, y: 4200 }, thicknessMm: 100 },
    { id: "w-bottom", start: { x: 3600, y: 4200 }, end: { x: 0, y: 4200 }, thicknessMm: 100 },
    { id: "w-left", start: { x: 0, y: 4200 }, end: { x: 0, y: 0 }, thicknessMm: 100 },
  ],
};

interface PlannerState {
  room: Room;
  modules: PlannerModule[];
  selectedModuleId: string | null;
  addModule: (m: PlannerModule) => void;
  selectModule: (id: string | null) => void;
  moveModule: (id: string, x: number, y: number) => void;
}

export const usePlannerStore = create<PlannerState>((set, get) => ({
  room: DEFAULT_ROOM,
  modules: [],
  selectedModuleId: null,

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
    const snapped = snapToWalls(desired, room);

    if (hasCollision(snapped, others)) return;

    set({
      modules: modules.map((m) =>
        m.id === id ? { ...m, position: { ...m.position, x: snapped.x, y: snapped.y } } : m,
      ),
    });
  },
}));
