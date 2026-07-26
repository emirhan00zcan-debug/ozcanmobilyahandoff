import Link from "next/link";
import type { CategoryCircle } from "@/lib/data/homepage-mock";

type Props = {
  items: CategoryCircle[];
  basePath: string; // örn: "/kategori" veya "/oda"
};

// /kategori ve /oda index sayfalarında kullanılan tam liste grid'i —
// CategoryCircles'ın (anasayfadaki yatay kaydırmalı widget) aksine burada tüm öğeler
// tek seferde, kaydırmadan görünür.
export default function CategoryGrid({ items, basePath }: Props) {
  return (
    <div className="grid grid-cols-3 gap-x-4 gap-y-8 sm:grid-cols-4 lg:grid-cols-6">
      {items.map((item) => (
        <Link key={item.id} href={`${basePath}/${item.slug}`} className="group flex flex-col items-center gap-3">
          <div className="h-24 w-24 overflow-hidden rounded-full border border-secondary/10 bg-secondary/[0.04] transition-transform duration-300 group-hover:-translate-y-1 lg:h-28 lg:w-28">
            {item.imageUrl ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img
                src={item.imageUrl}
                alt={item.name}
                className="h-full w-full object-cover transition-transform duration-300 group-hover:scale-110"
              />
            ) : (
              <div className="flex h-full w-full items-center justify-center font-display text-lg text-secondary/25">
                {item.name.charAt(0)}
              </div>
            )}
          </div>
          <span className="relative max-w-[110px] text-center font-body text-sm font-medium leading-tight text-secondary after:absolute after:inset-x-0 after:-bottom-0.5 after:h-[1.5px] after:origin-left after:scale-x-0 after:bg-secondary after:transition-transform after:duration-300 after:ease-out group-hover:text-primary group-hover:after:scale-x-100">
            {item.name}
          </span>
        </Link>
      ))}
    </div>
  );
}
