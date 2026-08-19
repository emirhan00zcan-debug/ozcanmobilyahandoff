"use client";

import { useEffect, useRef, useState, useActionState } from "react";
import Image from "next/image";
import { FaTimes, FaFacebookF, FaInstagram, FaWhatsapp, FaCheck } from "react-icons/fa";
import {
  subscribeNewsletterAction,
  type NewsletterActionState,
} from "@/lib/actions/newsletter-actions";

// Ziyaretçi fareyi tarayıcının GERİ tuşu civarına (sol-üst köşe) götürürken — ya üzerine
// gelip dururken ya da oradan sayfayı terk ederken — gösterilen %10 indirim popup'ı.
// Sayfanın kendisi tarayıcı arayüzünün (geri/ileri/yenile) piksel konumunu bilemez, ama bu
// düğmeler pratikte her tarayıcıda pencerenin sol-üst köşesine yakın durur — bu yüzden
// sol-üst köşeye (0,0) belli bir yarıçap içinde yaklaşma/oradan çıkış tespit edilir.
// Oturum başına sadece bir kez gösterilir: sessionStorage'a yazılan bayrak sayesinde,
// popup kapatılıp fare tekrar o bölgeye götürülse veya sayfa içi gezinmeyle bileşen
// yeniden mount olsa bile aynı sekmede/oturumda tekrar açılmaz. Yeni bir sekme/oturumda
// bayrak sıfırlanmış olur.
const ARM_DELAY_MS = 4000; // sayfa açılır açılmaz kazara tetiklenmesin diye kısa bekleme
const BACK_BUTTON_RADIUS = 120; // px — geri/ileri/yenile küme alanını rahatça kapsayan yarıçap
const SESSION_STORAGE_KEY = "exit-intent-popup-shown";

const SOCIAL_LINKS = [
  { label: "Facebook'ta takip edin", href: "https://facebook.com/profile.php?id=61574506475071", Icon: FaFacebookF },
  { label: "Instagram'da takip edin", href: "https://instagram.com/sinop_ozcan_mobilya/", Icon: FaInstagram },
  { label: "WhatsApp'tan yazın", href: "https://wa.me/905054423809", Icon: FaWhatsapp },
];

const initialState: NewsletterActionState = { success: false, error: null };

