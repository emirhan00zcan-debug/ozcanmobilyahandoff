import { FaStar } from "react-icons/fa";
import { productReviews } from "@/lib/data/products";

// "Sizden Gelenler" — referans sitedeki koyu lacivert (#1D349A) renk şemasıyla birebir aynı.
export default function ProductReviews() {
  return (
    <section className="bg-[#1D349A] py-16">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <h2 className="mb-8 font-display text-3xl font-semibold text-white">Sizden Gelenler</h2>
        <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
          {productReviews.map((review) => (
            <div key={review.id} className="flex flex-col overflow-hidden rounded-2xl bg-white">
              <div className="aspect-[3/4] w-full overflow-hidden">
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img src={review.image} alt={review.name} className="h-full w-full object-cover" />
              </div>
              <div className="flex flex-1 flex-col gap-2 p-4">
                <div className="flex gap-0.5 text-primary">
                  {Array.from({ length: review.rating }).map((_, i) => (
                    <FaStar key={i} className="h-3 w-3" />
                  ))}
                </div>
                <p className="font-body text-[13px] leading-relaxed text-secondary-light">
                  {review.quote}
                </p>
                <p className="mt-auto font-display text-sm font-semibold text-secondary">
                  {review.name}
                </p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
