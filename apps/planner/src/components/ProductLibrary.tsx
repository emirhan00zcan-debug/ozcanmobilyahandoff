import { useEffect, useState } from "react";
import { fetchCatalogBrowse, type CatalogProduct } from "../lib/catalog";
import { usePlannerStore } from "../lib/store";

type Status = "loading" | "error" | "done";

export function ProductLibrary({ onClose }: { onClose: () => void }) {
  const addModuleFromCatalog = usePlannerStore((s) => s.addModuleFromCatalog);
  const autoArrangeProducts = usePlannerStore((s) => s.autoArrangeProducts);
  const [products, setProducts] = useState<CatalogProduct[]>([]);
  const [status, setStatus] = useState<Status>("loading");
  const [error, setError] = useState<string | null>(null);
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
  const [arrangeMessage, setArrangeMessage] = useState<string | null>(null);

  const toggleSelected = (productId: string) => {
    setArrangeMessage(null);
    setSelectedIds((prev) => {
      const next = new Set(prev);
      if (next.has(productId)) next.delete(productId);
      else next.add(productId);
      return next;
    });
  };

  const handleAutoArrange = () => {
    const selected = products.filter((p) => selectedIds.has(p.productId));
    if (selected.length === 0) return;
    const { placedCount, unplacedCount } = autoArrangeProducts(selected);
    setSelectedIds(new Set());
    setArrangeMessage(
      unplacedCount === 0
        ? `${placedCount} ürün duvarlara yerleştirildi.`
        : `${placedCount} ürün yerleştirildi, ${unplacedCount} ürün için uygun boş duvar bulunamadı (elle yerleştirebilirsiniz).`,
    );
  };

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
        style={{ padding: 24, width: 700, maxWidth: "90vw", maxHeight: "85vh", overflow: "auto" }}
        onClick={(e) => e.stopPropagation()}
      >
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline", marginBottom: 8, gap: 10, flexWrap: "wrap" }}>
          <h2 style={{ fontSize: 16, fontWeight: 700, margin: 0, color: "var(--ink)", letterSpacing: "-0.01em" }}>Ürün Kütüphanesi</h2>
          <div style={{ display: "flex", gap: 10, alignItems: "baseline" }}>
            {selectedIds.size > 0 && (
              <button className="btn-primary" onClick={handleAutoArrange}>
                Seçilenleri Otomatik Yerleştir ({selectedIds.size})
              </button>
            )}
            <button
              onClick={onClose}
              style={{ border: "none", background: "none", cursor: "pointer", fontSize: 13, color: "var(--ink-muted)" }}
            >
              Kapat
            </button>
          </div>
        </div>
        <p style={{ fontSize: 12, color: "var(--ink-muted)", margin: "0 0 14px" }}>
          Duvarlara otomatik yerleştirmek için ürün(ler) seçin, ya da tek tek "Ekle" ile elle yerleştirin.
        </p>
        {arrangeMessage && (
          <p style={{ fontSize: 12, color: "var(--ink)", margin: "0 0 14px", fontWeight: 600 }}>{arrangeMessage}</p>
        )}

        {status === "loading" && <p style={{ color: "var(--ink-muted)", fontSize: 13 }}>Yükleniyor…</p>}
        {status === "error" && <p style={{ color: "var(--ink-muted)", fontSize: 13 }}>Hata: {error}</p>}
        {status === "done" && products.length === 0 && (
          <p style={{ color: "var(--ink-muted)", fontSize: 13 }}>Ürün bulunamadı.</p>
        )}

        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(180px, 1fr))", gap: 16 }}>
          {products.map((p) => (
            <div key={p.productId} className="product-card" style={{ fontSize: 12 }}>
              {p.images[0] ? (
                <img
                  src={p.images[0]}
                  alt={p.name}
                  style={{
                    width: "100%",
                    height: 150,
                    objectFit: "contain",
                    background: "var(--surface-2)",
                    borderRadius: "var(--radius-sm)",
                    marginBottom: 10,
                  }}
                />
              ) : (
                <div
                  style={{ width: "100%", height: 150, background: "var(--surface-2)", borderRadius: "var(--radius-sm)", marginBottom: 10 }}
                />
              )}
              <div style={{ fontWeight: 600, marginBottom: 4, color: "var(--ink)", lineHeight: 1.3 }}>{p.name}</div>
              <div className="mono" style={{ color: "var(--ink-muted)", marginBottom: 6, fontSize: 11.5 }}>
                {p.dimensionsMm.w}×{p.dimensionsMm.h}×{p.dimensionsMm.d} mm
              </div>
              <div className="mono" style={{ color: "var(--ink)", marginBottom: 10, fontSize: 16, fontWeight: 700 }}>
                {p.basePrice.toLocaleString("tr-TR")} ₺
              </div>
              <label style={{ display: "flex", alignItems: "center", gap: 6, marginBottom: 8, color: "var(--ink-muted)", fontSize: 11 }}>
                <input
                  type="checkbox"
                  checked={selectedIds.has(p.productId)}
                  onChange={() => toggleSelected(p.productId)}
                />
                Otomatik yerleştir için seç
              </label>
              <button className="btn-primary" style={{ width: "100%" }} onClick={() => addModuleFromCatalog(p)}>
                Ekle
              </button>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
