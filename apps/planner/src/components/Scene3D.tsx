import { useEffect, useRef, useState } from "react";
import * as THREE from "three";
import { moduleFootprint } from "../lib/geometry";
import { usePlannerStore } from "../lib/store";
import type { PlannerModule, Room } from "../lib/types";

// Bu modül yalnızca kullanıcı "3D" moduna geçtiğinde tembel-yüklenir (bkz.
// App.tsx'teki React.lazy) — Three.js hiçbir zaman 2D çalışma modunun
// bundle'ına girmez (§2.1). Gerçek zamanlı gölge haritası, PBR pürüzlülük/
// metaliklik hesapları ve post-processing kasıtlı olarak kullanılmıyor:
// duvar/zemin düz renkli MeshBasicMaterial (ışıksız), modüller tek, paylaşılan
// bir matcap dokusuyla (renk modül başına `color` ile tonlanıyor) — sahnede
// hiç THREE.Light nesnesi yok, per-piksel aydınlatma hesabı sıfır.

const MM_TO_M = 0.001;
const MIN_ZOOM = 0.4;
const MAX_ZOOM = 3;

function createMatcapTexture(): THREE.CanvasTexture {
  const size = 128;
  const canvas = document.createElement("canvas");
  canvas.width = size;
  canvas.height = size;
  const ctx = canvas.getContext("2d")!;
  const gradient = ctx.createRadialGradient(size * 0.35, size * 0.32, size * 0.04, size * 0.5, size * 0.5, size * 0.62);
  gradient.addColorStop(0, "#ffffff");
  gradient.addColorStop(0.55, "#aeb4b1");
  gradient.addColorStop(1, "#4c5652");
  ctx.fillStyle = gradient;
  ctx.fillRect(0, 0, size, size);
  const texture = new THREE.CanvasTexture(canvas);
  texture.colorSpace = THREE.SRGBColorSpace;
  return texture;
}

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
  const material = new THREE.MeshBasicMaterial({ color: "#dfe4e1" });
  const floor = new THREE.Mesh(geometry, material);
  floor.rotation.x = -Math.PI / 2;
  floor.position.set(w / 2, 0, d / 2);
  return floor;
}

function buildWalls(room: Room): THREE.Group {
  const group = new THREE.Group();
  const heightM = room.dimensionsMm.height * MM_TO_M;
  const material = new THREE.MeshBasicMaterial({ color: "#8a938e" });

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
  }

  return group;
}

