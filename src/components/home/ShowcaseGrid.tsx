import Link from "next/link";
import type { ShowcaseTile } from "@/lib/data/homepage-mock";

type Props = { tiles: (ShowcaseTile & { imageUrl?: string })[] };

function formatPrice(value: number) {
  return new Intl.NumberFormat("tr-TR", { minimumFractionDigits: 2 }).format(value) + "₺";
}

export default function ShowcaseGrid({ tiles }: Props) {
  return (
    <section className="mx-auto max-w-7xl px-4 py-12 sm:px-6 lg:px-8">
      <div className="grid grid-cols-1 gap-1.5 sm:grid-cols-2 lg:grid-cols-4">
        {tiles.map((tile) => (
          <Link
            key={tile.id}
            href={tile.href}
            className="group relative flex aspect-square items-end overflow-hidden bg-secondary/[0.04]"
          >
            {tile.imageUrl ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img
                src={tile.imageUrl}
                alt={tile.title}
                className="absolute inset-0 h-full w-full object-cover transition-transform duration-500 ease-in-out group-hover:scale-105"
              />
            ) : (
              <div className="absolute inset-0 flex items-center justify-center text-secondary/10 transition-transform duration-500 ease-in-out group-hover:scale-105">
                <span className="font-display text-6xl">ÖM</span>
              </div>
            )}
            {/* Okunabilirlik için alttan üste karartma */}
            <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-black/10 to-transparent" />

            <div className="relative z-10 w-full p-6 text-white">
              <p className="font-body text-xs font-medium uppercase tracking-[0.15em] text-white/70">
                {tile.subtitle}
              </p>
              <h3 className="mt-1.5 font-display text-xl font-semibold">{tile.title}</h3>

              {tile.miniProduct && (
                <div className="mt-3 flex items-center gap-2.5 rounded-lg bg-white/95 px-2.5 py-2 text-secondary">
                  <div className="h-8 w-8 shrink-0 rounded bg-secondary/10" />
                  <div className="min-w-0">
                    <p className="truncate font-body text-[11px] font-medium">
                      {tile.miniProduct.name}
                    </p>
                    <p className="font-body text-[11px] font-semibold text-primary">
                      {formatPrice(tile.miniProduct.price)}
                    </p>
                  </div>
                </div>
              )}
            </div>
          </Link>
        ))}
      </div>
    </section>
  );
}
