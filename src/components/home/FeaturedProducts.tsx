"use client";

import { useState } from "react";
import Image from "next/image";
import Link from "next/link";
import type { FeaturedBanner, FeaturedProduct } from "@/lib/data/homepage-mock";
import ProductCard from "@/components/product/ProductCard";

type Props = {
  title: string;
  description: string;
  tabs: { label: string; products: FeaturedProduct[] }[];
  allHref: string;
  banner?: FeaturedBanner; // sadece ilk sekmede, grid'in ilk hücresi olarak gösterilir
};

export default function FeaturedProducts({ title, description, tabs, allHref, banner }: Props) {
  const [activeTab, setActiveTab] = useState(0);

  return (
    <section className="mx-auto max-w-7xl px-4 py-20 sm:px-6 lg:px-8">
      <div className="mb-12 flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
        <div>
          <h2 className="font-display text-4xl font-semibold text-secondary">{title}</h2>
          <p className="mt-3 max-w-md font-body text-base text-secondary-light">{description}</p>
        </div>

        {tabs.length > 1 ? (
          <div className="flex gap-6">
            {tabs.map((tab, i) => (
              <button
                key={tab.label}
                onClick={() => setActiveTab(i)}
                className={[
                  "font-body text-sm font-medium underline-offset-4 transition-colors",
                  i === activeTab
                    ? "text-secondary underline"
                    : "text-secondary-light hover:text-secondary",
                ].join(" ")}
              >
                {tab.label}
              </button>
            ))}
          </div>
        ) : (
          <Link
            href={allHref}
            className="font-body text-sm font-medium text-primary underline underline-offset-4"
          >
            Tümünü Gör
          </Link>
        )}
      </div>

      <div
        key={activeTab}
        className="grid animate-fade-in grid-cols-2 gap-6 sm:gap-8 md:grid-cols-3 lg:grid-cols-5"
      >
        {banner && activeTab === 0 && (
          <Link
            href={banner.ctaHref}
            className="group relative flex aspect-square flex-col justify-end overflow-hidden rounded-xl bg-secondary p-5"
          >
            {banner.imageUrl && (
              <Image
                src={banner.imageUrl}
                alt={banner.title}
                fill
                sizes="(max-width: 767px) 50vw, (max-width: 1023px) 33vw, 20vw"
                className="object-cover transition-transform duration-500 ease-in-out group-hover:scale-105"
              />
            )}
            <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-black/15 to-transparent" />
            <div className="relative z-10 text-white">
              <p className="font-body text-xs font-medium uppercase tracking-[0.15em] text-white/70">
                {banner.eyebrow}
              </p>
              <h3 className="mt-1.5 font-display text-xl font-semibold leading-snug">
                {banner.title}
              </h3>
              <span className="mt-4 inline-block rounded-full bg-white px-5 py-2.5 font-body text-xs font-semibold text-secondary transition-all duration-200 group-hover:bg-primary group-hover:text-white">
                {banner.ctaLabel}
              </span>
            </div>
          </Link>
        )}
        {tabs[activeTab].products.map((product) => (
          <ProductCard key={product.id} product={product} />
        ))}
      </div>
    </section>
  );
}
