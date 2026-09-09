"use client";

import { useCallback, useRef, useState } from "react";
import Image from "next/image";

type Props = {
  beforeSrc: string;
  afterSrc: string;
  beforeAlt: string;
  afterAlt: string;
  beforeLabel?: string;
  afterLabel?: string;
};

// Ottowall'daki sürüklenebilir önce/sonra karşılaştırma mekaniğinin markamıza
// uyarlanmış hali: "after" görseli üstte, clip-path ile sürükleme konumuna göre
// kesiliyor, altta "before" görseli tam görünür duruyor. Pointer Events (mouse +
// dokunmatik + kalem tek API) kullanılıyor, ok tuşlarıyla da kontrol edilebiliyor.
export default function BeforeAfterSlider({
  beforeSrc,
  afterSrc,
  beforeAlt,
  afterAlt,
  beforeLabel = "Önce",
  afterLabel = "Sonra",
}: Props) {
  const containerRef = useRef<HTMLDivElement>(null);
  const [position, setPosition] = useState(50);
  const [dragging, setDragging] = useState(false);

  const updateFromClientX = useCallback((clientX: number) => {
    const el = containerRef.current;
    if (!el) return;
    const rect = el.getBoundingClientRect();
    const ratio = ((clientX - rect.left) / rect.width) * 100;
    setPosition(Math.min(100, Math.max(0, ratio)));
  }, []);

  const handlePointerDown = (e: React.PointerEvent) => {
    e.currentTarget.setPointerCapture(e.pointerId);
    setDragging(true);
    updateFromClientX(e.clientX);
  };

  const handlePointerMove = (e: React.PointerEvent) => {
    if (!dragging) return;
    updateFromClientX(e.clientX);
  };

  const stopDragging = () => setDragging(false);

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === "ArrowLeft") {
      e.preventDefault();
      setPosition((p) => Math.max(0, p - 5));
    } else if (e.key === "ArrowRight") {
      e.preventDefault();
      setPosition((p) => Math.min(100, p + 5));
    }
  };

  return (
    <div
      ref={containerRef}
      onPointerDown={handlePointerDown}
      onPointerMove={handlePointerMove}
      onPointerUp={stopDragging}
      onPointerLeave={stopDragging}
      className="relative h-full w-full cursor-ew-resize touch-none select-none overflow-hidden"
    >
      {/* Alt katman: "önce" görseli, tam alan */}
      <Image
        src={beforeSrc}
        alt={beforeAlt}
        fill
        sizes="(min-width: 1024px) 1152px, 100vw"
        priority
        draggable={false}
        className="pointer-events-none object-cover"
      />

      {/* Üst katman: "sonra" görseli, sürükleme konumuna kadar kesilerek gösterilir */}
      <div
        className="absolute inset-0 overflow-hidden"
        style={{ clipPath: `inset(0 ${100 - position}% 0 0)` }}
      >
        <Image
          src={afterSrc}
          alt={afterAlt}
          fill
          sizes="(min-width: 1024px) 1152px, 100vw"
          priority
          draggable={false}
          className="pointer-events-none object-cover"
        />
      </div>

      {/* Ayırıcı çizgi + tutamaç */}
      <div
        className="pointer-events-none absolute inset-y-0 w-px bg-white/80"
        style={{ left: `${position}%` }}
      />
      <div
        role="slider"
        tabIndex={0}
        aria-label="Önce sonra karşılaştırma"
        aria-valuenow={Math.round(position)}
        aria-valuemin={0}
        aria-valuemax={100}
        onKeyDown={handleKeyDown}
        style={{ left: `${position}%` }}
        className="absolute top-1/2 flex h-11 w-11 -translate-x-1/2 -translate-y-1/2 cursor-ew-resize items-center justify-center rounded-full bg-white text-secondary shadow-lg focus:outline-none focus-visible:ring-2 focus-visible:ring-primary"
      >
        <svg width="16" height="16" viewBox="0 0 16 16" fill="none" aria-hidden="true">
          <path
            d="M5 3 1 8l4 5M11 3l4 5-4 5"
            stroke="currentColor"
            strokeWidth="1.6"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        </svg>
      </div>

      {/* Köşe etiketleri */}
      <span className="pointer-events-none absolute bottom-5 left-5 rounded-full bg-black/50 px-3 py-1.5 font-body text-xs font-medium text-white backdrop-blur-sm sm:bottom-7 sm:left-7">
        {beforeLabel}
      </span>
      <span className="pointer-events-none absolute bottom-5 right-5 rounded-full bg-black/50 px-3 py-1.5 font-body text-xs font-medium text-white backdrop-blur-sm sm:bottom-7 sm:right-7">
        {afterLabel}
      </span>
    </div>
  );
}
