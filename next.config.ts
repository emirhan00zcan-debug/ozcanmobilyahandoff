import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  experimental: {
    // Supabase pooler bağlantısı bu ortamdan yavaş (~1.5-5sn/sorgu); build sırasında
    // varsayılan paralel worker sayısı (CPU çekirdek sayısı) hepsi aynı anda DB'ye
    // bağlanmaya çalışınca bağlantı havuzunu (ve Prisma'nın pool_timeout'unu) tüketip
    // "Timed out fetching a new connection from the connection pool" hatası veriyordu.
    cpus: 4,
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
