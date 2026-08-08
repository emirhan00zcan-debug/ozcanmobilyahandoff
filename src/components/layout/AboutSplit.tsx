import Image from "next/image";
import Link from "next/link";

type Props = {
  eyebrow: string;
  title: string;
  body: string;
  imageUrl: string;
  reverse?: boolean;
  cta?: { label: string; href: string };
};

// Hakkımızda sayfasında iki kez kullanılan görsel+metin bölümü — reverse ile taraf değişir.
export default function AboutSplit({ eyebrow, title, body, imageUrl, reverse, cta }: Props) {
  return (
    <section className="mx-auto max-w-7xl px-4 py-14 sm:px-6 lg:px-8">
      <div className={`grid items-center gap-12 md:grid-cols-2 ${reverse ? "md:[&>*:first-child]:order-2" : ""}`}>
        <div className="relative aspect-[4/3] overflow-hidden rounded-2xl">
          <Image
            src={imageUrl}
            alt={title}
            fill
            sizes="(max-width: 768px) 100vw, 50vw"
            className="object-cover"
          />
        </div>
        <div>
          <p className="font-body text-xs font-semibold uppercase tracking-[0.2em] text-primary">{eyebrow}</p>
          <h2 className="mt-4 font-display text-3xl font-bold leading-snug text-secondary sm:text-4xl">{title}</h2>
          <p className="mt-5 font-body text-base leading-relaxed text-secondary-light">{body}</p>
          {cta && (
            <Link
              href={cta.href}
              className="btn-sweep mt-7 inline-block rounded-full border border-primary/30 px-8 py-3.5 font-body text-sm font-semibold text-secondary hover:scale-105 active:scale-95"
            >
              {cta.label}
            </Link>
          )}
        </div>
      </div>
    </section>
  );
}
