type Props = { title: string; imageUrl?: string };

// Kategori/oda detay sayfalarının üst banner'ı — referans sitedeki collection-hero
// bölümüyle aynı yapı: sol yarı düz renkli başlık paneli, sağ yarı görsel.
export default function CategoryHero({ title, imageUrl }: Props) {
  return (
    <div className="grid h-[320px] overflow-hidden rounded-2xl sm:h-[380px] lg:h-[430px] lg:grid-cols-2">
      <div className="flex items-center bg-primary px-8 sm:px-12 lg:px-16">
        <h1 className="font-display text-4xl font-semibold text-white sm:text-5xl">{title}</h1>
      </div>
      <div className="hidden bg-secondary/[0.04] lg:block">
        {imageUrl ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={imageUrl} alt={title} className="h-full w-full object-cover" />
        ) : null}
      </div>
    </div>
  );
}
