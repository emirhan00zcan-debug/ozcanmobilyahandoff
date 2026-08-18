"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useSession, signOut } from "next-auth/react";
import { FaSearch, FaUser, FaShoppingBag, FaBars, FaTimes, FaChevronRight } from "react-icons/fa";
import { useCartTotalQuantity } from "@/store/cart-store";
import { promoCards, type CategoryCircle } from "@/lib/data/homepage-mock";

// Alt metin menüsü — referans Shopify sitesiyle birebir aynı etiketler ve sıra
const MENU_LINKS = [
  { label: "Kategoriler", href: "/kategori" },
  { label: "Odalara Göre", href: "/oda" },
  { label: "İndirimdekiler", href: "/indirimler" },
  { label: "Katalog", href: "/katalog" },
  { label: "Ana sayfa", href: "/" },
  { label: "Blog", href: "/blog" },
  { label: "Hakkımızda", href: "/hakkimizda" },
  { label: "İletişim", href: "/iletisim" },
  { label: "Mobilyanı Tasarla", href: "/planlayici" },
];

// "Kategoriler" mega menu'sündeki promosyon kartı — sabit veri olduğu için modül
// seviyesinde bir kez hesaplanır (kategori sütunları artık props'tan geldiği için
// bileşen içinde useMemo ile hesaplanıyor, bkz. aşağı).
const CATEGORY_PROMO = promoCards[0];

type SearchSuggestion = {
  slug: string;
  name: string;
  imageUrl: string | null;
  price: number;
  compareAtPrice: number | null;
};

function formatSuggestionPrice(value: number) {
  return new Intl.NumberFormat("tr-TR", { minimumFractionDigits: 2 }).format(value) + "₺";
}

// Arama kutusunun altında açılan öneri paneli — hem masaüstü hem mobil arama
// kutusu aynı içeriği (farklı konumlandırmayla) kullanıyor, bu yüzden ortak.
function SearchSuggestionsPanel({
  query,
  suggestions,
  isSearching,
  onNavigate,
}: {
  query: string;
  suggestions: SearchSuggestion[];
  isSearching: boolean;
  onNavigate: () => void;
}) {
  return (
    <>
      {suggestions.length > 0 ? (
        <ul className="max-h-[420px] overflow-y-auto py-2">
          {suggestions.map((p) => (
            <li key={p.slug}>
              <Link
                href={`/urun/${p.slug}`}
                onClick={onNavigate}
                className="flex items-center gap-3 px-5 py-2.5 hover:bg-secondary/[0.04]"
              >
                <span className="relative h-12 w-12 shrink-0 overflow-hidden rounded-lg border border-secondary/10 bg-secondary/[0.04]">
                  {p.imageUrl ? (
                    <Image src={p.imageUrl} alt={p.name} fill sizes="48px" className="object-cover" />
                  ) : null}
                </span>
                <span className="min-w-0 flex-1">
                  <span className="block truncate font-body text-sm font-medium text-secondary">{p.name}</span>
                  <span className="mt-0.5 flex items-center gap-2">
                    <span className="font-body text-xs font-semibold text-primary">
                      {formatSuggestionPrice(p.price)}
                    </span>
                    {p.compareAtPrice != null && (
                      <span className="font-body text-xs text-secondary-light line-through">
                        {formatSuggestionPrice(p.compareAtPrice)}
                      </span>
                    )}
                  </span>
                </span>
              </Link>
            </li>
          ))}
        </ul>
      ) : (
        <p className="px-5 py-4 font-body text-sm text-secondary-light">
          {isSearching ? "Aranıyor..." : `"${query}" ile eşleşen ürün bulunamadı.`}
        </p>
      )}
      <Link
        href={`/arama?q=${encodeURIComponent(query)}`}
        onClick={onNavigate}
        className="block border-t border-secondary/10 px-5 py-3 text-center font-body text-xs font-semibold text-secondary hover:text-primary"
      >
        Tüm sonuçları gör
      </Link>
    </>
  );
}

