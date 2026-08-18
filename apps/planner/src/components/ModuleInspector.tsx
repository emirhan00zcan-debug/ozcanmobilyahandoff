import { useEffect, useState } from "react";
import { usePlannerStore } from "../lib/store";

const STEP_MM = 10;
const COLLISION_WARNING = "Bu konum başka bir modülle veya duvarla çakışıyor — konum değiştirilmedi.";

export function ModuleInspector() {
  const modules = usePlannerStore((s) => s.modules);
  const selectedModuleIds = usePlannerStore((s) => s.selectedModuleIds);
  const selectModule = usePlannerStore((s) => s.selectModule);
  const setModulePosition = usePlannerStore((s) => s.setModulePosition);
  const rotateModule = usePlannerStore((s) => s.rotateModule);
  const [warning, setWarning] = useState(false);

  const selectedList = modules.filter((m) => selectedModuleIds.includes(m.id));
  const selected = selectedList.length === 1 ? selectedList[0] : undefined;

  // Seçim değişince (modül, grup ya da kapanış) önceki uyarı yeni duruma taşınmasın.
  useEffect(() => {
    setWarning(false);
  }, [selectedModuleIds]);

  if (selectedList.length === 0) {
    return (
      <aside className="inspector">
        <div className="inspector-handle" />
        <p style={{ color: "var(--ink-muted)", fontSize: 13, margin: 0 }}>
          Düzenlemek için bir modül seçin. Birden fazla modülü birlikte taşımak için Shift+tıklayarak seçime ekleyin.
        </p>
      </aside>
    );
  }

  // Grup taşıma (§Faz 4): 2+ modül seçiliyken tek bir modülün X/Y/rotasyonunu
  // düzenlemek anlamsız (hangisi?) — bunun yerine sadeleştirilmiş bir özet
  // gösterilir, taşıma canvas'ta sürükleyerek yapılır (bkz. PlannerCanvas
  // moveModuleGroup).
  if (!selected) {
    return (
      <aside className="inspector open">
        <div className="inspector-handle" />
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 10 }}>
          <h2 style={{ fontSize: 14, fontWeight: 700, margin: 0, color: "var(--ink)" }}>{selectedList.length} modül seçili</h2>
          <button
            onClick={() => selectModule(null)}
            style={{ border: "none", background: "none", cursor: "pointer", fontSize: 13, color: "var(--ink-muted)", padding: 4 }}
          >
            Kapat
          </button>
        </div>
        <p style={{ color: "var(--ink-muted)", fontSize: 13, margin: 0 }}>
          Birlikte taşımak için canvas'ta herhangi birini sürükleyin. Tek tek düzenlemek için Shift+tıklayarak seçimi daraltın.
        </p>
      </aside>
    );
  }

  // Sayısal panelden gelen konum kesin bir komuttur (§3.4) — çakışırsa
  // önceden sessizce yok sayılıyordu (input eski değere geri dönüyordu ama
  // neden belli değildi). Artık ret durumu görünür bir uyarıya çevriliyor.
  const applyPosition = (x: number, y: number) => setWarning(!setModulePosition(selected.id, x, y));

  const stepX = (delta: number) => applyPosition(selected.position.x + delta, selected.position.y);
  const stepY = (delta: number) => applyPosition(selected.position.x, selected.position.y + delta);

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
              border: "1px solid rgba(17,17,17,0.12)",
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
            onChange={(e) => applyPosition(Number(e.target.value), selected.position.y)}
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
            onChange={(e) => applyPosition(selected.position.x, Number(e.target.value))}
          />
          <button className="btn-step" onClick={() => stepY(STEP_MM)}>
            +
          </button>
        </div>
      </label>

      {warning && (
        <p style={{ fontSize: 12, color: "var(--warn)", margin: "0 0 12px", lineHeight: 1.4 }}>{COLLISION_WARNING}</p>
      )}

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
