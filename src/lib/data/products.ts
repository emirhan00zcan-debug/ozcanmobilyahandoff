// Ürün detay sayfası verisi. "modern-klasik-3-kapakli-cerceve-kapakli-mat-beyaz-gardirop"
// kaydı referans Shopify sitesindeki gerçek ürün sayfasından (preview link) birebir
// alınmıştır. Diğer kayıtlar aynı şablonu kullanabilmesi için makul içerikle dolduruldu
// (henüz referans sitede tek tek incelenmedi).

import type { FeaturedProduct } from "./homepage-mock";

export type ProductDimensionRow = {
  label: string;
  widthCm: string;
  heightCm: string;
  depthCm: string;
};

export type MaterialInfoItem = {
  label: string;
  text: string;
};

export type ProductDetail = {
  slug: string;
  name: string;
  vendor: string;
  basePrice: number;
  compareAtPrice?: number;
  inStock: boolean;
  images: string[];
  features: string[];
  dimensions: ProductDimensionRow[];
  description: string;
  featureList: string[];
  materialInfo: MaterialInfoItem[];
  // productCategories / rooms (homepage-mock.ts) içindeki slug'larla eşleşir —
  // /kategori/[slug] ve /oda/[slug] sayfalarında ürünleri filtrelemek için kullanılır.
  categorySlug: string;
  roomSlug: string;
};

