"use client";

import { useEffect, useState, useCallback } from "react";
import type { Testimonial } from "@/lib/data/homepage-mock";

type Props = { items: Testimonial[] };

const AUTOPLAY_MS = 6000;

// Referans videodaki gibi her slaytın kendi renk şeması var: 1. koyu teal (beyaz metin),
// 2. pembe pastel, 3. mint pastel (ikisi de koyu metin)
const SCHEMES = [
  { bg: "#0f5c56", text: "text-white", subtext: "text-white/60" },
  { bg: "#f6dede", text: "text-secondary", subtext: "text-secondary-light" },
  { bg: "#dcefe1", text: "text-secondary", subtext: "text-secondary-light" },
];

export default function Testimonials({ items }: Props) {
  const [index, setIndex] = useState(0);

  const goTo = useCallback(
    (i: number) => setIndex((i + items.length) % items.length),
    [items.length],
  );

  useEffect(() => {
    const timer = setInterval(() => goTo(index + 1), AUTOPLAY_MS);
    return () => clearInterval(timer);
  }, [index, goTo]);

  const scheme = SCHEMES[index % SCHEMES.length];

  return (
    <section
      className="py-20 transition-colors duration-700 ease-in-out"
      style={{ backgroundColor: scheme.bg }}
    >
      <div className="mx-auto max-w-3xl px-4 text-center sm:px-6 lg:px-8">
        <p className={`font-body text-xs font-semibold uppercase tracking-[0.2em] ${scheme.subtext}`}>
          Müşteri Deneyimleri
        </p>

        <div key={index} className="mt-8 animate-fade-in">
          <p className={`font-display text-2xl leading-relaxed ${scheme.text}`}>
            &ldquo;{items[index].quote}&rdquo;
          </p>
          <p className={`mt-6 font-body text-sm font-semibold ${scheme.text}`}>
            {items[index].name}
          </p>
          <p className={`font-body text-xs ${scheme.subtext}`}>{items[index].location}</p>
        </div>

        <div className="mt-8 flex items-center justify-center gap-3">
          {items.map((t, i) => (
            <button
              key={t.id}
              onClick={() => goTo(i)}
              aria-label={`${i + 1}. yoruma git`}
              className={[
                "h-2 rounded-full transition-all duration-300",
                i === index ? `w-8 ${scheme.text === "text-white" ? "bg-white" : "bg-secondary"}` : `w-2 ${scheme.text === "text-white" ? "bg-white/40" : "bg-secondary/25"}`,
              ].join(" ")}
            />
          ))}
        </div>
      </div>
    </section>
  );
}
