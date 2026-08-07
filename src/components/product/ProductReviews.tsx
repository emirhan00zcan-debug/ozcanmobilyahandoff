import Image from "next/image";
import Link from "next/link";
import { FaStar } from "react-icons/fa";
import { BadgeCheck, ChevronRight } from "lucide-react";
import { productReviews } from "@/lib/data/products";

// "Sizden Gelenler" — referans sitedeki koyu lacivert (#1D349A) renk şemasıyla birebir aynı.
export default function ProductReviews({ productSlug }: { productSlug?: string }) {
  const reviews = productSlug
    ? productReviews.filter((r) => r.productSlug === productSlug)
    : productReviews;

  if (reviews.length === 0) {
    return (
      <section className="bg-[#1D349A] py-16">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="mb-8">
            <h2 className="font-display text-3xl font-semibold text-white">Sizden Gelenler</h2>
            <p className="mt-2 text-white/80 font-body text-sm max-w-2xl">
              Bu ürün için henüz örnek değerlendirme bulunmuyor. İlk yorum yapan siz olun!
            </p>
          </div>
        </div>
      </section>
    );
  }

  return (
    <section className="bg-[#1D349A] py-16">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="mb-8 flex flex-col sm:flex-row sm:items-end justify-between gap-4">
          <div>
            <h2 className="font-display text-3xl font-semibold text-white">Sizden Gelenler</h2>
            <p className="mt-2 text-white/80 font-body text-sm max-w-2xl">
              Müşterilerimizin evlerinden örnek deneyimler ve kurulum fotoğrafları. Zamanla puanlama sistemi aktifleşecek ve ürünlere özel yorumlar yayınlanacaktır.
            </p>
          </div>
        </div>
        <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
          {reviews.map((review) => (
            <div key={review.id} className="flex flex-col overflow-hidden rounded-2xl bg-white/5 border border-white/10 hover:bg-white/10 transition-colors">
              <div className="relative aspect-[3/4] w-full overflow-hidden">
                <Image
                  src={review.image}
                  alt={review.name}
                  fill
                  sizes="(max-width: 640px) 100vw, (max-width: 1024px) 50vw, 25vw"
                  className="object-cover"
                />
              </div>
              <div className="flex flex-1 flex-col gap-3 p-5 bg-white">
                <div className="flex items-center justify-between">
                  <div className="flex gap-0.5 text-[#F5B800]">
                    {Array.from({ length: review.rating }).map((_, i) => (
                      <FaStar key={i} className="h-4 w-4" />
                    ))}
                  </div>
                  {review.verifiedPurchase && (
                    <div className="flex items-center gap-1 text-emerald-600 bg-emerald-50 px-2 py-1 rounded-full border border-emerald-100">
                      <BadgeCheck className="h-3.5 w-3.5" />
                      <span className="text-[10px] font-semibold tracking-wide uppercase">Doğrulanmış</span>
                    </div>
                  )}
                </div>

                <p className="font-body text-[14px] leading-relaxed text-slate-700 italic">
                  &quot;{review.quote}&quot;
                </p>

                <div className="mt-auto pt-4 border-t border-slate-100 space-y-3">
                  <div className="flex items-center gap-2">
                    <div className="h-8 w-8 rounded-full bg-slate-100 flex items-center justify-center text-slate-500 font-display font-bold text-sm">
                      {review.name.charAt(0)}
                    </div>
                    <p className="font-display text-sm font-semibold text-slate-900">
                      {review.name}
                    </p>
                  </div>

                  {review.productSlug && review.productName && (
                    <Link
                      href={`/urun/${review.productSlug}`}
                      className="group flex items-center gap-2 rounded-lg bg-slate-50 p-2 text-xs transition-colors hover:bg-slate-100"
                    >
                      <div className="flex flex-1 flex-col">
                        <span className="text-[10px] uppercase tracking-wider text-slate-500 font-medium">Değerlendirilen Ürün</span>
                        <span className="font-semibold text-slate-700 group-hover:text-primary transition-colors line-clamp-1">{review.productName}</span>
                      </div>
                      <ChevronRight className="h-4 w-4 text-slate-400 group-hover:text-primary transition-colors" />
                    </Link>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
