import { NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { verifyPaytrCallbackHash } from "@/lib/payment/paytr";

// PayTR'ın sunucudan sunucuya gönderdiği ödeme bildirimi (webhook). PayTR bu uç noktayı
// merchant panelinde tanımlı sabit adresten çağırır (checkout sırasında dinamik olarak
// belirlenmez) — dokümantasyona göre yanıt tam olarak düz metin "OK" değilse PayTR bildirimi
// tekrar tekrar göndermeye devam eder.
export async function POST(req: NextRequest) {
  const formData = await req.formData();
  const merchantOid = String(formData.get("merchant_oid") ?? "");
  const status = String(formData.get("status") ?? "");
  const totalAmount = String(formData.get("total_amount") ?? "");
  const hash = String(formData.get("hash") ?? "");

  if (!merchantOid || !status || !totalAmount || !hash) {
    return new Response("PAYTR notification failed: missing fields", {
      status: 400,
      headers: { "Content-Type": "text/plain" },
    });
  }

  let hashValid: boolean;
  try {
    hashValid = verifyPaytrCallbackHash({ merchant_oid: merchantOid, status, total_amount: totalAmount, hash });
  } catch (err) {
    console.error("[paytr-bildirim] Hash doğrulaması sırasında hata:", err);
    return new Response("PAYTR notification failed: server error", {
      status: 500,
      headers: { "Content-Type": "text/plain" },
    });
  }

  // Hash uyuşmuyorsa bildirim PayTR'dan gelmiyor demektir (sahte istek olabilir) — işlem
  // yapılmaz. Gerçek PayTR bildirimlerinde hash her zaman doğru hesaplanır, bu yüzden burada
  // "OK" dönmemek (ve PayTR'ın tekrar denemesi) bir sorun oluşturmaz.
  if (!hashValid) {
    console.error("[paytr-bildirim] Geçersiz hash, bildirim yok sayıldı. merchant_oid:", merchantOid);
    return new Response("PAYTR notification failed: bad hash", {
      status: 400,
      headers: { "Content-Type": "text/plain" },
    });
  }

  try {
    await prisma.order.update({
      where: { id: merchantOid },
      data: { paymentStatus: status === "success" ? "PAID" : "FAILED" },
    });
  } catch (err) {
    // Sipariş bulunamadı vb. — PayTR'ın tekrar denemesi bu durumu çözmeyeceği için yine de
    // "OK" dönülür, sadece loglanır.
    console.error("[paytr-bildirim] Sipariş güncellenemedi. merchant_oid:", merchantOid, err);
  }

  return new Response("OK", { headers: { "Content-Type": "text/plain" } });
}
