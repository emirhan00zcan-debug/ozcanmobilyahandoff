// Anasayfanın salt-görsel/pazarlama içerikleri (hero slayt, testimonial, promo kart, footer...)
// burada statik kalır — Prisma şemasında bunlara karşılık gelen bir model yok. Kategori/oda
// taksonomisi ise Category/Room modelleriyle birebir eşleştiği için aşağıdaki fonksiyonlarla
// veritabanından okunuyor (bkz. getCategories/getRooms).

import { unstable_cache } from "next/cache";
import { prisma } from "@/lib/prisma";

export type CategoryCircle = {
  id: string;
  name: string;
  slug: string;
  imageUrl?: string; // boşsa bileşen otomatik yer tutucu gösterir
  description?: string; // sadece Category'de var (Room'da yok) — kategori sayfası meta description'ı için
};

// Üstteki "Kategoriler" çember navigasyonu — Category tablosundan, eklenme sırasına göre.
// Her sayfa (marketing layout üzerinden Navbar'a) bunu çağırdığı için unstable_cache ile
// sarmalanıyor — aksi halde 50+ sayfalık bir build tek başına aynı sorguyu 50+ kez tekrarlar.
export const getCategories = unstable_cache(
  async (): Promise<CategoryCircle[]> => {
    const categories = await prisma.category.findMany({ orderBy: { createdAt: "asc" } });
    return categories.map((c) => ({ id: c.id, name: c.name, slug: c.slug, imageUrl: c.imageUrl ?? undefined }));
  },
  ["homepage-mock:getCategories"],
  { revalidate: 300 },
);

// generateMetadata ve sayfa bileşeni aynı slug için ayrı ayrı çağırır — diğer fonksiyonlarla
// aynı unstable_cache deseni burada da tekrar sorguyu önler (bkz. getCategories yorumu).
export const getCategoryBySlug = unstable_cache(
  async (slug: string): Promise<CategoryCircle | null> => {
    const category = await prisma.category.findUnique({ where: { slug } });
    if (!category) return null;
    return {
      id: category.id,
      name: category.name,
      slug: category.slug,
      imageUrl: category.imageUrl ?? undefined,
      description: category.description ?? undefined,
    };
  },
  ["homepage-mock:getCategoryBySlug"],
  { revalidate: 300 },
);

// Alttaki "Yaşam Alanına Göre Alışveriş" — Room taksonomisi, Room.order'a göre sıralı (bkz. getCategories yorumu).
export const getRooms = unstable_cache(
  async (): Promise<CategoryCircle[]> => {
    const rooms = await prisma.room.findMany({ orderBy: { order: "asc" } });
    return rooms.map((r) => ({ id: r.id, name: r.name, slug: r.slug, imageUrl: r.imageUrl ?? undefined }));
  },
  ["homepage-mock:getRooms"],
  { revalidate: 300 },
);

export const getRoomBySlug = unstable_cache(
  async (slug: string): Promise<CategoryCircle | null> => {
    const room = await prisma.room.findUnique({ where: { slug } });
    if (!room) return null;
    return { id: room.id, name: room.name, slug: room.slug, imageUrl: room.imageUrl ?? undefined };
  },
  ["homepage-mock:getRoomBySlug"],
  { revalidate: 300 },
);

export type HeroSlide = {
  id: string;
  title: string;
  subtitle?: string;
  ctaLabel: string;
  ctaHref: string;
};

// Referans Shopify sitesindeki gerçek 2 slaytla birebir aynı metinler + gerçek fotoğraflar
export const heroSlides: (HeroSlide & { imageUrl: string })[] = [
  { id: "s1", title: "Size Özel Tasarımlar", subtitle: "Birebir Evinize Uygun Ölçüde", ctaLabel: "Koleksiyonu Gör", ctaHref: "/koleksiyon", imageUrl: "/media/premium-dresuar.jpg" },
  { id: "s2", title: "Tarzınızı Yansıtan Modeller", subtitle: "Şık Tasarıma Sahip Kapaklar", ctaLabel: "Koleksiyonu Gör", ctaHref: "/koleksiyon", imageUrl: "/media/y5_pro_1769512354644.jpg" },
];