// "Odalara Göre" mega menu'sünde her odanın sağ panelinde gösterilecek kategoriler —
// gerçek kategori verisinden (categories prop'u) odayla ilişkili anlamlı bir alt küme.
const ROOM_CATEGORY_SLUGS: Record<string, string[]> = {
  "yatak-odasi": ["gardirop", "dresuar", "makyaj-kosesi", "portmanto", "tv-unitesi", "kahve-kosesi"],
  "giyinme-odasi": ["gardirop", "portmanto", "makyaj-kosesi", "dresuar", "kahve-kosesi", "banyo-dolabi"],
  "antre-hol": ["portmanto", "dresuar", "gardirop", "makyaj-kosesi"],
  "salon-oturma-odasi": ["tv-unitesi", "dresuar", "kahve-kosesi", "gardirop", "portmanto", "calisma-masasi"],
  mutfak: ["moduler-mutfak-dolabi", "kahve-kosesi", "dresuar"],
  banyo: ["banyo-dolabi", "makyaj-kosesi"],
  "calisma-odasi": ["calisma-masasi", "kahve-kosesi", "dresuar", "tv-unitesi"],
  "genc-cocuk-odasi": ["cocuk-odasi", "oyuncu-masasi", "calisma-masasi", "gardirop", "dresuar"],
  "ofis-is-yeri": ["calisma-masasi", "dresuar", "kahve-kosesi", "tv-unitesi"],
  "cok-amacli-dolaplar": ["gardirop", "dresuar", "banyo-dolabi", "moduler-mutfak-dolabi", "portmanto", "tv-unitesi"],
  aksesuarlar: ["kahve-kosesi", "makyaj-kosesi", "oyuncu-masasi", "dresuar"],
};

type Props = {
  categories: CategoryCircle[];
  rooms: CategoryCircle[];
};

