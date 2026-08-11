import { lazy, Suspense, useEffect, useRef, useState } from "react";
import { BomPanel } from "./components/BomPanel";
import { ModuleInspector } from "./components/ModuleInspector";
import { PlannerCanvas } from "./components/PlannerCanvas";
import { ProductLibrary } from "./components/ProductLibrary";
import { fetchCatalog } from "./lib/catalog";
import { usePlannerStore } from "./lib/store";
import type { PlannerModule } from "./lib/types";

// Three.js yalnızca kullanıcı "3D" moduna geçtiğinde indirilir — 2D
// (varsayılan/birincil) çalışma modu bu bundle'ı hiç yüklemez (§2.1).
const Scene3D = lazy(() => import("./components/Scene3D"));

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

const toolbarButtonStyle = {
  fontFamily: "Consolas, monospace",
  fontSize: 12,
  padding: "6px 10px",
  border: "1px solid #1f5ca6",
  color: "#1f5ca6",
  background: "#fff",
  cursor: "pointer",
} as const;

const toolbarButtonActiveStyle = { ...toolbarButtonStyle, background: "#1f5ca6", color: "#fff" } as const;

export default function App() {
  const addModule = usePlannerStore((s) => s.addModule);
  const drawMode = usePlannerStore((s) => s.drawMode);
  const draftPoints = usePlannerStore((s) => s.draftPoints);
  const toggleDrawMode = usePlannerStore((s) => s.toggleDrawMode);
  const finishRoom = usePlannerStore((s) => s.finishRoom);
  const cancelDraft = usePlannerStore((s) => s.cancelDraft);
  const openingMode = usePlannerStore((s) => s.openingMode);
  const toggleOpeningMode = usePlannerStore((s) => s.toggleOpeningMode);
  const [status, setStatus] = useState<Status>("idle");
  const [error, setError] = useState<string | null>(null);
  const [bomOpen, setBomOpen] = useState(false);
  const [libraryOpen, setLibraryOpen] = useState(false);
  const [viewMode, setViewMode] = useState<"2d" | "3d">("2d");

  // React 19 StrictMode geliştirme modunda mount effect'ini iki kez çalıştırır;
  // `modules.length` gibi durum-tabanlı bir bekçi bunu yakalayamaz çünkü her
  // iki çağrı da effect'in ilk render'daki (boş) kapanışını görür. Tohumlamanın
  // tam olarak bir kez çalışmasını garantilemek için render'lar arası kalıcı
  // bir ref kullanılıyor.
  const seededRef = useRef(false);

  useEffect(() => {
    if (seededRef.current) return;
    seededRef.current = true;

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
          id: crypto.randomUUID(),
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
  }, [addModule]);

  return (
    <div style={{ padding: 16, maxWidth: 1200 }}>
      <div style={{ display: "flex", flexWrap: "wrap", justifyContent: "space-between", alignItems: "baseline", gap: 8, marginBottom: 4 }}>
        <h1 style={{ fontSize: 18, margin: 0 }}>Oda &amp; Mobilya Planlayıcı — Faz 2</h1>
        <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
          {viewMode === "2d" && !drawMode && <button style={toolbarButtonStyle} onClick={toggleDrawMode}>Duvar Çiz</button>}
          {viewMode === "2d" && drawMode && (
            <>
              <button style={toolbarButtonStyle} onClick={cancelDraft}>İptal</button>
              <button
                style={{ ...toolbarButtonStyle, opacity: draftPoints.length < 3 ? 0.4 : 1 }}
                disabled={draftPoints.length < 3}
                onClick={finishRoom}
              >
                Bitir ({draftPoints.length} nokta)
              </button>
            </>
          )}
          {viewMode === "2d" && !drawMode && (
            <>
              <button
                style={openingMode === "door" ? toolbarButtonActiveStyle : toolbarButtonStyle}
                onClick={() => toggleOpeningMode("door")}
              >
                Kapı Ekle
              </button>
              <button
                style={openingMode === "window" ? toolbarButtonActiveStyle : toolbarButtonStyle}
                onClick={() => toggleOpeningMode("window")}
              >
                Pencere Ekle
              </button>
            </>
          )}
          {!drawMode && (
            <button
              style={viewMode === "3d" ? toolbarButtonActiveStyle : toolbarButtonStyle}
              onClick={() => setViewMode(viewMode === "2d" ? "3d" : "2d")}
            >
              {viewMode === "2d" ? "3D" : "2D"}
            </button>
          )}
          <button style={toolbarButtonStyle} onClick={() => setLibraryOpen(true)}>Ürünler</button>
          <button style={toolbarButtonStyle} onClick={() => setBomOpen(true)}>BOM</button>
        </div>
      </div>
      <p style={{ fontSize: 13, color: "#54635e", margin: "0 0 12px" }}>
        {viewMode === "3d" && "Sürükleyerek çevirin, tekerlek/iki parmakla yakınlaştırın — düzenlemek için 2D'ye dönün."}
        {viewMode === "2d" && drawMode && "Oda köşelerini sırayla tıklayın (dik açıya kilitlenir, 50mm ızgaraya yapışır) — bitince Bitir'e basın."}
        {viewMode === "2d" &&
          !drawMode &&
          openingMode &&
          `Bir duvara tıklayın: ${openingMode === "door" ? "kapı" : "pencere"} eklenir; mevcut bir açıklığa tıklayınca kaldırılır.`}
        {viewMode === "2d" && !drawMode && !openingMode && status === "loading" && "Ürün katalogdan yükleniyor…"}
        {viewMode === "2d" && !drawMode && !openingMode && status === "error" && `Hata: ${error}`}
        {viewMode === "2d" &&
          !drawMode &&
          !openingMode &&
          status === "done" &&
          "Modülü sürükleyerek duvara/diğer modüle yaklaştırın ya da seçip sağdaki panelden mm/rotasyon girin."}
      </p>
      <div style={{ display: "flex", gap: 12, alignItems: "flex-start" }}>
        {viewMode === "2d" ? (
          <PlannerCanvas />
        ) : (
          <Suspense fallback={<div style={{ width: "100%", maxWidth: 760, padding: 24, color: "#54635e" }}>3D görünüm yükleniyor…</div>}>
            <Scene3D />
          </Suspense>
        )}
        {viewMode === "2d" && <ModuleInspector />}
      </div>
      {bomOpen && <BomPanel onClose={() => setBomOpen(false)} />}
      {libraryOpen && <ProductLibrary onClose={() => setLibraryOpen(false)} />}
    </div>
  );
}