export type FeaturedProduct = {
  id: string;
  slug: string;
  name: string;
  price: number;
  compareAtPrice?: number;
  imageUrl?: string;
  hoverImageUrl?: string; // ürünün 2. görseli (hover'da açılan iç görünüm vb.)
  inStock?: boolean; // belirtilmezse stokta kabul edilir
  stock?: number; // gerçek stok adedi (opsiyonel — bazı çağıranlar hâlâ sadece inStock verebilir)
};

export type FeaturedBanner = {
  eyebrow: string;
  title: string;
  ctaLabel: string;
  ctaHref: string;
  imageUrl?: string;
};

// "Öne Çıkan Modeller" grid'inin ilk hücresi — referans sitedeki gerçek tanıtım kartı
export const featuredProductsBanner: FeaturedBanner = {
  eyebrow: "Evinize Özel Ölçü",
  title: "Gardrop Çözümlerinde Yeni Sezon",
  ctaLabel: "Keşfet",
  ctaHref: "/kategori/gardirop",
  imageUrl: "/media/premium-bedroom.jpg",
};

// "Öne Çıkan Modeller" vitrini artık Product.isFeatured alanından geliyor —
// bkz. getFeaturedProducts() (src/lib/data/products.ts).

export type ShowcaseTile = {
  id: string;
  title: string;
  subtitle: string;
  href: string;
  miniProduct?: { name: string; price: number };
};

export const showcaseTiles: (ShowcaseTile & { imageUrl?: string })[] = [
  {
    id: "sc1",
    title: "Akıllı Gardrop Sistemleri",
    subtitle: "Yatak Odası",
    href: "/kategori/gardirop",
    miniProduct: { name: "Modern Klasik Gardırop", price: 30000 },
    imageUrl: "/media/y1_pro_1769511645588.jpg",
  },
  {
    id: "sc2",
    title: "Ahşap Konsol & TV Üniteleri",
    subtitle: "Salon & Yaşam",
    href: "/kategori/tv-unitesi",
    miniProduct: { name: "Ahşap TV Ünitesi", price: 18500 },
    imageUrl: "/media/d9_pro_1769533007384.jpg",
  },
  {
    id: "sc3",
    title: "Şık Dresuar & Depolama",
    subtitle: "Minimalist Tarz",
    href: "/kategori/dresuar",
    miniProduct: { name: "Minimalist Dresuar", price: 15900 },
    imageUrl: "/media/d2_pro_variant.jpg",
  },
  {
    id: "sc4",
    title: "Lüks Giysi Dolapları",
    subtitle: "Giyinme Odası",
    href: "/kategori/gardirop",
    miniProduct: { name: "K37 Giysi Dolabı", price: 42900 },
    imageUrl: "/media/premium-bedroom.jpg",
  },
];

// "Sizin İçin Seçtiklerimiz" sekmeli vitrin — referans siteyle birebir aynı 3 sekme
export type CollectionTab = {
  id: string;
  label: string;
  description: string;
  ctaHref: string;
  imageUrl: string;
};

export const collectionTabs: CollectionTab[] = [
  {
    id: "gardrop-sistemleri",
    label: "Gardrop Sistemleri",
    description:
      "Yatak odanıza ve giyinme odanıza tam uyum sağlayan, fonksiyonel ve modern dolap çözümleri.",
    ctaHref: "/kategori/gardirop",
    imageUrl: "/media/y5_pro_1769512354644.jpg",
  },
  {
    id: "tv-uniteleri",
    label: "TV Üniteleri",
    description:
      "Salonunuzun oda noktası için hem estetik hem de fonksiyonel çözümler. Geniş depolama alanları, gizli kablo sistemleri ve modern ahşap işçiliğiyle yaşam alanınıza şıklık katın.",
    ctaHref: "/kategori/tv-unitesi",
    imageUrl: "/media/t3_pro_1769533120140.jpg",
  },
  {
    id: "portmanto-antre",
    label: "Portmanto & Antre",
    description:
      "Evinizin ilk izlenimi antreniz için akıllı depolama çözümleri. Gizli askılıklar, geniş ayakkabılık modülleri ve aynalı kapak seçenekleriyle alanınızı en verimli şekilde değerlendirin.",
    ctaHref: "/kategori/portmanto",
    imageUrl: "/media/reklam2_karsidan.jpg",
  },
];

