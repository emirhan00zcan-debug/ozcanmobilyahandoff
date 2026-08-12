import { useCallback, useEffect, useRef, useState } from "react";
import { moduleFootprint, orthoLock, snapToGrid } from "../lib/geometry";
import { usePlannerStore } from "../lib/store";
import type { Point, Room } from "../lib/types";

const CANVAS_BG = "#eef1f0";
const FLOOR = "#ffffff";
const WALL = "#7c8884";
const GRID = "rgba(21,33,31,0.07)";
const ACCENT = "#1f5ca6";
const INK = "#15211f";
const FONT_SANS = '-apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif';
const FONT_MONO = '"Cascadia Code", Consolas, "SF Mono", "Roboto Mono", monospace';
const GRID_STEP_MM = 500;
const PADDING = 40; // px — oda ilk sığdırıldığında kenarlarda bırakılan boşluk
const MIN_SCALE = 0.015; // px / mm
const MAX_SCALE = 0.8;
const SNAP_THRESHOLD_PX = 8; // §3.3 — ekran-pikseli cinsinden sabit hedefleme eşiği

// WCAG bağıl parlaklık — modül rengine göre okunur (beyaz/koyu) etiket rengi
// seçmek için (bkz. §UX geri bildirimi: sabit koyu metin koyu renkli
// modüllerde okunmuyordu).
function relativeLuminance(hex: string): number {
  const clean = hex.replace("#", "");
  if (clean.length !== 6) return 1;
  const toLinear = (v: number) => (v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4));
  const r = toLinear(parseInt(clean.slice(0, 2), 16) / 255);
  const g = toLinear(parseInt(clean.slice(2, 4), 16) / 255);
  const b = toLinear(parseInt(clean.slice(4, 6), 16) / 255);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

interface Camera {
  scale: number;
  panX: number;
  panY: number;
}

function fitCamera(room: Room, viewportW: number, viewportH: number): Camera {
  const scaleX = (viewportW - PADDING * 2) / room.dimensionsMm.width;
  const scaleY = (viewportH - PADDING * 2) / room.dimensionsMm.depth;
  const scale = Math.min(scaleX, scaleY, MAX_SCALE);
  const contentW = room.dimensionsMm.width * scale;
  const contentH = room.dimensionsMm.depth * scale;
  return { scale, panX: (viewportW - contentW) / 2, panY: (viewportH - contentH) / 2 };
}

function clamp(v: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, v));
}

function distance(a: Point, b: Point): number {
  return Math.hypot(a.x - b.x, a.y - b.y);
}

function midpoint(a: Point, b: Point): Point {
  return { x: (a.x + b.x) / 2, y: (a.y + b.y) / 2 };
}

function nextDraftPoint(raw: Point, points: Point[]): Point {
  if (points.length === 0) return snapToGrid(raw);
  return snapToGrid(orthoLock(points[points.length - 1], raw));
}

type Gesture =
  | { type: "idle" }
  | { type: "drag-module"; id: string; offsetX: number; offsetY: number }
  | { type: "pan"; startClientX: number; startClientY: number; startPanX: number; startPanY: number }
  | { type: "pinch"; startDistance: number; startScale: number; mmUnderFinger: Point };

interface MagnifierState {
  screenPos: Point;
  mm: Point;
  blocked: boolean;
  snapTarget: "wall" | "neighbor" | null;
}

