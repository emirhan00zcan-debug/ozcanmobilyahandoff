import { moduleFootprint } from "../lib/geometry";
import { usePlannerStore } from "../lib/store";
import type { PlannerModule, Room } from "../lib/types";

// Faz 4 "Üretime Hazır Çıktı": 2D ölçülendirilmiş çıktı. Gerçek fiziksel
// ölçekte (1:50 vb.) yazdırma tarayıcılar/yazıcılar arasında güvenilir değil
// (sayfa taşması, yazıcı kenar boşluğu farkları), bu yüzden çizim şematiktir
// ve sayfaya sığacak şekilde otomatik ölçeklenir — kesin ölçünün tek kaynağı
// aşağıdaki tablo (her modülün mm cinsinden konumu/ölçüsü/rotasyonu).
// window.print() ile tetiklenir; kullanıcı yazdırma diyaloğundan "PDF olarak
// kaydet" seçer — jsPDF/html2canvas gibi bir bağımlılık eklemeden (bkz.
// Mimari Doküman §2: bundle boyutu önceliği) gerçek, keskin vektör bir PDF
// üretir.

const WALL_COLOR = "#8f8a82";
const FLOOR_COLOR = "#ffffff";
const ACCENT = "#0058a3";
const DOOR_COLOR = "#a84e29";
const INK = "#111111";

function relativeLuminance(hex: string): number {
  const clean = hex.replace("#", "");
  if (clean.length !== 6) return 1;
  const toLinear = (v: number) => (v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4));
  const r = toLinear(parseInt(clean.slice(0, 2), 16) / 255);
  const g = toLinear(parseInt(clean.slice(2, 4), 16) / 255);
  const b = toLinear(parseInt(clean.slice(4, 6), 16) / 255);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

