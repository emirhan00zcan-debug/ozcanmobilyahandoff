import type { CSSProperties } from "react";
import { usePlannerStore } from "../lib/store";

const panelStyle: CSSProperties = {
  width: 220,
  flex: "0 0 auto",
  border: "1px solid #c6d0cb",
  background: "#fff",
  padding: 14,
  fontSize: 13,
};

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
  fontSize: 13,
  padding: "4px 6px",
  border: "1px solid #c6d0cb",
  color: "#182422",
  textTransform: "none",
  letterSpacing: "normal",
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
  const setModulePosition = usePlannerStore((s) => s.setModulePosition);
  const rotateModule = usePlannerStore((s) => s.rotateModule);

  const selected = modules.find((m) => m.id === selectedModuleId);

  if (!selected) {
    return (
      <aside style={panelStyle}>
        <p style={{ color: "#54635e", margin: 0 }}>Düzenlemek için bir modül seçin.</p>
      </aside>
    );
  }

  return (
    <aside style={panelStyle}>
      <h2 style={{ fontSize: 14, margin: "0 0 12px", color: "#182422" }}>{selected.meta.name}</h2>

      <label style={labelStyle}>
        X (mm)
        <input
          type="number"
          style={inputStyle}
          value={selected.position.x}
          onChange={(e) => setModulePosition(selected.id, Number(e.target.value), selected.position.y)}
        />
      </label>

      <label style={labelStyle}>
        Y (mm)
        <input
          type="number"
          style={inputStyle}
          value={selected.position.y}
          onChange={(e) => setModulePosition(selected.id, selected.position.x, Number(e.target.value))}
        />
      </label>

      <div style={labelStyle}>
        Rotasyon
        <button style={buttonStyle} onClick={() => rotateModule(selected.id)}>
          {selected.rotationDeg}° — döndür
        </button>
      </div>

      <div style={labelStyle}>
        Ölçü (g×y×d)
        <span style={{ ...inputStyle, border: "none", padding: 0 }}>
          {selected.dimensionsMm.w}×{selected.dimensionsMm.h}×{selected.dimensionsMm.d} mm
        </span>
      </div>
    </aside>
  );
}
