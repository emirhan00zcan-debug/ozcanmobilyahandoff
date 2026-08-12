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

        {error && <p style={{ color: "#a84e29", fontSize: 12, margin: "8px 0 0" }}>{error}</p>}

        <div style={{ display: "flex", gap: 8, marginTop: 10 }}>
          <button
            onClick={handleDownload}
            style={{
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

          {handoffToken && (
            <button
              onClick={handleSendToCart}
              disabled={sending || bom.length === 0}
              style={{
                fontFamily: "Consolas, monospace",
                fontSize: 12,
                padding: "6px 10px",
                border: "1px solid #1f5ca6",
                color: "#fff",
                background: "#1f5ca6",
                cursor: sending || bom.length === 0 ? "default" : "pointer",
                opacity: sending || bom.length === 0 ? 0.6 : 1,
              }}
            >
              {sending ? "Gönderiliyor…" : "Sepete Gönder"}
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
