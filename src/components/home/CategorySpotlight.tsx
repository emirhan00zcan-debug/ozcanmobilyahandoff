"use client";

import { useCallback, useEffect, useState } from "react";
import Image from "next/image";
import Link from "next/link";
import type { CategorySpotlightCard, CategorySpotlightHero } from "@/lib/data/homepage-mock";

type Props = { hero: CategorySpotlightHero; cards: CategorySpotlightCard[] };

const AUTOPLAY_MS = 6000;

// "Sizin İçin Seçtiklerimiz" sekmelerinin altına, referans Shopify temasındaki
// "Hot Deals" bölümüyle aynı yerleşim: solda büyük tanıtım kartı (foto slider'lı,
// anasayfa üstündeki HeroSlider ile aynı mekanik), sağda 2x2 kategori vitrini.
export default function CategorySpotlight({ hero, cards }: Props) {
  const [index, setIndex] = useState(0);

  const goTo = useCallback(
    (i: number) => setIndex((i + hero.images.length) % hero.images.length),
    [hero.images.length],
  );

  useEffect(() => {
    if (hero.images.length <= 1) return;
    const timer = setInterval(() => goTo(index + 1), AUTOPLAY_MS);
    return () => clearInterval(timer);
  }, [index, goTo, hero.images.length]);

  return (
    <section className="mx-auto max-w-7xl px-4 py-12 sm:px-6 lg:px-8">
      <div className="grid gap-4 lg:grid-cols-2">
        <div className="relative flex min-h-[420px] flex-col justify-end overflow-hidden rounded-2xl bg-secondary/[0.04] lg:min-h-[560px]">
          <div
            className="absolute inset-0 flex transition-transform duration-700 ease-in-out"
            style={{ transform: `translateX(-${index * 100}%)` }}
          >
            {hero.images.map((src, i) => (
              <div key={src} className="relative h-full w-full shrink-0">
                <Image
                  src={src}
                  alt={hero.title}
                  fill
                  sizes="(max-width: 1024px) 100vw, 50vw"
                  priority={i === 0}
                  className="object-cover"
                />
              </div>
            ))}
          </div>
          <div className="pointer-events-none absolute inset-0 bg-gradient-to-t from-black/85 via-black/25 to-transparent" />

          <div className="relative z-10 max-w-md p-9 text-white">
            <p className="font-body text-xs font-semibold uppercase tracking-[0.15em] text-white/70">
              {hero.eyebrow}
            </p>
            <h2 className="mt-3 font-display text-4xl font-bold leading-tight sm:text-5xl">{hero.title}</h2>
            <p className="mt-3 font-body text-sm text-white/80">{hero.description}</p>
            <Link
              href={hero.ctaHref}
              className="btn-sweep mt-6 inline-block rounded-full px-7 py-3.5 font-body text-sm font-semibold text-secondary hover:scale-105 active:scale-95"
            >
              {hero.ctaLabel}
            </Link>
          </div>

          {hero.images.length > 1 && (
            <div className="relative z-10 flex items-center justify-center gap-5 pb-6">
              <button
                onClick={() => goTo(index - 1)}
                aria-label="Önceki fotoğraf"
                className="flex h-9 w-9 items-center justify-center rounded-full text-white/80 transition-colors hover:text-white"
              >
                ‹
              </button>
              <div className="flex gap-2">
                {hero.images.map((src, i) => (
                  <button
                    key={src}
                    onClick={() => goTo(i)}
                    aria-label={`${i + 1}. fotoğrafa git`}
                    className={[
                      "h-2 rounded-full transition-all duration-300",
                      i === index ? "w-8 bg-white" : "w-2 bg-white/40",
                    ].join(" ")}
                  />
                ))}
              </div>
              <button
                onClick={() => goTo(index + 1)}
                aria-label="Sonraki fotoğraf"
                className="flex h-9 w-9 items-center justify-center rounded-full text-white/80 transition-colors hover:text-white"
              >
                ›
              </button>
            </div>
          )}
        </div>

        <div className="grid grid-cols-2 grid-rows-2 gap-4">
          {cards.map((card) => (
            <Link
              key={card.id}
              href={card.href}
              className="group flex flex-col overflow-hidden rounded-2xl bg-secondary/[0.04] transition-colors duration-200 hover:bg-secondary/[0.07]"
            >
              <div className="relative aspect-[4/3] w-full overflow-hidden">
                <Image
                  src={card.imageUrl}
                  alt={card.title}
                  fill
                  sizes="(min-width: 1024px) 25vw, 50vw"
                  className="object-cover transition-transform duration-300 group-hover:scale-105"
                />
              </div>
              <div className="p-4">
                <h3 className="font-display text-base font-semibold text-secondary sm:text-lg">
                  {card.title}
                </h3>
                <p className="mt-1 font-body text-xs text-secondary-light">{card.subtitle}</p>
              </div>
            </Link>
          ))}
        </div>
      </div>
    </section>
  );
}
