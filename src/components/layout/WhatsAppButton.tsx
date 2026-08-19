"use client";

import { useEffect, useRef, useState } from "react";
import { FaWhatsapp, FaTimes, FaPaperPlane } from "react-icons/fa";
import { trackEvent } from "@/lib/analytics";

// contactInfo'daki gerçek işletme telefonu (+90 505 442 3809), wa.me formatı için
// ülke koduyla birlikte sadece rakamlar (bkz. src/lib/data/homepage-mock.ts contactInfo).
const WHATSAPP_NUMBER = "905054423809";
const DEFAULT_MESSAGE = "Merhaba, bir ürün hakkında bilgi almak istiyorum.";

const IDLE_TRIGGER_MS = 90000; // 1-2dk istendi; hiç ürüne tıklamadan sadece geziniyorsa (1.5dk) tetikle
const CLOSE_CORNER_ARM_DELAY_MS = 3000; // sayfa yüklenir yüklenmez fare köşedeyse yanlışlıkla tetiklenmesin
const CLOSE_CORNER_RADIUS = 120; // px — tarayıcının sekme kapatma (X) düğmesinin bulunduğu sağ-üst köşe yarıçapı
// Aşağıdaki iki süre, konteynerdeki Tailwind `duration-500` sınıfıyla birebir eşleşmeli ki
// bir sonraki aşamaya geçiş, bir önceki CSS geçişi tam bitmeden araya girmesin.
const STAGE1_MS = 500; // ikon dönüp kaybolurken yatay dikdörtgenin sola açılma süresi
const STAGE2_MS = 500; // yatay kutunun telefon boyutuna yukarı doğru açılma süresi
const CONTENT_FADE_MS = 150; // dikey açılma bitince içeriğin belirme gecikmesi

// Kapanış durumu (yuvarlak ikon) -> aşama 1 (yatay şerit + ikon dönerek kaybolur)
// -> aşama 2 (telefon ekranı boyutunda dikey panel).
type Phase = "closed" | "expanding" | "expanded";

