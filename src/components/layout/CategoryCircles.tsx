"use client";

import { useRef } from "react";
import Image from "next/image";
import Link from "next/link";
import { FaChevronRight, FaChevronLeft } from "react-icons/fa";
import type { CategoryCircle } from "@/lib/data/homepage-mock";

type Props = {
  items: CategoryCircle[];
  basePath: string; // örn: "/kategori" veya "/oda"
  size?: "sm" | "lg";
};

export default function CategoryCircles({ items, basePath, size = "sm" }: Props) {
  const circleSize = size === "lg" ? "h-28 w-28" : "h-24 w-24";
  const circlePx = size === "lg" ? 112 : 96;
  const scrollerRef = useRef<HTMLDivElement>(null);

  const scrollBy = (dir: 1 | -1) => {
    scrollerRef.current?.scrollBy({ left: dir * 320, behavior: "smooth" });
  };

  return (
    <div className="group/slider relative mx-auto max-w-7xl animate-fade-in px-4 sm:px-6 lg:px-8">
      <div
        ref={scrollerRef}
        className="scrollbar-hide flex gap-8 overflow-x-auto pb-4 pt-3"
      >
        {items.map((item) => (
          <Link
            key={item.id}
            href={`${basePath}/${item.slug}`}
            className="group flex shrink-0 flex-col items-center gap-3"
          >
            {/* Hover'da hafif yukarı kalkma efekti */}
            <div
              className={[
                circleSize,
                "-translate-y-0 transform overflow-hidden rounded-full border border-secondary/10 bg-secondary/[0.04] transition-transform duration-300 group-hover:-translate-y-1",
              ].join(" ")}
            >
              {item.imageUrl ? (
                <Image
                  src={item.imageUrl}
                  alt={item.name}
                  width={circlePx}
                  height={circlePx}
                  className="h-full w-full object-cover transition-transform duration-300 group-hover:scale-110"
                />
              ) : (
                <div className="flex h-full w-full items-center justify-center bg-secondary/[0.04] font-display text-lg text-secondary/25">
                  {item.name.charAt(0)}
                </div>
              )}
            </div>
            <span className="relative flex max-w-[110px] items-center gap-1 text-center font-body text-[13px] font-medium leading-tight text-secondary after:absolute after:inset-x-0 after:-bottom-0.5 after:h-[1.5px] after:origin-left after:scale-x-0 after:bg-secondary after:transition-transform after:duration-300 after:ease-out group-hover:text-primary group-hover:after:scale-x-100">
              {item.name}
              <FaChevronRight className="hidden h-2 w-2 shrink-0 text-secondary-light md:block" />
            </span>
          </Link>
        ))}
      </div>

      {/* Hover'da beliren ok navigasyonu — sadece masaüstü */}
      <button
        onClick={() => scrollBy(-1)}
        aria-label="Önceki"
        className="absolute left-0 top-1/2 hidden h-10 w-10 -translate-y-1/2 items-center justify-center rounded-full border border-secondary/10 bg-white text-secondary opacity-0 shadow-md transition-opacity duration-200 group-hover/slider:opacity-100 md:flex"
      >
        <FaChevronLeft className="h-3.5 w-3.5" />
      </button>
      <button
        onClick={() => scrollBy(1)}
        aria-label="Sonraki"
        className="absolute right-0 top-1/2 hidden h-10 w-10 -translate-y-1/2 items-center justify-center rounded-full border border-secondary/10 bg-white text-secondary opacity-0 shadow-md transition-opacity duration-200 group-hover/slider:opacity-100 md:flex"
      >
        <FaChevronRight className="h-3.5 w-3.5" />
      </button>
    </div>
  );
}
