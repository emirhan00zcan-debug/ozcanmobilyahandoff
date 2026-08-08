import Link from "next/link";
import { FaWhatsapp } from "react-icons/fa";

// contactInfo'daki gerçek işletme telefonu (bkz. WhatsAppButton.tsx ve homepage-mock.ts#contactInfo)
const WHATSAPP_NUMBER = "905054423809";

function waHref(message: string) {
  return `https://wa.me/${WHATSAPP_NUMBER}?text=${encodeURIComponent(message)}`;
}

export default function ConsultCta() {
  return (
    <section className="mx-auto max-w-3xl px-4 py-16 text-center sm:px-6 lg:px-8">
      <h2 className="font-display text-2xl font-semibold text-secondary">
        Kararsız mı kaldınız? Yanınızdayız.
      </h2>
      <p className="mt-3 font-body text-sm text-secondary-light">
        Renk ve tasarım için tasarımcımıza, ölçü ve malzeme için ustamıza danışın.
      </p>

      <div className="mt-6 flex flex-wrap items-center justify-center gap-3">
        <Link
          href={waHref("Merhaba, renk ve tasarım konusunda tasarımcınıza danışmak istiyorum.")}
          target="_blank"
          rel="noopener noreferrer"
          className="inline-flex items-center gap-2 rounded-full bg-black px-6 py-3 font-body text-sm font-semibold text-white transition-all duration-200 hover:scale-[1.02] hover:bg-black/80 active:scale-95"
        >
          <span aria-hidden="true">📐</span>
          Tasarımcımıza Danışın
          <FaWhatsapp className="h-4 w-4 text-[#25D366]" />
        </Link>

        <Link
          href={waHref("Merhaba, ölçü ve malzeme konusunda ustanıza danışmak istiyorum.")}
          target="_blank"
          rel="noopener noreferrer"
          className="inline-flex items-center gap-2 rounded-full bg-black px-6 py-3 font-body text-sm font-semibold text-white transition-all duration-200 hover:scale-[1.02] hover:bg-black/80 active:scale-95"
        >
          <span aria-hidden="true">🛠️</span>
          Ustamıza Danışın
          <FaWhatsapp className="h-4 w-4 text-[#25D366]" />
        </Link>
      </div>
    </section>
  );
}
