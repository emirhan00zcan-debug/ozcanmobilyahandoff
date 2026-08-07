"use client";

import { FaWhatsapp } from "react-icons/fa";
import { trackEvent } from "@/lib/analytics";

// contactInfo'daki gerçek işletme telefonu (+90 505 442 3809), wa.me formatı için
// ülke koduyla birlikte sadece rakamlar (bkz. src/lib/data/homepage-mock.ts contactInfo).
const WHATSAPP_NUMBER = "905054423809";
const DEFAULT_MESSAGE = "Merhaba, bir ürün hakkında bilgi almak istiyorum.";

export default function WhatsAppButton() {
  const href = `https://wa.me/${WHATSAPP_NUMBER}?text=${encodeURIComponent(DEFAULT_MESSAGE)}`;

  return (
    <a
      href={href}
      target="_blank"
      rel="noopener noreferrer"
      aria-label="WhatsApp'tan yazın"
      onClick={() => trackEvent("whatsapp_click")}
      className="fixed bottom-5 right-5 z-40 flex h-14 w-14 items-center justify-center rounded-full bg-[#25D366] text-white shadow-lg transition-transform duration-200 hover:scale-110 active:scale-95"
    >
      <FaWhatsapp className="h-7 w-7" />
    </a>
  );
}
