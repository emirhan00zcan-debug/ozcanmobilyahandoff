"use client";

import { useActionState } from "react";
import Link from "next/link";
import { FaFacebookF, FaInstagram, FaCheck } from "react-icons/fa";
import { footerColumns, socialLinks } from "@/lib/data/homepage-mock";
import {
  subscribeNewsletterAction,
  type NewsletterActionState,
} from "@/lib/actions/newsletter-actions";

const initialState: NewsletterActionState = { success: false, error: null };

export default function Footer() {
  const [state, formAction, isPending] = useActionState(subscribeNewsletterAction, initialState);

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

          {state.success ? (
            <div className="mt-4 flex items-center gap-3 rounded-full border border-primary/30 bg-primary/5 px-5 py-3">
              <span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-primary text-white">
                <FaCheck className="h-3 w-3" />
              </span>
              <p className="font-body text-sm text-secondary">
                Teşekkürler! İndirim kodunuz:{" "}
                <span className="font-semibold text-primary">{state.couponCode}</span>
              </p>
            </div>
          ) : (
            <>
              <form action={formAction} className="mt-4">
                <div className="flex overflow-hidden rounded-full border border-secondary/15">
                  <input
                    name="email"
                    type="email"
                    required
                    placeholder="E-posta adresiniz"
                    className="w-full bg-transparent px-5 py-3 font-body text-sm text-secondary placeholder:text-secondary-light focus:outline-none"
                  />
                  <button
                    type="submit"
                    disabled={isPending}
                    className="btn-sweep shrink-0 border-l border-primary/30 px-6 font-body text-sm font-semibold text-secondary active:scale-95 disabled:opacity-60"
                  >
                    {isPending ? "..." : "Kaydol"}
                  </button>
                </div>

                <label className="mt-3 flex items-start gap-2 font-body text-xs text-secondary-light">
                  <input type="checkbox" name="consent" required className="mt-0.5 accent-primary" />
                  <span>
                    <Link href="/gizlilik-politikasi" target="_blank" className="underline">
                      Gizlilik Politikası&apos;nı
                    </Link>{" "}
                    okudum, Özcan Mobilya&apos;nın bana e-posta yoluyla kampanya/indirim
                    bildirimi göndermesini kabul ediyorum.
                  </span>
                </label>

                {state.error && (
                  <p className="mt-2 font-body text-xs font-medium text-red-600">{state.error}</p>
                )}
              </form>
            </>
          )}
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
