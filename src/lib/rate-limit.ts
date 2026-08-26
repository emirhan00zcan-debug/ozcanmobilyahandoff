import { Ratelimit } from "@upstash/ratelimit";
import { Redis } from "@upstash/redis";
import { headers } from "next/headers";

// UPSTASH_REDIS_REST_URL/TOKEN tanımlı değilse (bkz. .env.example) rate limiting
// sessizce atlanır — RESEND_API_KEY/PLANNER_HANDOFF_SECRET'taki "best-effort" deseniyle
// aynı (bkz. lib/email.ts, lib/planner-handoff.ts): eksik konfigürasyon build/deploy'u
// kırmamalı, sadece o katmanı devre dışı bırakmalı.
const redis =
  process.env.UPSTASH_REDIS_REST_URL && process.env.UPSTASH_REDIS_REST_TOKEN
    ? new Redis({ url: process.env.UPSTASH_REDIS_REST_URL, token: process.env.UPSTASH_REDIS_REST_TOKEN })
    : null;

const limiters = new Map<string, Ratelimit>();

function getLimiter(action: string, limit: number, windowSeconds: number): Ratelimit | null {
  if (!redis) return null;
  let limiter = limiters.get(action);
  if (!limiter) {
    limiter = new Ratelimit({
      redis,
      limiter: Ratelimit.slidingWindow(limit, `${windowSeconds} s`),
      prefix: `ratelimit:${action}`,
    });
    limiters.set(action, limiter);
  }
  return limiter;
}

async function clientIp(): Promise<string> {
  const h = await headers();
  // Vercel istekleri x-forwarded-for'a gerçek istemci IP'sini en başa ekler.
  const forwarded = h.get("x-forwarded-for");
  return forwarded?.split(",")[0]?.trim() || "unknown";
}

// Herkese açık, e-posta gönderen server action'lardan (kayıt, şifre sıfırlama, bülten,
// iletişim) çağrılır — limit aşıldıysa true döner. Redis tanımlı değilse her zaman false
// (bkz. yukarıdaki not).
export async function isRateLimited(action: string, limit: number, windowSeconds: number): Promise<boolean> {
  const limiter = getLimiter(action, limit, windowSeconds);
  if (!limiter) return false;
  const ip = await clientIp();
  const { success } = await limiter.limit(ip);
  return !success;
}