// "TV Üniteleri %40 / Gardroplar %30" — referans sitedeki gerçek kampanya kartları
export type PromoCard = {
  id: string;
  title: string;
  description: string;
  badgeLabel: string;
  badgeValue: string;
  ctaLabel: string;
  ctaHref: string;
};

export const promoCards: (PromoCard & { imageUrl: string })[] = [
  {
    id: "promo-tv",
    title: "TV Üniteleri",
    description:
      "Salonunuza modern bir hava katın. Kısa süreliğine tüm hazır modüler TV ünitelerinde fabrikadan doğrudan satışa özel %40 indirim!",
    badgeLabel: "Fırsat",
    badgeValue: "40%",
    ctaLabel: "Fırsatı Yakala",
    ctaHref: "/kategori/tv-unitesi",
    imageUrl: "/media/t3_pro_1769533120140.jpg",
  },
  {
    id: "promo-gardrop",
    title: "Gardroplar",
    description:
      "Evdeki kalabalığa son verin! Kolay kurulumlukiler, ayakkabılık ve modüler gardrop modellerinde net %30 indirim şansını kaçırmayın.",
    badgeLabel: "İndirim",
    badgeValue: "30%",
    ctaLabel: "Fırsatı Yakala",
    ctaHref: "/kategori/gardirop",
    imageUrl: "/media/wardrobe_front_closed_1776678972128.jpg",
  },
];

// "Sizin İçin Seçtiklerimiz" sekmelerinin hemen altındaki keşif bölümü — solda büyük
// tanıtım kartı, sağda 2x2 kategori vitrini (referans Shopify temasındaki "Hot Deals" bölümü)
export type CategorySpotlightHero = {
  eyebrow: string;
  title: string;
  description: string;
  ctaLabel: string;
  ctaHref: string;
  images: string[]; // anasayfa üstündeki HeroSlider ile aynı otomatik geçişli slider
};

export type CategorySpotlightCard = {
  id: string;
  title: string;
  subtitle: string;
  href: string;
  imageUrl: string;
};

export const categorySpotlight: { hero: CategorySpotlightHero; cards: CategorySpotlightCard[] } = {
  hero: {
    eyebrow: "Fabrikadan Doğrudan",
    title: "Demonte Tasarımlarda Kolay Kurulum",
    description:
      "Sağlam paketleme, numaralandırılmış parçalar ve net kurulum şemasıyla mobilyanız evinizde yarım saatte hazır.",
    ctaLabel: "Koleksiyonu Keşfet",
    ctaHref: "/koleksiyon",
    images: [
      "/media/download.jpg",
      "/media/gbxv.jpg",
      "/media/dasd.jpg",
    ],
  },
  cards: [
    {
      id: "spotlight-calisma-masasi",
      title: "Çalışma Masası",
      subtitle: "Ev ofisiniz için fonksiyonel çözümler",
      href: "/kategori/calisma-masasi",
      imageUrl: "/media/Gemini_Generated_Image_umx6nlumx6nlumx6.png",
    },
    {
      id: "spotlight-kahve-kosesi",
      title: "Kahve Köşesi",
      subtitle: "Sabah keyfinize özel setler",
      href: "/kategori/kahve-kosesi",
      imageUrl: "/media/Gemini_Generated_Image_5oyd1r5oyd1r5oyd.png",
    },
    {
      id: "spotlight-banyo-dolabi",
      title: "Banyo Dolabı",
      subtitle: "Neme dayanıklı şık modeller",
      href: "/kategori/banyo-dolabi",
      imageUrl: "/media/d4_pro_1769532928933.jpg",
    },
    {
      id: "spotlight-mutfak-dolabi",
      title: "Mutfak Dolabı",
      subtitle: "Ölçünüze özel modüler üretim",
      href: "/kategori/moduler-mutfak-dolabi",
      imageUrl: "/media/premium-kitchen.jpg",
    },
  ],
};

// Ürün grid'lerinin üstünde hızlı filtre olarak kullanılan gerçek kategori isimleri
export const quickFilterChips: string[] = [
  "Gardrop",
  "TV Ünitesi",
  "Portmanto",
  "Çok Amaçlı Dolap",
  "Dresuar",
  "Kitaplık",
  "Ayakkabılık",
  "Çalışma Masası",
];

