import { buildBom } from "../lib/bom";
import { usePlannerStore } from "../lib/store";

export function BomPanel({ onClose }: { onClose: () => void }) {
  const modules = usePlannerStore((s) => s.modules);
  const bom = buildBom(modules);
  const json = JSON.stringify(bom, null, 2);

  const handleDownload = () => {
    const blob = new Blob([json], { type: "application/json" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = "bom.json";
    a.click();
    URL.revokeObjectURL(url);
  };

  return (
    <div
      style={{
        position: "fixed",
        inset: 0,
        background: "rgba(24,36,34,0.35)",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        zIndex: 10,
      }}
      onClick={onClose}
    >
      <div
        style={{ background: "#fff", border: "1px solid #c6d0cb", padding: 20, width: 420, maxWidth: "90vw" }}
        onClick={(e) => e.stopPropagation()}
      >
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline", marginBottom: 10 }}>
          <h2 style={{ fontSize: 14, margin: 0 }}>Parça Listesi (BOM)</h2>
          <button onClick={onClose} style={{ border: "none", background: "none", cursor: "pointer", fontSize: 13 }}>
            Kapat
          </button>
        </div>
        <pre
          style={{
            fontFamily: "Consolas, monospace",
            fontSize: 12,
            background: "#e4e9e6",
            border: "1px solid #c6d0cb",
            padding: 10,
            maxHeight: 320,
            overflow: "auto",
          }}
        >
          {json}
        </pre>
        <button
          onClick={handleDownload}
          style={{
            marginTop: 10,
            fontFamily: "Consolas, monospace",
            fontSize: 12,
            padding: "6px 10px",
            border: "1px solid #1f5ca6",
            color: "#1f5ca6",
            background: "#fff",
            cursor: "pointer",
          }}
        >
          bom.json indir
        </button>
      </div>
    </div>
  );
}
