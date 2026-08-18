import { lazy, Suspense, useEffect, useRef, useState } from "react";
import { BomPanel } from "./components/BomPanel";
import { ModuleInspector } from "./components/ModuleInspector";
import { PrintPlan } from "./components/PrintPlan";
import { ProductLibrary } from "./components/ProductLibrary";
import { RoomTemplatePicker } from "./components/RoomTemplatePicker";
import { fetchCatalog } from "./lib/catalog";
import { readHandoffToken } from "./lib/handoff";
import { usePlannerStore } from "./lib/store";
import type { PlannerModule } from "./lib/types";

// IKEA Kreativ modeli (bkz. planner.md): "her şey 3D üzerinden" — 2D canvas
// (PlannerCanvas) tamamen kaldırıldı, Scene3D artık tek/birincil çalışma
// alanı. Yine de tembel yükleniyor: ilk boyama, oda şablonu seçilene kadar
// Three.js'in ~472KB'lık chunk'ını hiç indirmez.
const Scene3D = lazy(() => import("./components/Scene3D"));

// product_id verilmediğinde sahneyi ağdan bağımsız test edilebilir kılan iki
// örnek modül — biri diğerinin sürüklenip çakışma/duvar-snap/anchor
// davranışını gözlemleyebileceği bir komşu olarak konumlandırıldı.
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
  const addModule = usePlannerStore((s) => s.addModule);
  const openingMode = usePlannerStore((s) => s.openingMode);
  const toggleOpeningMode = usePlannerStore((s) => s.toggleOpeningMode);
  const [status, setStatus] = useState<Status>("idle");
  const [error, setError] = useState<string | null>(null);
  const [bomOpen, setBomOpen] = useState(false);
  const [libraryOpen, setLibraryOpen] = useState(false);
  const [printOpen, setPrintOpen] = useState(false);
  const [roomPickerOpen, setRoomPickerOpen] = useState(false);
  // Ana siteden gelen devir token'ı (bkz. lib/handoff.ts) — URL sorgu
  // parametreleri oturum boyunca değişmediğinden bir kez okunması yeterli.
  const [handoffToken] = useState<string | null>(() => readHandoffToken());

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
    <div style={{ padding: "20px 20px 40px", maxWidth: 1200, margin: "0 auto" }}>
      <div style={{ display: "flex", flexWrap: "wrap", justifyContent: "space-between", alignItems: "baseline", gap: 10, marginBottom: 6 }}>
        <h1 style={{ fontSize: 19, fontWeight: 700, letterSpacing: "-0.01em", margin: 0 }}>
          Oda &amp; Mobilya Planlayıcı
        </h1>
        <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
          <button className="btn" onClick={() => setRoomPickerOpen(true)}>
            Oda Boyutu
          </button>
          <button
            className={openingMode === "door" ? "btn btn-active" : "btn"}
            onClick={() => toggleOpeningMode("door")}
          >
            Kapı Ekle
          </button>
          <button
            className={openingMode === "window" ? "btn btn-active" : "btn"}
            onClick={() => toggleOpeningMode("window")}
          >
            Pencere Ekle
          </button>
          <button className="btn" onClick={() => setLibraryOpen(true)}>
            Ürünler
          </button>
          <button className="btn" onClick={() => setBomOpen(true)}>
            BOM
          </button>
          <button className="btn" onClick={() => setPrintOpen(true)}>
            PDF
          </button>
        </div>
      </div>
      <p style={{ fontSize: 13, color: "var(--ink-muted)", margin: "0 0 16px", maxWidth: 640 }}>
        {openingMode && `Bir duvara tıklayın: ${openingMode === "door" ? "kapı" : "pencere"} eklenir; mevcut bir açıklığa tıklayınca kaldırılır.`}
        {!openingMode && status === "loading" && "Ürün katalogdan yükleniyor…"}
        {!openingMode && status === "error" && `Hata: ${error}`}
        {!openingMode &&
          status === "done" &&
          "Sahnede sürükleyerek taşıyın, tıklayıp seçin, Shift+tık ile birden fazlasını birlikte taşıyın. Boş yeri sürükleyerek kamerayı döndürün, tekerlek/iki parmakla yakınlaştırın."}
      </p>
      <div style={{ display: "flex", gap: 16, alignItems: "flex-start" }}>
        <Suspense
          fallback={
            <div className="panel" style={{ width: "100%", maxWidth: 760, aspectRatio: "760 / 547", padding: 24, color: "var(--ink-muted)" }}>
              3D sahne yükleniyor…
            </div>
          }
        >
          <Scene3D />
        </Suspense>
        <ModuleInspector />
      </div>
      {bomOpen && <BomPanel onClose={() => setBomOpen(false)} handoffToken={handoffToken} />}
      {libraryOpen && <ProductLibrary onClose={() => setLibraryOpen(false)} />}
      {printOpen && <PrintPlan onClose={() => setPrintOpen(false)} />}
      {roomPickerOpen && <RoomTemplatePicker onClose={() => setRoomPickerOpen(false)} />}
    </div>
  );
}
