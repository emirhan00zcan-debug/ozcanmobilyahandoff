// Geliştirme/staging veritabanını referans-site içeriğiyle (ürünler, kategoriler, odalar,
// FLAŞ20 kampanyası) dolduran seed script. Veri kaynağı burada literal olarak tutulur — uygulama
// artık bu içeriği src/lib/data/*.ts üzerinden değil doğrudan Prisma sorgularıyla okuyor, seed
// script'i ise ilk kurulumda/CI'da DB'yi aynı içerikle doldurmak için ayrı bir veri seti taşır.
// Çalıştırma: npm run db:seed  (prisma db seed de aynı komutu tetikler, bkz. package.json#prisma.seed)

import { PrismaClient } from "@prisma/client";
import bcrypt from "bcryptjs";

const prisma = new PrismaClient();

type SeedTaxonomy = { name: string; slug: string; imageUrl?: string };

// "Kategoriler" mega menu + /kategori sayfaları — görseller referans siteden indirilen gerçek fotoğraflar
const SEED_CATEGORIES: SeedTaxonomy[] = [
  { name: "Gardrop", slug: "gardirop", imageUrl: "/media/reklam2_karsidan.jpg" },
  { name: "Portmanto", slug: "portmanto", imageUrl: "/media/wardrobe_front_closed_1776678972128.jpg" },
  { name: "Çalışma Masası", slug: "calisma-masasi", imageUrl: "/media/Gemini_Generated_Image_ci9bm4ci9bm4ci9b.png" },
  { name: "Tv Ünitesi", slug: "tv-unitesi", imageUrl: "/media/t3_pro_1769533120140.jpg" },
  { name: "Kahve Köşesi", slug: "kahve-kosesi", imageUrl: "/media/Gemini_Generated_Image_5oyd1r5oyd1r5oyd.png" },
  { name: "Oyuncu Masası", slug: "oyuncu-masasi", imageUrl: "/media/gorsel_2026-06-27_145006208.png" },
  { name: "Banyo Dolabı", slug: "banyo-dolabi", imageUrl: "/media/d4_pro_1769532928933.jpg" },
  { name: "Çocuk Odası", slug: "cocuk-odasi", imageUrl: "/media/Gemini_Generated_Image_ci9bm4ci9bm4ci9b.png" },
  { name: "Dresuar", slug: "dresuar", imageUrl: "/media/d2_pro_1769513413217.jpg" },
  { name: "Makyaj Köşesi", slug: "makyaj-kosesi", imageUrl: "/media/9134f1b6-81e7-4e49-8914-9f9ae2af4137.jpg" },
  { name: "Modüler Mutfak Dolabı", slug: "moduler-mutfak-dolabi", imageUrl: "/media/premium-kitchen.jpg" },
];

// "Odalara Göre" mega menu + /oda sayfaları — dizideki sıra menü sırasıdır (Room.order)
const SEED_ROOMS: SeedTaxonomy[] = [
  { name: "Yatak Odası", slug: "yatak-odasi", imageUrl: "/media/gorsel_2026-07-09_230726761.png" },
  { name: "Giyinme Odası", slug: "giyinme-odasi", imageUrl: "/media/Gemini_Generated_Image_zfdnerzfdnerzfdn.jpg" },
  { name: "Antre & Hol", slug: "antre-hol", imageUrl: "/media/d6_pro_1769532959772_57b19b7d-cba8-4c79-b9a7-df88d2e24087.jpg" },
  { name: "Salon & Oturma Odası", slug: "salon-oturma-odasi", imageUrl: "/media/Gemini_Generated_Image_xzuxo6xzuxo6xzux.png" },
  { name: "Mutfak", slug: "mutfak", imageUrl: "/media/premium-kitchen.jpg" },
  { name: "Banyo", slug: "banyo", imageUrl: "/media/gorsel_2026-07-09_233916617.png" },
  { name: "Çalışma Odası", slug: "calisma-odasi", imageUrl: "/media/Gemini_Generated_Image_umx6nlumx6nlumx6.png" },
  { name: "Genç & Çocuk Odası", slug: "genc-cocuk-odasi", imageUrl: "/media/gorsel_2026-07-09_235237239.png" },
  { name: "Ofis & İş Yeri", slug: "ofis-is-yeri", imageUrl: "/media/Gemini_Generated_Image_sn8381sn8381sn83.png" },
  { name: "Çok Amaçlı Dolaplar", slug: "cok-amacli-dolaplar", imageUrl: "/media/Gemini_Generated_Image_h3rivih3rivih3ri.png" },
  { name: "Aksesuarlar", slug: "aksesuarlar", imageUrl: "/media/Gemini_Generated_Image_8jyuzm8jyuzm8jyu.png" },
];

