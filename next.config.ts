import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  experimental: {
    // Supabase pooler bağlantısı bu ortamdan yavaş (~1.5-5sn/sorgu); build sırasında
    // varsayılan paralel worker sayısı (CPU çekirdek sayısı) hepsi aynı anda DB'ye
    // bağlanmaya çalışınca bağlantı havuzunu (ve Prisma'nın pool_timeout'unu) tüketip
    // "Timed out fetching a new connection from the connection pool" hatası veriyordu.
    cpus: 4,
  },
};

export default nextConfig;