export const products: ProductDetail[] = [
  {
    slug: "modern-klasik-3-kapakli-cerceve-kapakli-mat-beyaz-gardirop",
    name: "Modern Klasik 3 Kapaklı Çerçeve Kapaklı Mat Beyaz Gardırop",
    vendor: "Özcan Mobilya",
    basePrice: 30000,
    compareAtPrice: 42000,
    inStock: false,
    categorySlug: "gardirop",
    roomSlug: "yatak-odasi",
    images: [
      "/media/k602_lifestyle_1782831673363.jpg",
      "/media/k602_closed_studio_1782831490167.jpg",
      "/media/k602_open_interior_1782831500815.jpg",
    ],
    features: ["Modern", "Yatak odanıza özel tasarımlar", "2 yıllık garanti"],
    dimensions: [
      { label: "Dış Ölçüler", widthCm: "200 cm", heightCm: "220 cm (Taç Dahil)", depthCm: "60 cm" },
      { label: "Ayak Yüksekliği", widthCm: "-", heightCm: "10 cm (Robot Süpürge Uyumlu)", depthCm: "-" },
    ],
    description:
      "Geleneksel çerçeve tasarımının en modern hali! K 602 gardırop, düz ve net dikdörtgen panel hatları ile hem country hem de modern yatak odası dekorasyonlarına mükemmel uyum sağlar",
    featureList: [
      "Tasarım: Derin fugalı, simetrik dikdörtgen çerçeve kapak yapısı ve belirgin üst taç detayı.",
      "Depolama: Uzun kıyafetleriniz ve raflı düzenlemeler için optimum hacim sunan 3 kapaklı tasarım.",
      "Kulp: Minimalist, estetik metalik gri/beyaz tonlarında düğme kulplar.",
      "Malzeme: Çizilmeye karşı dayanıklı, uzun ömürlü mat beyaz gövde ve kapaklar.",
    ],
    materialInfo: [
      {
        label: "Gövde ve Kapaklar:",
        text: "1. Sınıf E1 kalitesinde, neme, ısıya ve çizilmeye karşı maksimum dayanıklı, yüksek yoğunluklu 18mm kalınlığında MDF malzeme kullanılarak üretilmiştir.",
      },
      {
        label: "Yüzey:",
        text: "Kolay temizlenebilir, leke tutmayan ve sararmaya karşı dirençli premium mat beyaz kaplama.",
      },
      {
        label: "Sağlık Standartları:",
        text: "Kanserojen madde içermeyen, Avrupa standartlarına uygun (E1) çevre ve çocuk dostu materyallerden üretilmiştir.",
      },
    ],
  },
  {
    slug: "alya-klasik-kemer-detayli-gardirop",
    name: "Alya Klasik Kemer Detaylı 3 Kapaklı Gardırop - Mat Beyaz",
    vendor: "Özcan Mobilya",
    basePrice: 25000,
    inStock: true,
    categorySlug: "gardirop",
    roomSlug: "yatak-odasi",
    images: [
      "/media/k88_closed_studio_1782832274292.jpg",
      "/media/k88_lifestyle_1782832301685.jpg",
    ],
    features: ["Modern", "Yatak odanıza özel tasarımlar", "2 yıllık garanti"],
    dimensions: [
      { label: "Dış Ölçüler", widthCm: "180 cm", heightCm: "215 cm (Taç Dahil)", depthCm: "58 cm" },
      { label: "Ayak Yüksekliği", widthCm: "-", heightCm: "8 cm", depthCm: "-" },
    ],
    description:
      "Kemer detaylı kapak hatlarıyla klasik çizgiyi modern bir yatak odasına taşıyan Alya, mat beyaz gövdesiyle her dekorasyona uyum sağlar.",
    featureList: [
      "Tasarım: Üst kısmı kemerli, simetrik 3 kapaklı klasik çizgi.",
      "Depolama: Raflı ve askılıklı iç düzenlemeyle geniş kullanım alanı.",
      "Kulp: Zarif, ince profil metal kulplar.",
      "Malzeme: Uzun ömürlü, çizilmeye dayanıklı mat beyaz gövde ve kapaklar.",
    ],
    materialInfo: [
      {
        label: "Gövde ve Kapaklar:",
        text: "1. Sınıf E1 kalitesinde, neme ve çizilmeye dayanıklı 18mm MDF malzeme kullanılarak üretilmiştir.",
      },
      {
        label: "Yüzey:",
        text: "Kolay temizlenebilir, leke tutmayan mat beyaz kaplama.",
      },
      {
        label: "Sağlık Standartları:",
        text: "Avrupa standartlarına uygun (E1) çevre ve çocuk dostu materyallerden üretilmiştir.",
      },
    ],
  },
  {
    slug: "klasik-avangart-4-cekmeceli-gardirop",
    name: "Klasik Avangart 3 Kapaklı 4 Çekmeceli Beyaz Gardırop",
    vendor: "Özcan Mobilya",
    basePrice: 35000,
    inStock: true,
    categorySlug: "gardirop",
    roomSlug: "yatak-odasi",
    images: [
      "/media/k83_closed_studio_1782833640405.jpg",
      "/media/k83_lifestyle_1782833667431.jpg",
    ],
    features: ["Modern", "Yatak odanıza özel tasarımlar", "2 yıllık garanti"],
    dimensions: [
      { label: "Dış Ölçüler", widthCm: "210 cm", heightCm: "220 cm (Taç Dahil)", depthCm: "60 cm" },
      { label: "Ayak Yüksekliği", widthCm: "-", heightCm: "10 cm (Robot Süpürge Uyumlu)", depthCm: "-" },
    ],
    description:
      "Avangart kapak hatları ve 4 geniş çekmecesiyle depolama ihtiyacınızı katlayan Klasik Avangart, yatak odanıza kullanışlı ve şık bir çözüm sunar.",
    featureList: [
      "Tasarım: Avangart, dikdörtgen çerçeve kapak yapısı ve belirgin taç detayı.",
      "Depolama: 3 kapaklı gövde + 4 geniş çekmece ile ekstra depolama alanı.",
      "Kulp: Minimalist metalik düğme kulplar.",
      "Malzeme: Çizilmeye karşı dayanıklı, uzun ömürlü mat beyaz gövde ve kapaklar.",
    ],
    materialInfo: [
      {
        label: "Gövde ve Kapaklar:",
        text: "1. Sınıf E1 kalitesinde, yüksek yoğunluklu 18mm kalınlığında MDF malzeme kullanılarak üretilmiştir.",
      },
      {
        label: "Yüzey:",
        text: "Kolay temizlenebilir, leke tutmayan ve sararmaya karşı dirençli premium mat beyaz kaplama.",
      },
      {
        label: "Çekmece Sistemi:",
        text: "Yumuşak kapanma (soft-close) raylı çekmece mekanizması kullanılmıştır.",
      },
    ],
  },
  {
    slug: "k37-4-kapili-4-cekmeceli-gardirop",
    name: "K37 | 4 Kapılı 4 Çekmeceli Beyaz Gardırop",
    vendor: "Özcan Mobilya",
    basePrice: 42900,
    inStock: false,
    categorySlug: "gardirop",
    roomSlug: "yatak-odasi",
    images: [
      "/media/k37_closed_studio_1782841086991.jpg",
      "/media/k37_lifestyle_1782841116348.jpg",
    ],
    features: ["Modern", "Yatak odanıza özel tasarımlar", "2 yıllık garanti"],
    dimensions: [
      { label: "Dış Ölçüler", widthCm: "240 cm", heightCm: "220 cm (Taç Dahil)", depthCm: "60 cm" },
      { label: "Ayak Yüksekliği", widthCm: "-", heightCm: "10 cm (Robot Süpürge Uyumlu)", depthCm: "-" },
    ],
    description:
      "Geniş aile yatak odaları için tasarlanan K37, 4 kapılı gövdesi ve 4 çekmecesiyle maksimum depolama alanı sunar.",
    featureList: [
      "Tasarım: Geniş, simetrik 4 kapaklı çerçeve yapı ve belirgin üst taç detayı.",
      "Depolama: 4 kapaklı gövde + 4 çekmece ile büyük hacimli depolama.",
      "Kulp: Minimalist, estetik metalik düğme kulplar.",
      "Malzeme: Çizilmeye karşı dayanıklı, uzun ömürlü mat beyaz gövde ve kapaklar.",
    ],
    materialInfo: [
      {
        label: "Gövde ve Kapaklar:",
        text: "1. Sınıf E1 kalitesinde, yüksek yoğunluklu 18mm kalınlığında MDF malzeme kullanılarak üretilmiştir.",
      },
      {
        label: "Yüzey:",
        text: "Kolay temizlenebilir, leke tutmayan ve sararmaya karşı dirençli premium mat beyaz kaplama.",
      },
      {
        label: "Çekmece Sistemi:",
        text: "Yumuşak kapanma (soft-close) raylı çekmece mekanizması kullanılmıştır.",
      },
    ],
  },
];

