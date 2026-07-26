// Bu dosya sadece ana sayfa arayüzünü geliştirebilmek için geçici mock veridir.
// Gerçek ürünler eklendiğinde bu diziler yerine `prisma.product.findMany(...)`
// sorgularının döndürdüğü veri kullanılacak; bileşenlerin prop tipleri buna göre
// tasarlandı ki geçiş sorunsuz olsun.

export type CategoryCircle = {
  id: string;
  name: string;
  slug: string;
  imageUrl?: string; // boşsa bileşen otomatik yer tutucu gösterir
};

// Üstteki "Kategoriler" çember navigasyonu — görseller referans siteden indirilen gerçek fotoğraflar
export const productCategories: CategoryCircle[] = [
  { id: "1", name: "Gardrop", slug: "gardirop", imageUrl: "/media/reklam2_karsidan.jpg" },
  { id: "2", name: "Portmanto", slug: "portmanto", imageUrl: "/media/wardrobe_front_closed_1776678972128.jpg" },
  { id: "3", name: "Çalışma Masası", slug: "calisma-masasi", imageUrl: "/media/Gemini_Generated_Image_ci9bm4ci9bm4ci9b.png" },
  { id: "4", name: "Tv Ünitesi", slug: "tv-unitesi", imageUrl: "/media/t3_pro_1769533120140.jpg" },
  { id: "5", name: "Kahve Köşesi", slug: "kahve-kosesi", imageUrl: "/media/Gemini_Generated_Image_5oyd1r5oyd1r5oyd.png" },
  { id: "6", name: "Oyuncu Masası", slug: "oyuncu-masasi", imageUrl: "/media/gorsel_2026-06-27_145006208.png" },
  { id: "7", name: "Banyo Dolabı", slug: "banyo-dolabi", imageUrl: "/media/d4_pro_1769532928933.jpg" },
  { id: "8", name: "Çocuk Odası", slug: "cocuk-odasi" },
  { id: "9", name: "Dresuar", slug: "dresuar", imageUrl: "/media/d2_pro_1769513413217.jpg" },
  { id: "10", name: "Makyaj Köşesi", slug: "makyaj-kosesi", imageUrl: "/media/9134f1b6-81e7-4e49-8914-9f9ae2af4137.jpg" },
  { id: "11", name: "Modüler Mutfak Dolabı", slug: "moduler-mutfak-dolabi", imageUrl: "/media/premium-kitchen.jpg" },
];

// Alttaki "Yaşam Alanına Göre Alışveriş" — Room taksonomisi (schema.prisma'daki Room modeliyle birebir)
export const rooms: CategoryCircle[] = [
  { id: "r1", name: "Yatak Odası", slug: "yatak-odasi", imageUrl: "/media/gorsel_2026-07-09_230726761.png" },
  { id: "r2", name: "Giyinme Odası", slug: "giyinme-odasi", imageUrl: "/media/Gemini_Generated_Image_zfdnerzfdnerzfdn.jpg" },
  { id: "r3", name: "Antre & Hol", slug: "antre-hol" },
  { id: "r4", name: "Salon & Oturma Odası", slug: "salon-oturma-odasi", imageUrl: "/media/Gemini_Generated_Image_xzuxo6xzuxo6xzux.png" },
  { id: "r5", name: "Mutfak", slug: "mutfak", imageUrl: "/media/premium-kitchen.jpg" },
  { id: "r6", name: "Banyo", slug: "banyo", imageUrl: "/media/gorsel_2026-07-09_233916617.png" },
  { id: "r7", name: "Çalışma Odası", slug: "calisma-odasi", imageUrl: "/media/Gemini_Generated_Image_umx6nlumx6nlumx6.png" },
  { id: "r8", name: "Genç & Çocuk Odası", slug: "genc-cocuk-odasi", imageUrl: "/media/gorsel_2026-07-09_235237239.png" },
  { id: "r9", name: "Ofis & İş Yeri", slug: "ofis-is-yeri", imageUrl: "/media/Gemini_Generated_Image_sn8381sn8381sn83.png" },
  { id: "r10", name: "Çok Amaçlı Dolaplar", slug: "cok-amacli-dolaplar", imageUrl: "/media/Gemini_Generated_Image_h3rivih3rivih3ri.png" },
  { id: "r11", name: "Aksesuarlar", slug: "aksesuarlar", imageUrl: "/media/Gemini_Generated_Image_8jyuzm8jyuzm8jyu.png" },
];

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
  ctaHref: "/iletisim",
  imageUrl: "/media/premium-bedroom.jpg",
};

// Görseller referans sitedeki gerçek ürün fotoğrafları (stüdyo + yaşam alanı çekimi, hover'da ikincisi belirir)
export const featuredProducts: FeaturedProduct[] = [
  {
    id: "p1",
    slug: "modern-klasik-3-kapakli-cerceve-kapakli-mat-beyaz-gardirop",
    name: "Modern Klasik 3 Kapaklı Çerçeve Kapaklı Mat Beyaz Gardırop",
    price: 30000,
    compareAtPrice: 42000,
    imageUrl: "/media/k602_closed_studio_1782831490167.jpg",
    hoverImageUrl: "/media/k602_lifestyle_1782831673363.jpg",
  },
  {
    id: "p2",
    slug: "alya-klasik-kemer-detayli-gardirop",
    name: "Alya Klasik Kemer Detaylı 3 Kapaklı Gardırop - Mat Beyaz",
    price: 25000,
    imageUrl: "/media/k88_closed_studio_1782832274292.jpg",
    hoverImageUrl: "/media/k88_lifestyle_1782832301685.jpg",
  },
  {
    id: "p3",
    slug: "klasik-avangart-4-cekmeceli-gardirop",
    name: "Klasik Avangart 3 Kapaklı 4 Çekmeceli Beyaz Gardırop",
    price: 35000,
    imageUrl: "/media/k83_closed_studio_1782833640405.jpg",
    hoverImageUrl: "/media/k83_lifestyle_1782833667431.jpg",
  },
  {
    id: "p4",
    slug: "k37-4-kapili-4-cekmeceli-gardirop",
    name: "K37 | 4 Kapılı 4 Çekmeceli Beyaz Gardırop",
    price: 42900,
    imageUrl: "/media/k37_closed_studio_1782841086991.jpg",
    hoverImageUrl: "/media/k37_lifestyle_1782841116348.jpg",
  },
];

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
      { label: "Sıkça Sorulan Sorular", href: "/sss" },
    ],
  },
  {
    title: "Koleksiyon",
    links: [
      { label: "Kategoriler", href: "/kategori" },
      { label: "Odalara Göre", href: "/oda" },
      { label: "Yeni Gelenler", href: "/yeni-gelenler" },
    ],
  },
  {
    title: "Alışveriş",
    links: [
      { label: "Sepetim", href: "/sepet" },
      { label: "Hesabım", href: "/hesabim" },
      { label: "Kargo & İade", href: "/kargo-iade" },
    ],
  },
];

export const socialLinks = {
  facebook: "https://facebook.com/profile.php?id=61574506475071",
  instagram: "https://instagram.com/sinop_ozcan_mobilya/",
  instagramHandle: "@sinop_ozcan_mobilya",
};