export default function WhatsAppButton() {
  const [phase, setPhase] = useState<Phase>("closed");
  const [showContent, setShowContent] = useState(false);
  const [message, setMessage] = useState("");
  const [sent, setSent] = useState(false);

  // Panel zaten açıkken (expanding/expanded) tetikleyicilerin üst üste binmesini önlemek için
  // güncel fazı ref üzerinden okuyoruz — kapanınca (closed) her tetikleyici tekrar açabilir.
  const phaseRef = useRef<Phase>("closed");
  useEffect(() => {
    phaseRef.current = phase;
  }, [phase]);

  // Sağ-üst köşeye yaklaşma tetikleyicisi, sayfa yüklenip CLOSE_CORNER_ARM_DELAY_MS geçtikten
  // sonra "silahlanır"; ziyaret başına sadece bir kez tetiklenir (cornerFiredRef) — widget
  // kapatılıp fare tekrar köşeye götürülse bile bir daha açılmaz.
  const armedRef = useRef(false);
  const cornerFiredRef = useRef(false);
  const timeoutsRef = useRef<number[]>([]);

  useEffect(() => {
    const timeouts = timeoutsRef.current;
    return () => {
      timeouts.forEach((id) => window.clearTimeout(id));
    };
  }, []);

  const openWidget = () => {
    if (phaseRef.current !== "closed") return;

    setPhase("expanding");
    const t1 = window.setTimeout(() => {
      setPhase("expanded");
      const t2 = window.setTimeout(() => setShowContent(true), STAGE2_MS + CONTENT_FADE_MS);
      timeoutsRef.current.push(t2);
    }, STAGE1_MS);
    timeoutsRef.current.push(t1);
  };

  const handleClose = () => {
    setShowContent(false);
    setPhase("closed");
  };

  // WhatsApp Business API'si (Graph API) yok — "Gönder" butonu da, kapalı haldeki ikon gibi,
  // yazılan mesajla birlikte wa.me linkini yeni sekmede açar.
  const handleSend = () => {
    const text = message.trim() || DEFAULT_MESSAGE;
    trackEvent("whatsapp_click");
    window.open(`https://wa.me/${WHATSAPP_NUMBER}?text=${encodeURIComponent(text)}`, "_blank", "noopener,noreferrer");
    setMessage("");
    setSent(true);
  };

  useEffect(() => {
    if (typeof window === "undefined") return;

    // 1) Idle: hiç ürüne tıklamadan sadece gezinip IDLE_TRIGGER_MS kadar süre geçerse tetikle.
    // (Menü/sepet gibi ürünle ilgisiz tıklamalar sayılmaz — sadece /urun/[slug] linkleri.)
    let clickedProduct = false;
    const onClick = (e: MouseEvent) => {
      const target = e.target as Element | null;
      if (target?.closest('a[href*="/urun/"]')) clickedProduct = true;
    };
    document.addEventListener("click", onClick);
    const idleTimer = window.setTimeout(() => {
      if (!clickedProduct) openWidget();
    }, IDLE_TRIGGER_MS);

    // 2) Kapatma niyeti: fare, tarayıcının sekme kapatma (X) düğmesinin bulunduğu sağ-üst
    // köşeye yaklaşırsa (sayfadan çıkmadan sadece o bölgede gezinse bile) tetikle — ziyaret
    // başına yalnızca bir kez (cornerFiredRef), tekrar tekrar açılmaz. Geri tuşu (sol-üst köşe)
    // zaten ExitIntentPopup'ta ayrı bir işleve bağlı, burada tekrar edilmiyor.
    const armTimer = window.setTimeout(() => {
      armedRef.current = true;
    }, CLOSE_CORNER_ARM_DELAY_MS);

    const nearCloseCorner = (clientX: number, clientY: number) =>
      Math.hypot(window.innerWidth - clientX, clientY) <= CLOSE_CORNER_RADIUS;

    const triggerCorner = () => {
      if (cornerFiredRef.current) return;
      cornerFiredRef.current = true;
      openWidget();
    };
    const onMouseMove = (e: MouseEvent) => {
      if (!armedRef.current || cornerFiredRef.current) return;
      if (nearCloseCorner(e.clientX, e.clientY)) triggerCorner();
    };
    const onMouseOut = (e: MouseEvent) => {
      if (!armedRef.current || cornerFiredRef.current) return;
      if (e.clientY <= 0 && !e.relatedTarget && nearCloseCorner(e.clientX, e.clientY)) triggerCorner();
    };
    document.addEventListener("mousemove", onMouseMove);
    document.addEventListener("mouseout", onMouseOut);

    return () => {
      document.removeEventListener("click", onClick);
      window.clearTimeout(idleTimer);
      window.clearTimeout(armTimer);
      document.removeEventListener("mousemove", onMouseMove);
      document.removeEventListener("mouseout", onMouseOut);
    };
  }, []);

  const waHref = `https://wa.me/${WHATSAPP_NUMBER}?text=${encodeURIComponent(DEFAULT_MESSAGE)}`;

  return (
    <div
      className={[
        "fixed bottom-5 right-5 z-50 overflow-hidden shadow-2xl transition-all duration-500 ease-in-out",
        phase === "closed" && "h-14 w-14 rounded-full bg-[#25D366]",
        phase === "expanding" && "h-14 w-[280px] max-w-[calc(100vw-2.5rem)] rounded-full bg-[#25D366]",
        phase === "expanded" &&
          "h-[calc(100vh-2.5rem)] w-[calc(100vw-2.5rem)] rounded-[28px] bg-white sm:h-[min(500px,calc(100vh-2.5rem))] sm:w-[min(300px,calc(100vw-2.5rem))]",
      ]
        .filter(Boolean)
        .join(" ")}
    >
      {phase !== "expanded" && (
        <a
          href={waHref}
          target="_blank"
          rel="noopener noreferrer"
          aria-label="WhatsApp'tan yazın"
          onClick={() => trackEvent("whatsapp_click")}
          className="absolute right-0 top-0 flex h-14 w-14 items-center justify-center text-white"
        >
          <FaWhatsapp
            className={`h-7 w-7 transition-all duration-500 ease-in-out ${
              phase === "expanding" ? "rotate-[360deg] scale-50 opacity-0" : "rotate-0 scale-100 opacity-100"
            }`}
          />
        </a>
      )}

      {phase === "expanded" && (
        <div
          className={`flex h-full w-full flex-col p-5 transition-opacity duration-300 ${
            showContent ? "opacity-100" : "opacity-0"
          }`}
        >
          <button
            type="button"
            onClick={handleClose}
            aria-label="Kapat"
            className="flex h-8 w-8 shrink-0 items-center justify-center self-end rounded-full text-secondary-light transition-colors hover:bg-secondary/10 hover:text-secondary"
          >
            <FaTimes className="h-4 w-4" />
          </button>

          <p className="mt-3 font-display text-2xl font-extrabold uppercase leading-tight text-secondary">
            Kararsız mı kaldınız?
            <br />
            Endişelerinizi giderelim...
          </p>

          <div className="mt-auto">
            <div className="flex items-center gap-2 rounded-full border border-secondary/15 bg-secondary/[0.03] py-1.5 pl-4 pr-1.5">
              <input
                value={message}
                onChange={(e) => {
                  setMessage(e.target.value);
                  setSent(false);
                }}
                onKeyDown={(e) => {
                  if (e.key === "Enter") handleSend();
                }}
                placeholder="Bize buradan yazın..."
                className="min-w-0 flex-1 bg-transparent font-body text-sm text-secondary outline-none placeholder:text-secondary-light"
              />
              <button
                type="button"
                onClick={handleSend}
                aria-label="Gönder"
                className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-[#25D366] text-white transition-transform hover:scale-105 active:scale-95"
              >
                <FaPaperPlane className="h-3.5 w-3.5" />
              </button>
            </div>
            {sent && (
              <p className="mt-2 px-1 font-body text-xs text-primary">
                WhatsApp&apos;ta açılıyor...
              </p>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
