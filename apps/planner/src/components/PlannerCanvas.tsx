import { useCallback, useEffect, useRef } from "react";
import { moduleFootprint } from "../lib/geometry";
import { usePlannerStore } from "../lib/store";

const SCALE = 0.15; // px / mm
const MARGIN = 40; // px

export function PlannerCanvas() {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const dragRef = useRef<{ id: string; offsetX: number; offsetY: number } | null>(null);

  const room = usePlannerStore((s) => s.room);
  const modules = usePlannerStore((s) => s.modules);
  const selectedModuleId = usePlannerStore((s) => s.selectedModuleId);
  const selectModule = usePlannerStore((s) => s.selectModule);
  const moveModule = usePlannerStore((s) => s.moveModule);

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
    for (const wall of room.walls) {
      ctx.lineWidth = wall.thicknessMm * SCALE;
      ctx.beginPath();
      ctx.moveTo(toPx(wall.start.x), toPx(wall.start.y));
      ctx.lineTo(toPx(wall.end.x), toPx(wall.end.y));
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
  }, [room, modules, selectedModuleId, toPx, width, height]);

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

  const pointerToMm = (e: React.PointerEvent<HTMLCanvasElement>) => {
    const rect = canvasRef.current!.getBoundingClientRect();
    return { x: toMm(e.clientX - rect.left), y: toMm(e.clientY - rect.top) };
  };

  const handlePointerDown = (e: React.PointerEvent<HTMLCanvasElement>) => {
    const { x: mmX, y: mmY } = pointerToMm(e);
    const hit = findModuleAt(mmX, mmY);
    selectModule(hit ? hit.id : null);
    if (hit) {
      dragRef.current = { id: hit.id, offsetX: mmX - hit.position.x, offsetY: mmY - hit.position.y };
      canvasRef.current!.setPointerCapture(e.pointerId);
    }
  };

  const handlePointerMove = (e: React.PointerEvent<HTMLCanvasElement>) => {
    const drag = dragRef.current;
    if (!drag) return;
    const { x: mmX, y: mmY } = pointerToMm(e);
    moveModule(drag.id, mmX - drag.offsetX, mmY - drag.offsetY);
  };

  const handlePointerUp = () => {
    dragRef.current = null;
  };

  return (
    <canvas
      ref={canvasRef}
      width={width}
      height={height}
      style={{ touchAction: "none", background: "#eef2f0", border: "1px solid #c6d0cb", display: "block" }}
      onPointerDown={handlePointerDown}
      onPointerMove={handlePointerMove}
      onPointerUp={handlePointerUp}
      onPointerLeave={handlePointerUp}
    />
  );
}
