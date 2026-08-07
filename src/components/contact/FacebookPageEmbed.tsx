import Link from "next/link";
import { FaFacebookF } from "react-icons/fa";

type Props = { pageUrl: string };

// Facebook'un resmi "Page Plugin" iframe'i — API anahtarı gerekmiyor, sayfanın gerçek
// kapak/profil fotoğrafını ve son gönderilerini gerçekten gömüp kaydırılabilir hale
// getiriyor (haritadaki gibi içinde gezinilebilir, statik bir kopya değil).
function buildPagePluginSrc(pageUrl: string) {
  const params = new URLSearchParams({
    href: pageUrl,
    tabs: "timeline",
    width: "260",
    height: "440",
    small_header: "true",
    adapt_container_width: "true",
    hide_cover: "false",
    show_facepile: "false",
  });
  return `https://www.facebook.com/plugins/page.php?${params.toString()}`;
}

export default function FacebookPageEmbed({ pageUrl }: Props) {
  return (
    <div>
      <div className="mx-auto w-full max-w-[260px] rounded-[2rem] border-[6px] border-secondary bg-secondary shadow-lg">
        <div className="relative overflow-hidden rounded-[1.5rem] bg-white">
          <div className="absolute left-1/2 top-2 z-10 h-1.5 w-12 -translate-x-1/2 rounded-full bg-secondary/60" />
          <div className="pt-6">
            <iframe
              src={buildPagePluginSrc(pageUrl)}
              title="Özcan Mobilya Facebook Sayfası"
              width="260"
              height="440"
              className="border-0"
              style={{ colorScheme: "light" }}
              loading="lazy"
              scrolling="yes"
            />
          </div>
        </div>
      </div>
      <Link
        href={pageUrl}
        target="_blank"
        rel="noopener noreferrer"
        className="group mt-3 flex items-center justify-center gap-1.5 text-center font-body text-sm font-medium text-secondary transition-colors hover:text-primary"
      >
        <FaFacebookF className="h-3 w-3" />
        Sayfaya Git
      </Link>
    </div>
  );
}
