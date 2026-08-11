import type { CSSProperties } from "react";
import { usePlannerStore } from "../lib/store";

const STEP_MM = 10;

const labelStyle: CSSProperties = {
  display: "flex",
  flexDirection: "column",
  gap: 4,
  marginBottom: 10,
  color: "#54635e",
  fontSize: 11,
  textTransform: "uppercase",
  letterSpacing: "0.06em",
};

const inputStyle: CSSProperties = {
  fontFamily: "Consolas, monospace",
  fontSize: 14,
  padding: "8px 6px",
  border: "1px solid #c6d0cb",
  color: "#182422",
  textTransform: "none",
  letterSpacing: "normal",
  width: "100%",
  textAlign: "center",
};

// Dokunmatik hedefler için büyük (min. 36px) — §4.3: "büyük dokunma hedefli
// +/- adım butonları".
const stepButtonStyle: CSSProperties = {
  fontFamily: "Consolas, monospace",
  fontSize: 16,
  width: 36,
  height: 36,
  flex: "0 0 auto",
  border: "1px solid #c6d0cb",
  color: "#1f5ca6",
  background: "#fff",
  cursor: "pointer",
};

const buttonStyle: CSSProperties = {
  fontFamily: "Consolas, monospace",
  fontSize: 12,
  padding: "5px 8px",
  border: "1px solid #1f5ca6",
  color: "#1f5ca6",
  background: "#fff",
  cursor: "pointer",
};

export function ModuleInspector() {
  const modules = usePlannerStore((s) => s.modules);
  const selectedModuleId = usePlannerStore((s) => s.selectedModuleId);
  const selectModule = usePlannerStore((s) => s.selectModule);
  const setModulePosition = usePlannerStore((s) => s.setModulePosition);
  const rotateModule = usePlannerStore((s) => s.rotateModule);

  const selected = modules.find((m) => m.id === selectedModuleId);

  if (!selected) {
    return (
      <aside className="inspector">
        <div className="inspector-handle" />
        <p style={{ color: "#54635e", margin: 0 }}>Düzenlemek için bir modül seçin.</p>
      </aside>
    );
  }

  const stepX = (delta: number) => setModulePosition(selected.id, selected.position.x + delta, selected.position.y);
  const stepY = (delta: number) => setModulePosition(selected.id, selected.position.x, selected.position.y + delta);

  return (
    <aside className="inspector open">
      <div className="inspector-handle" />
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline", marginBottom: 12 }}>
        <h2 style={{ fontSize: 14, margin: 0, color: "#182422" }}>{selected.meta.name}</h2>
        <button
          onClick={() => selectModule(null)}
          style={{ border: "none", background: "none", cursor: "pointer", fontSize: 13, color: "#54635e" }}
        >
          Kapat
        </button>
      </div>

      <label style={labelStyle}>
        X (mm)
        <div style={{ display: "flex", gap: 6 }}>
          <button style={stepButtonStyle} onClick={() => stepX(-STEP_MM)}>
            −
          </button>
          <input
            type="number"
            style={inputStyle}
            value={selected.position.x}
            onChange={(e) => setModulePosition(selected.id, Number(e.target.value), selected.position.y)}
          />
          <button style={stepButtonStyle} onClick={() => stepX(STEP_MM)}>
            +
          </button>
        </div>
      </label>

      <label style={labelStyle}>
        Y (mm)
        <div style={{ display: "flex", gap: 6 }}>
          <button style={stepButtonStyle} onClick={() => stepY(-STEP_MM)}>
            −
          </button>
          <input
            type="number"
            style={inputStyle}
            value={selected.position.y}
            onChange={(e) => setModulePosition(selected.id, selected.position.x, Number(e.target.value))}
          />
          <button style={stepButtonStyle} onClick={() => stepY(STEP_MM)}>
            +
          </button>
        </div>
      </label>

      <div style={labelStyle}>
        Rotasyon
        <button style={buttonStyle} onClick={() => rotateModule(selected.id)}>
          {selected.rotationDeg}° — döndür
        </button>
      </div>

      <div style={{ ...labelStyle, marginBottom: 0 }}>
        Ölçü (g×y×d)
        <span style={{ ...inputStyle, border: "none", padding: 0, textAlign: "left" }}>
          {selected.dimensionsMm.w}×{selected.dimensionsMm.h}×{selected.dimensionsMm.d} mm
        </span>
      </div>
    </aside>
  );
}
