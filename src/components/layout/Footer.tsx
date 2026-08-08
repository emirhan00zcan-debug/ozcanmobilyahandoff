"use client";

import Link from "next/link";
import { FaFacebookF, FaInstagram } from "react-icons/fa";
import { footerColumns, socialLinks } from "@/lib/data/homepage-mock";

export default function Footer() {
  return (
    <footer className="mx-auto max-w-7xl px-4 py-12 sm:px-6 lg:px-8">
      <div className="grid grid-cols-1 gap-10 border-t border-secondary/10 pt-12 md:grid-cols-[1fr_1px_repeat(3,minmax(0,140px))] md:gap-8">
        {/* Bülten kaydı */}
        <div className="max-w-md">
          <h3 className="font-display text-xl font-semibold text-secondary">
            Fırsatlardan ilk siz haberdar olun
          </h3>
          <p className="mt-2 font-body text-sm text-secondary-light">
            E-bültenimize kaydolun ve anında %10 indirim sizin olsun
          </p>
          <form
            onSubmit={(e) => e.preventDefault()}
            className="mt-4 flex overflow-hidden rounded-full border border-secondary/15"
          >
            <input
              type="email"
              placeholder="E-posta adresiniz"
              className="w-full bg-transparent px-5 py-3 font-body text-sm text-secondary placeholder:text-secondary-light focus:outline-none"
            />
            <button
              type="submit"
              className="btn-sweep shrink-0 border-l border-primary/30 px-6 font-body text-sm font-semibold text-secondary active:scale-95"
            >
              Kaydol
            </button>
          </form>
          <p className="mt-3 font-body text-xs text-secondary-light">
            Abone olarak{" "}
            <Link href="/hizmet-sartlari" className="underline">
              Hizmet Şartları&apos;nı
            </Link>{" "}
            ve{" "}
            <Link href="/gizlilik-politikasi" className="underline">
              Gizlilik Politikası&apos;nı
            </Link>{" "}
            kabul etmiş olursunuz.
          </p>
        </div>

        <div className="hidden bg-secondary/10 md:block" />

        {/* Menü kolonları */}
        {footerColumns.map((col) => (
          <div key={col.title}>
            <h4 className="font-body text-sm font-semibold text-secondary">{col.title}</h4>
            <ul className="mt-4 space-y-2.5">
              {col.links.map((link) => (
                <li key={link.label}>
                  <Link
                    href={link.href}
                    className="font-body text-sm text-secondary-light transition-colors hover:text-secondary"
                  >
                    {link.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>
        ))}
      </div>

      <div className="mt-10 flex flex-col items-center gap-4 border-t border-secondary/10 pt-6 sm:flex-row sm:justify-between">
        <p className="font-body text-xs text-secondary-light">© 2026 Özcan Mobilya</p>
        <div className="flex gap-3">
          <Link
            href={socialLinks.facebook}
            target="_blank"
            rel="noopener noreferrer"
            aria-label="Facebook"
            className="flex h-9 w-9 items-center justify-center rounded-full border border-secondary/15 text-secondary transition-colors hover:border-secondary hover:text-primary"
          >
            <FaFacebookF className="h-3.5 w-3.5" />
          </Link>
          <Link
            href={socialLinks.instagram}
            target="_blank"
            rel="noopener noreferrer"
            aria-label="Instagram"
            className="flex h-9 w-9 items-center justify-center rounded-full border border-secondary/15 text-secondary transition-colors hover:border-secondary hover:text-primary"
          >
            <FaInstagram className="h-3.5 w-3.5" />
          </Link>
        </div>
      </div>
    </footer>
  );
}
