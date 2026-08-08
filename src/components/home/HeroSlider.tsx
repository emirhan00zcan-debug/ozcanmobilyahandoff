"use client";

import { useEffect, useState, useCallback } from "react";
import Image from "next/image";
import Link from "next/link";
import type { HeroSlide } from "@/lib/data/homepage-mock";

type Props = { slides: (HeroSlide & { imageUrl?: string })[] };

const AUTOPLAY_MS = 6000;

export default function HeroSlider({ slides }: Props) {
  const [index, setIndex] = useState(0);

  const goTo = useCallback(
    (i: number) => setIndex((i + slides.length) % slides.length),
    [slides.length],
  );

  // Sonsuz döngü: otomatik olarak bir sonraki slayta geç
  useEffect(() => {
    const timer = setInterval(() => goTo(index + 1), AUTOPLAY_MS);
    return () => clearInterval(timer);
  }, [index, goTo]);

  return (
    <section className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
    <div className="relative overflow-hidden rounded-3xl">
      {/* Kayan track: her slayt %100 genişlikte, translateX ile yumuşak geçiş */}
      <div
        className="flex transition-transform duration-700 ease-in-out"
        style={{ transform: `translateX(-${index * 100}%)` }}
      >
        {slides.map((slide, i) => (
          <div
            key={slide.id}
            className="relative flex h-[560px] w-full shrink-0 items-center justify-center overflow-hidden bg-gradient-to-br from-secondary/80 via-secondary/60 to-secondary/80 sm:h-[680px]"
          >
            {slide.imageUrl ? (
              <Image
                src={slide.imageUrl}
                alt={slide.title}
                fill
                sizes="100vw"
                priority={i === 0}
                className={["object-cover", i === index ? "animate-hero-zoom" : ""].join(" ")}
              />
            ) : (
              <div className="absolute inset-0 flex items-center justify-center text-white/10">
                <span className="font-display text-9xl">ÖM</span>
              </div>
            )}
            {/* Koyu overlay: metnin okunurluğu için */}
            <div className="absolute inset-0 bg-black/40" />

            <div className="relative z-10 max-w-2xl px-6 text-center text-white">
              {slide.subtitle && (
                <p className="mb-4 font-body text-sm font-semibold uppercase tracking-[0.2em]">
                  {slide.subtitle}
                </p>
              )}
              <h1 className="font-display text-5xl font-bold leading-tight sm:text-6xl">
                {slide.title}
              </h1>
              <Link
                href={slide.ctaHref}
                className="btn-sweep mt-9 inline-block rounded-full px-10 py-4 font-body text-sm font-semibold text-secondary hover:scale-105 active:scale-95"
              >
                {slide.ctaLabel}
              </Link>
            </div>
          </div>
        ))}
      </div>

      {/* Alt-orta navigasyon: ok butonları + dot pagination */}
      <div className="absolute inset-x-0 bottom-6 flex items-center justify-center gap-5">
        <button
          onClick={() => goTo(index - 1)}
          aria-label="Önceki slayt"
          className="flex h-9 w-9 items-center justify-center rounded-full text-white/80 transition-colors hover:text-white"
        >
          ‹
        </button>
        <div className="flex gap-2">
          {slides.map((slide, i) => (
            <button
              key={slide.id}
              onClick={() => goTo(i)}
              aria-label={`${i + 1}. slayta git`}
              className={[
                "h-2 rounded-full transition-all duration-300",
                i === index ? "w-8 bg-white" : "w-2 bg-white/40",
              ].join(" ")}
            />
          ))}
        </div>
        <button
          onClick={() => goTo(index + 1)}
          aria-label="Sonraki slayt"
          className="flex h-9 w-9 items-center justify-center rounded-full text-white/80 transition-colors hover:text-white"
        >
          ›
        </button>
      </div>
    </div>
    </section>
  );
}
