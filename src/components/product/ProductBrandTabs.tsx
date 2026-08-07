"use client";

import { useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { FaCheck } from "react-icons/fa";
import { productTechnicalTab, productBrandTab } from "@/lib/data/products";

type TabContent = {
  tabLabel: string;
  image: string;
  heading: string;
  body: string;
  checklist: string[];
  ctaLabel?: string;
  ctaHref?: string;
};

const TABS: TabContent[] = [productTechnicalTab, productBrandTab];

export default function ProductBrandTabs() {
  const [active, setActive] = useState(0);
  const tab = TABS[active];

  return (
    <section className="mx-auto max-w-7xl px-4 py-16 sm:px-6 lg:px-8">
      <div className="mb-8 flex gap-8 border-b border-secondary/10">
        {TABS.map((t, i) => (
          <button
            key={t.tabLabel}
            onClick={() => setActive(i)}
            className={[
              "border-b-2 pb-3 font-display text-lg font-semibold transition-colors",
              i === active
                ? "border-secondary text-secondary"
                : "border-transparent text-secondary-light hover:text-secondary",
            ].join(" ")}
          >
            {t.tabLabel}
          </button>
        ))}
      </div>

      <div key={active} className="grid animate-fade-in grid-cols-1 items-center gap-10 md:grid-cols-2">
        <div className="relative aspect-[4/3] overflow-hidden rounded-2xl">
          <Image
            src={tab.image}
            alt={tab.heading}
            fill
            sizes="(max-width: 768px) 100vw, 50vw"
            className="object-cover"
          />
        </div>
        <div>
          <h3 className="font-display text-2xl font-semibold text-secondary">{tab.heading}</h3>
          <p className="mt-3 font-body text-sm leading-relaxed text-secondary-light">{tab.body}</p>

          {tab.ctaLabel && tab.ctaHref && (
            <Link
              href={tab.ctaHref}
              className="mt-5 inline-block rounded-full bg-secondary px-7 py-3.5 font-body text-sm font-semibold text-white transition-all duration-200 hover:scale-105 hover:bg-primary active:scale-95"
            >
              {tab.ctaLabel}
            </Link>
          )}

          <ul className="mt-6 space-y-3">
            {tab.checklist.map((item) => (
              <li key={item} className="flex items-center gap-2.5">
                <FaCheck className="h-3.5 w-3.5 shrink-0 text-secondary" />
                <span className="font-body text-sm font-medium text-secondary">{item}</span>
              </li>
            ))}
          </ul>
        </div>
      </div>
    </section>
  );
}
