import Link from "next/link";
import { FaRulerCombined } from "react-icons/fa";

// Anasayfaya özel, sol kenara sabit dikey "sekme" CTA'sı — planlayıcı tanıtım
// sayfasına (/planlayici) yönlendirir. Sadece anasayfada render edildiği için
// (bkz. page.tsx) diğer sayfalarda görünmez.
export default function DesignFurnitureButton() {
  return (
    <Link
      href="/planlayici"
      aria-label="Mobilyanı Tasarla — Planlayıcıyı Keşfet"
      className="fixed left-0 top-1/2 z-40 flex -translate-y-1/2 flex-col items-center gap-4 bg-[#FFDB00] py-10 pl-3 pr-4 shadow-lg transition-colors duration-200 hover:bg-[#E6C500] sm:py-14 sm:pl-4 sm:pr-5"
    >
      <FaRulerCombined className="h-5 w-5 shrink-0 text-primary sm:h-6 sm:w-6" />
      <span className="[writing-mode:vertical-rl] rotate-180 font-display text-base font-bold uppercase tracking-tight text-primary sm:text-lg">
        Mobilyanı Tasarla
      </span>
    </Link>
  );
}
