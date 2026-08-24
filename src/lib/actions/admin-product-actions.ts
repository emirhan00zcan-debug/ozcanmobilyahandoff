"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { prisma } from "@/lib/prisma";
import { requireAdmin } from "@/lib/auth";

export type ProductFormState = { error: string | null };

const TURKISH_CHAR_MAP: Record<string, string> = {
  ç: "c", Ç: "c", ğ: "g", Ğ: "g", ı: "i", I: "i", İ: "i",
  ö: "o", Ö: "o", ş: "s", Ş: "s", ü: "u", Ü: "u",
};

function slugify(input: string): string {
  return input
    .split("")
    .map((ch) => TURKISH_CHAR_MAP[ch] ?? ch)
    .join("")
    .toLowerCase()
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

function parseImages(raw: string): string[] {
  return raw
    .split("\n")
    .map((line) => line.trim())
    .filter(Boolean);
}

type ParsedProductForm =
  | { ok: false; error: string }
  | {
      ok: true;
      data: {
        name: string;
        slug: string;
        shortDescription: string | null;
        description: string;
        basePrice: number;
        compareAtPrice: number | null;
        stock: number;
        categoryId: string;
        roomId: string | null;
        isActive: boolean;
        isFeatured: boolean;
        installationAvailable: boolean;
        installationPrice: number | null;
        images: string[];
      };
    };

function parseProductForm(formData: FormData, fallbackSlugSource: string): ParsedProductForm {
  const name = String(formData.get("name") ?? "").trim();
  const slugInput = String(formData.get("slug") ?? "").trim();
  const shortDescription = String(formData.get("shortDescription") ?? "").trim();
  const description = String(formData.get("description") ?? "").trim();
  const basePriceRaw = String(formData.get("basePrice") ?? "").trim();
  const compareAtPriceRaw = String(formData.get("compareAtPrice") ?? "").trim();
  const stockRaw = String(formData.get("stock") ?? "0").trim();
  const categoryId = String(formData.get("categoryId") ?? "").trim();
  const roomId = String(formData.get("roomId") ?? "").trim();
  const imagesRaw = String(formData.get("images") ?? "");
  const isActive = formData.get("isActive") === "on";
  const isFeatured = formData.get("isFeatured") === "on";
  const installationAvailable = formData.get("installationAvailable") === "on";
  const installationPriceRaw = String(formData.get("installationPrice") ?? "").trim();

  if (!name || !description || !basePriceRaw || !categoryId) {
    return { ok: false, error: "Lütfen isim, açıklama, fiyat ve kategori alanlarını doldurun." };
  }

  const basePrice = Number(basePriceRaw);
  if (!Number.isFinite(basePrice) || basePrice < 0) {
    return { ok: false, error: "Geçerli bir fiyat girin." };
  }

  let compareAtPrice: number | null = null;
  if (compareAtPriceRaw) {
    compareAtPrice = Number(compareAtPriceRaw);
    if (!Number.isFinite(compareAtPrice) || compareAtPrice < 0) {
      return { ok: false, error: "Geçerli bir eski fiyat girin." };
    }
  }

  const stock = Number.parseInt(stockRaw, 10);
  if (!Number.isFinite(stock) || stock < 0) {
    return { ok: false, error: "Geçerli bir stok adedi girin." };
  }

  const slug = slugify(slugInput || fallbackSlugSource);
  if (!slug) {
    return { ok: false, error: "İsimden geçerli bir URL (slug) oluşturulamadı, lütfen URL alanını elle girin." };
  }

  let installationPrice: number | null = null;
  if (installationPriceRaw) {
    installationPrice = Number(installationPriceRaw);
    if (!Number.isFinite(installationPrice) || installationPrice < 0) {
      return { ok: false, error: "Geçerli bir kurulum/montaj ücreti girin." };
    }
  }

  if (installationAvailable && installationPrice === null) {
    return { ok: false, error: "Kurulum/montaj hizmeti sunuluyorsa lütfen bir ücret girin." };
  }

  if (!installationAvailable) {
    installationPrice = null;
  }

  return {
    ok: true,
    data: {
      name,
      slug,
      shortDescription: shortDescription || null,
      description,
      basePrice,
      compareAtPrice,
      stock,
      categoryId,
      roomId: roomId || null,
      isActive,
      isFeatured,
      installationAvailable,
      installationPrice,
      images: parseImages(imagesRaw),
    },
  };
}

function revalidateStorefront() {
  revalidatePath("/admin/urunler");
  revalidatePath("/");
  revalidatePath("/kategori");
  revalidatePath("/kategori/[slug]", "page");
  revalidatePath("/oda");
  revalidatePath("/oda/[slug]", "page");
  revalidatePath("/koleksiyon");
  revalidatePath("/koleksiyon/[slug]", "page");
  revalidatePath("/katalog");
  revalidatePath("/indirimler");
  // "/urun" segmentinin kendi layout.tsx'i yok (yalnızca /urun/[slug]/page.tsx var), bu yüzden
  // eski "/urun", "layout" çağrısı hiçbir cache tag'iyle eşleşmiyordu ve ürünün kendi sayfası
  // fiyat değişikliğinden sonra hiç güncellenmiyordu. Doğru dinamik segment kalıbı gerekiyor.
  revalidatePath("/urun/[slug]", "page");
}

export async function createProductAction(
  _prevState: ProductFormState,
  formData: FormData,
): Promise<ProductFormState> {
  await requireAdmin();

  const parsed = parseProductForm(formData, String(formData.get("name") ?? ""));
  if (!parsed.ok) return { error: parsed.error };

  const existing = await prisma.product.findUnique({ where: { slug: parsed.data.slug } });
  if (existing) {
    return { error: `"${parsed.data.slug}" URL'si zaten kullanılıyor. Lütfen farklı bir isim/URL deneyin.` };
  }

  const category = await prisma.category.findUnique({ where: { id: parsed.data.categoryId } });
  if (!category) return { error: "Seçilen kategori bulunamadı." };

  const product = await prisma.product.create({
    data: {
      name: parsed.data.name,
      slug: parsed.data.slug,
      shortDescription: parsed.data.shortDescription,
      description: parsed.data.description,
      basePrice: parsed.data.basePrice,
      compareAtPrice: parsed.data.compareAtPrice,
      stock: parsed.data.stock,
      categoryId: parsed.data.categoryId,
      roomId: parsed.data.roomId,
      isActive: parsed.data.isActive,
      isFeatured: parsed.data.isFeatured,
      installationAvailable: parsed.data.installationAvailable,
      installationPrice: parsed.data.installationPrice,
      images: { create: parsed.data.images.map((url, order) => ({ url, order })) },
    },
  });

  revalidateStorefront();
  redirect(`/admin/urunler/${product.id}`);
}

export async function updateProductAction(
  productId: string,
  _prevState: ProductFormState,
  formData: FormData,
): Promise<ProductFormState> {
  await requireAdmin();

  const parsed = parseProductForm(formData, String(formData.get("name") ?? ""));
  if (!parsed.ok) return { error: parsed.error };

  const slugOwner = await prisma.product.findUnique({ where: { slug: parsed.data.slug } });
  if (slugOwner && slugOwner.id !== productId) {
    return { error: `"${parsed.data.slug}" URL'si başka bir üründe kullanılıyor.` };
  }

  const category = await prisma.category.findUnique({ where: { id: parsed.data.categoryId } });
  if (!category) return { error: "Seçilen kategori bulunamadı." };

  await prisma.product.update({
    where: { id: productId },
    data: {
      name: parsed.data.name,
      slug: parsed.data.slug,
      shortDescription: parsed.data.shortDescription,
      description: parsed.data.description,
      basePrice: parsed.data.basePrice,
      compareAtPrice: parsed.data.compareAtPrice,
      stock: parsed.data.stock,
      categoryId: parsed.data.categoryId,
      roomId: parsed.data.roomId,
      isActive: parsed.data.isActive,
      isFeatured: parsed.data.isFeatured,
      installationAvailable: parsed.data.installationAvailable,
      installationPrice: parsed.data.installationPrice,
    },
  });

  // Görselleri sıfırdan yaz — seed.ts'teki aynı "sil + yeniden ekle" deseni.
  await prisma.productImage.deleteMany({ where: { productId } });
  if (parsed.data.images.length > 0) {
    await prisma.productImage.createMany({
      data: parsed.data.images.map((url, order) => ({ productId, url, order })),
    });
  }

  revalidateStorefront();
  revalidatePath(`/admin/urunler/${productId}`);
  return { error: null };
}

export type VariationsFormState = { error: string | null };

// Ürün sayfasında bir varyasyon (ör. Cam Kapak + Mat Siyah + Uzun Ayak) seçildiğinde
// gösterilen fiyat/stok, Product.basePrice/stock değil bu tablodaki (ProductVariation)
// satırdan geliyor (bkz. ProductDetailClient effectivePrice/effectiveStock) — bu yüzden
// varyasyonlu ürünlerde admin panelindeki "Satış Fiyatı"/"Stok Adedi" alanları tek başına
// ürün sayfasındaki gösterilen fiyatı/stoku değiştirmiyor, bu form ayrıca gerekiyor.
export async function updateProductVariationsAction(
  productId: string,
  _prevState: VariationsFormState,
  formData: FormData,
): Promise<VariationsFormState> {
  await requireAdmin();

  const variations = await prisma.productVariation.findMany({
    where: { productId },
    select: { id: true },
  });
  if (variations.length === 0) return { error: null };

  const updates: { id: string; price: number; stock: number }[] = [];
  for (const { id } of variations) {
    const priceRaw = String(formData.get(`price_${id}`) ?? "").trim();
    const stockRaw = String(formData.get(`stock_${id}`) ?? "").trim();
    const price = Number(priceRaw);
    const stock = Number.parseInt(stockRaw, 10);
    if (!Number.isFinite(price) || price < 0) {
      return { error: "Geçerli olmayan bir fiyat girildi." };
    }
    if (!Number.isFinite(stock) || stock < 0) {
      return { error: "Geçerli olmayan bir stok adedi girildi." };
    }
    updates.push({ id, price, stock });
  }

  await prisma.$transaction(
    updates.map(({ id, price, stock }) =>
      prisma.productVariation.update({ where: { id }, data: { price, stock } }),
    ),
  );

  revalidateStorefront();
  revalidatePath(`/admin/urunler/${productId}`);
  return { error: null };
}