// "Biz Kimiz?" bölümü — referans sitedeki gerçek marka metni ve 3 güven rozeti
export const aboutSection = {
  imageUrl: "/media/ozcan-marka-kimligi.jpg",
  eyebrow: "Biz Kimiz?",
  title: "Kolay Kurulum, Hızlı Kargo: Evinizi Yenilemek Bu Kadar Kolay!",
  body:
    "Özcan Mobilya olarak, en modern tasarımları sağlam paketleme ve kolay kurulum avantajıyla Türkiye'nin her yerine ulaştırıyoruz. Aracıları aradan kaldırarak yüksek kaliteyi en uygun fiyatlarla sunuyoruz.",
  ctaLabel: "İletişime Geç",
  ctaHref: "/iletisim",
  facts: [
    { label: "Üretim Merkezi Sinop/Türkiye" },
    { label: "4,8 Müşteri Memnuniyeti" },
    { label: "250+ üzerinde ürün" },
  ],
};

// Müşteri Deneyimleri — referans sitedeki gerçek 3 Türkçe yorum
export type Testimonial = {
  id: string;
  quote: string;
  name: string;
  location: string;
};

export const testimonials: Testimonial[] = [
  {
    id: "t1",
    quote:
      "Ürün korumalı kutularda, hiçbir hasar almadan sapasağlam geldi. İçinden çıkan kurulum şemasıyla eşimle birlikte yarım saatte tıkır tıkır kurduk. Parçaların numaralandırılmış olması işi çok kolaylaştırdı.",
    name: "Murat K.",
    location: "Ankara",
  },
  {
    id: "t2",
    quote:
      "İlk başta internetten dolap almaya çok çekiniyordum ama paketlemeyi görünce hayran kaldım. Köşelerine kalın köpükler koymuşlar, sapasağlam geldi. İçinden vidaları, her şeyi fazlasıyla çıktı. Kurulum şeması da çok netti, tek başıma kolayca kurdum.",
    name: "Selin T.",
    location: "İzmir",
  },
  {
    id: "t3",
    quote:
      "Ürünün tasarımı çok modern, odama harika uyum sağladı. Mağazalardaki hazır mobilyalara dünyanın parasını vermeye hiç gerek yokmuş. Fabrikadan doğrudan demonte geldiği için fiyatı çok uygun.",
    name: "Caner M.",
    location: "Eskişehir",
  },
];

// Footer üstü iletişim bilgi şeridi — gerçek işletme bilgileri
export const contactInfo = [
  { label: "Müşteri Hizmetleri", value: "Pazartesi-Cumartesi 09.00-18.00" },
  { label: "Bize Ulaşın", value: "+90 505 442 3809" },
  { label: "İletişime Geçin", value: "ozcan.mobilya.sinop@gmail.com" },
  { label: "Adres", value: "Camikebir Mahallesi Tütüncü sokak no 6 /A Sinop/Merkez" },
];

// Footer menü kolonları
export const footerColumns = [
  {
    title: "Kurumsal",
    links: [
      { label: "Hakkımızda", href: "/hakkimizda" },
      { label: "İletişim", href: "/iletisim" },
      { label: "Mesafeli Satış Sözleşmesi", href: "/mesafeli-satis-sozlesmesi" },
      { label: "Gizlilik Politikası", href: "/gizlilik-politikasi" },
      { label: "Çerez Politikası", href: "/cerez-politikasi" },
    ],
  },
  {
    title: "Koleksiyon",
    links: [
      { label: "Kategoriler", href: "/kategori" },
      { label: "Odalara Göre", href: "/oda" },
      { label: "Yeni Gelenler", href: "/koleksiyon/yeni-gelenler" },
      { label: "Oda Planlayıcı", href: "/planlayici" },
    ],
  },
  {
    title: "Alışveriş",
    links: [
      { label: "Sepetim", href: "/sepet" },
      { label: "Hesabım", href: "/hesabim" },
      { label: "Kargo & İade", href: "/kargo-iade" },
      { label: "Cayma Formu", href: "/cayma-formu" },
    ],
  },
];

export const socialLinks = {
  facebook: "https://facebook.com/profile.php?id=61574506475071",
  instagram: "https://instagram.com/sinop_ozcan_mobilya/",
  instagramHandle: "@sinop_ozcan_mobilya",
};
