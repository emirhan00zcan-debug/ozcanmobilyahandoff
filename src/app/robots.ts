import type { MetadataRoute } from "next";
import { absoluteUrl } from "@/lib/seo";

export default function robots(): MetadataRoute.Robots {
  return {
    rules: {
      userAgent: "*",
      allow: "/",
      disallow: ["/admin", "/api", "/hesabim", "/sepet", "/odeme", "/giris", "/sifremi-sifirla", "/sifremi-unuttum"],
    },
    sitemap: absoluteUrl("sitemap.xml"),
  };
}
