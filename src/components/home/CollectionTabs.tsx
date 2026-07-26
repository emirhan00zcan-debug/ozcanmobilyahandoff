"use client";

import { useState } from "react";
import Link from "next/link";
import type { CollectionTab } from "@/lib/data/homepage-mock";

type Props = { tabs: CollectionTab[] };

// Sekmelerin altındaki küçük "hızlı bak" ürün fotoları — gerçek gardrop ürün fotoğrafları
const QUICK_PRODUCTS = [
  {
    slug: "modern-klasik-3-kapakli-cerceve-kapakli-mat-beyaz-gardirop",
    name: "Modern Klasik Gardırop",
    image: "/media/k602_closed_studio_1782831490167.jpg",
  },
  {
    slug: "alya-klasik-kemer-detayli-gardirop",
    name: "Alya Klasik Kemer Detaylı Gardırop",
    image: "/media/k88_closed_studio_1782832274292.jpg",
  },
  {
    slug: "klasik-avangart-4-cekmeceli-gardirop",
    name: "Klasik Avangart Gardırop",
    image: "/media/k83_closed_studio_1782833640405.jpg",
  },
  {
    slug: "k37-4-kapili-4-cekmeceli-gardirop",
    name: "K37 Gardırop",
    image: "/media/k37_closed_studio_1782841086991.jpg",
  },
];

export default function CollectionTabs({ tabs }: Props) {
  const [active, setActive] = useState(0);
  const current = tabs[active];

  return (
    <section className="mx-auto max-w-7xl px-4 py-20 sm:px-6 lg:px-8">
      <h2 className="mb-10 font-display text-3xl font-semibold text-secondary">
        Sizin İçin Seçtiklerimiz
      </h2>

      <div className="grid gap-12 lg:grid-cols-[minmax(0,340px)_1fr] lg:items-center">
        {/* Sol: sekme listesi + açıklama + CTA — görselle dikey olarak ortalanır */}
        <div className="flex flex-col items-start justify-center gap-5">
          {tabs.map((tab, i) => (
            <button
              key={tab.id}
              onClick={() => setActive(i)}
              className={[
                "relative font-display text-3xl font-semibold transition-colors after:absolute after:inset-x-0 after:-bottom-1 after:h-[1.5px] after:origin-left after:bg-secondary after:transition-transform after:duration-300 after:ease-out",
                i === active
                  ? "text-secondary after:scale-x-100"
                  : "text-secondary-light/40 hover:text-secondary-light after:scale-x-0 hover:after:scale-x-100",
              ].join(" ")}
            >
              {tab.label}
            </button>
          ))}

          <div className="grid grid-cols-4 gap-2">
            {QUICK_PRODUCTS.map((p) => (
              <Link
                key={p.slug}
                href={`/urun/${p.slug}`}
                aria-label={p.name}
                className="group aspect-square overflow-hidden rounded-lg bg-secondary/[0.04]"
              >
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img
                  src={p.image}
                  alt={p.name}
                  className="h-full w-full object-cover transition-transform duration-300 group-hover:scale-110"
                />
              </Link>
            ))}
          </div>

          <p className="mt-2 font-body text-base text-secondary-light">{current.description}</p>

          <Link
            href={current.ctaHref}
            className="mt-3 rounded-full bg-secondary px-7 py-3.5 font-body text-sm font-semibold text-white transition-all duration-200 hover:scale-105 hover:bg-primary active:scale-95"
          >
            Modelleri İncele
          </Link>
        </div>

        {/* Sağ: aktif sekmenin yaşam alanı görseli */}
        <div key={active} className="animate-fade-in aspect-square w-full overflow-hidden rounded-2xl">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src={current.imageUrl}
            alt={current.label}
            className="h-full w-full object-cover"
          />
        </div>
      </div>
    </section>
  );
}
