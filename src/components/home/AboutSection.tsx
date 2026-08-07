import Image from "next/image";
import Link from "next/link";
import { FaMapMarkerAlt, FaSmile, FaCouch } from "react-icons/fa";

type Props = {
  data: {
    imageUrl?: string;
    eyebrow: string;
    title: string;
    body: string;
    ctaLabel: string;
    ctaHref: string;
    facts: { label: string }[];
  };
};

const FACT_ICONS = [FaMapMarkerAlt, FaSmile, FaCouch];

export default function AboutSection({ data }: Props) {
  return (
    <section className="mx-auto max-w-7xl px-4 py-20 sm:px-6 lg:px-8">
      <div className="grid items-center gap-14 md:grid-cols-2">
        {/* Sol: görsel + dönen rozet */}
        <div className="relative aspect-square overflow-hidden rounded-2xl bg-secondary/[0.04]">
          {data.imageUrl ? (
            <Image
              src={data.imageUrl}
              alt={data.title}
              fill
              sizes="(max-width: 768px) 100vw, 50vw"
              className="object-cover"
            />
          ) : (
            <div className="flex h-full w-full items-center justify-center text-secondary/10">
              <span className="font-display text-8xl">ÖM</span>
            </div>
          )}
          <div className="absolute right-6 top-6 flex h-24 w-24 items-center justify-center rounded-full bg-primary text-center font-body text-[9px] font-semibold uppercase tracking-widest text-white">
            Kaliteli Tasarım
          </div>
        </div>

        {/* Sağ: metin + fact listesi */}
        <div>
          <p className="font-body text-xs font-semibold uppercase tracking-[0.2em] text-primary">
            {data.eyebrow}
          </p>
          <h2 className="mt-4 font-display text-4xl font-bold leading-snug text-secondary sm:text-5xl">
            {data.title}
          </h2>
          <p className="mt-5 font-body text-base leading-relaxed text-secondary-light">
            {data.body}
          </p>

          <ul className="mt-8 space-y-4">
            {data.facts.map((fact, i) => {
              const Icon = FACT_ICONS[i % FACT_ICONS.length];
              return (
                <li key={fact.label} className="flex items-center gap-3 font-body text-base text-secondary">
                  <Icon className="h-4 w-4 shrink-0 text-primary" />
                  {fact.label}
                </li>
              );
            })}
          </ul>

          <Link
            href={data.ctaHref}
            className="mt-8 inline-block rounded-full bg-secondary px-8 py-3.5 font-body text-sm font-semibold text-white transition-all duration-200 hover:scale-105 hover:bg-primary active:scale-95"
          >
            {data.ctaLabel}
          </Link>
        </div>
      </div>
    </section>
  );
}
