import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  experimental: {
    // Supabase pooler bağlantısı bu ortamdan yavaş (~1.5-5sn/sorgu); build sırasında
    // varsayılan paralel worker sayısı (CPU çekirdek sayısı) hepsi aynı anda DB'ye
    // bağlanmaya çalışınca bağlantı havuzunu (ve Prisma'nın pool_timeout'unu) tüketip
    // "Timed out fetching a new connection from the connection pool" hatası veriyordu.
    cpus: 4,
  },
  async redirects() {
    // Eski kurumsal sitenin (ozcanmobilya.com, /tr-TR/... yapısı) taranmış URL'lerinden
    // yeni e-ticaret sitesindeki en yakın karşılıklarına 301 — SEO/backlink değerini korumak için.
    return [
      { source: "/tr-TR", destination: "/", permanent: true },
      { source: "/tr-TR/", destination: "/", permanent: true },

      // Ürün kategorileri (/kategori/[slug])
      { source: "/tr-TR/taahhut-tv-unitesi", destination: "/kategori/tv-unitesi", permanent: true },
      { source: "/tr-TR/proje-tv-unitesi", destination: "/kategori/tv-unitesi", permanent: true },
      { source: "/tr-TR/taahhut-portmanto", destination: "/kategori/portmanto", permanent: true },
      { source: "/tr-TR/proje-portmanto", destination: "/kategori/portmanto", permanent: true },
      { source: "/tr-TR/taahhut-dresuar-ayna", destination: "/kategori/dresuar", permanent: true },
      { source: "/tr-TR/proje-dresuar-ayna", destination: "/kategori/dresuar", permanent: true },
      { source: "/tr-TR/taahhut-mutfak", destination: "/kategori/moduler-mutfak-dolabi", permanent: true },
      { source: "/tr-TR/proje-mutfak", destination: "/kategori/moduler-mutfak-dolabi", permanent: true },
      { source: "/tr-TR/taahhut-banyo-lavabo-dolaplari", destination: "/kategori/banyo-dolabi", permanent: true },
      { source: "/tr-TR/proje-banyo-lavabo-dolaplari", destination: "/kategori/banyo-dolabi", permanent: true },

      // Odalar (/oda/[slug])
      { source: "/tr-TR/taahhut-giyinme-odasi", destination: "/oda/giyinme-odasi", permanent: true },
      { source: "/tr-TR/proje-giyinme-odasi", destination: "/oda/giyinme-odasi", permanent: true },
      { source: "/tr-TR/taahhut-yatak-odasi", destination: "/oda/yatak-odasi", permanent: true },
      { source: "/tr-TR/proje-yatak-odasi", destination: "/oda/yatak-odasi", permanent: true },
      { source: "/tr-TR/taahhut-cocuk-odasi", destination: "/oda/genc-cocuk-odasi", permanent: true },
      { source: "/tr-TR/proje-cocuk-odasi", destination: "/oda/genc-cocuk-odasi", permanent: true },

      // Genel "mobilya" sayfaları -> genel katalog
      { source: "/tr-TR/proje-mobilya", destination: "/katalog", permanent: true },
      { source: "/tr-TR/taahhut-mobilya", destination: "/katalog", permanent: true },

      // Birebir karşılığı olan sayfalar
      { source: "/tr-TR/hakkimizda", destination: "/hakkimizda", permanent: true },
      { source: "/tr-TR/iletisim", destination: "/iletisim", permanent: true },

      // Kurumsal hub sayfaları -> Hakkımızda
      { source: "/tr-TR/kurumsal", destination: "/hakkimizda", permanent: true },
      { source: "/tr-TR/taahhutlerimiz", destination: "/hakkimizda", permanent: true },
      { source: "/tr-TR/projelerimiz", destination: "/hakkimizda", permanent: true },

      // İK sayfaları -> İletişim
      { source: "/tr-TR/is-basvurusu", destination: "/iletisim", permanent: true },
      { source: "/tr-TR/staj-basvurusu", destination: "/iletisim", permanent: true },

      // Yeni sitede karşılığı olmayan saf inşaat/tadilat hizmeti sayfaları -> Ana sayfa
      { source: "/tr-TR/taahhut-fayans-uygulama", destination: "/", permanent: true },
      { source: "/tr-TR/taahhut-elektrik-su-ve-tamirat", destination: "/", permanent: true },
      { source: "/tr-TR/taahhut-alci-dekorasyon", destination: "/", permanent: true },
      { source: "/tr-TR/uygulamalar", destination: "/", permanent: true },
    ];
  },
  async headers() {
    // public/models/<slug>/model.usdz varsayılan olarak application/octet-stream ile
    // sunulur (mime-db .usdz uzantısını tanımıyor) — iOS AR Quick Look, Content-Type
    // tam olarak model/vnd.usdz+zip olmadan AR'ı açmayı reddedip dosyayı indirmeye
    // çalışır (bkz. ArModelViewer'daki "Odanızda Görün" butonu). .glb için mime-db
    // zaten doğru tip döndürüyor ama Vercel'in statik sunumunda da garanti olsun diye
    // burada açıkça belirtiliyor.
    return [
      {
        source: "/models/:slug/model.usdz",
        headers: [{ key: "Content-Type", value: "model/vnd.usdz+zip" }],
      },
      {
        source: "/models/:slug/model.glb",
        headers: [{ key: "Content-Type", value: "model/gltf-binary" }],
      },
    ];
  },
};

export default nextConfig;
