import { useCallback, useEffect, useRef, useState } from "react";
import * as THREE from "three";
import { moduleFootprint } from "../lib/geometry";
import { usePlannerStore } from "../lib/store";
import type { Point, PlannerModule, Room } from "../lib/types";

// IKEA Kreativ modeli (bkz. planner.md): "her şey 3D üzerinden" — 2D canvas
// artık birincil (hatta tek) etkileşim yüzeyi değil, PlannerCanvas kaldırıldı.
// Bu bileşen artık yalnızca kamera döndürme değil, modül seçme/sürükleme/
// döndürme ve kapı/pencere yerleştirmeyi doğrudan 3D sahnede yapıyor — ama
// alttaki mm-hassasiyetli snap/çarpışma/anchor motoru (store.ts, snap.ts)
// birebir aynı kalıyor, yalnızca girdi kaynağı (canvas px yerine 3D raycast)
// değişti. Gerçek zamanlı ışıklandırma eklendi (ambient + tek directional,
// gölge haritası YOK — "pc'yi yormasın": iki ekstra ışık hesای gölge
// haritasından çok daha ucuz) ki bırakılan mobilya "ortam ışığıyla uyumunu
// anında" göstersin.

const MM_TO_M = 0.001;
const MIN_ZOOM = 0.4;
const MAX_ZOOM = 3;
const ACCENT = "#0058a3";
const WARN = "#b5502a";

function disposeObject3D(root: THREE.Object3D) {
  root.traverse((obj) => {
    if (obj instanceof THREE.Mesh) {
      obj.geometry.dispose();
      const materials = Array.isArray(obj.material) ? obj.material : [obj.material];
      for (const m of materials) m.dispose();
    }
  });
}

function buildFloor(room: Room): THREE.Mesh {
  const w = room.dimensionsMm.width * MM_TO_M;
  const d = room.dimensionsMm.depth * MM_TO_M;
  const geometry = new THREE.PlaneGeometry(w, d);
  const material = new THREE.MeshStandardMaterial({ color: "#eae7e1", roughness: 0.95, metalness: 0 });
  const floor = new THREE.Mesh(geometry, material);
  floor.rotation.x = -Math.PI / 2;
  floor.position.set(w / 2, 0, d / 2);
  return floor;
}

function buildWalls(room: Room): { group: THREE.Group; meshes: THREE.Mesh[] } {
  const group = new THREE.Group();
  const meshes: THREE.Mesh[] = [];
  const heightM = room.dimensionsMm.height * MM_TO_M;
  const material = new THREE.MeshStandardMaterial({ color: "#948d80", roughness: 0.9, metalness: 0 });

  for (const wall of room.walls) {
    const dx = wall.end.x - wall.start.x;
    const dy = wall.end.y - wall.start.y;
    const lengthM = Math.hypot(dx, dy) * MM_TO_M;
    if (lengthM < 0.001) continue;

    const geometry = new THREE.BoxGeometry(lengthM, heightM, wall.thicknessMm * MM_TO_M);
    const mesh = new THREE.Mesh(geometry, material);
    const midX = ((wall.start.x + wall.end.x) / 2) * MM_TO_M;
    const midZ = ((wall.start.y + wall.end.y) / 2) * MM_TO_M;
    mesh.position.set(midX, heightM / 2, midZ);
    mesh.rotation.y = -Math.atan2(dy, dx);
    group.add(mesh);
    meshes.push(mesh);
  }

  return { group, meshes };
}