type SeedDimensionRow = { label: string; widthCm: string; heightCm: string; depthCm: string };
type SeedMaterialInfo = { label: string; text: string };

type SeedProduct = {
  slug: string;
  name: string;
  vendor: string;
  basePrice: number;
  compareAtPrice?: number;
  inStock: boolean;
  categorySlug: string;
  roomSlug: string;
  images: string[];
  features: string[];
  dimensions: SeedDimensionRow[];
  description: string;
  featureList: string[];
  materialInfo: SeedMaterialInfo[];
};

// "modern-klasik-3-kapakli-cerceve-kapakli-mat-beyaz-gardirop" kaydı referans Shopify sitesindeki
// gerçek ürün sayfasından (preview link) birebir alınmıştır. Diğer kayıtlar aynı şablonu
// kullanabilmesi için makul içerikle dolduruldu (henüz referans sitede tek tek incelenmedi).
const SEED_PRODUCTS: SeedProduct[] = [
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

// "220 cm (Taç Dahil)" -> { value: 220, note: "Taç Dahil" }; "-" -> { value: null, note: null }
function parseDimension(raw: string): { value: number | null; note: string | null } {
  if (!raw || raw.trim() === "-") return { value: null, note: null };
  const numberMatch = raw.match(/[\d.,]+/);
  const noteMatch = raw.match(/\(([^)]+)\)/);
  return {
    value: numberMatch ? parseFloat(numberMatch[0].replace(",", ".")) : null,
    note: noteMatch ? noteMatch[1] : null,
  };
}

// ============================================================================
// VARYASYONLAR (renk/kapak tipi/ölçü seçici) — gardırop ürünleri için
// ============================================================================

type SeedVariationOption = { value: string; priceModifier?: number; hexColor?: string };
type SeedVariationType = { name: string; options: SeedVariationOption[] };

// Sıra önemli: Ayak Tipi'nin "Uzun Ayak" seçeneği aşağıda footHeightOverrideCm hesaplanırken
// index üzerinden (GARDIROP_VARIATIONS[2]) referans alınıyor.
const GARDIROP_VARIATIONS: SeedVariationType[] = [
  {
    name: "Kapak Tipi",
    options: [
      { value: "Çerçeve Kapak" },
      { value: "Cam Kapak", priceModifier: 1500 },
      { value: "Aynalı Kapak", priceModifier: 2500 },
    ],
  },
  {
    name: "Kulp Rengi",
    options: [
      { value: "Krom", hexColor: "#C0C0C0" },
      { value: "Mat Siyah", priceModifier: 300, hexColor: "#1A1A1A" },
    ],
  },
  {
    name: "Ayak Tipi",
    options: [
      { value: "Standart Ayak" },
      { value: "Uzun Ayak (+5 cm)", priceModifier: 400 },
    ],
  },
];

