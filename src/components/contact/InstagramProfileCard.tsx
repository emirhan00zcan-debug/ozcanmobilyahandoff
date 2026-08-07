import Image from "next/image";
import Link from "next/link";
import { FaInstagram, FaBookmark, FaUserCircle, FaThLarge } from "react-icons/fa";

type Props = {
  href: string;
  handle: string;
  bio: string;
  followers: number;
  following: number;
  highlights: string[];
  images: string[]; // 3'lü sütun ızgarası için
};

// Instagram, tüm profili tıklayıp gezebileceğiniz şekilde gömmeye izin vermiyor (sadece
// tek tek gönderi embed.js'i destekliyor) — bu yüzden gerçek profildeki biyografi/takipçi
// bilgilerini kullanarak IG arayüzünün birebir bir kopyasını çiziyoruz. Telefon çerçevesi
// içi kaydırılabilir (overflow-y-auto), böylece haritadaki gibi "içinde gezinme" hissi verir.
export default function InstagramProfileCard({ href, handle, bio, followers, following, highlights, images }: Props) {
  return (
    <Link href={href} target="_blank" rel="noopener noreferrer" className="group block">
      <div className="mx-auto w-full max-w-[260px] rounded-[2rem] border-[6px] border-secondary bg-secondary shadow-lg transition-transform duration-300 group-hover:-translate-y-1.5">
        <div className="relative h-[460px] overflow-hidden rounded-[1.5rem] bg-white">
          {/* Telefon çentiği */}
          <div className="absolute left-1/2 top-2 z-10 h-1.5 w-12 -translate-x-1/2 rounded-full bg-secondary/60" />

          {/* Kaydırılabilir profil görünümü */}
          <div className="scrollbar-hide h-full overflow-y-auto pt-6">
            {/* Üst bar */}
            <div className="flex items-center justify-center gap-1.5 border-b border-secondary/10 px-3 pb-2.5">
              <span className="font-body text-[11px] font-semibold text-secondary">{handle}</span>
            </div>

            {/* Profil başlığı */}
            <div className="flex items-center gap-4 px-4 pt-3">
              <FaUserCircle className="h-14 w-14 shrink-0 text-secondary/20" />
              <div className="flex flex-1 justify-around text-center">
                <div>
                  <p className="font-body text-xs font-bold text-secondary">{followers}</p>
                  <p className="font-body text-[9px] text-secondary-light">Takipçi</p>
                </div>
                <div>
                  <p className="font-body text-xs font-bold text-secondary">{following}</p>
                  <p className="font-body text-[9px] text-secondary-light">Takip</p>
                </div>
              </div>
            </div>

            <p className="mt-3 px-4 font-body text-[10px] leading-snug text-secondary-light">{bio}</p>

            <div className="mt-3 flex gap-2 px-4">
              <span className="flex-1 rounded-lg bg-primary py-1.5 text-center font-body text-[10px] font-semibold text-white">
                Takip Et
              </span>
              <span className="flex-1 rounded-lg border border-secondary/15 py-1.5 text-center font-body text-[10px] font-semibold text-secondary">
                Mesaj
              </span>
            </div>

            {/* Öne çıkanlar (gerçek highlight başlıkları) */}
            <div className="scrollbar-hide mt-4 flex gap-3 overflow-x-auto px-4">
              {highlights.map((label) => (
                <div key={label} className="flex w-12 shrink-0 flex-col items-center gap-1">
                  <span className="flex h-9 w-9 items-center justify-center rounded-full border border-secondary/15 bg-secondary/[0.04]">
                    <FaBookmark className="h-3 w-3 text-secondary/40" />
                  </span>
                  <span className="line-clamp-1 w-full text-center font-body text-[7px] text-secondary-light">
                    {label}
                  </span>
                </div>
              ))}
            </div>

            {/* Sekme çubuğu */}
            <div className="mt-4 flex justify-center border-t border-secondary/10">
              <FaThLarge className="mt-2 h-3 w-3 text-secondary" />
            </div>

            {/* Gönderi ızgarası — 3 sütun, gerçek IG grid oranı */}
            <div className="grid grid-cols-3 gap-px">
              {images.map((src, i) => (
                <div key={i} className="relative aspect-square overflow-hidden bg-secondary/[0.04]">
                  <Image src={src} alt="" fill sizes="90px" className="object-cover" />
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
      <p className="mt-3 flex items-center justify-center gap-1.5 text-center font-body text-sm font-medium text-secondary transition-colors group-hover:text-primary">
        <FaInstagram className="h-3.5 w-3.5" />
        Profile Git
      </p>
    </Link>
  );
}