// Kapı/pencere işaretleri: gerçek bir delik açmıyor (kutu geometrisiyle
// "gerçek delik" kesişim gerektirir, bu ölçekte gereksiz karmaşıklık) —
// bunun yerine duvarın üstünde, açıklığın tam mm konum/boyutunda renkli bir
// panel (kapı=toprak tonu, pencere=mavi) gösteriyor. 2D'deki (kaldırılan)
// PlannerCanvas'ın aynı renk kuralıyla tutarlı.
function buildOpenings(room: Room): THREE.Group {
  const group = new THREE.Group();

  for (const opening of room.openings) {
    const wall = room.walls.find((w) => w.id === opening.wallId);
    if (!wall) continue;
    const dx = wall.end.x - wall.start.x;
    const dy = wall.end.y - wall.start.y;
    const len = Math.hypot(dx, dy) || 1;
    const ux = dx / len;
    const uy = dy / len;
    const midOffset = opening.offsetMm + opening.widthMm / 2;
    const midX = (wall.start.x + ux * midOffset) * MM_TO_M;
    const midZ = (wall.start.y + uy * midOffset) * MM_TO_M;

    const widthM = opening.widthMm * MM_TO_M;
    const heightM = opening.heightMm * MM_TO_M;
    const sillM = opening.sillHeightMm * MM_TO_M;
    const thicknessM = wall.thicknessMm * MM_TO_M * 1.05; // duvardan hafif taşsın, z-fighting olmasın

    const geometry = new THREE.BoxGeometry(widthM, heightM, thicknessM);
    const material = new THREE.MeshStandardMaterial({
      color: opening.type === "door" ? "#a84e29" : "#0058a3",
      roughness: 0.7,
      metalness: 0,
    });
    const mesh = new THREE.Mesh(geometry, material);
    mesh.position.set(midX, sillM + heightM / 2, midZ);
    mesh.rotation.y = -Math.atan2(dy, dx);
    group.add(mesh);
  }

  return group;
}

// Rotasyon her zaman 90°'nin katı olduğundan (§3.1), moduleFootprint()'in
// zaten eksene hizalı yer kaplama alanını (w/d yer değiştirmiş) doğrudan kutu
// boyutu olarak kullanmak, ek bir Y-ekseni rotasyonu uygulamaktan daha basit
// ve 2D ile birebir tutarlı.
function buildModules(modules: PlannerModule[], selectedIds: string[]): { group: THREE.Group; meshes: Map<string, THREE.Mesh> } {
  const group = new THREE.Group();
  const meshes = new Map<string, THREE.Mesh>();

  for (const mod of modules) {
    const footprint = moduleFootprint(mod);
    const wM = footprint.w * MM_TO_M;
    const dM = footprint.h * MM_TO_M;
    const hM = mod.dimensionsMm.h * MM_TO_M;
    const selected = selectedIds.includes(mod.id);

    const geometry = new THREE.BoxGeometry(wM, hM, dM);
    const material = new THREE.MeshStandardMaterial({
      color: mod.meta.colorHex ?? "#c9d2cf",
      roughness: 0.6,
      metalness: 0,
      emissive: selected ? new THREE.Color(ACCENT) : new THREE.Color(0x000000),
      emissiveIntensity: selected ? 0.25 : 0,
    });
    const mesh = new THREE.Mesh(geometry, material);
    mesh.position.set((footprint.x + footprint.w / 2) * MM_TO_M, hM / 2, (footprint.y + footprint.h / 2) * MM_TO_M);
    mesh.userData.moduleId = mod.id;
    group.add(mesh);
    meshes.set(mod.id, mesh);
  }

  return { group, meshes };
}

function buildGhostBox(footprint: { w: number; h: number }, heightMm: number, positionMm: Point): THREE.Mesh {
  const wM = footprint.w * MM_TO_M;
  const dM = footprint.h * MM_TO_M;
  const hM = heightMm * MM_TO_M;
  const geometry = new THREE.BoxGeometry(wM, hM, dM);
  const material = new THREE.MeshBasicMaterial({ color: WARN, transparent: true, opacity: 0.35, depthWrite: false });
  const mesh = new THREE.Mesh(geometry, material);
  mesh.position.set((positionMm.x + footprint.w / 2) * MM_TO_M, hM / 2, (positionMm.y + footprint.h / 2) * MM_TO_M);
  return mesh;
}

