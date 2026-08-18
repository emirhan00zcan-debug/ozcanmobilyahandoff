import { useEffect, useState } from "react";
import { fetchCatalog, type CatalogVariation } from "../lib/catalog";
import { usePlannerStore } from "../lib/store";

const STEP_MM = 10;
const COLLISION_WARNING = "Bu konum başka bir modülle veya duvarla çakışıyor — konum değiştirilmedi.";

// Varyasyon SKU'ları tek bir renk ekseni değil, birden çok özelliği (kapak
// tipi, çerçeve rengi, ayak boyu vb.) tek bir kısa koda kodluyor — bu yüzden
// aynı hexColor'a sahip birçok varyasyon olabiliyor (bkz. gerçek katalogda
// bir gardırobun 12 varyasyonunun yalnızca 2 farklı rengi olması). Salt renk
// yuvarlağı bu durumda ayırt edici değil; bütün varyasyonlar arasındaki ortak
// önek (ürün adının SKU'daki karşılığı) çıkarılıp geri kalan okunabilir bir
// etikete çevriliyor.
function commonSkuPrefix(skus: string[]): string {
  if (skus.length === 0) return "";
  let prefix = skus[0];
  for (const sku of skus.slice(1)) {
    while (prefix && !sku.startsWith(prefix)) prefix = prefix.slice(0, -1);
    if (!prefix) return "";
  }
  const lastDash = prefix.lastIndexOf("-");
  return lastDash > 0 ? prefix.slice(0, lastDash + 1) : "";
}

function variationLabel(sku: string, prefix: string): string {
  const suffix = prefix && sku.startsWith(prefix) ? sku.slice(prefix.length) : sku;
  return (suffix || sku).replace(/-/g, " ");
}

export function ModuleInspector() {
  const modules = usePlannerStore((s) => s.modules);
  const selectedModuleIds = usePlannerStore((s) => s.selectedModuleIds);
  const selectModule = usePlannerStore((s) => s.selectModule);
  const setModulePosition = usePlannerStore((s) => s.setModulePosition);
  const setModuleVariation = usePlannerStore((s) => s.setModuleVariation);
  const rotateModule = usePlannerStore((s) => s.rotateModule);
  const [warning, setWarning] = useState(false);
  const [variations, setVariations] = useState<CatalogVariation[]>([]);

  const selectedList = modules.filter((m) => selectedModuleIds.includes(m.id));
  const selected = selectedList.length === 1 ? selectedList[0] : undefined;

  // Seçim değişince (modül, grup ya da kapanış) önceki uyarı yeni duruma taşınmasın.
  useEffect(() => {
    setWarning(false);
  }, [selectedModuleIds]);

  // Renk/kulp/ayak varyasyonu seçici (PAX tarzı "rengini seç" adımının bu
  // katalogdaki karşılığı) — modül eklenirken yalnızca ilk varyasyon
  // kaydediliyor (bkz. store.addModuleFromCatalog), burada tüm seçenekleri
  // görmek için ürün tekrar (varyasyonlarıyla) çekiliyor. Demo modüllerin
  // (productId "demo-1"/"demo-2") gerçek katalogda karşılığı olmadığından
  // istek sessizce boş sonuç döner — hata göstermeye değmez, sadece
  // seçici gizli kalır.
  useEffect(() => {
    if (!selected) {
      setVariations([]);
      return;
    }
    let cancelled = false;
    fetchCatalog([selected.productId])
      .then(([product]) => {
        if (!cancelled) setVariations(product?.variations ?? []);
      })
      .catch(() => {
        if (!cancelled) setVariations([]);
      });
    return () => {
      cancelled = true;
    };
  }, [selected?.productId]);

  const variationLabelPrefix = commonSkuPrefix(variations.map((v) => v.sku));

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

      {variations.length > 1 && (
        <div style={{ marginBottom: 16 }}>
          <span className="field-label">Renk / Varyasyon</span>
          <div style={{ display: "flex", flexDirection: "column", gap: 4, maxHeight: 200, overflowY: "auto" }}>
            {variations.map((v) => {
              const active = v.id === selected.productVariationId;
              return (
                <button
                  key={v.id}
                  onClick={() => setModuleVariation(selected.id, v.id, v.hexColor)}
                  style={{
                    display: "flex",
                    alignItems: "center",
                    gap: 8,
                    padding: "6px 8px",
                    borderRadius: "var(--radius-sm)",
                    border: active ? "1.5px solid var(--accent)" : "1px solid var(--rule)",
                    background: active ? "var(--accent-soft)" : "var(--surface)",
                    cursor: "pointer",
                    textAlign: "left",
                  }}
                >
                  <span
                    style={{
                      width: 18,
                      height: 18,
                      borderRadius: "50%",
                      background: v.hexColor ?? "var(--surface-2)",
                      border: "1px solid var(--rule-strong)",
                      flex: "0 0 auto",
                    }}
                  />
                  <span style={{ fontSize: 11.5, color: "var(--ink)", flex: 1, textTransform: "capitalize" }}>
                    {variationLabel(v.sku, variationLabelPrefix)}
                  </span>
                </button>
              );
            })}
          </div>
        </div>
      )}

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
