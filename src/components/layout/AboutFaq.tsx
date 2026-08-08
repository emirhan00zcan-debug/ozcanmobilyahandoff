"use client";

import { useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { FaPlus, FaMinus } from "react-icons/fa";

const FAQ_ITEMS = [
  {
    question: "Siparişimin teslimatı ne kadar sürer?",
    answer:
      "Siparişiniz onaylandıktan sonra ortalama 5-10 iş günü içinde hazırlanıp kargoya verilir ve kapınıza kadar teslim edilir.",
  },
  {
    question: "Türkiye genelinde gönderim yapıyor musunuz?",
    answer:
      "Evet, Sinop'taki üretim merkezimizden Türkiye'nin her iline sağlam paketleme ile gönderim yapıyoruz.",
  },
  {
    question: "İade politikanız nedir?",
    answer:
      "30 gün içerisinde koşulsuz iade hakkınız bulunuyor; ürün orijinal ambalajında olduğu sürece ek bir ücret talep etmiyoruz.",
  },
  {
    question: "Ürünleri özel ölçüde yaptırabilir miyim?",
    answer:
      "Bazı modellerimizde farklı ölçü seçenekleri sunuyoruz. Özel ölçü taleplerinizi İletişim sayfamızdan bize iletebilirsiniz.",
  },
];

export default function AboutFaq() {
  const [openIndex, setOpenIndex] = useState<number | null>(0);

  return (
    <section className="bg-[#1D349A] py-16">
      <div className="mx-auto grid max-w-7xl gap-10 px-4 sm:px-6 md:grid-cols-[280px_1fr] lg:px-8">
        <div className="rounded-2xl bg-white p-6">
          <div className="relative aspect-[4/3] overflow-hidden rounded-xl">
            <Image
              src="/media/ozcan-marka-kimligi.jpg"
              alt="Hâlâ yardıma mı ihtiyacınız var?"
              fill
              sizes="(max-width: 768px) 100vw, 280px"
              className="object-cover"
            />
          </div>
          <p className="mt-4 font-display text-lg font-semibold text-secondary">Hâlâ yardıma mı ihtiyacınız var?</p>
          <Link
            href="/iletisim"
            className="btn-sweep mt-4 inline-block rounded-full border border-primary/30 px-6 py-3 font-body text-sm font-semibold text-secondary hover:scale-105 active:scale-95"
          >
            İletişime Geç
          </Link>
        </div>

        <div>
          <h2 className="font-display text-2xl font-semibold text-white sm:text-3xl">
            Sıkça Sorulan Sorularımızda Daha Fazlasını Keşfedin
          </h2>
          <div className="mt-6 divide-y divide-white/15">
            {FAQ_ITEMS.map((item, i) => (
              <div key={item.question}>
                <button
                  onClick={() => setOpenIndex((current) => (current === i ? null : i))}
                  className="flex w-full items-center justify-between py-4 text-left"
                >
                  <span className="font-body text-base font-medium text-white">{item.question}</span>
                  {openIndex === i ? (
                    <FaMinus className="h-3 w-3 shrink-0 text-white" />
                  ) : (
                    <FaPlus className="h-3 w-3 shrink-0 text-white" />
                  )}
                </button>
                {openIndex === i && (
                  <p className="pb-4 font-body text-sm leading-relaxed text-white/80">{item.answer}</p>
                )}
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
