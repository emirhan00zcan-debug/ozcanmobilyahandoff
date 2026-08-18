import { useState } from "react";
import { usePlannerStore } from "../lib/store";

// IKEA Kreativ modeli (bkz. planner.md): "Şablon odalar... tercih edilmeli"
// — serbest el duvar çizimi yerine hazır oda boyutları + gerekirse tek bir
// özel genişlik/derinlik çifti. Manuel köşe köşe koordinat girişi yok.
interface Preset {
  label: string;
  widthMm: number;
  depthMm: number;
}

const PRESETS: Preset[] = [
  { label: "Küçük Yatak Odası", widthMm: 3000, depthMm: 3500 },
  { label: "Standart Yatak Odası", widthMm: 3600, depthMm: 4200 },
  { label: "Genç Odası", widthMm: 3200, depthMm: 3800 },
  { label: "Mutfak", widthMm: 3000, depthMm: 3000 },
  { label: "Salon", widthMm: 4500, depthMm: 5500 },
  { label: "Geniş Salon", widthMm: 5000, depthMm: 6500 },
];

export function RoomTemplatePicker({ onClose }: { onClose: () => void }) {
  const setRoomTemplate = usePlannerStore((s) => s.setRoomTemplate);
  const [customWidth, setCustomWidth] = useState(4000);
  const [customDepth, setCustomDepth] = useState(4000);

  const apply = (widthMm: number, depthMm: number) => {
    if (widthMm < 1000 || depthMm < 1000) return;
    setRoomTemplate(widthMm, depthMm);
    onClose();
  };

  return (
    <div
      style={{
        position: "fixed",
        inset: 0,
        background: "rgba(17,17,17,0.4)",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        zIndex: 10,
      }}
      onClick={onClose}
    >
      <div className="panel" style={{ padding: 24, width: 640, maxWidth: "90vw", maxHeight: "85vh", overflow: "auto" }} onClick={(e) => e.stopPropagation()}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline", marginBottom: 8 }}>
          <h2 style={{ fontSize: 16, fontWeight: 700, margin: 0, color: "var(--ink)", letterSpacing: "-0.01em" }}>Oda Boyutu Seç</h2>
          <button onClick={onClose} style={{ border: "none", background: "none", cursor: "pointer", fontSize: 13, color: "var(--ink-muted)" }}>
            Kapat
          </button>
        </div>
        <p style={{ fontSize: 12, color: "var(--ink-muted)", margin: "0 0 18px" }}>
          Bir şablon seçin — istediğiniz zaman değiştirebilirsiniz. Oda değişince sahnedeki mobilyalar temizlenir.
        </p>

        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(170px, 1fr))", gap: 12, marginBottom: 20 }}>
          {PRESETS.map((p) => (
            <button
              key={p.label}
              className="product-card"
              style={{ textAlign: "left", cursor: "pointer" }}
              onClick={() => apply(p.widthMm, p.depthMm)}
            >
              <div style={{ fontWeight: 600, color: "var(--ink)", marginBottom: 4 }}>{p.label}</div>
              <div className="mono" style={{ color: "var(--ink-muted)", fontSize: 12 }}>
                {(p.widthMm / 1000).toLocaleString("tr-TR")}×{(p.depthMm / 1000).toLocaleString("tr-TR")} m
              </div>
            </button>
          ))}
        </div>

        <span className="field-label">Özel Boyut (mm)</span>
        <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
          <input type="number" className="field-input" value={customWidth} onChange={(e) => setCustomWidth(Number(e.target.value))} />
          <span style={{ color: "var(--ink-muted)" }}>×</span>
          <input type="number" className="field-input" value={customDepth} onChange={(e) => setCustomDepth(Number(e.target.value))} />
          <button className="btn-primary" style={{ flex: "0 0 auto" }} onClick={() => apply(customWidth, customDepth)}>
            Uygula
          </button>
        </div>
      </div>
    </div>
  );
}