export function getProductBySlug(slug: string): ProductDetail | undefined {
  return products.find((p) => p.slug === slug);
}

export function getProductsByCategory(categorySlug: string): ProductDetail[] {
  return products.filter((p) => p.categorySlug === categorySlug);
}

export function getProductsByRoom(roomSlug: string): ProductDetail[] {
  return products.filter((p) => p.roomSlug === roomSlug);
}

// Kategori/oda listeleme sayfalarında ProductCard'ı (FeaturedProduct bekler) tekrar
// kullanabilmek için — bkz. /kategori/[slug] ve /oda/[slug].
export function toFeaturedProduct(product: ProductDetail): FeaturedProduct {
  return {
    id: product.slug,
    slug: product.slug,
    name: product.name,
    price: product.basePrice,
    compareAtPrice: product.compareAtPrice,
    imageUrl: product.images[0],
    hoverImageUrl: product.images[1],
    inStock: product.inStock,
  };
}

// "Sizden Gelenler" — referans sitedeki gerçek 4 yorum + gerçek müşteri fotoğrafları.
// Ürün sayfaları arasında ortak (siteye özel, ürüne özel değil) bir bölüm.
export type ProductReview = {
  id: string;
  image: string;
  name: string;
  rating: number;
  quote: string;
};

export const productReviews: ProductReview[] = [
  {
    id: "rev1",
    image: "/media/review-y1.jpg",
    name: "Serkan T.",
    rating: 5,
    quote:
      "Ürünler sorunsuz geldi özellikle ürünü teslim aldığımızda bizi arayıp ilgilendiler kurulumda herhangi bi yardıma ihtiyaç oluğ olmadığını sordular ilgi alaka çok iyiydi",
  },
  {
    id: "rev2",
    image: "/media/review-y3.jpg",
    name: "Elif K.",
    rating: 5,
    quote:
      "İnternetten büyük bir mobilya alırken tereddütlerim vardı fakat montaj şeması ve minifiks sistemi sayesinde kurulumu eşimle çok rahat yaptık",
  },
  {
    id: "rev3",
    image: "/media/review-y10.jpg",
    name: "Murat & Aslı Y.",
    rating: 5,
    quote:
      "Gardrop almıştık raflarından biri hasarlı geldi ancak bizimle ilgilenip hızlıca yenisini gönderdiler teşekkürler özcan mobilya",
  },
  {
    id: "rev4",
    image: "/media/review-p2.jpg",
    name: "Mehmet Ö.",
    rating: 5,
    quote:
      "Salonumuz için TV ünitesi ve gardırop siparişi verdik. Üretim kalitesi, özellikle MDF işçiliği beklediğimin çok üzerinde geldi. Paketleme o kadar sağlamdı ki hiçbir zarar görmeden teslim aldık",
  },
];

