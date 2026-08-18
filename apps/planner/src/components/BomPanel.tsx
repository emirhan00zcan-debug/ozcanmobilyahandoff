import { useState } from "react";
import { buildBom } from "../lib/bom";
import { cartUrl, sendBomToCart } from "../lib/handoff";
import { usePlannerStore } from "../lib/store";

export function BomPanel({ onClose, handoffToken }: { onClose: () => void; handoffToken: string | null }) {
  const modules = usePlannerStore((s) => s.modules);
  const bom = buildBom(modules);
  const json = JSON.stringify(bom, null, 2);

  const [sending, setSending] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleDownload = () => {
    const blob = new Blob([json], { type: "application/json" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = "bom.json";
    a.click();
    URL.revokeObjectURL(url);
  };

  const handleSendToCart = async () => {
    if (!handoffToken || bom.length === 0) return;
    setError(null);
    setSending(true);
    try {
      await sendBomToCart(bom, handoffToken);
      window.location.href = cartUrl();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Sepete aktarma başarısız oldu.");
      setSending(false);
    }
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
      <div
        className="panel"
        style={{ padding: 22, width: 440, maxWidth: "90vw" }}
        onClick={(e) => e.stopPropagation()}
      >
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline", marginBottom: 12 }}>
          <h2 style={{ fontSize: 15, fontWeight: 700, margin: 0, color: "var(--ink)" }}>Parça Listesi (BOM)</h2>
          <button
            onClick={onClose}
            style={{ border: "none", background: "none", cursor: "pointer", fontSize: 13, color: "var(--ink-muted)" }}
          >
            Kapat
          </button>
        </div>
        <pre
          className="mono"
          style={{
            fontSize: 12,
            background: "var(--surface-2)",
            border: "1px solid var(--rule)",
            borderRadius: "var(--radius-sm)",
            padding: 12,
            maxHeight: 320,
            overflow: "auto",
          }}
        >
          {json}
        </pre>

        {error && <p style={{ color: "var(--warn)", fontSize: 12, margin: "10px 0 0" }}>{error}</p>}

        <div style={{ display: "flex", gap: 8, marginTop: 12 }}>
          <button className="btn" onClick={handleDownload}>
            bom.json indir
          </button>

          {handoffToken && (
            <button className="btn-primary" onClick={handleSendToCart} disabled={sending || bom.length === 0}>
              {sending ? "Gönderiliyor…" : "Sepete Gönder"}
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
