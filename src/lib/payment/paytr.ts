// PayTR iFrame API entegrasyonu (server-only) — kart verisi (numara/CVV) hiçbir zaman bu
// sunucudan geçmez: PayTR bize gömülü (iframe) bir ödeme sayfası için tek kullanımlık bir
// "token" verir, kartı kullanıcı doğrudan PayTR'ın kendi sayfasında (iframe içinde) girer.
// Bu yüzden bu entegrasyon PCI-DSS kapsamına girmez.
// Dokümantasyon: https://dev.paytr.com/iframe-api
import crypto from "crypto";
import { absoluteUrl } from "@/lib/seo";

const GET_TOKEN_ENDPOINT = "https://www.paytr.com/odeme/api/get-token";

function getPaytrCredentials() {
  const merchantId = process.env.PAYTR_MERCHANT_ID;
  const merchantKey = process.env.PAYTR_MERCHANT_KEY;
  const merchantSalt = process.env.PAYTR_MERCHANT_SALT;

  if (!merchantId || !merchantKey || !merchantSalt) {
    throw new Error(
      "PayTR kimlik bilgileri eksik: PAYTR_MERCHANT_ID, PAYTR_MERCHANT_KEY ve PAYTR_MERCHANT_SALT ortam " +
        "değişkenlerinin tanımlı olması gerekir (bkz. .env.example).",
    );
  }

  return { merchantId, merchantKey, merchantSalt };
}

// Checkout'ta "Kredi Kartı" seçeneğinin gösterilip gösterilmeyeceğine bu karar verir —
// kimlik bilgileri boşsa arayüzde yanıltıcı/çalışmayan bir seçenek durmamalı.
export function isPaytrConfigured(): boolean {
  return Boolean(process.env.PAYTR_MERCHANT_ID && process.env.PAYTR_MERCHANT_KEY && process.env.PAYTR_MERCHANT_SALT);
}

export type PaytrBasketItem = {
  name: string;
  unitPrice: number; // TL, örn. 1299.90
  quantity: number;
};

// PayTR'ın user_basket alanı: [["Ürün Adı", "birim_fiyat", adet], ...] base64 JSON dizisi.
function buildUserBasket(items: PaytrBasketItem[]): string {
  const basket = items.map((item) => [item.name, item.unitPrice.toFixed(2), item.quantity]);
  return Buffer.from(JSON.stringify(basket)).toString("base64");
}

export type GetPaytrTokenInput = {
  orderId: string; // merchant_oid olarak gönderilir — Order.id (cuid, tire içermez)
  amount: number; // TL cinsinden toplam tutar, örn. 1299.90
  userIp: string;
  email: string;
  userName: string;
  userAddress: string;
  userPhone: string;
  basket: PaytrBasketItem[];
};

export type GetPaytrTokenResult = { success: true; token: string } | { success: false; error: string };

// https://www.paytr.com/odeme/api/get-token uç noktasına istek atıp iframe için token ister.
export async function getPaytrIframeToken(input: GetPaytrTokenInput): Promise<GetPaytrTokenResult> {
  const { merchantId, merchantKey, merchantSalt } = getPaytrCredentials();

  const merchantOid = input.orderId;
  const paymentAmount = Math.round(input.amount * 100); // PayTR tutarları kuruş cinsinden (virgülsüz) bekler
  const userBasket = buildUserBasket(input.basket);
  const noInstallment = "0"; // Taksit seçeneklerini kısıtlamıyoruz
  const maxInstallment = "0"; // 0 = tüm taksit seçenekleri açık
  const currency = "TL";
  const testMode = "0";

  // PayTR dokümantasyonundaki sabit alan sırası — sıra değişirse hash uyuşmaz.
  const hashStr =
    merchantId +
    input.userIp +
    merchantOid +
    input.email +
    paymentAmount +
    userBasket +
    noInstallment +
    maxInstallment +
    currency +
    testMode;
  const paytrToken = crypto
    .createHmac("sha256", merchantKey)
    .update(hashStr + merchantSalt)
    .digest("base64");

  const body = new URLSearchParams({
    merchant_id: merchantId,
    user_ip: input.userIp,
    merchant_oid: merchantOid,
    email: input.email,
    payment_amount: String(paymentAmount),
    paytr_token: paytrToken,
    user_basket: userBasket,
    debug_on: "0",
    no_installment: noInstallment,
    max_installment: maxInstallment,
    user_name: input.userName,
    user_address: input.userAddress,
    user_phone: input.userPhone,
    merchant_ok_url: absoluteUrl(`/siparis-durumu/${input.orderId}`),
    merchant_fail_url: absoluteUrl(`/siparis-durumu/${input.orderId}`),
    timeout_limit: "30",
    currency,
    test_mode: testMode,
    lang: "tr",
  });

  let response: Response;
  try {
    response = await fetch(GET_TOKEN_ENDPOINT, {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body,
    });
  } catch {
    return { success: false, error: "PayTR'a bağlanılamadı. Lütfen daha sonra tekrar deneyin." };
  }

  const data = (await response.json().catch(() => null)) as { status?: string; token?: string; reason?: string } | null;

  if (!data || data.status !== "success" || !data.token) {
    return { success: false, error: data?.reason || "PayTR ödeme sayfası oluşturulamadı." };
  }

  return { success: true, token: data.token };
}

export type PaytrCallbackFields = {
  merchant_oid: string;
  status: string; // "success" | "failed"
  total_amount: string;
  hash: string;
};

// PayTR'dan gelen sunucu-sunucu bildiriminin gerçekten PayTR'dan geldiğini doğrular.
export function verifyPaytrCallbackHash(fields: PaytrCallbackFields): boolean {
  const { merchantKey, merchantSalt } = getPaytrCredentials();

  const hashStr = fields.merchant_oid + merchantSalt + fields.status + fields.total_amount;
  const expected = crypto.createHmac("sha256", merchantKey).update(hashStr).digest("base64");

  const expectedBuf = Buffer.from(expected);
  const receivedBuf = Buffer.from(fields.hash);
  if (expectedBuf.length !== receivedBuf.length) return false;
  return crypto.timingSafeEqual(expectedBuf, receivedBuf);
}
