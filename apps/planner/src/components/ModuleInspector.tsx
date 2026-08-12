import { usePlannerStore } from "../lib/store";

const STEP_MM = 10;

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
        <p style={{ color: "var(--ink-muted)", fontSize: 13, margin: 0 }}>Düzenlemek için bir modül seçin.</p>
      </aside>
    );
  }

  const stepX = (delta: number) => setModulePosition(selected.id, selected.position.x + delta, selected.position.y);
  const stepY = (delta: number) => setModulePosition(selected.id, selected.position.x, selected.position.y + delta);

  return (
    <aside className="inspector open">
      <div className="inspector-handle" />
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 16 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
          <span
            style={{
              width: 14,
              height: 14,
              borderRadius: 4,
              background: selected.meta.colorHex ?? "#c9d2cf",
              border: "1px solid rgba(21,33,31,0.15)",
              flex: "0 0 auto",
            }}
          />
          <h2 style={{ fontSize: 14, fontWeight: 700, margin: 0, color: "var(--ink)" }}>{selected.meta.name}</h2>
        </div>
        <button
          onClick={() => selectModule(null)}
          style={{ border: "none", background: "none", cursor: "pointer", fontSize: 13, color: "var(--ink-muted)", padding: 4 }}
        >
          Kapat
        </button>
      </div>

      <label style={{ display: "block", marginBottom: 12 }}>
        <span className="field-label">X (mm)</span>
        <div style={{ display: "flex", gap: 6 }}>
          <button className="btn-step" onClick={() => stepX(-STEP_MM)}>
            −
          </button>
          <input
            type="number"
            className="field-input"
            value={selected.position.x}
            onChange={(e) => setModulePosition(selected.id, Number(e.target.value), selected.position.y)}
          />
          <button className="btn-step" onClick={() => stepX(STEP_MM)}>
            +
          </button>
        </div>
      </label>

      <label style={{ display: "block", marginBottom: 12 }}>
        <span className="field-label">Y (mm)</span>
        <div style={{ display: "flex", gap: 6 }}>
          <button className="btn-step" onClick={() => stepY(-STEP_MM)}>
            −
          </button>
          <input
            type="number"
            className="field-input"
            value={selected.position.y}
            onChange={(e) => setModulePosition(selected.id, selected.position.x, Number(e.target.value))}
          />
          <button className="btn-step" onClick={() => stepY(STEP_MM)}>
            +
          </button>
        </div>
      </label>

      <div style={{ marginBottom: 12 }}>
        <span className="field-label">Rotasyon</span>
        <button className="btn" style={{ width: "100%" }} onClick={() => rotateModule(selected.id)}>
          {selected.rotationDeg}° — döndür
        </button>
      </div>

      <div>
        <span className="field-label">Ölçü (g×y×d)</span>
        <span className="mono" style={{ fontSize: 13, color: "var(--ink)" }}>
          {selected.dimensionsMm.w}×{selected.dimensionsMm.h}×{selected.dimensionsMm.d} mm
        </span>
      </div>
    </aside>
  );
}
