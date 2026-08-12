import { useEffect, useState } from "react";
import { fetchCatalogBrowse, type CatalogProduct } from "../lib/catalog";
import { usePlannerStore } from "../lib/store";

type Status = "loading" | "error" | "done";

export function ProductLibrary({ onClose }: { onClose: () => void }) {
  const addModuleFromCatalog = usePlannerStore((s) => s.addModuleFromCatalog);
  const [products, setProducts] = useState<CatalogProduct[]>([]);
  const [status, setStatus] = useState<Status>("loading");
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchCatalogBrowse(24)
      .then((items) => {
        setProducts(items);
        setStatus("done");
      })
      .catch((e: unknown) => {
        setError(e instanceof Error ? e.message : "Katalog isteği başarısız oldu.");
        setStatus("error");
      });
  }, []);

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
        className="panel"
        style={{ padding: 22, width: 660, maxWidth: "90vw", maxHeight: "80vh", overflow: "auto" }}
        onClick={(e) => e.stopPropagation()}
      >
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline", marginBottom: 14 }}>
          <h2 style={{ fontSize: 15, fontWeight: 700, margin: 0, color: "var(--ink)" }}>Ürün Kütüphanesi</h2>
          <button
            onClick={onClose}
            style={{ border: "none", background: "none", cursor: "pointer", fontSize: 13, color: "var(--ink-muted)" }}
          >
            Kapat
          </button>
        </div>

        {status === "loading" && <p style={{ color: "var(--ink-muted)", fontSize: 13 }}>Yükleniyor…</p>}
        {status === "error" && <p style={{ color: "var(--ink-muted)", fontSize: 13 }}>Hata: {error}</p>}
        {status === "done" && products.length === 0 && (
          <p style={{ color: "var(--ink-muted)", fontSize: 13 }}>Ürün bulunamadı.</p>
        )}

        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(170px, 1fr))", gap: 12 }}>
          {products.map((p) => (
            <div
              key={p.productId}
              className="panel"
              style={{ padding: 10, fontSize: 12, boxShadow: "none" }}
            >
              {p.images[0] ? (
                <img
                  src={p.images[0]}
                  alt={p.name}
                  style={{ width: "100%", height: 96, objectFit: "cover", borderRadius: "var(--radius-sm)", marginBottom: 8 }}
                />
              ) : (
                <div
                  style={{ width: "100%", height: 96, background: "var(--surface-2)", borderRadius: "var(--radius-sm)", marginBottom: 8 }}
                />
              )}
              <div style={{ fontWeight: 600, marginBottom: 4, color: "var(--ink)" }}>{p.name}</div>
              <div className="mono" style={{ color: "var(--ink-muted)", marginBottom: 2, fontSize: 11.5 }}>
                {p.dimensionsMm.w}×{p.dimensionsMm.h}×{p.dimensionsMm.d} mm
              </div>
              <div className="mono" style={{ color: "var(--ink)", marginBottom: 8, fontSize: 13, fontWeight: 600 }}>
                {p.basePrice.toLocaleString("tr-TR")} ₺
              </div>
              <button className="btn" style={{ width: "100%" }} onClick={() => addModuleFromCatalog(p)}>
                Ekle
              </button>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
