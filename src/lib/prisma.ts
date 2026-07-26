import { PrismaClient } from "@prisma/client";

// Next.js dev modunda hot-reload her dosya değişikliğinde modülü yeniden çalıştırır;
// globalThis'e önbelleklenmezse her reload'da yeni bir PrismaClient (ve yeni bir DB
// connection pool) açılır ve "too many connections" hatasına yol açar.
const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };

export const prisma = globalForPrisma.prisma ?? new PrismaClient();

if (process.env.NODE_ENV !== "production") {
  globalForPrisma.prisma = prisma;
}