// Rotasyon her zaman 90°'nin katı olduğundan (§3.1), moduleFootprint()'in
// zaten eksene hizalı yer kaplama alanını (w/d yer değiştirmiş) doğrudan
// kutu boyutu olarak kullanmak, ek bir Y-ekseni rotasyonu uygulamaktan daha
// basit ve 2D ile birebir tutarlı — düz renkli kutular için görsel sonuç aynı.
function buildModules(modules: PlannerModule[], matcap: THREE.Texture): THREE.Group {
  const group = new THREE.Group();

  for (const mod of modules) {
    const footprint = moduleFootprint(mod);
    const wM = footprint.w * MM_TO_M;
    const dM = footprint.h * MM_TO_M;
    const hM = mod.dimensionsMm.h * MM_TO_M;

    const geometry = new THREE.BoxGeometry(wM, hM, dM);
    const material = new THREE.MeshMatcapMaterial({
      matcap,
      color: mod.meta.colorHex ?? "#c9d2cf",
    });
    const mesh = new THREE.Mesh(geometry, material);
    mesh.position.set((footprint.x + footprint.w / 2) * MM_TO_M, hM / 2, (footprint.y + footprint.h / 2) * MM_TO_M);
    group.add(mesh);
  }

  return group;
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

export default function Scene3D() {
  const containerRef = useRef<HTMLDivElement>(null);
  const [size, setSize] = useState({ w: 640, h: 460 });

  const room = usePlannerStore((s) => s.room);
  const modules = usePlannerStore((s) => s.modules);

  const sceneRef = useRef<{
    renderer: THREE.WebGLRenderer;
    scene: THREE.Scene;
    camera: THREE.OrthographicCamera;
    matcap: THREE.Texture;
    roomGroup: THREE.Group;
    moduleGroup: THREE.Group;
    target: THREE.Vector3;
    distance: number;
  } | null>(null);

  const orbitRef = useRef({ azimuth: Math.PI / 4, elevation: 0.85 });
  const pointersRef = useRef<Map<number, { x: number; y: number }>>(new Map());
  const dragRef = useRef<{ startX: number; startAzimuth: number } | null>(null);
  const pinchRef = useRef<{ startDistance: number; startZoom: number } | null>(null);

  // Kapsayıcı boyutunu izler (mobilde küçülür, masaüstünde büyür — PlannerCanvas ile tutarlı).
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

  // Kurulum — bir kez. Renderer/scene/camera imperatif Three.js nesneleridir,
  // React state'i değildir (§2.3 ile aynı "yalnızca değişince çiz" ilkesi).
  useEffect(() => {
    const container = containerRef.current;
    if (!container) return;

    const scene = new THREE.Scene();
    scene.background = new THREE.Color("#eef2f0");

    const camera = new THREE.OrthographicCamera(-1, 1, 1, -1, 0.1, 100);
    const renderer = new THREE.WebGLRenderer({ antialias: true });
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    container.appendChild(renderer.domElement);

    const matcap = createMatcapTexture();
    const roomGroup = new THREE.Group();
    const moduleGroup = new THREE.Group();
    scene.add(roomGroup, moduleGroup);

    sceneRef.current = { renderer, scene, camera, matcap, roomGroup, moduleGroup, target: new THREE.Vector3(), distance: 6 };

    return () => {
      renderer.dispose();
      matcap.dispose();
      disposeObject3D(roomGroup);
      disposeObject3D(moduleGroup);
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

  // Oda/modüller değiştiğinde sahneyi yeniden kurar ve kamerayı odaya göre çerçeveler.
  useEffect(() => {
    const s = sceneRef.current;
    if (!s) return;

    disposeObject3D(s.roomGroup);
    disposeObject3D(s.moduleGroup);
    s.roomGroup.clear();
    s.moduleGroup.clear();
    s.roomGroup.add(buildFloor(room), buildWalls(room));
    s.moduleGroup.add(buildModules(modules, s.matcap));

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
    // `size` kasıtlı olarak dışarıda bırakıldı: viewport boyutu değişince
    // yalnızca projeksiyon/renderer güncellenir (ayrı [size] efekti), tüm
    // geometriyi yeniden kurmaya gerek yok.
  }, [room, modules]);

  // Fare tekerleği ile yakınlaştırma (ortografik `zoom`, frustum yeniden
  // hesaplamaya gerek yok). Native listener: React'in sentetik onWheel'i
  // pasif olduğundan preventDefault sessizce yok sayılır.
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

  const handlePointerDown = (e: React.PointerEvent<HTMLDivElement>) => {
    try {
      containerRef.current?.setPointerCapture(e.pointerId);
    } catch {
      // PlannerCanvas'taki aynı NotFoundError olasılığı (bkz. o dosyadaki not) — yut.
    }
    pointersRef.current.set(e.pointerId, { x: e.clientX, y: e.clientY });

    if (pointersRef.current.size >= 2) {
      const pts = [...pointersRef.current.values()].slice(0, 2);
      dragRef.current = null;
      pinchRef.current = { startDistance: Math.hypot(pts[0].x - pts[1].x, pts[0].y - pts[1].y) || 1, startZoom: sceneRef.current?.camera.zoom ?? 1 };
      return;
    }

    dragRef.current = { startX: e.clientX, startAzimuth: orbitRef.current.azimuth };
  };

  const handlePointerMove = (e: React.PointerEvent<HTMLDivElement>) => {
    if (!pointersRef.current.has(e.pointerId)) return;
    pointersRef.current.set(e.pointerId, { x: e.clientX, y: e.clientY });

    if (pinchRef.current && pointersRef.current.size >= 2) {
      const pts = [...pointersRef.current.values()];
      const d = Math.hypot(pts[0].x - pts[1].x, pts[0].y - pts[1].y) || 1;
      const s = sceneRef.current;
      if (!s) return;
      s.camera.zoom = clamp(pinchRef.current.startZoom * (d / pinchRef.current.startDistance), MIN_ZOOM, MAX_ZOOM);
      s.camera.updateProjectionMatrix();
      render();
      return;
    }

    if (dragRef.current) {
      const dx = e.clientX - dragRef.current.startX;
      // Ekranın 300px'i tam bir tur (2π) döndürsün — hıza duyarlı ama aşırı değil.
      orbitRef.current.azimuth = dragRef.current.startAzimuth + (dx / 300) * Math.PI;
      updateCamera();
      render();
    }
  };

  const endPointer = (e: React.PointerEvent<HTMLDivElement>) => {
    pointersRef.current.delete(e.pointerId);
    if (pointersRef.current.size < 2) pinchRef.current = null;
    if (pointersRef.current.size === 0) dragRef.current = null;
  };

  return (
    <div
      ref={containerRef}
      style={{ width: "100%", maxWidth: 760, touchAction: "none", cursor: "grab", border: "1px solid #c6d0cb", lineHeight: 0 }}
      onPointerDown={handlePointerDown}
      onPointerMove={handlePointerMove}
      onPointerUp={endPointer}
      onPointerCancel={endPointer}
      onPointerLeave={endPointer}
    />
  );
}
