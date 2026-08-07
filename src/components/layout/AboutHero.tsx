import Image from "next/image";

type Props = { title: string; imageUrl: string };

// Hakkımızda sayfasının tam genişlikte, üzerine başlık bindirilmiş banner'ı.
export default function AboutHero({ title, imageUrl }: Props) {
  return (
    <div className="relative h-[280px] overflow-hidden rounded-2xl sm:h-[360px] lg:h-[440px]">
      <Image src={imageUrl} alt={title} fill sizes="100vw" priority className="object-cover" />
      <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-black/10 to-transparent" />
      <h1 className="absolute bottom-8 left-6 max-w-xl font-display text-3xl font-bold leading-tight text-white sm:left-10 sm:text-4xl lg:text-5xl">
        {title}
      </h1>
    </div>
  );
}
