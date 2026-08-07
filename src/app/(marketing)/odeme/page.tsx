import { auth } from "@/lib/auth";
import { isPaytrConfigured } from "@/lib/payment/paytr";
import CheckoutClient from "@/components/checkout/CheckoutClient";

export const metadata = { title: "Ödeme | Özcan Mobilya" };

// Giriş şart değil — misafir sipariş verilebilir (bkz. createOrderAction). Oturum
// varsa ad/e-posta önceden doldurulur; yoksa CheckoutClient e-postayı formda ister.
export default async function OdemePage() {
  const session = await auth();

  return (
    <CheckoutClient
      userName={session?.user?.name}
      userEmail={session?.user?.email}
      paytrEnabled={isPaytrConfigured()}
    />
  );
}
