// Ana site ile planlayıcı SPA'sı (tasarla.ozcanmobilya.com — ayrı orijin,
// ayrı deploy) arasındaki kimlik devri. İki uygulama çerez paylaşamadığından
// (farklı kök alan adları) kısa ömürlü, imzalı bir HS256 JWT ile kullanıcı
// kimliği taşınır — bkz. Mimari Doküman §1.2. Üçüncü parti bir JWT
// kütüphanesi eklemek yerine PayTR entegrasyonuyla aynı desen kullanılıyor
// (bkz. src/lib/payment/paytr.ts): crypto.createHmac + timingSafeEqual.
import crypto from "crypto";

const ISSUER = "ozcanmobilya-anasite";
const AUDIENCE = "ozcanmobilya-planner";
const TTL_SECONDS = 60;
const HEADER = base64url(JSON.stringify({ alg: "HS256", typ: "JWT" }));

export interface HandoffClaims {
  iss: string;
  aud: string;
  sub: string; // NextAuth User.id — bkz. kapsam notu: misafir akışı bu fazda desteklenmiyor
  productId: string;
  iat: number;
  exp: number;
}

function base64url(input: string | Buffer): string {
  return Buffer.from(input).toString("base64url");
}

function getSecret(): string {
  const secret = process.env.PLANNER_HANDOFF_SECRET;
  if (!secret) {
    throw new Error(
      "PLANNER_HANDOFF_SECRET tanımlı değil — planlayıcı devir token'ı imzalanamaz/doğrulanamaz (bkz. .env.example).",
    );
  }
  return secret;
}

// Planlayıcının deploy edilip edilmediğinden bağımsız olarak "Odanda Tasarla"
// CTA'sının gösterilip gösterilmeyeceğine bu karar verir — isPaytrConfigured()
// ile aynı desen (src/lib/payment/paytr.ts).
export function isPlannerConfigured(): boolean {
  return Boolean(process.env.PLANNER_HANDOFF_SECRET && process.env.NEXT_PUBLIC_PLANNER_URL);
}

export function signHandoffToken(params: { userId: string; productId: string }): string {
  const secret = getSecret();
  const now = Math.floor(Date.now() / 1000);
  const claims: HandoffClaims = {
    iss: ISSUER,
    aud: AUDIENCE,
    sub: params.userId,
    productId: params.productId,
    iat: now,
    exp: now + TTL_SECONDS,
  };

  const payload = base64url(JSON.stringify(claims));
  const signature = crypto.createHmac("sha256", secret).update(`${HEADER}.${payload}`).digest("base64url");
  return `${HEADER}.${payload}.${signature}`;
}

export class HandoffTokenError extends Error {}

export function verifyHandoffToken(token: string): HandoffClaims {
  const secret = getSecret();
  const parts = token.split(".");
  if (parts.length !== 3) {
    throw new HandoffTokenError("Geçersiz token biçimi");
  }
  const [header, payload, signature] = parts;

  const expectedSignature = crypto.createHmac("sha256", secret).update(`${header}.${payload}`).digest("base64url");
  const expectedBuf = Buffer.from(expectedSignature);
  const actualBuf = Buffer.from(signature);
  if (expectedBuf.length !== actualBuf.length || !crypto.timingSafeEqual(expectedBuf, actualBuf)) {
    throw new HandoffTokenError("İmza doğrulanamadı");
  }

  let claims: HandoffClaims;
  try {
    claims = JSON.parse(Buffer.from(payload, "base64url").toString("utf8")) as HandoffClaims;
  } catch {
    throw new HandoffTokenError("Payload çözümlenemedi");
  }

  const now = Math.floor(Date.now() / 1000);
  if (claims.exp < now) {
    throw new HandoffTokenError("Token süresi dolmuş");
  }
  if (claims.iss !== ISSUER || claims.aud !== AUDIENCE) {
    throw new HandoffTokenError("Geçersiz iss/aud");
  }
  if (!claims.sub || !claims.productId) {
    throw new HandoffTokenError("Eksik claim");
  }

  return claims;
}
