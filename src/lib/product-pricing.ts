import { prisma } from "@/lib/prisma";

export type PriceLookupInput = {
  productId: string; // sepette tutulan değer — product.slug
  productVariationId?: string;
  name: string; // hata mesajlarında gösterilecek ürün adı
};

export type ResolvedPrice = {
  productDbId: string;
  unitPrice: number;
  // Kurulum/montaj hizmeti — ürün sunuyorsa fiyatı (yoksa null); istemciden gelen
  // installationRequested bayrağı bu değerlerle doğrulanır (bkz. order-actions.ts).
  installationAvailable: boolean;
  installationPrice: number | null;
};

// Sipariş/kupon hesaplarında satır fiyatının HER ZAMAN veritabanından okunmasını sağlar —
// istemciden (tarayıcı/devtools) gelen unitPrice asla güvenilir kaynak olarak kullanılmaz.
// Hem createOrderAction hem applyCouponAction bu fonksiyonu kullanır ki ödeme adımındaki
// önizleme ile siparişin kaydedilen tutarı her zaman aynı (ve doğru) kaynaktan gelsin.
export async function resolveAuthoritativePrice(item: PriceLookupInput): Promise<ResolvedPrice> {
  const product = await prisma.product.findUnique({ where: { slug: item.productId } });
  if (!product) throw new Error(`"${item.name}" artık satışta değil.`);

  const installationAvailable = product.installationAvailable;
  const installationPrice = product.installationPrice?.toNumber() ?? null;

  if (item.productVariationId) {
    const variation = await prisma.productVariation.findFirst({
      where: { id: item.productVariationId, productId: product.id, isActive: true },
    });
    if (!variation) throw new Error(`"${item.name}" için seçilen varyasyon artık mevcut değil.`);
    return {
      productDbId: product.id,
      unitPrice: variation.price.toNumber(),
      installationAvailable,
      installationPrice,
    };
  }

  return {
    productDbId: product.id,
    unitPrice: product.basePrice.toNumber(),
    installationAvailable,
    installationPrice,
  };
}