export default function ExitIntentPopup() {
  const [isOpen, setIsOpen] = useState(false);
  const [state, formAction, isPending] = useActionState(subscribeNewsletterAction, initialState);
  const [copied, setCopied] = useState(false);

  // Handler'lar tek bir effect içinde bir kez kuruluyor (yeniden mount olmadıkça); güncel
  // isOpen değerini ref üzerinden okuyoruz ki popup açıkken gereksiz yere tekrar
  // tetiklenmesin ama kapatılınca dinleyiciler zaten hâlâ takılı olduğu için hemen
  // yeniden tetiklenebilsin.
  const isOpenRef = useRef(isOpen);
  useEffect(() => {
    isOpenRef.current = isOpen;
  }, [isOpen]);

  useEffect(() => {
    if (typeof window === "undefined") return;
    if (sessionStorage.getItem(SESSION_STORAGE_KEY)) return; // bu oturumda zaten gösterildi

    let armed = false;
    const armTimer = setTimeout(() => {
      armed = true;
    }, ARM_DELAY_MS);

    const trigger = () => {
      if (isOpenRef.current) return; // zaten açıksa tekrar tetiklemeye gerek yok
      if (sessionStorage.getItem(SESSION_STORAGE_KEY)) return; // bu oturumda zaten gösterildi
      sessionStorage.setItem(SESSION_STORAGE_KEY, "1");
      setIsOpen(true);
    };

    // "Tam geri tuşunun üzerindeyken": fare sayfa içindeyken sol-üst köşeye (geri tuşu
    // civarı) belli bir yarıçap içine girerse, sayfayı hiç terk etmeden tetikler.
    const handleMouseMove = (e: MouseEvent) => {
      if (!armed) return;
      if (Math.hypot(e.clientX, e.clientY) <= BACK_BUTTON_RADIUS) trigger();
    };

    // "Geri tuşuna sürüklerken": fare üst kenardan, o köşeye yakın bir noktadan
    // (relatedTarget'ı olmadan, yani tarayıcı arayüzüne doğru) sayfayı terk ederse tetikler.
    const handleMouseOut = (e: MouseEvent) => {
      if (!armed) return;
      if (e.clientY <= 0 && !e.relatedTarget && e.clientX <= BACK_BUTTON_RADIUS) trigger();
    };

    document.addEventListener("mousemove", handleMouseMove);
    document.addEventListener("mouseout", handleMouseOut);
    return () => {
      clearTimeout(armTimer);
      document.removeEventListener("mousemove", handleMouseMove);
      document.removeEventListener("mouseout", handleMouseOut);
    };
  }, []);

  // Popup açıkken arkadaki sayfanın kaymasını engelle (bkz. SampleRequestModal aynı deseni).
  useEffect(() => {
    document.body.style.overflow = isOpen ? "hidden" : "unset";
    return () => {
      document.body.style.overflow = "unset";
    };
  }, [isOpen]);

  const handleClose = () => setIsOpen(false);

  const handleCopyCode = () => {
    if (!state.success) return;
    navigator.clipboard.writeText(state.couponCode).then(() => {
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    });
  };

  if (!isOpen) return null;

  return (
    <div
      className="fixed inset-0 z-[70] flex items-center justify-center bg-black/60 p-4 sm:p-6"
      onClick={handleClose}
    >
      <div
        className="relative grid w-full max-w-3xl grid-cols-1 overflow-hidden rounded-2xl bg-white shadow-2xl animate-fade-in sm:grid-cols-2"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Kapat butonu — hover'da 180° dönüyor */}
        <button
          onClick={handleClose}
          aria-label="Kapat"
          className="group absolute right-4 top-4 z-10 flex h-10 w-10 items-center justify-center rounded-full border border-secondary/15 bg-white text-secondary shadow-sm transition-all duration-300 hover:rotate-180 hover:border-primary hover:bg-primary hover:text-white"
        >
          <FaTimes className="h-4 w-4" />
        </button>

        {/* Sol: marka görseli — mobilde yer kazanmak için gizli */}
        <div className="relative hidden sm:block">
          <Image
            src="/media/premium-bedroom.jpg"
            alt="Özcan Mobilya"
            fill
            sizes="(max-width: 640px) 0px, 400px"
            className="object-cover"
          />
        </div>

        {/* Sağ: içerik */}
        <div className="flex flex-col justify-center p-8 sm:p-10">
          {state.success ? (
            <div className="text-center">
              <div className="mx-auto flex h-14 w-14 items-center justify-center rounded-full bg-primary/10 text-primary">
                <FaCheck className="h-5 w-5" />
              </div>
              <h3 className="mt-4 font-display text-xl font-bold text-secondary">Teşekkürler!</h3>
              <p className="mt-1.5 font-body text-sm text-secondary-light">
                İndirim kodunuz e-posta adresinize de gönderildi.
              </p>

              <button
                type="button"
                onClick={handleCopyCode}
                className="mt-5 w-full rounded-full border-2 border-dashed border-primary/40 bg-primary/5 py-3.5 font-body text-sm font-bold tracking-widest text-primary transition-colors hover:bg-primary/10"
              >
                {copied ? "Kopyalandı!" : state.couponCode}
              </button>

              <button
                type="button"
                onClick={handleClose}
                className="mt-4 font-body text-xs font-medium text-secondary-light underline underline-offset-2 transition-colors hover:text-secondary"
              >
                Alışverişe devam et
              </button>
            </div>
          ) : (
            <>
              <p className="font-body text-xs font-semibold uppercase tracking-[0.2em] text-primary">
                Özcan Mobilya Ailesine Katılın
              </p>
              <h3 className="mt-3 font-display text-2xl font-bold leading-snug text-secondary sm:text-3xl">
                İlk Siparişinize Özel %10 İndirim
              </h3>
              <p className="mt-3 font-body text-sm leading-relaxed text-secondary-light">
                E-posta adresinizi bırakın, indirim kodunuz hemen burada ve gelen kutunuzda olsun.
              </p>

              <form action={formAction} className="mt-6">
                <input
                  name="email"
                  type="email"
                  required
                  placeholder="E-posta adresiniz"
                  className="w-full rounded-full border border-secondary/15 bg-secondary/[0.02] px-5 py-3.5 font-body text-sm text-secondary placeholder:text-secondary-light focus:border-primary focus:outline-none"
                />

                {state.error && (
                  <p className="mt-2 font-body text-xs font-medium text-red-600">{state.error}</p>
                )}

                <button
                  type="submit"
                  disabled={isPending}
                  className="btn-sweep mt-3 w-full rounded-full border border-primary/30 py-3.5 font-body text-sm font-semibold text-secondary disabled:opacity-60"
                >
                  {isPending ? "Gönderiliyor..." : "%10 İndirimi Al"}
                </button>
              </form>

              <p className="mt-3 text-center font-body text-[11px] text-secondary-light">
                Kaydolarak kampanya e-postalarımızı almayı kabul edersiniz, istediğiniz zaman
                vazgeçebilirsiniz.
              </p>

              {/* Sosyal medya — sitede az önce tanımlanan ortak .btn-sweep dolgu animasyonu
                  (bkz. globals.css) ile aynı dil: hover'da teal degrade soldan dolar. */}
              <div className="mt-6 flex items-center justify-center gap-3 border-t border-secondary/10 pt-6">
                {SOCIAL_LINKS.map(({ label, href, Icon }) => (
                  <a
                    key={label}
                    href={href}
                    target="_blank"
                    rel="noopener noreferrer"
                    aria-label={label}
                    className="btn-sweep flex h-10 w-10 items-center justify-center rounded-full border border-secondary/15 text-secondary"
                  >
                    <Icon className="h-4 w-4" />
                  </a>
                ))}
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  );
}
