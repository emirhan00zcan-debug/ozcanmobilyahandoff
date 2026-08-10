import { useEffect, useState } from "react";
import { PlannerCanvas } from "./components/PlannerCanvas";
import { fetchCatalog } from "./lib/catalog";
import { usePlannerStore } from "./lib/store";
import type { PlannerModule } from "./lib/types";

// product_id verilmediğinde canvas'ı ağdan bağımsız test edilebilir kılan iki
// örnek modül — biri diğerinin sürüklenip çakışma/duvar-snap davranışını
// gözlemleyebileceği bir komşu olarak konumlandırıldı.
const DEMO_MODULES: PlannerModule[] = [
  {
    id: "demo-1",
    productId: "demo-1",
    productVariationId: null,
    position: { x: 150, y: 150, z: 0 },
    rotationDeg: 0,
    dimensionsMm: { w: 900, h: 2000, d: 600 },
    meta: { name: "Demo Gardırop", colorHex: "#8b5e34" },
  },
  {
    id: "demo-2",
    productId: "demo-2",
    productVariationId: null,
    position: { x: 1400, y: 150, z: 0 },
    rotationDeg: 0,
    dimensionsMm: { w: 600, h: 750, d: 450 },
    meta: { name: "Demo Komodin", colorHex: "#4b6b57" },
  },
];

type Status = "idle" | "loading" | "error" | "done";

export default function App() {
  const modules = usePlannerStore((s) => s.modules);
  const addModule = usePlannerStore((s) => s.addModule);
  const [status, setStatus] = useState<Status>("idle");
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (modules.length > 0) return;

    const productId = new URLSearchParams(window.location.search).get("product_id");
    if (!productId) {
      DEMO_MODULES.forEach(addModule);
      setStatus("done");
      return;
    }

    setStatus("loading");
    fetchCatalog([productId])
      .then(([product]) => {
        if (!product) {
          setError("Ürün katalogda bulunamadı.");
          setStatus("error");
          return;
        }
        addModule({
          id: `mod_${product.productId}`,
          productId: product.productId,
          productVariationId: product.variations[0]?.id ?? null,
          position: { x: 150, y: 150, z: 0 },
          rotationDeg: 0,
          dimensionsMm: product.dimensionsMm,
          meta: {
            name: product.name,
            colorHex: product.variations[0]?.hexColor ?? null,
          },
        });
        setStatus("done");
      })
      .catch((e: unknown) => {
        setError(e instanceof Error ? e.message : "Katalog isteği başarısız oldu.");
        setStatus("error");
      });
  }, [addModule, modules.length]);

  return (
    <div style={{ padding: 16, maxWidth: 960 }}>
      <h1 style={{ fontSize: 18, margin: "0 0 4px" }}>Oda &amp; Mobilya Planlayıcı — Faz 0</h1>
      <p style={{ fontSize: 13, color: "#54635e", margin: "0 0 12px" }}>
        {status === "loading" && "Ürün katalogdan yükleniyor…"}
        {status === "error" && `Hata: ${error}`}
        {status === "done" && "Modülü sürükleyerek duvara veya diğer modüle yaklaştırın — 15mm eşikte kilitlenir."}
      </p>
      <PlannerCanvas />
    </div>
  );
}