// "Teknik Detaylar" / "Marka Kimliğimiz" sekmeleri — referans sitedeki gerçek metinler,
// tüm ürün sayfalarında ortak (siteye özel) statik içerik.
export const productTechnicalTab = {
  tabLabel: "Teknik Detaylar",
  image: "/media/wardrobe_technical_drawing_v3.jpg",
  heading: "Hayallerinizi Tasarlıyor, Yaşam Alanlarınıza Taşıyoruz.",
  body: "Özcan Mobilya olarak, her bir parçayı sadece bir eşya değil, evinizin ruhunu tamamlayan birer tasarım objesi olarak görüyoruz. Modern üretim tesislerimizde, en yüksek kalitedeki ham maddeleri titiz bir işçilikle harmanlıyoruz. Çizgilerimizdeki zarafet, detaylardaki mühendislik ve malzeme kalitemizle, nesiller boyu güvenle kullanabileceğiniz zamansız ve premium yaşam alanları inşa ediyoruz.",
  checklist: [
    "1. Sınıf En İyi Malzeme Kalitesi",
    "Modern ve Estetik Endüstriyel Tasarım",
    "Güvenli Lojistik ve Kusursuz Teslimat Süreci",
  ],
};

export const productBrandTab = {
  tabLabel: "Marka Kimliğimiz",
  image: "/media/ozcan-marka-kimligi.jpg",
  heading: "Yarım Asırlık Üretim Tecrübesi: Özcan Mobilya",
  body: "Özcan Mobilya, kuruluşundan bu yana yaşam alanlarına değer katma misyonuyla hareket eden, köklü bir aile geleneğinin modern ve dijital dünyaya açılan yüzüdür. Geleneksel üretim disiplinimizi ve ustalığımızı, en güncel endüstriyel teknolojiler ve modern tasarım çizgileriyle birleştiriyoruz. Tasarımdan lojistiğe kadar her aşamada bizzat kontrolümüz altında olan üretim süreçlerimiz sayesinde, eviniz için en yüksek standartlarda, uzun ömürlü ve premium mobilyalar üretiyoruz.",
  ctaLabel: "Daha Fazla Ürün",
  ctaHref: "/kategori",
  checklist: [
    "Aile Geleneğinden Gelen Üretim Gücü",
    "Modern Teknoloji ve Dijital Dönüşüm Vizyonu",
    "Koşulsuz Müşteri Memnuniyeti Odağı",
  ],
};
