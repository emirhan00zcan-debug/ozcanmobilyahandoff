// Geliştirme/staging veritabanını, src/lib/data/*.ts içindeki mock veriyle dolduran seed script.
// Çalıştırma: npm run db:seed  (prisma db seed de aynı komutu tetikler, bkz. package.json#prisma.seed)
//
// Amaç: mock dosyalardaki gerçek referans-site içeriğini (ürünler, kategoriler, odalar,
// FLAŞ20 kampanyası) birebir DB'ye taşımak — böylece sayfalar mock array'ler yerine
// Prisma sorgularına geçtiğinde görünüm aynı kalır.

import { PrismaClient } from "@prisma/client";
import { productCategories, rooms } from "../src/lib/data/homepage-mock";
import { products } from "../src/lib/data/products";

const prisma = new PrismaClient();

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

async function main() {
  console.log("Seed başlıyor...");

  // --- Kategoriler ("Kategoriler" mega menu + /kategori sayfaları) ---
  for (const cat of productCategories) {
    await prisma.category.upsert({
      where: { slug: cat.slug },
      update: { name: cat.name, imageUrl: cat.imageUrl },
      create: { name: cat.name, slug: cat.slug, imageUrl: cat.imageUrl },
    });
  }
  console.log(`  ${productCategories.length} kategori işlendi.`);

  // --- Odalar ("Odalara Göre" mega menu + /oda sayfaları) — dizideki sıra menü sırasıdır ---
  for (const [index, room] of rooms.entries()) {
    await prisma.room.upsert({
      where: { slug: room.slug },
      update: { name: room.name, imageUrl: room.imageUrl, order: index },
      create: { name: room.name, slug: room.slug, imageUrl: room.imageUrl, order: index },
    });
  }
  console.log(`  ${rooms.length} oda işlendi.`);

  // --- Ürünler (products.ts'teki 4 gerçek ürün) ---
  for (const p of products) {
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
      },
    });

    // Görselleri sıfırdan yaz (upsert yerine sil+yeniden ekle — seed'i tekrar çalıştırmak idempotent olsun diye)
    await prisma.productImage.deleteMany({ where: { productId: product.id } });
    if (p.images.length > 0) {
      await prisma.productImage.createMany({
        data: p.images.map((url, order) => ({ productId: product.id, url, order })),
      });
    }
  }
  console.log(`  ${products.length} ürün işlendi.`);

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