function FloorPlanSvg({ room, modules }: { room: Room; modules: PlannerModule[] }) {
  const width = room.dimensionsMm.width;
  const depth = room.dimensionsMm.depth;
  // Tüm ölçü/çizgi/yazı boyutları odanın küçük kenarıyla orantılı — böylece
  // hem 2m'lik hem 8m'lik bir oda için okunabilir, tutarlı bir çizim üretir.
  const unit = Math.max(1, Math.min(width, depth));
  const lineW = unit * 0.003;
  const fontSize = unit * 0.032;
  const tick = unit * 0.02;
  const gap = unit * 0.1; // duvardan ölçü çizgisine mesafe
  const dimSpace = gap + tick + fontSize * 1.6; // ölçü çizgisi + etiket için gereken toplam kenar boşluğu
  // Üst/sağ kenarda ölçü çizgisi yok, ama duvar kalınlığı (sabit 100mm, oda
  // boyutuyla ölçeklenmez) taşabilir — küçük odalarda fontSize tabanlı payın
  // yetersiz kalmaması için sabit bir alt sınır konur.
  const edgePad = Math.max(fontSize, 60);

  const floorPoints = room.walls.map((w) => `${w.start.x},${w.start.y}`).join(" ");
  const dimY = depth + gap; // yatay (genişlik) ölçü çizgisinin y konumu
  const dimX = -gap; // dikey (derinlik) ölçü çizgisinin x konumu

  return (
    <svg
      viewBox={`${-dimSpace} ${-edgePad} ${width + dimSpace + edgePad} ${depth + dimSpace + edgePad}`}
      width="100%"
      role="img"
      aria-label="Oda yerleşim planı"
    >
      <defs>
        <marker id="dimTick" viewBox="0 0 10 10" refX="5" refY="5" markerWidth="3.5" markerHeight="3.5">
          <circle cx="5" cy="5" r="5" fill={INK} />
        </marker>
      </defs>

      {floorPoints && <polygon points={floorPoints} fill={FLOOR_COLOR} stroke="none" />}

      {room.walls.map((wall) => (
        <line
          key={wall.id}
          x1={wall.start.x}
          y1={wall.start.y}
          x2={wall.end.x}
          y2={wall.end.y}
          stroke={WALL_COLOR}
          strokeWidth={Math.max(unit * 0.006, wall.thicknessMm)}
          strokeLinecap="square"
        />
      ))}

      {room.openings.map((opening) => {
        const wall = room.walls.find((w) => w.id === opening.wallId);
        if (!wall) return null;
        const len = Math.hypot(wall.end.x - wall.start.x, wall.end.y - wall.start.y) || 1;
        const ux = (wall.end.x - wall.start.x) / len;
        const uy = (wall.end.y - wall.start.y) / len;
        const x1 = wall.start.x + ux * opening.offsetMm;
        const y1 = wall.start.y + uy * opening.offsetMm;
        const x2 = wall.start.x + ux * (opening.offsetMm + opening.widthMm);
        const y2 = wall.start.y + uy * (opening.offsetMm + opening.widthMm);
        return (
          <line
            key={opening.id}
            x1={x1}
            y1={y1}
            x2={x2}
            y2={y2}
            stroke={opening.type === "door" ? DOOR_COLOR : ACCENT}
            strokeWidth={wall.thicknessMm * 0.6}
          />
        );
      })}

      {modules.map((mod, i) => {
        const rect = moduleFootprint(mod);
        const color = mod.meta.colorHex ?? "#c9d2cf";
        const textColor = relativeLuminance(color) > 0.45 ? INK : "#ffffff";
        const labelFits = rect.w > unit * 0.1 && rect.h > unit * 0.06;
        return (
          <g key={mod.id}>
            <rect x={rect.x} y={rect.y} width={rect.w} height={rect.h} fill={color} stroke="rgba(17,17,17,0.3)" strokeWidth={unit * 0.0015} />
            {labelFits && (
              <text
                x={rect.x + rect.w / 2}
                y={rect.y + rect.h / 2}
                textAnchor="middle"
                dominantBaseline="middle"
                fill={textColor}
                fontSize={fontSize * 0.9}
                fontFamily="var(--font-sans)"
                fontWeight={700}
              >
                {i + 1}
              </text>
            )}
          </g>
        );
      })}

      {/* Genişlik ölçü çizgisi (yatay, odanın altında) */}
      <g stroke={INK} strokeWidth={lineW}>
        <line x1={0} y1={depth} x2={0} y2={dimY + tick} />
        <line x1={width} y1={depth} x2={width} y2={dimY + tick} />
        <line x1={0} y1={dimY} x2={width} y2={dimY} markerStart="url(#dimTick)" markerEnd="url(#dimTick)" />
      </g>
      <text x={width / 2} y={dimY + tick + fontSize} textAnchor="middle" fill={INK} fontSize={fontSize} fontFamily="var(--font-mono)">
        {width} mm
      </text>

      {/* Derinlik ölçü çizgisi (dikey, odanın solunda) */}
      <g stroke={INK} strokeWidth={lineW}>
        <line x1={0} y1={0} x2={dimX - tick} y2={0} />
        <line x1={0} y1={depth} x2={dimX - tick} y2={depth} />
        <line x1={dimX} y1={0} x2={dimX} y2={depth} markerStart="url(#dimTick)" markerEnd="url(#dimTick)" />
      </g>
      <text
        x={dimX - tick - fontSize * 0.4}
        y={depth / 2}
        textAnchor="middle"
        fill={INK}
        fontSize={fontSize}
        fontFamily="var(--font-mono)"
        transform={`rotate(-90 ${dimX - tick - fontSize * 0.4} ${depth / 2})`}
      >
        {depth} mm
      </text>
    </svg>
  );
}