export default function Navbar({ categories, rooms }: Props) {
  const categoryMid = Math.ceil(categories.length / 2);
  const categoryColumns = useMemo(
    () => [categories.slice(0, categoryMid), categories.slice(categoryMid)],
    [categories, categoryMid],
  );
  const categoryBySlug = useMemo(() => new Map(categories.map((cat) => [cat.slug, cat])), [categories]);

  // Sayfa kaydırıldığında navbar arkasına cam efekti uygulamak ve alt menü
  // satırını katlamak için — üst satır (logo/arama/ikonlar) HER ZAMAN sabit kalır,
  // sadece alt metin menüsü (Kategoriler...İletişim) scroll'da kaybolur.
  const [isScrolled, setIsScrolled] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);
  const [categoriesOpen, setCategoriesOpen] = useState(false);
  const categoriesCloseTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const categoriesOpenTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  // "Odalara Göre" — referans temadaki menu-sidebar davranışı: panel açık/kapalı durumu
  // ile o an aktif (hover'lanan) oda ayrı state'ler; oda seçimi panel kapansa da kalıcıdır.
  const [roomsOpen, setRoomsOpen] = useState(false);
  const [activeRoomSlug, setActiveRoomSlug] = useState(rooms[0]?.slug ?? "");
  const roomsCloseTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const roomsOpenTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const [mobileSearchOpen, setMobileSearchOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");
  const [suggestions, setSuggestions] = useState<SearchSuggestion[]>([]);
  const [suggestionsOpen, setSuggestionsOpen] = useState(false);
  const [isSearching, setIsSearching] = useState(false);
  const desktopSearchRef = useRef<HTMLDivElement | null>(null);
  const mobileSearchRef = useRef<HTMLDivElement | null>(null);
  const cartCount = useCartTotalQuantity();
  const { data: session, status } = useSession();
  const pathname = usePathname();
  const router = useRouter();

  const submitSearch = (e: React.FormEvent) => {
    e.preventDefault();
    const q = searchQuery.trim();
    if (!q) return;
    router.push(`/arama?q=${encodeURIComponent(q)}`);
    setMobileSearchOpen(false);
    setSuggestionsOpen(false);
  };

  const closeSuggestions = () => {
    setSuggestionsOpen(false);
    setMobileSearchOpen(false);
  };

  // Yazarken arama: kullanıcı yazmayı bıraktıktan 250ms sonra /api/search'e
  // istek atılır; her yeni tuş vuruşunda önceki zamanlayıcı ve istek iptal edilir.
  useEffect(() => {
    const q = searchQuery.trim();
    if (!q) {
      setSuggestions([]);
      setSuggestionsOpen(false);
      setIsSearching(false);
      return;
    }
    setIsSearching(true);
    const controller = new AbortController();
    const timer = setTimeout(() => {
      fetch(`/api/search?q=${encodeURIComponent(q)}`, { signal: controller.signal })
        .then((res) => res.json())
        .then((data: { products: SearchSuggestion[] }) => {
          setSuggestions(data.products ?? []);
          setSuggestionsOpen(true);
        })
        .catch((err) => {
          if (err?.name !== "AbortError") setSuggestions([]);
        })
        .finally(() => {
          if (!controller.signal.aborted) setIsSearching(false);
        });
    }, 250);
    return () => {
      clearTimeout(timer);
      controller.abort();
    };
  }, [searchQuery]);

  // Arama kutusunun/panelinin dışına tıklanınca öneri panelini kapat.
  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      const target = e.target as Node;
      if (desktopSearchRef.current?.contains(target)) return;
      if (mobileSearchRef.current?.contains(target)) return;
      setSuggestionsOpen(false);
    };
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  const handleSearchKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === "Escape") {
      setSuggestionsOpen(false);
      e.currentTarget.blur();
    }
  };

  // Mega menu/hamburger içindeki bir linke tıklanıp sayfa değiştiğinde, Navbar
  // aynı layout içinde kalıp yeniden mount olmadığı için panel açık kalabiliyordu
  // (örn. "Gardrop"a tıklayınca kategori sayfasına geçilir ama panel üstte asılı kalırdı).
  // Rota her değiştiğinde tüm menüleri kapatıyoruz — React'in "prop değişince state
  // sıfırlama" için önerdiği şekilde, effect yerine render sırasında yapılıyor:
  // https://react.dev/learn/you-might-not-need-an-effect#adjusting-some-state-when-a-prop-changes
  const [prevPathname, setPrevPathname] = useState(pathname);
  if (pathname !== prevPathname) {
    setPrevPathname(pathname);
    setCategoriesOpen(false);
    setRoomsOpen(false);
    setMenuOpen(false);
    setMobileSearchOpen(false);
    setSuggestionsOpen(false);
  }

  useEffect(() => {
    // Kayan sayfa en üste dönünce alt metin menüsü zaten yeniden görünür hale gelir;
    // hamburger dropdown'u da açık kalırsa aynı linkler iki kez üst üste görünür.
    // Bu yüzden en üste dönüldüğünde dropdown'u kapatıyoruz.
    const handleScroll = () => {
      const scrolled = window.scrollY > 8;
      setIsScrolled(scrolled);
      if (!scrolled) setMenuOpen(false);
      // Alt metin menüsü scroll'da katlanınca "Kategoriler"/"Odalara Göre" tetikleyicileri de
      // görünmez oluyor — mega menu panelleri ortada asılı kalmasın diye kapatıyoruz.
      setCategoriesOpen(false);
      setRoomsOpen(false);
    };
    window.addEventListener("scroll", handleScroll, { passive: true });
    handleScroll();
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  // Trigger'dan panele geçerken aradaki küçük boşlukta menünün anında kapanmaması için
  // kapanışı hafifçe geciktiriyoruz; yeniden hover edilirse zamanlayıcı iptal edilir.
  const openCategoriesMenu = () => {
    if (categoriesCloseTimer.current) clearTimeout(categoriesCloseTimer.current);
    setCategoriesOpen(true);
  };
  // Trigger metninin üzerinden sadece geçerken (fare yatayda kayarken) mega menünün
  // kazara açılmasını önlemek için: imleç 400ms boyunca trigger üzerinde kalırsa açılır,
  // daha erken ayrılırsa (closeCategoriesMenu) zamanlayıcı hiç tetiklenmeden iptal edilir.
  const scheduleOpenCategoriesMenu = () => {
    if (categoriesCloseTimer.current) clearTimeout(categoriesCloseTimer.current);
    if (categoriesOpenTimer.current) return;
    categoriesOpenTimer.current = setTimeout(() => {
      categoriesOpenTimer.current = null;
      setCategoriesOpen(true);
    }, 400);
  };
  const closeCategoriesMenu = () => {
    if (categoriesOpenTimer.current) {
      clearTimeout(categoriesOpenTimer.current);
      categoriesOpenTimer.current = null;
    }
    categoriesCloseTimer.current = setTimeout(() => setCategoriesOpen(false), 120);
  };

  const openRoomsMenu = () => {
    if (roomsCloseTimer.current) clearTimeout(roomsCloseTimer.current);
    setRoomsOpen(true);
  };
  const scheduleOpenRoomsMenu = () => {
    if (roomsCloseTimer.current) clearTimeout(roomsCloseTimer.current);
    if (roomsOpenTimer.current) return;
    roomsOpenTimer.current = setTimeout(() => {
      roomsOpenTimer.current = null;
      setRoomsOpen(true);
    }, 400);
  };
  const closeRoomsMenu = () => {
    if (roomsOpenTimer.current) {
      clearTimeout(roomsOpenTimer.current);
      roomsOpenTimer.current = null;
    }
    roomsCloseTimer.current = setTimeout(() => setRoomsOpen(false), 120);
  };

  // Güvenlik ağı: fare, tetikleyici satırı + açık panel alanının tamamını (aradaki
  // boşluklar dahil) terk ettiğinde her iki mega menünün de kapanmasını garantiler.
  const closeAllMegaMenus = () => {
    closeCategoriesMenu();
    closeRoomsMenu();
  };

  return (
    <header
      className={[
        "sticky top-0 z-50 transition-all duration-300",
        isScrolled ? "bg-white/80 shadow-sm backdrop-blur-md" : "bg-white/0 backdrop-blur-0",
      ].join(" ")}
    >
      {/* Ana navbar satırı: hamburger / logo / arama / kullanıcı araçları */}
      <div className="mx-auto flex max-w-7xl items-center gap-8 px-4 py-5 sm:px-6 lg:px-8">
        <button
          onClick={() => setMenuOpen((v) => !v)}
          aria-label="Menüyü aç/kapat"
          className={[
            "grid shrink-0 place-items-center overflow-hidden text-secondary transition-all duration-300 hover:text-primary",
            // Desktop: kaydırılınca göster (isScrolled), kaydırılmamışsa gizle.
            // Mobil: Her zaman göster (w-9, opacity-100, scale-100 vb. zorlanıyor)
            isScrolled ? "h-9 w-9 scale-100 opacity-100" : "max-lg:h-9 max-lg:w-9 max-lg:scale-100 max-lg:opacity-100 lg:h-9 lg:w-0 lg:scale-75 lg:opacity-0",
          ].join(" ")}
        >
          {menuOpen ? <FaTimes className="h-4 w-4" /> : <FaBars className="h-4 w-4" />}
        </button>

        {/* Logo — imza tam olarak "ÖZCAN MOBİLYA" satırının altına ortalanır */}
        <Link href="/" className="flex shrink-0 flex-col items-center">
          <span className="whitespace-nowrap">
            <span className="font-display text-3xl font-bold tracking-wide text-brand">
              ÖZCAN
            </span>
            <span className="ml-2 font-body text-xs font-medium tracking-[0.25em] text-secondary">
              MOBİLYA
            </span>
          </span>
          <span className="font-script text-2xl leading-none text-brand/80">
            &ldquo;Hayallerinizi Tasarlar&rdquo;
          </span>
        </Link>

        {/* Arama barı — masaüstünde her zaman görünür, yazarken öneri panelini açar,
            Enter'a basınca /arama sonuç sayfasına gönderir */}
        <div ref={desktopSearchRef} className="relative hidden flex-1 md:block">
          <form
            onSubmit={submitSearch}
            className="flex items-center rounded-full border border-secondary/15 bg-secondary/[0.03] px-6 py-3.5"
          >
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              onFocus={() => suggestions.length > 0 && setSuggestionsOpen(true)}
              onKeyDown={handleSearchKeyDown}
              placeholder="Ne arıyorsunuz?"
              className="w-full bg-transparent font-body text-sm text-secondary placeholder:text-secondary-light focus:outline-none"
            />
            <button
              type="submit"
              aria-label="Ara"
              className="ml-3 shrink-0 text-secondary-light transition-colors hover:text-primary"
            >
              <FaSearch className="h-4 w-4" />
            </button>
          </form>

          {suggestionsOpen && searchQuery.trim() && (
            <div className="absolute inset-x-0 top-full z-40 mt-2 overflow-hidden rounded-2xl border border-secondary/10 bg-white shadow-lg">
              <SearchSuggestionsPanel
                query={searchQuery.trim()}
                suggestions={suggestions}
                isSearching={isSearching}
                onNavigate={closeSuggestions}
              />
            </div>
          )}
        </div>

        {/* Kullanıcı araçları */}
        <div className="ml-auto flex shrink-0 items-center gap-5">
          {/* Mobil arama ikonu — masaüstü arama kutusu md:hidden olduğu için mobilde tek giriş noktası bu */}
          <button
            onClick={() => setMobileSearchOpen((v) => !v)}
            aria-label="Aramayı aç/kapat"
            className="md:hidden"
          >
            <FaSearch className="h-4 w-4 text-secondary transition-colors hover:text-primary" />
          </button>

          {status === "authenticated" ? (
            <div className="hidden items-center gap-3 sm:flex">
              {session.user?.role === "ADMIN" && (
                <Link
                  href="/admin"
                  className="font-body text-xs font-medium text-secondary hover:text-primary"
                >
                  Admin Paneli
                </Link>
              )}
              <Link
                href="/hesabim"
                className="flex items-center gap-2 font-body text-xs font-medium text-secondary hover:text-primary"
              >
                <FaUser className="h-3.5 w-3.5" />
                <span>{session.user?.name ?? "Hesabım"}</span>
              </Link>
              <button
                onClick={() => signOut({ callbackUrl: "/" })}
                className="font-body text-xs font-medium text-secondary-light hover:text-primary"
              >
                Çıkış
              </button>
            </div>
          ) : (
            <Link
              href="/giris"
              className="hidden items-center gap-2 font-body text-xs font-medium text-secondary hover:text-primary sm:flex"
            >
              <FaUser className="h-3.5 w-3.5" />
              <span>Giriş Yap / Kayıt Ol</span>
            </Link>
          )}
          <Link href="/sepet" className="relative">
            <FaShoppingBag className="h-5 w-5 text-secondary transition-colors hover:text-primary" />
            {cartCount > 0 && (
              <span
                key={cartCount}
                className="absolute -right-1.5 -top-1.5 flex h-4 w-4 animate-cart-bump items-center justify-center rounded-full bg-primary text-[9px] font-semibold text-white"
              >
                {cartCount}
              </span>
            )}
          </Link>
        </div>
      </div>

      {/* Mobil tam genişlikte arama katmanı — masaüstü arama kutusu md:hidden olduğu için
          mobil ziyaretçinin arama yapabildiği tek yer burası. */}
      {mobileSearchOpen && (
        <div ref={mobileSearchRef} className="border-t border-secondary/10 bg-white px-4 py-4 sm:px-6 md:hidden">
          <form
            onSubmit={submitSearch}
            className="flex items-center gap-3 rounded-full border border-secondary/15 bg-secondary/[0.03] px-5 py-3"
          >
            <input
              type="text"
              autoFocus
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              onKeyDown={handleSearchKeyDown}
              placeholder="Ne arıyorsunuz?"
              className="w-full bg-transparent font-body text-sm text-secondary placeholder:text-secondary-light focus:outline-none"
            />
            <button type="submit" aria-label="Ara" className="shrink-0 text-secondary-light hover:text-primary">
              <FaSearch className="h-4 w-4" />
            </button>
            <button
              type="button"
              onClick={() => setMobileSearchOpen(false)}
              aria-label="Aramayı kapat"
              className="shrink-0 text-secondary-light hover:text-primary"
            >
              <FaTimes className="h-4 w-4" />
            </button>
          </form>

          {suggestionsOpen && searchQuery.trim() && (
            <div className="mt-2 overflow-hidden rounded-2xl border border-secondary/10 bg-white shadow-sm">
              <SearchSuggestionsPanel
                query={searchQuery.trim()}
                suggestions={suggestions}
                isSearching={isSearching}
                onNavigate={closeSuggestions}
              />
            </div>
          )}
        </div>
      )}

      {/* Alt metin menüsü — scroll'da veya hamburger dropdown'u açıkken katlanır, ikisi aynı anda görünmez.
          Mobil cihazlarda (lg altı) tamamen gizlenir, çünkü menü erişimi sadece hamburgerden sağlanır. */}
      <div className="relative hidden lg:block" onMouseLeave={closeAllMegaMenus}>
        <nav
          className={[
            "scrollbar-hide overflow-hidden border-t border-secondary/10 transition-[max-height,opacity] duration-300 ease-in-out",
            isScrolled || menuOpen ? "max-h-0 border-t-0 opacity-0" : "max-h-20 opacity-100",
          ].join(" ")}
        >
          <ul className="mx-auto flex max-w-7xl items-center gap-8 whitespace-nowrap px-4 py-3.5 font-body text-sm font-medium text-secondary sm:px-6 lg:px-8">
            {MENU_LINKS.map((link) =>
              link.label === "Kategoriler" ? (
                <li
                  key={link.label}
                  onMouseEnter={scheduleOpenCategoriesMenu}
                  onMouseLeave={closeCategoriesMenu}
                  onFocus={openCategoriesMenu}
                >
                  <Link
                    href={link.href}
                    className="categories-trigger relative inline-block py-1 text-secondary after:absolute after:inset-x-0 after:-bottom-0.5 after:h-[1.5px] after:origin-left after:scale-x-0 after:bg-secondary after:transition-transform after:duration-300 after:ease-out hover:text-primary hover:after:scale-x-100"
                  >
                    {link.label}
                  </Link>
                </li>
              ) : link.label === "Odalara Göre" ? (
                <li
                  key={link.label}
                  onMouseEnter={scheduleOpenRoomsMenu}
                  onMouseLeave={closeRoomsMenu}
                  onFocus={openRoomsMenu}
                >
                  <Link
                    href={link.href}
                    className="categories-trigger relative inline-block py-1 text-secondary after:absolute after:inset-x-0 after:-bottom-0.5 after:h-[1.5px] after:origin-left after:scale-x-0 after:bg-secondary after:transition-transform after:duration-300 after:ease-out hover:text-primary hover:after:scale-x-100"
                  >
                    {link.label}
                  </Link>
                </li>
              ) : link.label === "Mobilyanı Tasarla" ? (
                <li key={link.label}>
                  <Link
                    href={link.href}
                    className="inline-block rounded-md bg-[#FFDB00] px-3 py-1 font-semibold text-primary transition-colors hover:bg-[#E6C500]"
                  >
                    {link.label}
                  </Link>
                </li>
              ) : (
                <li key={link.label}>
                  <Link
                    href={link.href}
                    className="relative inline-block py-1 transition-colors after:absolute after:inset-x-0 after:-bottom-0.5 after:h-[1.5px] after:origin-left after:scale-x-0 after:bg-secondary after:transition-transform after:duration-300 after:ease-out hover:text-primary hover:after:scale-x-100"
                  >
                    {link.label}
                  </Link>
                </li>
              )
            )}
          </ul>
        </nav>

        {/* "Kategoriler" mega menu paneli — referans temadaki .mega-menu__container gibi
            TAM GENİŞLİKTE, düz bir panel (kart/gölge/yuvarlak köşe yok), sadece üstte ince
            bir çizgiyle ayrılıyor. Hover'da .categories-mega.is-open ile açılır, animasyon
            mantığı globals.css'te tanımlı (bkz. .categories-mega*). */}
        <div
          className={[
            "categories-mega pointer-events-none absolute inset-x-0 top-full z-40 border-t border-secondary/10 bg-white",
            categoriesOpen ? "is-open pointer-events-auto" : "",
          ].join(" ")}
          onMouseEnter={openCategoriesMenu}
          onMouseLeave={closeCategoriesMenu}
          aria-hidden={!categoriesOpen}
        >
          <div className="mx-auto max-w-7xl px-4 py-10 sm:px-6 lg:px-8">
            <div className="flex flex-wrap gap-16">
              {categoryColumns.map((col, i) => (
                <ul key={i} className="categories-mega__col flex w-52 flex-col gap-4">
                  {col.map((cat) => (
                    <li key={cat.id}>
                      <Link href={`/kategori/${cat.slug}`} className="group flex items-center gap-3">
                        <span className="relative h-9 w-9 shrink-0 overflow-hidden rounded-full border border-secondary/10 bg-secondary/[0.04]">
                          {cat.imageUrl ? (
                            <Image
                              src={cat.imageUrl}
                              alt={cat.name}
                              fill
                              sizes="36px"
                              className="object-cover transition-transform duration-300 group-hover:scale-110"
                            />
                          ) : null}
                        </span>
                        <span className="relative font-body text-sm font-medium text-secondary after:absolute after:inset-x-0 after:-bottom-0.5 after:h-[1.5px] after:origin-left after:scale-x-0 after:bg-secondary after:transition-transform after:duration-300 after:ease-out group-hover:text-primary group-hover:after:scale-x-100">
                          {cat.name}
                        </span>
                      </Link>
                    </li>
                  ))}
                </ul>
              ))}

              <Link
                href={CATEGORY_PROMO.ctaHref}
                className="categories-mega__promo group relative block w-72 shrink-0 overflow-hidden rounded-xl"
              >
                <span className="categories-mega__promo-media relative block h-64 w-full overflow-hidden">
                  <Image
                    src={CATEGORY_PROMO.imageUrl}
                    alt={CATEGORY_PROMO.title}
                    fill
                    sizes="288px"
                    className="object-cover"
                  />
                </span>
                <span className="absolute inset-0 bg-gradient-to-t from-black/75 via-black/10 to-transparent" />
                <span className="absolute inset-x-0 bottom-0 p-5">
                  <span className="categories-mega__promo-eyebrow block font-body text-[11px] font-semibold uppercase tracking-wider text-white/80">
                    {CATEGORY_PROMO.badgeLabel} · {CATEGORY_PROMO.badgeValue}
                  </span>
                  <span className="categories-mega__promo-title mt-1 block font-display text-lg font-semibold text-white">
                    {CATEGORY_PROMO.title}
                  </span>
                  <span className="categories-mega__promo-cta btn-sweep mt-3 inline-block rounded-full px-4 py-2 font-body text-xs font-semibold text-secondary">
                    {CATEGORY_PROMO.ctaLabel}
                  </span>
                </span>
              </Link>
            </div>
          </div>
        </div>

        {/* "Odalara Göre" mega menu paneli — referans hyper-theme-demo "Shop By Room" mega
            menu'sünün birebir karşılığı: TAM GENİŞLİKTE düz panel (kart/gölge yok, sadece üst
            çizgi), solda hover'da aktif olan oda listesi, sağda o odaya ait kategori kartlarının
            aynı grid hücresinde üst üste durup (.rooms-mega-panel) crossfade + slide ile geçiş
            yaptığı panel (bkz. globals.css .rooms-mega-panel*). */}
        <div
          className={[
            "categories-mega pointer-events-none absolute inset-x-0 top-full z-40 border-t border-secondary/10 bg-white",
            roomsOpen ? "is-open pointer-events-auto" : "",
          ].join(" ")}
          onMouseEnter={openRoomsMenu}
          onMouseLeave={closeRoomsMenu}
          aria-hidden={!roomsOpen}
        >
          <div className="mx-auto max-w-7xl px-4 py-10 sm:px-6 lg:px-8">
            <div className="flex gap-12">
              {/* Sol: oda listesi — hover'da aktif oda değişir, tıklama navigasyon yapmaz
                  (referans temadaki summary davranışıyla birebir aynı: sadece sağdaki içeriği değiştirir) */}
              <div className="scrollbar-hide flex max-h-[360px] w-[220px] shrink-0 flex-col gap-1 overflow-y-auto border-r border-secondary/10 pr-6">
                {rooms.map((room) => (
                  <button
                    key={room.id}
                    type="button"
                    onMouseEnter={() => setActiveRoomSlug(room.slug)}
                    className={[
                      "rooms-mega-toggle flex items-center justify-between gap-2 rounded-lg px-3 py-2.5 text-left font-body text-sm font-medium text-secondary",
                      activeRoomSlug === room.slug ? "is-active" : "",
                    ].join(" ")}
                  >
                    {room.name}
                    <FaChevronRight className="h-2.5 w-2.5 shrink-0 text-secondary-light" />
                  </button>
                ))}
              </div>

              {/* Sağ: aktif odaya ait kategori kartları — tüm odaların panelleri aynı grid
                  hücresinde üst üste durur, sadece aktif olan görünür (bkz. .rooms-mega-panels).
                  Grid satırı görünmeyen paneller dahil en uzun içeriğe göre boyutlanır; bu yüzden
                  hem satırı (content-center) hem her panelin kendi hücre içindeki içeriğini
                  (items-center) ortalıyoruz — az kategorili odalar üstte yapışık kalmasın. */}
              <div className="rooms-mega-panels max-w-[620px] flex-1 content-center items-center">
                {rooms.map((room) => {
                  const roomCategories = (ROOM_CATEGORY_SLUGS[room.slug] ?? [])
                    .map((slug) => categoryBySlug.get(slug))
                    .filter((cat): cat is NonNullable<typeof cat> => Boolean(cat));
                  return (
                    <div
                      key={room.id}
                      className={[
                        "rooms-mega-panel grid grid-cols-3 gap-x-4 gap-y-5",
                        activeRoomSlug === room.slug ? "is-active" : "",
                      ].join(" ")}
                    >
                      {roomCategories.map((cat) => (
                        <Link
                          key={cat.id}
                          href={`/kategori/${cat.slug}`}
                          className="rooms-mega-panel__img group grid gap-2"
                        >
                          <span className="relative block aspect-[8/5] overflow-hidden rounded-lg bg-secondary/[0.04]">
                            {cat.imageUrl ? (
                              <Image src={cat.imageUrl} alt={cat.name} fill sizes="200px" className="object-cover" />
                            ) : null}
                          </span>
                          <span className="relative font-body text-xs font-medium text-secondary after:absolute after:inset-x-0 after:-bottom-0.5 after:h-[1.5px] after:origin-left after:scale-x-0 after:bg-secondary after:transition-transform after:duration-300 after:ease-out group-hover:text-primary group-hover:after:scale-x-100">
                            {cat.name}
                          </span>
                        </Link>
                      ))}
                    </div>
                  );
                })}
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Hamburger tıklanınca açılan dropdown menü */}
      <div
        className={[
          "overflow-hidden border-t border-secondary/10 bg-white shadow-md transition-[max-height,opacity] duration-300 ease-in-out",
          menuOpen ? "max-h-[500px] opacity-100" : "max-h-0 opacity-0",
        ].join(" ")}
      >
        <ul className="mx-auto flex max-w-7xl flex-col items-start gap-4 px-4 py-4 font-body text-base font-medium text-secondary sm:px-6 lg:flex-row lg:flex-wrap lg:items-center lg:gap-x-8 lg:gap-y-3 lg:px-8 lg:text-sm">
          {MENU_LINKS.map((link) => (
            <li key={link.label}>
              <Link
                href={link.href}
                onClick={() => setMenuOpen(false)}
                className={
                  link.label === "Mobilyanı Tasarla"
                    ? "inline-block rounded-md bg-[#FFDB00] px-3 py-1 font-semibold text-primary transition-colors hover:bg-[#E6C500]"
                    : "relative inline-block py-1 transition-colors after:absolute after:inset-x-0 after:-bottom-0.5 after:h-[1.5px] after:origin-left after:scale-x-0 after:bg-secondary after:transition-transform after:duration-300 after:ease-out hover:text-primary hover:after:scale-x-100"
                }
              >
                {link.label}
              </Link>
            </li>
          ))}
        </ul>
      </div>
    </header>
  );
}