function slugifyValue(value: string): string {
  const trMap: Record<string, string> = {
    ç: "c", Ç: "c", ğ: "g", Ğ: "g", ı: "i", İ: "i", ö: "o", Ö: "o", ş: "s", Ş: "s", ü: "u", Ü: "u",
  };
  return value
    .split("")
    .map((ch) => trMap[ch] ?? ch)
    .join("")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

function cartesianProduct<T>(arrays: T[][]): T[][] {
  return arrays.reduce<T[][]>((acc, curr) => acc.flatMap((a) => curr.map((c) => [...a, c])), [[]]);
}

// Kapak Tipi / Kulp Rengi / Ayak Tipi eksenlerini ve bunların tüm kombinasyonu için birer
// ProductVariation (fiyat = basePrice + priceModifier toplamı) oluşturur. "Uzun Ayak" seçilen
// kombinasyonlarda footHeightOverrideCm = ürünün taban ayak yüksekliği + 5cm olarak hesaplanır.
async function seedGardirobVariations(productId: string, slug: string, basePrice: number, inStock: boolean, baseFootHeightCm: number | null) {
  await prisma.productVariation.deleteMany({ where: { productId } });
  await prisma.variationType.deleteMany({ where: { productId } }); // cascade: VariationOption'ları da siler

  const createdTypes: { options: { id: string; value: string; priceModifier: number }[] }[] = [];
  for (const [order, vt] of GARDIROP_VARIATIONS.entries()) {
    const type = await prisma.variationType.create({ data: { productId, name: vt.name, order } });
    const options = await Promise.all(
      vt.options.map((opt) =>
        prisma.variationOption.create({
          data: {
            variationTypeId: type.id,
            value: opt.value,
            priceModifier: opt.priceModifier ?? 0,
            hexColor: opt.hexColor ?? null,
          },
        }),
      ),
    );
    createdTypes.push({
      options: options.map((o) => ({ id: o.id, value: o.value, priceModifier: o.priceModifier.toNumber() })),
    });
  }

  const AYAK_TIPI_INDEX = 2;
  const combos = cartesianProduct(createdTypes.map((t) => t.options));
  for (const combo of combos) {
    const priceModifierSum = combo.reduce((sum, o) => sum + o.priceModifier, 0);
    const isUzunAyak = combo[AYAK_TIPI_INDEX]?.value.startsWith("Uzun Ayak");
    const footHeightOverrideCm = isUzunAyak && baseFootHeightCm != null ? baseFootHeightCm + 5 : null;

    const variation = await prisma.productVariation.create({
      data: {
        productId,
        sku: `${slug}-${combo.map((o) => slugifyValue(o.value)).join("-")}`,
        stock: inStock ? 10 : 0,
        price: basePrice + priceModifierSum,
        footHeightOverrideCm,
      },
    });
    await prisma.variationOptionOnVariation.createMany({
      data: combo.map((o) => ({ productVariationId: variation.id, variationOptionId: o.id })),
    });
  }
}

async function main() {
  console.log("Seed başlıyor...");

  // --- Kategoriler ("Kategoriler" mega menu + /kategori sayfaları) ---
  for (const cat of SEED_CATEGORIES) {
    await prisma.category.upsert({
      where: { slug: cat.slug },
      update: { name: cat.name, imageUrl: cat.imageUrl },
      create: { name: cat.name, slug: cat.slug, imageUrl: cat.imageUrl },
    });
  }
  console.log(`  ${SEED_CATEGORIES.length} kategori işlendi.`);

  // --- Odalar ("Odalara Göre" mega menu + /oda sayfaları) — dizideki sıra menü sırasıdır ---
  for (const [index, room] of SEED_ROOMS.entries()) {
    await prisma.room.upsert({
      where: { slug: room.slug },
      update: { name: room.name, imageUrl: room.imageUrl, order: index },
      create: { name: room.name, slug: room.slug, imageUrl: room.imageUrl, order: index },
    });
  }
  console.log(`  ${SEED_ROOMS.length} oda işlendi.`);

  // --- Ürünler ---
  for (const p of SEED_PRODUCTS) {
    const category = await prisma.category.findUnique({ where: { slug: p.categorySlug } });
    if (!category) {
      console.warn(`  ! "${p.slug}" ürünü atlandı: "${p.categorySlug}" kategorisi bulunamadı.`);
      continue;
    }
    const room = await prisma.room.findUnique({ where: { slug: p.roomSlug } });

    // dimensions[0] = "Dış Ölçüler" satırı (W/H/D), dimensions[1] varsa = "Ayak Yüksekliği" (sadece H)
    const outer = p.dimensions.find((d) => d.label === "Dış Ölçüler") ?? p.dimensions[0];
    const footRow = p.dimensions.find((d) => d.label !== outer?.label);
    const width = parseDimension(outer?.widthCm ?? "-");
    const height = parseDimension(outer?.heightCm ?? "-");
    const depth = parseDimension(outer?.depthCm ?? "-");
    const foot = parseDimension(footRow?.heightCm ?? "-");
    const dimensionNote = [height.note, foot.note].filter(Boolean).join(", ") || null;

    const product = await prisma.product.upsert({
      where: { slug: p.slug },
      update: {
        name: p.name,
        description: p.description,
        basePrice: p.basePrice,
        compareAtPrice: p.compareAtPrice ?? null,
        stock: p.inStock ? 10 : 0,
        vendor: p.vendor,
        widthCm: width.value,
        heightCm: height.value,
        depthCm: depth.value,
        footHeightCm: foot.value,
        dimensionNote,
        features: p.features,
        featureList: p.featureList,
        materialInfo: p.materialInfo,
        categoryId: category.id,
        roomId: room?.id ?? null,
        isActive: true,
        isFeatured: true,
      },
      create: {
        name: p.name,
        slug: p.slug,
        description: p.description,
        basePrice: p.basePrice,
        compareAtPrice: p.compareAtPrice ?? null,
        stock: p.inStock ? 10 : 0,
        vendor: p.vendor,
        widthCm: width.value,
        heightCm: height.value,
        depthCm: depth.value,
        footHeightCm: foot.value,
        dimensionNote,
        features: p.features,
        featureList: p.featureList,
        materialInfo: p.materialInfo,
        categoryId: category.id,
        roomId: room?.id ?? null,
        isFeatured: true,
      },
    });

    // Görselleri sıfırdan yaz (upsert yerine sil+yeniden ekle — seed'i tekrar çalıştırmak idempotent olsun diye)
    await prisma.productImage.deleteMany({ where: { productId: product.id } });
    if (p.images.length > 0) {
      await prisma.productImage.createMany({
        data: p.images.map((url, order) => ({ productId: product.id, url, order })),
      });
    }

    // Varyasyon seçici (renk/kapak tipi/ölçü) — şimdilik gardırop ürünlerinde
    if (p.categorySlug === "gardirop") {
      await seedGardirobVariations(product.id, p.slug, p.basePrice, p.inStock, foot.value);
    }
  }
  console.log(`  ${SEED_PRODUCTS.length} ürün işlendi.`);

  // --- FLAŞ20 kampanyası (CountdownBar bileşenindeki gerçek metinle birebir) ---
  const gardirop = await prisma.category.findUnique({ where: { slug: "gardirop" } });
  const now = new Date();
  await prisma.coupon.upsert({
    where: { code: "FLAS20" },
    update: {
      discountType: "PERCENTAGE",
      discountValue: 20,
      description: "Bu aya özel tüm gardırop ve TV ünitelerinde %20'ye varan fırsatlar.",
      startsAt: now,
      endsAt: new Date(now.getTime() + 18 * 24 * 60 * 60 * 1000), // ~18 gün sonra (banner'daki sayaçla uyumlu)
      isActive: true,
    },
    create: {
      code: "FLAS20",
      discountType: "PERCENTAGE",
      discountValue: 20,
      description: "Bu aya özel tüm gardırop ve TV ünitelerinde %20'ye varan fırsatlar.",
      categoryId: gardirop?.id,
      startsAt: now,
      endsAt: new Date(now.getTime() + 18 * 24 * 60 * 60 * 1000),
      isActive: true,
    },
  });
  console.log("  FLAS20 kuponu işlendi.");

  // --- Admin kullanıcı (yönetim paneli girişi) ---
  // .env'de ADMIN_EMAIL/ADMIN_PASSWORD tanımlıysa upsert edilir (var olan bir hesapsa
  // sadece role=ADMIN yapılır + şifre günceller); tanımlı değilse bu adım atlanır —
  // rastgele bir hesabı yanlışlıkla admin yapmamak için varsayılan değer kullanılmaz.
  const adminEmail = process.env.ADMIN_EMAIL?.trim().toLowerCase();
  const adminPassword = process.env.ADMIN_PASSWORD;
  if (adminEmail && adminPassword) {
    const passwordHash = await bcrypt.hash(adminPassword, 10);
    await prisma.user.upsert({
      where: { email: adminEmail },
      update: { role: "ADMIN", passwordHash },
      create: { email: adminEmail, name: "Özcan Mobilya Yönetici", passwordHash, role: "ADMIN" },
    });
    console.log(`  Admin kullanıcı işlendi: ${adminEmail}`);
  } else {
    console.log("  ADMIN_EMAIL / ADMIN_PASSWORD tanımlı değil, admin kullanıcı adımı atlandı.");
  }

  console.log("Seed tamamlandı.");
}

main()
  .catch((err) => {
    console.error(err);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
