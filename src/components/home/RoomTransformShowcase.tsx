"use client";

import { useState } from "react";
import Link from "next/link";
import type { RoomTransform } from "@/lib/data/homepage-mock";
import BeforeAfterSlider from "./BeforeAfterSlider";

type Props = { items: RoomTransform[] };

// Referans (Ottowall) sitedeki sürüklenebilir önce/sonra vitrini — üstte başlık,
// ortada kaydırıcı, kendi marka renklerimiz ve ürünlerimizle. Birden fazla oda
// varsa üstteki pill sekmelerle aralarında geçiş yapılabiliyor.
export default function RoomTransformShowcase({ items }: Props) {
  const [active, setActive] = useState(0);
  const current = items[active];

  return (
    <section className="mx-auto max-w-7xl px-4 py-20 sm:px-6 lg:px-8">
      <div className="mx-auto max-w-2xl text-center">
        <p className="font-body text-xs font-semibold uppercase tracking-[0.25em] text-primary">
          Önce / Sonra
        </p>
        <h2 className="mt-3 font-display text-3xl font-semibold text-secondary sm:text-4xl">
          Özcan Mobilya ile mekanınız nasıl değişir?
        </h2>
        <p className="mt-3 font-body text-sm text-secondary-light">
          Çizgiyi sürükleyin, boş bir köşenin Özcan Mobilya ile nasıl dönüştüğünü görün.
        </p>
      </div>

      {items.length > 1 && (
        <div className="mt-8 flex items-center justify-center gap-3">
          {items.map((item, i) => (
            <button
              key={item.id}
              onClick={() => setActive(i)}
              className={[
                "rounded-full px-5 py-2.5 font-body text-sm font-medium transition-colors",
                i === active
                  ? "bg-secondary text-white"
                  : "border border-secondary/15 text-secondary hover:border-secondary/40",
              ].join(" ")}
            >
              {item.tabLabel}
            </button>
          ))}
        </div>
      )}

      <div className="relative mx-auto mt-10 aspect-[3/2] w-full max-w-3xl overflow-hidden rounded-3xl shadow-xl sm:max-w-4xl">
        <BeforeAfterSlider
          key={current.id}
          beforeSrc={current.beforeImage}
          afterSrc={current.afterImage}
          beforeAlt={`${current.tabLabel} - ${current.beforeLabel}`}
          afterAlt={`${current.tabLabel} - ${current.afterLabel}`}
          beforeLabel={current.beforeLabel}
          afterLabel={current.afterLabel}
        />
      </div>

      <div className="mt-8 flex justify-center">
        <Link
          href={current.ctaHref}
          className="btn-sweep inline-block rounded-full border border-primary/30 px-8 py-3.5 font-body text-sm font-semibold text-secondary hover:scale-105 active:scale-95"
        >
          {current.ctaLabel}
        </Link>
      </div>
    </section>
  );
}
