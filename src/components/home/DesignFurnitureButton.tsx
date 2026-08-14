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
      className="group fixed left-0 top-1/2 z-40 -translate-y-1/2"
    >
      <span
        className="absolute inset-0 animate-pulse rounded-r-2xl bg-primary opacity-60 blur-lg"
        aria-hidden="true"
      />
      <span className="relative flex flex-col items-center gap-4 rounded-r-2xl bg-primary py-10 pl-3 pr-4 shadow-2xl shadow-primary/50 transition-transform duration-300 ease-out group-hover:translate-x-1.5 sm:py-14 sm:pl-4 sm:pr-5">
        <FaRulerCombined className="h-5 w-5 shrink-0 text-white sm:h-6 sm:w-6" />
        <span className="[writing-mode:vertical-rl] rotate-180 font-display text-base font-bold tracking-wide text-white sm:text-lg">
          Mobilyanı Tasarla
        </span>
      </span>
    </Link>
  );
}
