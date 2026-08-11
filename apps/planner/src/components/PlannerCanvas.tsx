import { useCallback, useEffect, useRef, useState } from "react";
import { moduleFootprint, orthoLock, snapToGrid } from "../lib/geometry";
import { usePlannerStore } from "../lib/store";
import type { Point } from "../lib/types";

const SCALE = 0.15; // px / mm
const MARGIN = 40; // px
const CANVAS_BG = "#eef2f0";

function nextDraftPoint(raw: Point, points: Point[]): Point {
  if (points.length === 0) return snapToGrid(raw);
  return snapToGrid(orthoLock(points[points.length - 1], raw));
}

export function PlannerCanvas() {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const dragRef = useRef<{ id: string; offsetX: number; offsetY: number } | null>(null);
  const [cursorMm, setCursorMm] = useState<Point | null>(null);

  const room = usePlannerStore((s) => s.room);
  const modules = usePlannerStore((s) => s.modules);
  const selectedModuleId = usePlannerStore((s) => s.selectedModuleId);
  const selectModule = usePlannerStore((s) => s.selectModule);
  const moveModule = usePlannerStore((s) => s.moveModule);
  const drawMode = usePlannerStore((s) => s.drawMode);
  const draftPoints = usePlannerStore((s) => s.draftPoints);
  const addDraftPoint = usePlannerStore((s) => s.addDraftPoint);
  const openingMode = usePlannerStore((s) => s.openingMode);
  const placeOrRemoveOpening = usePlannerStore((s) => s.placeOrRemoveOpening);

  const width = room.dimensionsMm.width * SCALE + MARGIN * 2;
  const height = room.dimensionsMm.depth * SCALE + MARGIN * 2;

  const toPx = useCallback((mm: number) => mm * SCALE + MARGIN, []);
  const toMm = useCallback((px: number) => (px - MARGIN) / SCALE, []);

  // Sürekli render döngüsü yok — yalnızca durum değiştiğinde yeniden çizilir
  // (§2.3): "60 FPS" hedefi etkileşim tepkisi anlamına gelir, boşta sürekli
  // render anlamına gelmez.
  useEffect(() => {
    const canvas = canvasRef.current;
    const ctx = canvas?.getContext("2d");
    if (!canvas || !ctx) return;

    ctx.clearRect(0, 0, canvas.width, canvas.height);

    ctx.strokeStyle = "#8a938e";
    ctx.lineJoin = "round";
    for (const wall of room.walls) {
      ctx.lineWidth = wall.thicknessMm * SCALE;
      ctx.beginPath();
      ctx.moveTo(toPx(wall.start.x), toPx(wall.start.y));
      ctx.lineTo(toPx(wall.end.x), toPx(wall.end.y));
      ctx.stroke();
    }

    // Kapı/pencere: önce duvarı arka plan rengiyle "keser", sonra tipe göre
    // renkli bir çizgiyle işaretler. Basit ama etkili — duvarları açıklığa göre
    // ayrı segmentlere bölmeye gerek kalmıyor.
    for (const opening of room.openings) {
      const wall = room.walls.find((w) => w.id === opening.wallId);
      if (!wall) continue;
      const len = Math.hypot(wall.end.x - wall.start.x, wall.end.y - wall.start.y) || 1;
      const ux = (wall.end.x - wall.start.x) / len;
      const uy = (wall.end.y - wall.start.y) / len;
      const p1 = { x: wall.start.x + ux * opening.offsetMm, y: wall.start.y + uy * opening.offsetMm };
      const p2 = {
        x: wall.start.x + ux * (opening.offsetMm + opening.widthMm),
        y: wall.start.y + uy * (opening.offsetMm + opening.widthMm),
      };

      ctx.strokeStyle = CANVAS_BG;
      ctx.lineWidth = wall.thicknessMm * SCALE;
      ctx.beginPath();
      ctx.moveTo(toPx(p1.x), toPx(p1.y));
      ctx.lineTo(toPx(p2.x), toPx(p2.y));
      ctx.stroke();

      ctx.strokeStyle = opening.type === "door" ? "#a84e29" : "#1f5ca6";
      ctx.lineWidth = Math.max(2, wall.thicknessMm * SCALE * 0.4);
      ctx.beginPath();
      ctx.moveTo(toPx(p1.x), toPx(p1.y));
      ctx.lineTo(toPx(p2.x), toPx(p2.y));
      ctx.stroke();
    }

    for (const mod of modules) {
      const rect = moduleFootprint(mod);
      const x = toPx(rect.x);
      const y = toPx(rect.y);
      const w = rect.w * SCALE;
      const h = rect.h * SCALE;
      const selected = mod.id === selectedModuleId;

      ctx.fillStyle = mod.meta.colorHex ?? "#c9d2cf";
      ctx.fillRect(x, y, w, h);
      ctx.strokeStyle = selected ? "#1f5ca6" : "#4b5854";
      ctx.lineWidth = selected ? 2 : 1;
      ctx.strokeRect(x, y, w, h);

      ctx.fillStyle = "#12201c";
      ctx.font = "11px monospace";
      ctx.fillText(`${rect.w}×${rect.h} mm`, x + 6, y + 16);
      ctx.fillText(mod.meta.name, x + 6, y + h - 8);
    }

    if (drawMode && draftPoints.length > 0) {
      ctx.strokeStyle = "#1f5ca6";
      ctx.lineWidth = 2;
      ctx.setLineDash([5, 4]);
      ctx.beginPath();
      ctx.moveTo(toPx(draftPoints[0].x), toPx(draftPoints[0].y));
      for (const p of draftPoints.slice(1)) ctx.lineTo(toPx(p.x), toPx(p.y));
      if (cursorMm) ctx.lineTo(toPx(cursorMm.x), toPx(cursorMm.y));
      ctx.stroke();
      ctx.setLineDash([]);

      ctx.fillStyle = "#1f5ca6";
      for (const p of draftPoints) {
        ctx.beginPath();
        ctx.arc(toPx(p.x), toPx(p.y), 4, 0, Math.PI * 2);
        ctx.fill();
      }
    }
  }, [room, modules, selectedModuleId, drawMode, draftPoints, cursorMm, toPx, width, height]);

  const findModuleAt = useCallback(
    (mmX: number, mmY: number) => {
      for (let i = modules.length - 1; i >= 0; i--) {
        const rect = moduleFootprint(modules[i]);
        if (mmX >= rect.x && mmX <= rect.x + rect.w && mmY >= rect.y && mmY <= rect.y + rect.h) {
          return modules[i];
        }
      }
      return null;
    },
    [modules],
  );

  const pointerToMm = (e: React.PointerEvent<HTMLCanvasElement>): Point => {
    const rect = canvasRef.current!.getBoundingClientRect();
    return { x: toMm(e.clientX - rect.left), y: toMm(e.clientY - rect.top) };
  };

  const handlePointerDown = (e: React.PointerEvent<HTMLCanvasElement>) => {
    const raw = pointerToMm(e);

    if (drawMode) {
      addDraftPoint(nextDraftPoint(raw, draftPoints));
      return;
    }

    if (openingMode) {
      placeOrRemoveOpening(raw);
      return;
    }

    const hit = findModuleAt(raw.x, raw.y);
    selectModule(hit ? hit.id : null);
    if (hit) {
      dragRef.current = { id: hit.id, offsetX: raw.x - hit.position.x, offsetY: raw.y - hit.position.y };
      canvasRef.current!.setPointerCapture(e.pointerId);
    }
  };

  const handlePointerMove = (e: React.PointerEvent<HTMLCanvasElement>) => {
    const raw = pointerToMm(e);

    if (drawMode) {
      setCursorMm(nextDraftPoint(raw, draftPoints));
      return;
    }

    const drag = dragRef.current;
    if (!drag) return;
    moveModule(drag.id, raw.x - drag.offsetX, raw.y - drag.offsetY);
  };

  const handlePointerUp = () => {
    dragRef.current = null;
  };

  return (
    <canvas
      ref={canvasRef}
      width={width}
      height={height}
      style={{
        touchAction: "none",
        background: CANVAS_BG,
        border: "1px solid #c6d0cb",
        display: "block",
        cursor: drawMode || openingMode ? "crosshair" : "default",
      }}
      onPointerDown={handlePointerDown}
      onPointerMove={handlePointerMove}
      onPointerUp={handlePointerUp}
      onPointerLeave={handlePointerUp}
    />
  );
}