function orbitPosition(target: THREE.Vector3, distance: number, azimuth: number, elevation: number): THREE.Vector3 {
  const horizontalR = distance * Math.cos(elevation);
  return new THREE.Vector3(
    target.x + horizontalR * Math.sin(azimuth),
    target.y + distance * Math.sin(elevation),
    target.z + horizontalR * Math.cos(azimuth),
  );
}

function clamp(v: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, v));
}

function distance2D(a: Point, b: Point): number {
  return Math.hypot(a.x - b.x, a.y - b.y);
}

function midpoint2D(a: Point, b: Point): Point {
  return { x: (a.x + b.x) / 2, y: (a.y + b.y) / 2 };
}

interface FeedbackState {
  screenPos: Point;
  mm: Point;
  blocked: boolean;
  snapTarget: "wall" | "neighbor" | "anchor" | null;
  // Engellendiğinde `mm`, MoveResult sözleşmesi gereği modülün DEĞİŞMEMİŞ
  // (orijinal) konumuna eşittir — hayalet kutunun kullanıcının bırakmaya
  // çalıştığı yeri gösterebilmesi için ham (snap/çarpışma öncesi) denenen
  // konum ayrıca taşınır.
  attempted: Point;
}

type Gesture =
  | { type: "idle" }
  | { type: "drag-module"; id: string; offsetX: number; offsetY: number }
  | { type: "drag-group"; anchorId: string; offsetX: number; offsetY: number }
  | { type: "orbit"; startX: number; startAzimuth: number }
  | { type: "pinch"; startDistance: number; startZoom: number };

