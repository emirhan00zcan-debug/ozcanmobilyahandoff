// Ürün kataloğu verisi — Prisma üzerinden veritabanından okunur (bkz. prisma/schema.prisma
// Product/ProductImage modelleri). Bu dosyadaki tipler ve `toFeaturedProduct` gibi yardımcılar
// bileşenlerin (ProductCard, ProductDetailClient, ProductListingSection...) beklediği şekli
// korumak için tutuluyor; sadece veri kaynağı sabit dizi yerine DB sorgusu oldu.

import type { Prisma } from "@prisma/client";
import { prisma } from "@/lib/prisma";
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

// Ürün sayfasındaki varyasyon seçici (renk/kumaş numunesi, kapak tipi, ölçü) için —
// bkz. prisma/schema.prisma VariationType/VariationOption/ProductVariation.
export type VariationOptionView = {
  id: string;
  value: string; // örn: "Ceviz Ahşap", "Cam Kapak"
  priceModifier: number;
  hexColor: string | null;
  swatchImageUrl: string | null;
};

export type VariationTypeView = {
  id: string;
  name: string; // örn: "Kapak Tipi", "Kulp Rengi", "Ayak Tipi"
  options: VariationOptionView[];
};

export type ProductVariationView = {
  id: string;
  sku: string;
  stock: number;
  price: number;
  heightOverrideCm: number | null;
  footHeightOverrideCm: number | null;
  // Bu varyantı oluşturan seçenek id'lerinin kümesi — seçili option id'leriyle
  // eşleştirilerek hangi ProductVariation'ın aktif olduğu bulunur.
  optionIds: string[];
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
  // getCategories() / getRooms() (homepage-mock.ts) çıktısındaki slug'larla eşleşir —
  // /kategori/[slug] ve /oda/[slug] sayfalarında ürünleri filtrelemek için kullanılır.
  categorySlug: string;
  roomSlug: string;
  variationTypes: VariationTypeView[];
  variations: ProductVariationView[];
};

const productDetailInclude = {
  images: { orderBy: { order: "asc" } },
  category: true,
  room: true,
  variationTypes: {
    orderBy: { order: "asc" },
    include: { options: true },
  },
  variations: {
    where: { isActive: true },
    include: { selectedOptions: true },
  },
} satisfies Prisma.ProductInclude;

type ProductWithRelations = Prisma.ProductGetPayload<{ include: typeof productDetailInclude }>;

// dimensionNote seed sırasında "Dış Ölçüler" notu ve "Ayak Yüksekliği" notu ", " ile birleştirilip
// tek alanda saklanıyor (bkz. prisma/seed.ts parseDimension). Burada aynı ayrımı tersine çeviriyoruz.
function splitDimensionNote(
  note: string | null,
  hasFootRow: boolean,
): { heightNote: string | null; footNote: string | null } {
  if (!note) return { heightNote: null, footNote: null };
  if (!hasFootRow) return { heightNote: note, footNote: null };
  const [first, ...rest] = note.split(", ");
  return { heightNote: first || null, footNote: rest.length ? rest.join(", ") : null };
}

function formatCm(value: Prisma.Decimal | null, note: string | null): string {
  if (value == null) return "-";
  return note ? `${value.toNumber()} cm (${note})` : `${value.toNumber()} cm`;
}

function mapToProductDetail(p: ProductWithRelations): ProductDetail {
  const hasFootRow = p.footHeightCm != null;
  const { heightNote, footNote } = splitDimensionNote(p.dimensionNote, hasFootRow);

  const dimensions: ProductDimensionRow[] = [
    {
      label: "Dış Ölçüler",
      widthCm: formatCm(p.widthCm, null),
      heightCm: formatCm(p.heightCm, heightNote),
      depthCm: formatCm(p.depthCm, null),
    },
  ];
  if (hasFootRow) {
    dimensions.push({
      label: "Ayak Yüksekliği",
      widthCm: "-",
      heightCm: formatCm(p.footHeightCm, footNote),
      depthCm: "-",
    });
  }

  return {
    slug: p.slug,
    name: p.name,
    vendor: p.vendor,
    basePrice: p.basePrice.toNumber(),
    compareAtPrice: p.compareAtPrice?.toNumber(),
    inStock: p.stock > 0,
    images: p.images.map((img) => img.url),
    features: p.features,
    dimensions,
    description: p.description,
    featureList: p.featureList,
    materialInfo: (p.materialInfo as MaterialInfoItem[] | null) ?? [],
    categorySlug: p.category.slug,
    roomSlug: p.room?.slug ?? "",
    variationTypes: p.variationTypes.map((vt) => ({
      id: vt.id,
      name: vt.name,
      options: vt.options.map((opt) => ({
        id: opt.id,
        value: opt.value,
        priceModifier: opt.priceModifier.toNumber(),
        hexColor: opt.hexColor,
        swatchImageUrl: opt.swatchImageUrl,
      })),
    })),
    variations: p.variations.map((v) => ({
      id: v.id,
      sku: v.sku,
      stock: v.stock,
      price: v.price.toNumber(),
      heightOverrideCm: v.heightOverrideCm?.toNumber() ?? null,
      footHeightOverrideCm: v.footHeightOverrideCm?.toNumber() ?? null,
      optionIds: v.selectedOptions.map((s) => s.variationOptionId),
    })),
  };
}

