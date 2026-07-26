"use client";

import { useState } from "react";

// Referans sitedeki "Malzeme Kalitemiz ve Üretim Standartlarımız" bloğuyla birebir
// aynı metin — kategori/oda sayfaları arasında ortak (siteye özel) statik içerik.
const BODY = `Klasik ahşap dokulardan modern çizgilere uzanan mobilya tasarımlarımızda, her bir malzemenin kendine has avantajlarını ve sağlamlığını ön plana çıkarıyoruz. Üretim sürecimizin merkezinde yer alan 1. sınıf yüksek yoğunluklu MDF, mobilyalarımıza zamansız bir dayanıklılık ve pürüzsüz bir yüzey kalitesi kazandırır.

Tercih ettiğimiz ham maddeler sadece estetik bir görünüm sunmakla kalmaz; ürünlerimizin ömrünü, fonksiyonelliğini ve evinizdeki güvenliğini belirler. Özcan Mobilya olarak, her detayı yaşam alanlarınıza değer katacak şekilde titizlikle işliyoruz.`;

export default function MaterialQualitySection() {
  const [expanded, setExpanded] = useState(false);

  return (
    <section className="mx-auto max-w-7xl px-4 py-10 sm:px-6 lg:px-8">
      <div className="rounded-2xl bg-secondary/[0.03] p-8 sm:p-10">
        <h2 className="font-display text-2xl font-semibold text-secondary">
          Malzeme Kalitemiz ve Üretim Standartlarımız
        </h2>
        <p
          className={[
            "mt-4 max-w-3xl whitespace-pre-line font-body text-sm leading-relaxed text-secondary-light",
            expanded ? "" : "line-clamp-5",
          ].join(" ")}
        >
          {BODY}
        </p>
        <button
          onClick={() => setExpanded((v) => !v)}
          className="relative mt-3 inline-block font-body text-sm font-semibold text-secondary after:absolute after:inset-x-0 after:-bottom-0.5 after:h-[1.5px] after:origin-left after:scale-x-100 after:bg-secondary"
        >
          {expanded ? "View less" : "View More"}
        </button>
      </div>
    </section>
  );
}