export default function Scene3D() {
  const containerRef = useRef<HTMLDivElement>(null);
  const [size, setSize] = useState({ w: 640, h: 460 });
  const [feedback, setFeedback] = useState<FeedbackState | null>(null);

  const room = usePlannerStore((s) => s.room);
  const modules = usePlannerStore((s) => s.modules);
  const selectedModuleIds = usePlannerStore((s) => s.selectedModuleIds);
  const selectModule = usePlannerStore((s) => s.selectModule);
  const toggleSelectModule = usePlannerStore((s) => s.toggleSelectModule);
  const moveModule = usePlannerStore((s) => s.moveModule);
  const moveModuleGroup = usePlannerStore((s) => s.moveModuleGroup);
  const openingMode = usePlannerStore((s) => s.openingMode);
  const placeOrRemoveOpening = usePlannerStore((s) => s.placeOrRemoveOpening);

  const sceneRef = useRef<{
    renderer: THREE.WebGLRenderer;
    scene: THREE.Scene;
    camera: THREE.OrthographicCamera;
    roomGroup: THREE.Group;
    moduleGroup: THREE.Group;
    ghostGroup: THREE.Group;
    wallMeshes: THREE.Mesh[];
    moduleMeshes: Map<string, THREE.Mesh>;
    target: THREE.Vector3;
    distance: number;
  } | null>(null);

  const raycasterRef = useRef(new THREE.Raycaster());
  const groundPlaneRef = useRef(new THREE.Plane(new THREE.Vector3(0, 1, 0), 0));
  const orbitRef = useRef({ azimuth: Math.PI / 4, elevation: 0.85 });
  const pointersRef = useRef<Map<number, Point>>(new Map());
  const gestureRef = useRef<Gesture>({ type: "idle" });

  // Kapsayıcı boyutunu izler (mobilde küçülür, masaüstünde büyür).
  useEffect(() => {
    const el = containerRef.current;
    if (!el) return;
    const ro = new ResizeObserver((entries) => {
      const w = clamp(Math.floor(entries[0].contentRect.width), 280, 760);
      setSize({ w, h: Math.round(w * 0.72) });
    });
    ro.observe(el);
    return () => ro.disconnect();
  }, []);

  const render = () => {
    const s = sceneRef.current;
    if (!s) return;
    s.renderer.render(s.scene, s.camera);
  };

  const updateCamera = () => {
    const s = sceneRef.current;
    if (!s) return;
    const pos = orbitPosition(s.target, s.distance, orbitRef.current.azimuth, orbitRef.current.elevation);
    s.camera.position.copy(pos);
    s.camera.lookAt(s.target);
  };

  // Kurulum — bir kez. Renderer/scene/camera imperatif Three.js nesneleridir.
  useEffect(() => {
    const container = containerRef.current;
    if (!container) return;

    const scene = new THREE.Scene();
    scene.background = new THREE.Color("#f5f4f2");

    const camera = new THREE.OrthographicCamera(-1, 1, 1, -1, 0.1, 100);
    const renderer = new THREE.WebGLRenderer({ antialias: true });
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    renderer.outputColorSpace = THREE.SRGBColorSpace;
    container.appendChild(renderer.domElement);

    // Gerçek zamanlı ışıklandırma: gölge haritası YOK (pahalı), yalnızca
    // ambient (yumuşak dolgu) + tek directional (yön/hacim hissi) — iki
    // uniform hesabı, herhangi bir donanımda ölçülemeyecek kadar ucuz.
    const ambient = new THREE.AmbientLight(0xffffff, 0.7);
    const directional = new THREE.DirectionalLight(0xffffff, 0.85);
    directional.position.set(4, 7, 3);
    scene.add(ambient, directional);

    const roomGroup = new THREE.Group();
    const moduleGroup = new THREE.Group();
    const ghostGroup = new THREE.Group();
    scene.add(roomGroup, moduleGroup, ghostGroup);

    sceneRef.current = {
      renderer,
      scene,
      camera,
      roomGroup,
      moduleGroup,
      ghostGroup,
      wallMeshes: [],
      moduleMeshes: new Map(),
      target: new THREE.Vector3(),
      distance: 6,
    };

    return () => {
      renderer.dispose();
      disposeObject3D(roomGroup);
      disposeObject3D(moduleGroup);
      disposeObject3D(ghostGroup);
      container.removeChild(renderer.domElement);
      sceneRef.current = null;
    };
  }, []);

  // Viewport boyutu değişince renderer + ortografik frustum güncellenir.
  useEffect(() => {
    const s = sceneRef.current;
    if (!s) return;
    s.renderer.setSize(size.w, size.h);
    const aspect = size.w / size.h;
    const viewSize = s.distance * 0.62;
    s.camera.left = -viewSize * aspect;
    s.camera.right = viewSize * aspect;
    s.camera.top = viewSize;
    s.camera.bottom = -viewSize;
    s.camera.updateProjectionMatrix();
    render();
  }, [size]);

  // Oda/modüller/seçim değiştiğinde sahne geometrisini yeniden kurar.
  // Kamerayı YENİDEN ÇERÇEVELEMEZ (ayrı [room.id] efekti) — aksi halde 3D'de
  // doğrudan sürükleme her adımda `modules`'ı değiştireceğinden kamera her
  // pointermove'da zıplardı.
  useEffect(() => {
    const s = sceneRef.current;
    if (!s) return;

    disposeObject3D(s.roomGroup);
    disposeObject3D(s.moduleGroup);
    s.roomGroup.clear();
    s.moduleGroup.clear();

    const floor = buildFloor(room);
    const { group: wallGroup, meshes: wallMeshes } = buildWalls(room);
    s.roomGroup.add(floor, wallGroup, buildOpenings(room));
    s.wallMeshes = wallMeshes;

    const { group: moduleGroupContent, meshes: moduleMeshes } = buildModules(modules, selectedModuleIds);
    s.moduleGroup.add(moduleGroupContent);
    s.moduleMeshes = moduleMeshes;

    render();
  }, [room, modules, selectedModuleIds]);

  // Kamerayı yalnızca oda TAMAMEN değişince (yeni şablon) ya da viewport
  // boyutu değişince yeniden çerçeveler — PlannerCanvas'ın eski `room.id`
  // ayrımıyla aynı ilke.
  useEffect(() => {
    const s = sceneRef.current;
    if (!s) return;

    const wM = room.dimensionsMm.width * MM_TO_M;
    const dM = room.dimensionsMm.depth * MM_TO_M;
    s.target.set(wM / 2, 0, dM / 2);
    s.distance = Math.max(wM, dM) * 1.15 + 1.5;

    const aspect = size.w / size.h;
    const viewSize = s.distance * 0.62;
    s.camera.left = -viewSize * aspect;
    s.camera.right = viewSize * aspect;
    s.camera.top = viewSize;
    s.camera.bottom = -viewSize;
    s.camera.updateProjectionMatrix();

    updateCamera();
    render();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [room.id]);

  // Çarpışma/engelleme hayaleti: seçili modül(ler) sürükleme sırasında
  // çakışmaya girdiğinde, kullanıcının bırakmaya çalıştığı yerde yarı
  // saydam kırmızı bir kutu gösterilir (2D'deki §Faz4 kırmızı kesikli
  // dikdörtgenin 3D karşılığı).
  useEffect(() => {
    const s = sceneRef.current;
    if (!s) return;
    disposeObject3D(s.ghostGroup);
    s.ghostGroup.clear();

    if (!feedback?.blocked) {
      render();
      return;
    }

    const gesture = gestureRef.current;
    const targets: PlannerModule[] =
      gesture.type === "drag-group"
        ? modules.filter((m) => selectedModuleIds.includes(m.id))
        : gesture.type === "drag-module"
          ? modules.filter((m) => m.id === gesture.id)
          : [];
    const anchorModule = modules.find((m) => m.id === (gesture.type === "drag-group" ? gesture.anchorId : gesture.type === "drag-module" ? gesture.id : ""));
    if (!anchorModule) {
      render();
      return;
    }
    const dx = feedback.attempted.x - anchorModule.position.x;
    const dy = feedback.attempted.y - anchorModule.position.y;

    for (const m of targets) {
      const fp = moduleFootprint(m);
      s.ghostGroup.add(buildGhostBox(fp, m.dimensionsMm.h, { x: fp.x + dx, y: fp.y + dy }));
    }
    render();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [feedback]);

  const clientToLocal = useCallback((clientX: number, clientY: number): Point => {
    const rect = containerRef.current!.getBoundingClientRect();
    return { x: clientX - rect.left, y: clientY - rect.top };
  }, []);

  // Ekran-pikseli konumunu 3D ışın izleme (raycast) için normalize edilmiş
  // cihaz koordinatına (-1..1) çevirir.
  const raycastFromClient = useCallback(
    (clientX: number, clientY: number) => {
      const s = sceneRef.current;
      if (!s) return null;
      const local = clientToLocal(clientX, clientY);
      const ndc = new THREE.Vector2((local.x / size.w) * 2 - 1, -(local.y / size.h) * 2 + 1);
      raycasterRef.current.setFromCamera(ndc, s.camera);
      return raycasterRef.current;
    },
    [clientToLocal, size],
  );

  // İmlecin altındaki zemin (y=0) düzlemi ile kesişim noktasını mm cinsinden
  // döndürür — sürükleme sırasında "modülü nereye bırakmaya çalışıyor"
  // sorusunun tek kaynağı budur (obje yüksekliğinden bağımsız, paralaks yok).
  const groundHitMm = useCallback((clientX: number, clientY: number): Point | null => {
    const raycaster = raycastFromClient(clientX, clientY);
    if (!raycaster) return null;
    const hit = new THREE.Vector3();
    if (!raycaster.ray.intersectPlane(groundPlaneRef.current, hit)) return null;
    return { x: hit.x / MM_TO_M, y: hit.z / MM_TO_M };
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [raycastFromClient]);

  const handlePointerDown = (e: React.PointerEvent<HTMLDivElement>) => {
    try {
      containerRef.current?.setPointerCapture(e.pointerId);
    } catch {
      // PlannerCanvas'taki (kaldırıldı) aynı NotFoundError olasılığı — yut.
    }
    pointersRef.current.set(e.pointerId, { x: e.clientX, y: e.clientY });

    if (openingMode) {
      const raycaster = raycastFromClient(e.clientX, e.clientY);
      const s = sceneRef.current;
      if (raycaster && s) {
        const hit = raycaster.intersectObjects(s.wallMeshes, false)[0];
        if (hit) placeOrRemoveOpening({ x: hit.point.x / MM_TO_M, y: hit.point.z / MM_TO_M });
      }
      return;
    }

    if (pointersRef.current.size >= 2) {
      const pts = [...pointersRef.current.values()].slice(0, 2);
      gestureRef.current = {
        type: "pinch",
        startDistance: distance2D(pts[0], pts[1]) || 1,
        startZoom: sceneRef.current?.camera.zoom ?? 1,
      };
      return;
    }

    const raycaster = raycastFromClient(e.clientX, e.clientY);
    const s = sceneRef.current;
    const moduleHit = raycaster && s ? raycaster.intersectObjects([...s.moduleMeshes.values()], false)[0] : undefined;

    if (!moduleHit) {
      selectModule(null);
      gestureRef.current = { type: "orbit", startX: e.clientX, startAzimuth: orbitRef.current.azimuth };
      return;
    }

    const hitId = moduleHit.object.userData.moduleId as string;
    const hitModule = modules.find((m) => m.id === hitId);
    if (!hitModule) return;

    // Grab noktası MUTLAKA zemin düzleminden (y=0) alınmalı, modül mesh'inin
    // kendi yüzeyinden DEĞİL: kamera açılı (izometrik orbit) olduğundan, uzun
    // bir kutunun ÜST yüzeyindeki bir kesişim noktasının x/z'si, aynı ekran
    // pikselinin y=0 zemin düzlemiyle kesiştiği x/z'den FARKLIDIR (paralaks) —
    // sürükleme sırasında (handlePointerMove) zaten zemin düzlemi kullanıldığı
    // için, ofset de aynı referans düzlemden hesaplanmazsa modül her sürüklemede
    // tutma yüksekliğiyle orantılı bir sıçrama yapar. Mesh raycast'i yalnızca
    // "hangi modüle tıklandı" sorusu için kullanılıyor.
    const grabGround = groundHitMm(e.clientX, e.clientY);
    if (!grabGround) return;
    const grabMm = grabGround;

    if (e.shiftKey) {
      toggleSelectModule(hitId);
      gestureRef.current = { type: "idle" };
      return;
    }

    const isGroupDrag = selectedModuleIds.length > 1 && selectedModuleIds.includes(hitId);
    if (!isGroupDrag) selectModule(hitId);
    gestureRef.current = isGroupDrag
      ? { type: "drag-group", anchorId: hitId, offsetX: grabMm.x - hitModule.position.x, offsetY: grabMm.y - hitModule.position.y }
      : { type: "drag-module", id: hitId, offsetX: grabMm.x - hitModule.position.x, offsetY: grabMm.y - hitModule.position.y };
  };

  const handlePointerMove = (e: React.PointerEvent<HTMLDivElement>) => {
    if (!pointersRef.current.has(e.pointerId)) return;
    pointersRef.current.set(e.pointerId, { x: e.clientX, y: e.clientY });

    const gesture = gestureRef.current;

    if (gesture.type === "pinch") {
      const pts = [...pointersRef.current.values()];
      if (pts.length < 2) return;
      const [a, b] = pts;
      const ratio = distance2D(a, b) / gesture.startDistance;
      const s = sceneRef.current;
      if (!s) return;
      s.camera.zoom = clamp(gesture.startZoom * ratio, MIN_ZOOM, MAX_ZOOM);
      s.camera.updateProjectionMatrix();
      render();
      return;
    }

    if (gesture.type === "orbit") {
      const dx = e.clientX - gesture.startX;
      orbitRef.current.azimuth = gesture.startAzimuth + (dx / 300) * Math.PI;
      updateCamera();
      render();
      return;
    }

    if (gesture.type === "drag-module" || gesture.type === "drag-group") {
      const ground = groundHitMm(e.clientX, e.clientY);
      if (!ground) return;
      const localPx = clientToLocal(e.clientX, e.clientY);

      const result =
        gesture.type === "drag-module"
          ? moveModule(gesture.id, ground.x - gesture.offsetX, ground.y - gesture.offsetY)
          : moveModuleGroup(gesture.anchorId, ground.x - gesture.offsetX, ground.y - gesture.offsetY);

      if (result) {
        setFeedback({
          screenPos: localPx,
          mm: { x: result.x, y: result.y },
          blocked: result.blocked,
          snapTarget: result.snapTarget,
          attempted: { x: result.attemptedX, y: result.attemptedY },
        });
      }
    }
  };

  const endPointer = (e: React.PointerEvent<HTMLDivElement>) => {
    pointersRef.current.delete(e.pointerId);

    if (gestureRef.current.type === "drag-module" || gestureRef.current.type === "drag-group") {
      setFeedback(null);
    }

    if (pointersRef.current.size === 0) {
      gestureRef.current = { type: "idle" };
      return;
    }

    if (pointersRef.current.size === 1 && gestureRef.current.type === "pinch") {
      const [remaining] = [...pointersRef.current.values()];
      gestureRef.current = { type: "orbit", startX: remaining.x, startAzimuth: orbitRef.current.azimuth };
    }
  };

  // Masaüstünde fare tekerleği ile yakınlaştırma.
  useEffect(() => {
    const container = containerRef.current;
    if (!container) return;
    const onWheel = (e: WheelEvent) => {
      e.preventDefault();
      const s = sceneRef.current;
      if (!s) return;
      const factor = e.deltaY < 0 ? 1.1 : 1 / 1.1;
      s.camera.zoom = clamp(s.camera.zoom * factor, MIN_ZOOM, MAX_ZOOM);
      s.camera.updateProjectionMatrix();
      render();
    };
    container.addEventListener("wheel", onWheel, { passive: false });
    return () => container.removeEventListener("wheel", onWheel);
  }, []);

  return (
    <div
      ref={containerRef}
      style={{
        width: "100%",
        maxWidth: 760,
        position: "relative",
        touchAction: "none",
        cursor: openingMode ? "crosshair" : "grab",
        lineHeight: 0,
        border: "1px solid var(--rule)",
        borderRadius: 10,
        overflow: "hidden",
      }}
      onPointerDown={handlePointerDown}
      onPointerMove={handlePointerMove}
      onPointerUp={endPointer}
      onPointerCancel={endPointer}
      onPointerLeave={endPointer}
    >
      {feedback && (
        <div
          style={{
            position: "absolute",
            left: feedback.screenPos.x,
            top: feedback.screenPos.y - 44,
            transform: "translateX(-50%)",
            background: feedback.blocked ? WARN : "#111111",
            color: "#fff",
            padding: "6px 10px",
            fontSize: 11,
            fontFamily: "var(--font-mono)",
            fontVariantNumeric: "tabular-nums",
            whiteSpace: "nowrap",
            pointerEvents: "none",
            borderRadius: 6,
            boxShadow: "0 4px 12px rgba(17,17,17,0.24)",
          }}
        >
          {Math.round(feedback.mm.x)}, {Math.round(feedback.mm.y)} mm
          {feedback.blocked && " · çakışıyor"}
          {!feedback.blocked && feedback.snapTarget === "wall" && " · duvara kilitli"}
          {!feedback.blocked && feedback.snapTarget === "neighbor" && " · modüle kilitli"}
          {!feedback.blocked && feedback.snapTarget === "anchor" && " · bağlantı noktasına kilitli"}
        </div>
      )}
    </div>
  );
}