export async function getProductBySlug(slug: string): Promise<ProductDetail | null> {
  const product = await prisma.product.findFirst({
    where: { slug, isActive: true },
    include: productDetailInclude,
  });
  return product ? mapToProductDetail(product) : null;
}

export async function getAllProductSlugs(): Promise<string[]> {
  const products = await prisma.product.findMany({
    where: { isActive: true },
    select: { slug: true },
  });
  return products.map((p) => p.slug);
}

export async function getAllProducts(): Promise<ProductDetail[]> {
  const products = await prisma.product.findMany({
    where: { isActive: true },
    include: productDetailInclude,
    orderBy: { createdAt: "asc" },
  });
  return products.map(mapToProductDetail);
}

export async function getProductsByCategory(categorySlug: string): Promise<ProductDetail[]> {
  const products = await prisma.product.findMany({
    where: { isActive: true, category: { slug: categorySlug } },
    include: productDetailInclude,
    orderBy: { createdAt: "asc" },
  });
  return products.map(mapToProductDetail);
}

export async function getProductsByRoom(roomSlug: string): Promise<ProductDetail[]> {
  const products = await prisma.product.findMany({
    where: { isActive: true, room: { slug: roomSlug } },
    include: productDetailInclude,
    orderBy: { createdAt: "asc" },
  });
  return products.map(mapToProductDetail);
}

// Üst menüdeki arama kutusu ve /arama sonuç sayfası — ürün adı, açıklaması, kategori
// veya oda adında eşleşme arar (case-insensitive).
export async function searchProducts(query: string): Promise<ProductDetail[]> {
  const q = query.trim();
  if (!q) return [];

  const products = await prisma.product.findMany({
    where: {
      isActive: true,
      OR: [
        { name: { contains: q, mode: "insensitive" } },
        { description: { contains: q, mode: "insensitive" } },
        { category: { name: { contains: q, mode: "insensitive" } } },
        { room: { name: { contains: q, mode: "insensitive" } } },
      ],
    },
    include: productDetailInclude,
    orderBy: { createdAt: "asc" },
  });
  return products.map(mapToProductDetail);
}

// "İndirimdekiler" (/indirimler) ve "Kaçırılmayacak Fırsatlar" vitrini — üstü çizili
// compareAtPrice'ı olan (yani gerçekten indirimde olan) ürünler.
export async function getDiscountedProducts(): Promise<ProductDetail[]> {
  const products = await prisma.product.findMany({
    where: { isActive: true, compareAtPrice: { not: null } },
    include: productDetailInclude,
    orderBy: { createdAt: "asc" },
  });
  return products.map(mapToProductDetail).filter((p) => (p.compareAtPrice ?? 0) > p.basePrice);
}

// Anasayfadaki "Öne Çıkan Modeller" vitrini — Product.isFeatured alanına göre seçilir.
export async function getFeaturedProducts(): Promise<FeaturedProduct[]> {
  const products = await prisma.product.findMany({
    where: { isActive: true, isFeatured: true },
    include: { images: { orderBy: { order: "asc" }, take: 2 } },
    orderBy: { createdAt: "asc" },
  });
  return products.map((p) => ({
    id: p.slug,
    slug: p.slug,
    name: p.name,
    price: p.basePrice.toNumber(),
    compareAtPrice: p.compareAtPrice?.toNumber(),
    imageUrl: p.images[0]?.url,
    hoverImageUrl: p.images[1]?.url,
    inStock: p.stock > 0,
  }));
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
