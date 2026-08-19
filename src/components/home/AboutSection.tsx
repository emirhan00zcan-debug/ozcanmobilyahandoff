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
        {/* Sol: görsel + dönen rozet. Dış sarmalayıcıda overflow-hidden YOK ki rozet
            resmin sağ kenarını taşıp resim ile sağdaki metin arasındaki boşlukta,
            ikisinin ortasında dursun (referans tasarımdaki gibi). */}
        <div className="relative">
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
          </div>

          {/* Dönen rozet: metin bir daire boyunca kavisli akar ve SVG sürekli döner (teal marka
              rengi korunur, sarı değil) — merkezdeki ikon rozetle birlikte dönmesin diye ayrı katman.
              İki sütun yan yana durduğunda (md+) resmin sağ kenarını taşırıp resim ile metin
              arasındaki boşlukta durur; mobilde (tek sütun, taşacak boşluk yok) resmin içinde kalır. */}
          <div className="absolute right-4 top-6 flex h-24 w-24 items-center justify-center sm:h-28 sm:w-28 md:-right-12 md:top-10">
            <svg
              viewBox="0 0 100 100"
              className="absolute inset-0 h-full w-full animate-spin-slow motion-reduce:animate-none drop-shadow-lg"
              aria-hidden="true"
            >
              <circle cx="50" cy="50" r="48" className="fill-primary" />
              <path
                id="about-badge-ring"
                d="M 50,50 m -37,0 a 37,37 0 1,1 74,0 a 37,37 0 1,1 -74,0"
                fill="none"
              />
              <text className="fill-white font-body text-[8px] font-semibold uppercase tracking-[0.2em]">
                <textPath href="#about-badge-ring">
                  Kaliteli Tasarım • Özcan Mobilya •
                </textPath>
              </text>
            </svg>
            <span className="relative flex h-10 w-10 items-center justify-center rounded-full bg-white/15">
              <FaCouch className="h-4 w-4 text-white" />
            </span>
            <span className="sr-only">Kaliteli Tasarım — Özcan Mobilya</span>
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
            className="btn-sweep mt-8 inline-block rounded-full border border-primary/30 px-8 py-3.5 font-body text-sm font-semibold text-secondary hover:scale-105 active:scale-95"
          >
            {data.ctaLabel}
          </Link>
        </div>
      </div>
    </section>
  );
}