export function PlannerCanvas() {
  const containerRef = useRef<HTMLDivElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const pointersRef = useRef<Map<number, Point>>(new Map());
  const gestureRef = useRef<Gesture>({ type: "idle" });
  const [cursorMm, setCursorMm] = useState<Point | null>(null);
  const [viewport, setViewport] = useState({ w: 640, h: 480 });
  const [magnifier, setMagnifier] = useState<MagnifierState | null>(null);

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

  const [camera, setCamera] = useState<Camera>(() => fitCamera(room, viewport.w, viewport.h));

  // Kapsayıcı div'in genişliğini izler — canvas mobilde dar viewport'a sığar,
  // masaüstünde büyür (üst sınırla).
  useEffect(() => {
    const el = containerRef.current;
    if (!el) return;
    const ro = new ResizeObserver((entries) => {
      const w = clamp(Math.floor(entries[0].contentRect.width), 280, 760);
      setViewport({ w, h: Math.round(w * 0.72) });
    });
    ro.observe(el);
    return () => ro.disconnect();
  }, []);

  // Oda değiştiğinde (yeni çizim, farklı ölçü) kamerayı odayı ortalayacak
  // şekilde sıfırlar — aksi halde yeni oda eski pan/zoom ile ekran dışında
  // kalabilir. Kasıtlı olarak yalnızca room.id'ye bakılıyor: aynı odaya modül
  // eklemek/taşımak (room referansı da değişse bile) kullanıcının kamerasını
  // sıfırlamamalı, yalnızca odanın TAMAMEN değişmesi (yeni duvar çizimi) sıfırlamalı.
  useEffect(() => {
    setCamera(fitCamera(room, viewport.w, viewport.h));
  }, [room.id, viewport.w, viewport.h]);

  const toPx = useCallback((p: Point): Point => ({ x: p.x * camera.scale + camera.panX, y: p.y * camera.scale + camera.panY }), [camera]);
  // Gerçek kaynak veri her zaman tam sayı mm'dir (bkz. types.ts) — px/scale
  // bölmesi kaçınılmaz olarak ondalıklı üretir, burada kesin yuvarlanır ki
  // sürükleme/tıklamadan doğan HİÇBİR mm değeri ondalıklı sızmasın.
  const toMm = useCallback(
    (p: Point): Point => ({
      x: Math.round((p.x - camera.panX) / camera.scale),
      y: Math.round((p.y - camera.panY) / camera.scale),
    }),
    [camera],
  );

  // Masaüstünde fare tekerleği ile imlecin altındaki mm noktası sabit kalacak
  // şekilde yakınlaştırma. React'in sentetik onWheel'i pasif dinleyici olduğu
  // için preventDefault sessizce yok sayılır — bu yüzden native listener.
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const onWheel = (e: WheelEvent) => {
      e.preventDefault();
      const rect = canvas.getBoundingClientRect();
      const px = { x: e.clientX - rect.left, y: e.clientY - rect.top };
      setCamera((c) => {
        const mmUnderCursor = { x: (px.x - c.panX) / c.scale, y: (px.y - c.panY) / c.scale };
        const zoomFactor = e.deltaY < 0 ? 1.12 : 1 / 1.12;
        const newScale = clamp(c.scale * zoomFactor, MIN_SCALE, MAX_SCALE);
        return { scale: newScale, panX: px.x - mmUnderCursor.x * newScale, panY: px.y - mmUnderCursor.y * newScale };
      });
    };
    canvas.addEventListener("wheel", onWheel, { passive: false });
    return () => canvas.removeEventListener("wheel", onWheel);
  }, []);

  // Sürekli render döngüsü yok — yalnızca durum değiştiğinde yeniden çizilir
  // (§2.3): "60 FPS" hedefi etkileşim tepkisi anlamına gelir, boşta sürekli
  // render anlamına gelmez.
  useEffect(() => {
    const canvas = canvasRef.current;
    const ctx = canvas?.getContext("2d");
    if (!canvas || !ctx) return;

    ctx.clearRect(0, 0, canvas.width, canvas.height);

    // Zemin: dış canvas arka planından ayrışan düz bir yüzey — "içerisi" ile
    // "dışarısı" arasında net bir figür-zemin ayrımı kurar (bkz. §UX geri
    // bildirimi: duvar ve zemin öncesinde aynı tondaydı, oda okunmuyordu).
    const floorPts = room.walls.map((w) => toPx(w.start));
    if (floorPts.length > 0) {
      ctx.beginPath();
      ctx.moveTo(floorPts[0].x, floorPts[0].y);
      for (const p of floorPts.slice(1)) ctx.lineTo(p.x, p.y);
      ctx.closePath();
      ctx.fillStyle = FLOOR;
      ctx.fill();

      // Izgara: yalnızca anlamlı bir yakınlıkta, zemin poligonuna kırpılmış
      // (L-şekilli odalarda da doğru çalışır).
      if (camera.scale * GRID_STEP_MM > 12) {
        ctx.save();
        ctx.clip();
        ctx.strokeStyle = GRID;
        ctx.lineWidth = 1;
        const xs = room.walls.map((w) => w.start.x);
        const ys = room.walls.map((w) => w.start.y);
        const minX = Math.min(...xs);
        const maxX = Math.max(...xs);
        const minY = Math.min(...ys);
        const maxY = Math.max(...ys);
        for (let gx = Math.ceil(minX / GRID_STEP_MM) * GRID_STEP_MM; gx <= maxX; gx += GRID_STEP_MM) {
          const a = toPx({ x: gx, y: minY });
          const b = toPx({ x: gx, y: maxY });
          ctx.beginPath();
          ctx.moveTo(a.x, a.y);
          ctx.lineTo(b.x, b.y);
          ctx.stroke();
        }
        for (let gy = Math.ceil(minY / GRID_STEP_MM) * GRID_STEP_MM; gy <= maxY; gy += GRID_STEP_MM) {
          const a = toPx({ x: minX, y: gy });
          const b = toPx({ x: maxX, y: gy });
          ctx.beginPath();
          ctx.moveTo(a.x, a.y);
          ctx.lineTo(b.x, b.y);
          ctx.stroke();
        }
        ctx.restore();
      }
    }

    ctx.strokeStyle = WALL;
    ctx.lineJoin = "round";
    ctx.lineCap = "round";
    for (const wall of room.walls) {
      ctx.lineWidth = Math.max(1, wall.thicknessMm * camera.scale);
      const p1 = toPx(wall.start);
      const p2 = toPx(wall.end);
      ctx.beginPath();
      ctx.moveTo(p1.x, p1.y);
      ctx.lineTo(p2.x, p2.y);
      ctx.stroke();
    }

    // Kapı/pencere: önce duvarı zemin rengiyle "keser", sonra tipe göre
    // renkli bir çizgiyle işaretler.
    for (const opening of room.openings) {
      const wall = room.walls.find((w) => w.id === opening.wallId);
      if (!wall) continue;
      const len = Math.hypot(wall.end.x - wall.start.x, wall.end.y - wall.start.y) || 1;
      const ux = (wall.end.x - wall.start.x) / len;
      const uy = (wall.end.y - wall.start.y) / len;
      const p1 = toPx({ x: wall.start.x + ux * opening.offsetMm, y: wall.start.y + uy * opening.offsetMm });
      const p2 = toPx({
        x: wall.start.x + ux * (opening.offsetMm + opening.widthMm),
        y: wall.start.y + uy * (opening.offsetMm + opening.widthMm),
      });

      ctx.strokeStyle = FLOOR;
      ctx.lineWidth = Math.max(1, wall.thicknessMm * camera.scale);
      ctx.beginPath();
      ctx.moveTo(p1.x, p1.y);
      ctx.lineTo(p2.x, p2.y);
      ctx.stroke();

      ctx.strokeStyle = opening.type === "door" ? "#a84e29" : ACCENT;
      ctx.lineWidth = Math.max(2, wall.thicknessMm * camera.scale * 0.4);
      ctx.beginPath();
      ctx.moveTo(p1.x, p1.y);
      ctx.lineTo(p2.x, p2.y);
      ctx.stroke();
    }

    for (const mod of modules) {
      const rect = moduleFootprint(mod);
      const { x, y } = toPx({ x: rect.x, y: rect.y });
      const w = rect.w * camera.scale;
      const h = rect.h * camera.scale;
      const selected = mod.id === selectedModuleId;
      const color = mod.meta.colorHex ?? "#c9d2cf";
      const textColor = relativeLuminance(color) > 0.45 ? INK : "#ffffff";
      const radius = Math.max(0, Math.min(8, w / 4, h / 4));

      ctx.save();
      ctx.shadowColor = "rgba(21,33,31,0.22)";
      ctx.shadowBlur = selected ? 12 : 6;
      ctx.shadowOffsetY = 2;
      ctx.fillStyle = color;
      ctx.beginPath();
      ctx.roundRect(x, y, w, h, radius);
      ctx.fill();
      ctx.restore();

      ctx.strokeStyle = selected ? ACCENT : "rgba(21,33,31,0.22)";
      ctx.lineWidth = selected ? 2.5 : 1;
      ctx.beginPath();
      ctx.roundRect(x, y, w, h, radius);
      ctx.stroke();

      if (w > 56 && h > 30) {
        ctx.fillStyle = textColor;
        ctx.font = `600 12px ${FONT_SANS}`;
        ctx.fillText(mod.meta.name, x + 8, y + 18, w - 16);
        ctx.font = `11px ${FONT_MONO}`;
        ctx.globalAlpha = 0.82;
        ctx.fillText(`${rect.w}×${rect.h} mm`, x + 8, y + h - 9, w - 16);
        ctx.globalAlpha = 1;
      }
    }

    if (drawMode && draftPoints.length > 0) {
      ctx.strokeStyle = ACCENT;
      ctx.lineWidth = 2;
      ctx.setLineDash([5, 4]);
      ctx.beginPath();
      const first = toPx(draftPoints[0]);
      ctx.moveTo(first.x, first.y);
      for (const p of draftPoints.slice(1)) {
        const px = toPx(p);
        ctx.lineTo(px.x, px.y);
      }
      if (cursorMm) {
        const px = toPx(cursorMm);
        ctx.lineTo(px.x, px.y);
      }
      ctx.stroke();
      ctx.setLineDash([]);

      for (const p of draftPoints) {
        const px = toPx(p);
        ctx.beginPath();
        ctx.arc(px.x, px.y, 5, 0, Math.PI * 2);
        ctx.fillStyle = "#ffffff";
        ctx.fill();
        ctx.lineWidth = 2;
        ctx.strokeStyle = ACCENT;
        ctx.stroke();
      }
    }
  }, [room, modules, selectedModuleId, drawMode, draftPoints, cursorMm, camera, toPx, viewport]);

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

  const clientToLocalPx = (clientX: number, clientY: number): Point => {
    const rect = canvasRef.current!.getBoundingClientRect();
    return { x: clientX - rect.left, y: clientY - rect.top };
  };

  const handlePointerDown = (e: React.PointerEvent<HTMLCanvasElement>) => {
    // setPointerCapture, tarayıcının kendi "etkin pointer" defterinde kaydı
    // olmayan bir pointerId ile çağrılırsa (spesifikasyona göre mümkün) NotFoundError
    // fırlatabilir — bu, gerisindeki jest mantığını hiç çalıştırmadan tüm
    // etkileşimi sessizce kilitler. Yakalama olmadan atlanırsa yalnızca imleç
    // canvas dışına taşarsa sürükleme yarıda kesilir; kritik değil.
    try {
      canvasRef.current!.setPointerCapture(e.pointerId);
    } catch {
      // yut — aşağıdaki jest mantığı yine de çalışmalı
    }
    pointersRef.current.set(e.pointerId, { x: e.clientX, y: e.clientY });

    const mm = toMm(clientToLocalPx(e.clientX, e.clientY));

    if (drawMode) {
      addDraftPoint(nextDraftPoint(mm, draftPoints));
      return;
    }

    if (openingMode) {
      placeOrRemoveOpening(mm);
      return;
    }

    if (pointersRef.current.size >= 2) {
      // İkinci parmak indi: sürükleme/pan'i bırak, iki-parmak yakınlaştırmaya geç.
      const pts = [...pointersRef.current.values()].slice(0, 2);
      const midClient = midpoint(pts[0], pts[1]);
      gestureRef.current = {
        type: "pinch",
        startDistance: distance(pts[0], pts[1]) || 1,
        startScale: camera.scale,
        mmUnderFinger: toMm(clientToLocalPx(midClient.x, midClient.y)),
      };
      return;
    }

    // Tek parmak: seçili nesne üstündeyse taşı, değilse kamerayı kaydır (§4.1).
    const hit = findModuleAt(mm.x, mm.y);
    selectModule(hit ? hit.id : null);
    gestureRef.current = hit
      ? { type: "drag-module", id: hit.id, offsetX: mm.x - hit.position.x, offsetY: mm.y - hit.position.y }
      : { type: "pan", startClientX: e.clientX, startClientY: e.clientY, startPanX: camera.panX, startPanY: camera.panY };
  };

  const handlePointerMove = (e: React.PointerEvent<HTMLCanvasElement>) => {
    if (!pointersRef.current.has(e.pointerId)) return;
    pointersRef.current.set(e.pointerId, { x: e.clientX, y: e.clientY });

    if (drawMode) {
      const mm = toMm(clientToLocalPx(e.clientX, e.clientY));
      setCursorMm(nextDraftPoint(mm, draftPoints));
      return;
    }

    const gesture = gestureRef.current;

    if (gesture.type === "pinch") {
      const pts = [...pointersRef.current.values()];
      if (pts.length < 2) return;
      const [a, b] = pts;
      const ratio = distance(a, b) / gesture.startDistance;
      const newScale = clamp(gesture.startScale * ratio, MIN_SCALE, MAX_SCALE);
      const midClient = midpoint(a, b);
      const midLocal = clientToLocalPx(midClient.x, midClient.y);
      setCamera({
        scale: newScale,
        panX: midLocal.x - gesture.mmUnderFinger.x * newScale,
        panY: midLocal.y - gesture.mmUnderFinger.y * newScale,
      });
      return;
    }

    if (gesture.type === "pan") {
      const dx = e.clientX - gesture.startClientX;
      const dy = e.clientY - gesture.startClientY;
      setCamera((c) => ({ ...c, panX: gesture.startPanX + dx, panY: gesture.startPanY + dy }));
      return;
    }

    if (gesture.type === "drag-module") {
      const localPx = clientToLocalPx(e.clientX, e.clientY);
      const mm = toMm(localPx);
      const result = moveModule(gesture.id, mm.x - gesture.offsetX, mm.y - gesture.offsetY, SNAP_THRESHOLD_PX / camera.scale);
      if (result) {
        setMagnifier({ screenPos: localPx, mm: { x: result.x, y: result.y }, blocked: result.blocked, snapTarget: result.snapTarget });
      }
    }
  };

  const endPointer = (e: React.PointerEvent<HTMLCanvasElement>) => {
    pointersRef.current.delete(e.pointerId);

    if (gestureRef.current.type === "drag-module") {
      setMagnifier(null);
    }

    if (pointersRef.current.size === 0) {
      gestureRef.current = { type: "idle" };
      return;
    }

    if (pointersRef.current.size === 1 && gestureRef.current.type === "pinch") {
      // İki parmaktan bire düşüldü: sıçramayı önlemek için kalan parmaktan yeni bir pan başlangıcı al.
      const [remaining] = [...pointersRef.current.values()];
      gestureRef.current = {
        type: "pan",
        startClientX: remaining.x,
        startClientY: remaining.y,
        startPanX: camera.panX,
        startPanY: camera.panY,
      };
    }
  };

  return (
    <div ref={containerRef} style={{ width: "100%", maxWidth: 760, position: "relative" }}>
      <canvas
        ref={canvasRef}
        width={viewport.w}
        height={viewport.h}
        style={{
          touchAction: "none",
          background: CANVAS_BG,
          border: "1px solid #dbe1de",
          borderRadius: 10,
          display: "block",
          width: "100%",
          height: "auto",
          cursor: drawMode || openingMode ? "crosshair" : "default",
        }}
        onPointerDown={handlePointerDown}
        onPointerMove={handlePointerMove}
        onPointerUp={endPointer}
        onPointerCancel={endPointer}
        onPointerLeave={endPointer}
      />
      {magnifier && (
        <div
          style={{
            position: "absolute",
            left: magnifier.screenPos.x,
            top: magnifier.screenPos.y - 44,
            transform: "translateX(-50%)",
            background: magnifier.blocked ? "#b5502a" : "#15211f",
            color: "#fff",
            padding: "6px 10px",
            fontSize: 11,
            fontFamily: "var(--font-mono)",
            fontVariantNumeric: "tabular-nums",
            whiteSpace: "nowrap",
            pointerEvents: "none",
            borderRadius: 6,
            boxShadow: "0 4px 12px rgba(21,33,31,0.28)",
          }}
        >
          {Math.round(magnifier.mm.x)}, {Math.round(magnifier.mm.y)} mm
          {magnifier.blocked && " · çakışıyor"}
          {!magnifier.blocked && magnifier.snapTarget === "wall" && " · duvara kilitli"}
          {!magnifier.blocked && magnifier.snapTarget === "neighbor" && " · modüle kilitli"}
        </div>
      )}
    </div>
  );
}