export function PrintPlan({ onClose }: { onClose: () => void }) {
  const room = usePlannerStore((s) => s.room);
  const modules = usePlannerStore((s) => s.modules);
  const sortedModules = [...modules].sort((a, b) => a.meta.name.localeCompare(b.meta.name, "tr"));
  const generatedAt = new Date().toLocaleDateString("tr-TR", { day: "2-digit", month: "long", year: "numeric" });

  return (
    <div
      className="print-plan-overlay"
      style={{ position: "fixed", inset: 0, background: "rgba(17,17,17,0.4)", display: "flex", justifyContent: "center", zIndex: 20, overflowY: "auto", padding: "24px 12px" }}
      onClick={onClose}
    >
      <div
        className="print-plan-sheet panel"
        style={{ background: "#fff", padding: 28, width: 900, maxWidth: "100%", height: "fit-content" }}
        onClick={(e) => e.stopPropagation()}
      >
        <div className="print-hide" style={{ display: "flex", justifyContent: "space-between", marginBottom: 18 }}>
          <button className="btn-primary" onClick={() => window.print()}>
            Yazdır / PDF Olarak Kaydet
          </button>
          <button onClick={onClose} style={{ border: "none", background: "none", cursor: "pointer", fontSize: 13, color: "var(--ink-muted)" }}>
            Kapat
          </button>
        </div>

        <h1 style={{ fontSize: 18, fontWeight: 700, margin: "0 0 4px", color: INK }}>Oda &amp; Mobilya Planı</h1>
        <p style={{ fontSize: 12, color: "var(--ink-muted)", margin: "0 0 4px" }}>
          {generatedAt} · Oda: {room.dimensionsMm.width}×{room.dimensionsMm.depth}×{room.dimensionsMm.height} mm (G×D×Y)
        </p>
        <p style={{ fontSize: 11, color: "var(--ink-muted)", margin: "0 0 18px" }}>
          Şematik plan — gerçek ölçekte değildir. Kesin ölçüler aşağıdaki tablodan alınmalıdır.
        </p>

        <FloorPlanSvg room={room} modules={sortedModules} />

        {sortedModules.length === 0 ? (
          <p style={{ fontSize: 13, color: "var(--ink-muted)", marginTop: 18 }}>Odada henüz modül yok.</p>
        ) : (
          <table style={{ width: "100%", borderCollapse: "collapse", marginTop: 22, fontSize: 12 }}>
            <thead>
              <tr style={{ borderBottom: `1px solid ${INK}` }}>
                <th style={{ textAlign: "left", padding: "6px 8px" }}>#</th>
                <th style={{ textAlign: "left", padding: "6px 8px" }}>Ürün</th>
                <th style={{ textAlign: "left", padding: "6px 8px" }}>Ölçü (G×Y×D mm)</th>
                <th style={{ textAlign: "left", padding: "6px 8px" }}>Konum (X,Y mm)</th>
                <th style={{ textAlign: "left", padding: "6px 8px" }}>Rotasyon</th>
                <th style={{ textAlign: "left", padding: "6px 8px" }}>Renk</th>
              </tr>
            </thead>
            <tbody>
              {sortedModules.map((mod, i) => (
                <tr key={mod.id} style={{ borderBottom: "1px solid var(--rule)" }}>
                  <td className="mono" style={{ padding: "6px 8px" }}>
                    {i + 1}
                  </td>
                  <td style={{ padding: "6px 8px" }}>{mod.meta.name}</td>
                  <td className="mono" style={{ padding: "6px 8px" }}>
                    {mod.dimensionsMm.w}×{mod.dimensionsMm.h}×{mod.dimensionsMm.d}
                  </td>
                  <td className="mono" style={{ padding: "6px 8px" }}>
                    {mod.position.x}, {mod.position.y}
                  </td>
                  <td className="mono" style={{ padding: "6px 8px" }}>
                    {mod.rotationDeg}°
                  </td>
                  <td style={{ padding: "6px 8px" }}>
                    <span
                      style={{
                        display: "inline-block",
                        width: 12,
                        height: 12,
                        borderRadius: 3,
                        background: mod.meta.colorHex ?? "#c9d2cf",
                        border: "1px solid var(--rule-strong)",
                        marginRight: 6,
                        verticalAlign: "middle",
                      }}
                    />
                    <span className="mono">{mod.meta.colorHex ?? "—"}</span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
