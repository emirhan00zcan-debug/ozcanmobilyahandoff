import type { MetadataRoute } from "next";
import { getCategories, getRooms } from "@/lib/data/homepage-mock";
import { getAllProductSlugs } from "@/lib/data/products";
import { absoluteUrl } from "@/lib/seo";

// Genel (giriş gerektirmeyen, aramada değer taşıyan) statik sayfalar. Sepet/ödeme/hesabım/
// giriş gibi kişisel/işlevsel sayfalar ve /arama (sadece sorgu parametreli anlamlı) hariç.
const STATIC_ROUTES = [
  "",
  "hakkimizda",
  "iletisim",
  "kategori",
  "oda",
  "planlayici",
  "koleksiyon",
  "indirimler",
  "gizlilik-politikasi",
  "hizmet-sartlari",
  "kargo-iade",
  "mesafeli-satis-sozlesmesi",
];

const COLLECTION_SLUGS = ["yeni-tarz", "yeni-gelenler", "firsatlar"];

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const [productSlugs, categories, rooms] = await Promise.all([
    getAllProductSlugs(),
    getCategories(),
    getRooms(),
  ]);

  const now = new Date();

  const staticEntries: MetadataRoute.Sitemap = STATIC_ROUTES.map((path) => ({
    url: absoluteUrl(path),
    lastModified: now,
    changeFrequency: path === "" ? "daily" : "weekly",
    priority: path === "" ? 1 : 0.6,
  }));

  const collectionEntries: MetadataRoute.Sitemap = COLLECTION_SLUGS.map((slug) => ({
    url: absoluteUrl(`koleksiyon/${slug}`),
    lastModified: now,
    changeFrequency: "weekly",
    priority: 0.6,
  }));

  const categoryEntries: MetadataRoute.Sitemap = categories.map((c) => ({
    url: absoluteUrl(`kategori/${c.slug}`),
    lastModified: now,
    changeFrequency: "weekly",
    priority: 0.7,
  }));

  const roomEntries: MetadataRoute.Sitemap = rooms.map((r) => ({
    url: absoluteUrl(`oda/${r.slug}`),
    lastModified: now,
    changeFrequency: "weekly",
    priority: 0.6,
  }));

  const productEntries: MetadataRoute.Sitemap = productSlugs.map((slug) => ({
    url: absoluteUrl(`urun/${slug}`),
    lastModified: now,
    changeFrequency: "weekly",
    priority: 0.8,
  }));

  return [...staticEntries, ...collectionEntries, ...categoryEntries, ...roomEntries, ...productEntries];
}
