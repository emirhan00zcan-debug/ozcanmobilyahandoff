"use client";

import { useState } from "react";
import Image from "next/image";
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
  // Aktif olmayan diğer iki sekmenin görseli — öndeki görselin arkasında, biri sağda
  // biri solda karartılmış şekilde kısmen görünür (bkz. aşağıdaki görsel yığını).
  const prevTab = tabs[(active - 1 + tabs.length) % tabs.length];
  const nextTab = tabs[(active + 1) % tabs.length];
  const hasSidePeeks = tabs.length > 2;

  return (
    <section className="mx-auto max-w-7xl px-4 py-20 sm:px-6 lg:px-8">
      <div className="grid gap-12 lg:grid-cols-[minmax(0,380px)_1fr] lg:items-start">
        {/* Sol: sekme listesi + açıklama + CTA */}
        <div className="flex flex-col items-start justify-start gap-6 pt-4 lg:pt-8">
          <div className="space-y-4">
            <h2 className="font-body text-sm font-bold text-secondary">
              Sizin İçin Seçtiklerimiz
            </h2>

            <div className="flex flex-col items-start gap-2">
              {tabs.map((tab, i) => (
                <button
                  key={tab.id}
                  onClick={() => setActive(i)}
                  className={[
                    "relative font-display text-2xl sm:text-3xl font-semibold leading-tight transition-colors after:absolute after:inset-x-0 after:-bottom-1 after:h-[3px] after:origin-left after:bg-secondary after:transition-transform after:duration-300 after:ease-out",
                    i === active
                      ? "text-secondary after:scale-x-100"
                      : "text-secondary-light/40 hover:text-secondary-light after:scale-x-0 hover:after:scale-x-100",
                  ].join(" ")}
                >
                  {tab.label}
                </button>
              ))}
            </div>
          </div>

          <div className="grid w-full grid-cols-4 gap-3 mt-2">
            {QUICK_PRODUCTS.map((p) => (
              <Link
                key={p.slug}
                href={`/urun/${p.slug}`}
                aria-label={p.name}
                className="group relative aspect-square overflow-hidden rounded-xl bg-secondary/[0.04]"
              >
                <Image
                  src={p.image}
                  alt={p.name}
                  fill
                  sizes="(min-width: 1024px) 85px, 25vw"
                  className="object-cover transition-transform duration-300 group-hover:scale-110"
                />
              </Link>
            ))}
          </div>

          <p className="font-body text-sm text-secondary-light">{current.description}</p>

          <Link
            href={current.ctaHref}
            className="rounded-full bg-black px-8 py-3.5 font-body text-sm font-semibold text-white transition-all duration-200 hover:scale-[1.02] hover:bg-black/80 active:scale-95"
          >
            Modelleri İncele
          </Link>
        </div>

        {/* Sağ: aktif sekmenin görseli önde, diğer iki sekmenin görseli arkasında
            (biri sağda biri solda daha belirgin taşarak) karartılmış şekilde kısmen görünür.
            Sekme değişince üçü de birlikte, hafif kademeli bir gecikmeyle büyüyerek belirir. */}
        <div className="relative mx-auto w-full max-w-sm">
          {hasSidePeeks && (
            <div
              key={prevTab.id}
              style={{ animationDelay: "80ms" }}
              className="absolute inset-y-6 -left-14 z-0 hidden w-[80%] animate-collection-reveal overflow-hidden rounded-2xl opacity-0 sm:block"
            >
              <Image src={prevTab.imageUrl} alt="" fill sizes="320px" className="object-cover" />
              <div className="absolute inset-0 bg-black/50" />
            </div>
          )}
          {hasSidePeeks && (
            <div
              key={nextTab.id}
              style={{ animationDelay: "80ms" }}
              className="absolute inset-y-6 -right-14 z-0 hidden w-[80%] animate-collection-reveal overflow-hidden rounded-2xl opacity-0 sm:block"
            >
              <Image src={nextTab.imageUrl} alt="" fill sizes="320px" className="object-cover" />
              <div className="absolute inset-0 bg-black/50" />
            </div>
          )}

          <div
            key={active}
            className="relative z-10 aspect-square w-full animate-collection-reveal overflow-hidden rounded-2xl opacity-0 shadow-xl lg:aspect-[4/5]"
          >
            <Image
              src={current.imageUrl}
              alt={current.label}
              fill
              sizes="(min-width: 1024px) 480px, 100vw"
              priority
              className="object-cover"
            />
          </div>
        </div>
      </div>
    </section>
  );
}
