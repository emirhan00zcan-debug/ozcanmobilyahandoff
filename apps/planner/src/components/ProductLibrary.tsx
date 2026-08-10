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
        style={{ background: "#fff", border: "1px solid #c6d0cb", padding: 20, width: 640, maxWidth: "90vw", maxHeight: "80vh", overflow: "auto" }}
        onClick={(e) => e.stopPropagation()}
      >
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline", marginBottom: 10 }}>
          <h2 style={{ fontSize: 14, margin: 0 }}>Ürün Kütüphanesi</h2>
          <button onClick={onClose} style={{ border: "none", background: "none", cursor: "pointer", fontSize: 13 }}>
            Kapat
          </button>
        </div>

        {status === "loading" && <p style={{ color: "#54635e", fontSize: 13 }}>Yükleniyor…</p>}
        {status === "error" && <p style={{ color: "#54635e", fontSize: 13 }}>Hata: {error}</p>}
        {status === "done" && products.length === 0 && (
          <p style={{ color: "#54635e", fontSize: 13 }}>Ürün bulunamadı.</p>
        )}

        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(160px, 1fr))", gap: 10 }}>
          {products.map((p) => (
            <div key={p.productId} style={{ border: "1px solid #c6d0cb", padding: 8, fontSize: 12 }}>
              {p.images[0] ? (
                <img src={p.images[0]} alt={p.name} style={{ width: "100%", height: 90, objectFit: "cover", marginBottom: 6 }} />
              ) : (
                <div style={{ width: "100%", height: 90, background: "#e4e9e6", marginBottom: 6 }} />
              )}
              <div style={{ fontWeight: 600, marginBottom: 2 }}>{p.name}</div>
              <div style={{ color: "#54635e", marginBottom: 2, fontFamily: "Consolas, monospace" }}>
                {p.dimensionsMm.w}×{p.dimensionsMm.h}×{p.dimensionsMm.d} mm
              </div>
              <div style={{ color: "#54635e", marginBottom: 6, fontFamily: "Consolas, monospace" }}>
                {p.basePrice.toLocaleString("tr-TR")} ₺
              </div>
              <button
                onClick={() => addModuleFromCatalog(p)}
                style={{
                  width: "100%",
                  fontFamily: "Consolas, monospace",
                  fontSize: 12,
                  padding: "5px 8px",
                  border: "1px solid #1f5ca6",
                  color: "#1f5ca6",
                  background: "#fff",
                  cursor: "pointer",
                }}
              >
                Ekle
              </button>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
