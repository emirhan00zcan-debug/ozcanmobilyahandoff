import Link from "next/link";
import type { PromoCard } from "@/lib/data/homepage-mock";

type Props = { cards: (PromoCard & { imageUrl?: string })[] };

export default function PromoDuo({ cards }: Props) {
  return (
    <section className="mx-auto max-w-7xl px-4 py-12 sm:px-6 lg:px-8">
      <div className="grid grid-cols-1 gap-6 md:grid-cols-2">
        {cards.map((card) => (
          <div
            key={card.id}
            className="relative flex aspect-[4/3] flex-col justify-end overflow-hidden rounded-2xl bg-secondary/[0.04] p-9"
          >
            {card.imageUrl ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img
                src={card.imageUrl}
                alt={card.title}
                className="absolute inset-0 h-full w-full object-cover"
              />
            ) : (
              <div className="absolute inset-0 flex items-center justify-center text-secondary/10">
                <span className="font-display text-6xl">ÖM</span>
              </div>
            )}
            <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/20 to-transparent" />

            {/* Dairesel indirim rozeti */}
            <div className="absolute right-6 top-6 flex h-16 w-16 flex-col items-center justify-center rounded-full bg-primary text-white shadow-md">
              <span className="font-body text-[10px] font-medium leading-none">{card.badgeLabel}</span>
              <span className="font-body text-base font-bold leading-tight">{card.badgeValue}</span>
            </div>

            <div className="relative z-10 max-w-md text-white">
              <h3 className="font-display text-3xl font-semibold">{card.title}</h3>
              <p className="mt-3 font-body text-sm text-white/80">{card.description}</p>
              <Link
                href={card.ctaHref}
                className="mt-6 inline-block rounded-full bg-white px-7 py-3.5 font-body text-sm font-semibold text-secondary transition-all duration-200 hover:scale-105 hover:bg-primary hover:text-white active:scale-95"
              >
                {card.ctaLabel}
              </Link>
            </div>
          </div>
        ))}
      </div>
    </section>
  );
}
