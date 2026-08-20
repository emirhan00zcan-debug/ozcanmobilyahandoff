"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { FaCheckCircle } from "react-icons/fa";
import { useCartItems, useCartSubtotal, useCartInstallationTotal, useCartStore } from "@/store/cart-store";
import { createOrderAction, type CheckoutAddressInput } from "@/lib/actions/order-actions";
import { applyCouponAction } from "@/lib/actions/coupon-actions";
import { requestPaytrIframeTokenAction } from "@/lib/actions/paytr-actions";
import { trackBeginCheckout, trackPurchase } from "@/lib/analytics";
import citiesData from "@/lib/data/cities.json";
import type { PaymentMethodType } from "@prisma/client";

function formatPrice(value: number) {
  return (
    new Intl.NumberFormat("tr-TR", {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    }).format(value) + " TL"
  );
}

const EMPTY_ADDRESS: CheckoutAddressInput = {
  email: "",
  title: "Ev",
  fullName: "",
  phone: "",
  city: "",
  district: "",
  addressLine: "",
  postalCode: "",
};

type Props = { userName?: string | null; userEmail?: string | null; paytrEnabled: boolean };

const PAYMENT_METHOD_OPTIONS: { value: PaymentMethodType; label: string }[] = [
  { value: "CASH_ON_DELIVERY", label: "Kapıda Ödeme" },
  { value: "BANK_TRANSFER", label: "Havale / EFT" },
  { value: "CARD", label: "Kredi Kartı" },
];

export default function CheckoutClient({ userName, userEmail, paytrEnabled }: Props) {
  const items = useCartItems();
  const subtotal = useCartSubtotal();
  const installationTotal = useCartInstallationTotal();
  const clearCart = useCartStore((state) => state.clearCart);

  const [address, setAddress] = useState<CheckoutAddressInput>(() => ({
    ...EMPTY_ADDRESS,
    email: userEmail ?? "",
  }));
  const [note, setNote] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [orderNumber, setOrderNumber] = useState<string | null>(null);
  const [emailVerificationRequired, setEmailVerificationRequired] = useState(false);
  const [contractAccepted, setContractAccepted] = useState(false);

  const [paymentMethod, setPaymentMethod] = useState<PaymentMethodType>("CASH_ON_DELIVERY");
  const [paytrToken, setPaytrToken] = useState<string | null>(null);
  const [cardTokenError, setCardTokenError] = useState<string | null>(null);

  const [couponCode, setCouponCode] = useState("");
  const [couponLoading, setCouponLoading] = useState(false);
  const [couponError, setCouponError] = useState<string | null>(null);
  const [appliedCoupon, setAppliedCoupon] = useState<{
    code: string;
    description: string | null;
    discountAmount: number;
  } | null>(null);

  const total = Math.max(0, subtotal - (appliedCoupon?.discountAmount ?? 0) + installationTotal);

  // Ödeme sayfası dolu bir sepetle açıldığında bir kez — GA4 huninde view_item ->
  // add_to_cart -> begin_checkout -> purchase adımlarıyla "sepetin nerede terk edildiği" görünür olur.
  useEffect(() => {
    if (items.length > 0) {
      trackBeginCheckout(
        items.map((item) => ({
          item_id: item.productId,
          item_name: item.name,
          price: item.unitPrice,
          quantity: item.quantity,
        })),
        subtotal,
      );
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const handleChange = (field: keyof CheckoutAddressInput) => (e: React.ChangeEvent<HTMLInputElement>) => {
    setAddress((prev) => ({ ...prev, [field]: e.target.value }));
  };

  const handleApplyCoupon = async () => {
    if (!couponCode.trim()) return;
    setCouponLoading(true);
    setCouponError(null);

    const result = await applyCouponAction(
      couponCode,
      items.map((item) => ({
        productId: item.productId,
        productVariationId: item.productVariationId,
        name: item.name,
        quantity: item.quantity,
      })),
    );

    setCouponLoading(false);
    if (result.success) {
      setAppliedCoupon({
        code: result.code,
        description: result.description,
        discountAmount: result.discountAmount,
      });
    } else {
      setAppliedCoupon(null);
      setCouponError(result.error);
    }
  };

  const handleRemoveCoupon = () => {
    setAppliedCoupon(null);
    setCouponCode("");
    setCouponError(null);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (items.length === 0) return;
    if (!contractAccepted) {
      setError("Devam etmek için Ön Bilgilendirme Formu ve Mesafeli Satış Sözleşmesi'ni onaylamanız gerekir.");
      return;
    }
    setIsSubmitting(true);
    setError(null);

    const result = await createOrderAction(
      address,
      items.map((item) => ({
        productId: item.productId,
        productVariationId: item.productVariationId,
        name: item.name,
        unitPrice: item.unitPrice,
        quantity: item.quantity,
        installationRequested: item.installationRequested,
      })),
      note || undefined,
      appliedCoupon?.code,
      paymentMethod,
    );

    if (!result.success) {
      setIsSubmitting(false);
      setError(result.error);
      return;
    }

    trackPurchase(
      result.orderNumber,
      items.map((item) => ({
        item_id: item.productId,
        item_name: item.name,
        price: item.unitPrice,
        quantity: item.quantity,
      })),
      total,
    );

    if (paymentMethod === "CARD") {
      // Sepetteki her satır PayTR'ın user_basket alanına ayrı bir kalem olarak gönderilir
      // (bkz. lib/payment/paytr.ts) — bu, PayTR'ın ödeme ekranında ve kendi raporlamasında
      // gösterdiği ürün listesidir; asıl tahsil edilen tutar ayrıca "amount" ile gönderilir.
      const basket = items.map((item) => ({ name: item.name, unitPrice: item.unitPrice, quantity: item.quantity }));
      if (installationTotal > 0) {
        basket.push({ name: "Kurulum / Montaj Hizmeti", unitPrice: installationTotal, quantity: 1 });
      }

      const tokenResult = await requestPaytrIframeTokenAction({
        orderId: result.orderId,
        amount: total,
        customerName: address.fullName,
        customerEmail: address.email,
        customerPhone: address.phone,
        customerAddress: `${address.addressLine}, ${address.district}/${address.city}`,
        basket,
      });

      setIsSubmitting(false);
      clearCart();

      if (tokenResult.success) {
        setPaytrToken(tokenResult.token);
        setOrderNumber(result.orderNumber);
        setEmailVerificationRequired(result.emailVerificationRequired);
      } else {
        // Sipariş zaten oluşturuldu (PENDING) — sadece PayTR ödeme sayfası açılamadı.
        // Kullanıcıyı normal "sipariş alındı" akışına düşürüp durumu dürüstçe bildiriyoruz.
        setCardTokenError(tokenResult.error);
        setOrderNumber(result.orderNumber);
        setEmailVerificationRequired(result.emailVerificationRequired);
      }
      return;
    }

    setIsSubmitting(false);
    setOrderNumber(result.orderNumber);
    setEmailVerificationRequired(result.emailVerificationRequired);
    clearCart();
  };

  if (paytrToken) {
    return (
      <div className="mx-auto max-w-2xl px-4 py-10 sm:px-6 lg:px-8">
        <h1 className="text-center font-display text-2xl font-bold text-secondary sm:text-3xl">
          Kart ile Ödeme
        </h1>
        <p className="mt-2 text-center font-body text-sm text-secondary-light">
          Kart bilgilerinizi PayTR&apos;ın güvenli ödeme sayfasında girebilirsiniz. Sipariş
          numaranız: <span className="font-semibold text-secondary">{orderNumber}</span>
        </p>
        <div className="mt-6 overflow-hidden rounded-2xl border border-secondary/10">
          <iframe
            src={`https://www.paytr.com/odeme/guvenli/${paytrToken}`}
            className="h-[640px] w-full"
            frameBorder={0}
            title="PayTR Güvenli Ödeme"
          />
        </div>
      </div>
    );
  }

  if (items.length === 0 && !orderNumber) {
    return (
      <div className="mx-auto flex max-w-7xl flex-col items-center px-4 py-24 text-center sm:px-6 lg:px-8">
        <h1 className="font-display text-2xl font-bold text-secondary">Sepetiniz boş</h1>
        <Link
          href="/kategori"
          className="btn-sweep mt-6 rounded-full border border-primary/30 px-8 py-3.5 font-body text-sm font-semibold text-secondary hover:scale-105 active:scale-95"
        >
          Kategorilere Göz At
        </Link>
      </div>
    );
  }

  if (orderNumber) {
    return (
      <div className="mx-auto flex max-w-2xl flex-col items-center px-4 py-24 text-center sm:px-6 lg:px-8">
        <FaCheckCircle className="h-14 w-14 text-primary" />
        <h1 className="mt-5 font-display text-2xl font-bold text-secondary sm:text-3xl">
          Siparişiniz Alındı!
        </h1>
        <p className="mt-2 font-body text-sm text-secondary-light">
          Sipariş numaranız: <span className="font-semibold text-secondary">{orderNumber}</span>
        </p>
        {emailVerificationRequired ? (
          <p className="mt-1 max-w-sm font-body text-sm text-secondary-light">
            Sipariş detaylarını içeren onay e-postasını gönderebilmemiz için adresinize bir
            doğrulama bağlantısı yolladık — lütfen gelen kutunuzu kontrol edip bağlantıya
            tıklayın.
          </p>
        ) : (
          <p className="mt-1 font-body text-sm text-secondary-light">
            Sipariş detaylarını Hesabım sayfanızdan takip edebilirsiniz.
          </p>
        )}
        {cardTokenError && (
          <p className="mt-3 max-w-sm rounded-xl border border-red-200 bg-red-50 px-4 py-3 font-body text-xs text-red-700">
            Kredi kartı ödeme sayfası şu anda açılamadı ({cardTokenError}). Ekibimiz siparişiniz
            için sizinle iletişime geçecek.
          </p>
        )}
        <div className="mt-6 flex gap-3">
          <Link
            href="/"
            className="btn-sweep rounded-full border border-primary/30 px-6 py-3 font-body text-sm font-semibold text-secondary"
          >
            Ana Sayfa
          </Link>
          <Link
            href="/hesabim"
            className="btn-sweep rounded-full border border-primary/30 px-6 py-3 font-body text-sm font-semibold text-secondary"
          >
            Siparişlerim
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
      <nav className="mb-6 flex items-center gap-2 font-body text-xs text-secondary-light">
        <Link href="/" className="font-medium text-secondary hover:text-primary">
          Ana sayfa
        </Link>
        <span>|</span>
        <Link href="/sepet" className="hover:text-primary">
          Sepetim
        </Link>
        <span>|</span>
        <span className="text-secondary-light">Ödeme</span>
      </nav>

      <h1 className="font-display text-2xl font-bold text-secondary sm:text-3xl">
        Teslimat Bilgileri {userName ? `— Merhaba, ${userName}` : ""}
      </h1>
      {!userName && (
        <p className="mt-1.5 font-body text-xs text-secondary-light">
          Misafir olarak sipariş verebilirsiniz. Zaten hesabınız var mı?{" "}
          <Link href="/giris?callbackUrl=%2Fodeme" className="font-medium text-primary hover:underline">
            Giriş yapın
          </Link>
          .
        </p>
      )}

      <form onSubmit={handleSubmit} className="mt-8 grid grid-cols-1 gap-10 lg:grid-cols-3">
        {/* Adres formu */}
        <div className="space-y-4 lg:col-span-2">
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <Field label="E-posta" value={address.email} onChange={handleChange("email")} required type="email" />
            <Field label="Adres Başlığı" value={address.title} onChange={handleChange("title")} placeholder="Ev, Ofis..." />
            <Field label="Ad Soyad" value={address.fullName} onChange={handleChange("fullName")} required />
            <Field label="Telefon" value={address.phone} onChange={handleChange("phone")} required type="tel" />
            <Field label="Posta Kodu" value={address.postalCode ?? ""} onChange={handleChange("postalCode")} />

            <SelectField
              label="Şehir"
              value={address.city}
              onChange={(e) => {
                setAddress((prev) => ({ ...prev, city: e.target.value, district: "" }));
              }}
              required
              options={citiesData.map((c) => ({ label: c.name, value: c.name }))}
              placeholder="İl Seçiniz"
            />

            <SelectField
              label="İlçe"
              value={address.district}
              onChange={(e) => setAddress((prev) => ({ ...prev, district: e.target.value }))}
              required
              options={
                address.city
                  ? citiesData
                    .find((c) => c.name === address.city)
                    ?.districts.map((d) => ({ label: d.name, value: d.name })) || []
                  : []
              }
              placeholder="İlçe Seçiniz"
              disabled={!address.city}
            />
          </div>
          <div>
            <label className="mb-1.5 block font-body text-xs font-medium text-secondary-light">Açık Adres</label>
            <textarea
              required
              rows={3}
              value={address.addressLine}
              onChange={(e) => setAddress((prev) => ({ ...prev, addressLine: e.target.value }))}
              className="w-full rounded-xl border border-secondary/15 px-4 py-3 font-body text-sm text-secondary focus:border-primary focus:outline-none"
            />
          </div>
          <div>
            <label className="mb-1.5 block font-body text-xs font-medium text-secondary-light">Sipariş Notu (opsiyonel)</label>
            <textarea
              rows={2}
              value={note}
              onChange={(e) => setNote(e.target.value)}
              className="w-full rounded-xl border border-secondary/15 px-4 py-3 font-body text-sm text-secondary focus:border-primary focus:outline-none"
            />
          </div>
        </div>

        {/* Özet */}
        <div className="h-fit rounded-2xl border border-secondary/10 p-6">
          <h2 className="font-display text-lg font-semibold text-secondary">Sipariş Özeti</h2>
          <ul className="mt-4 space-y-2">
            {items.map((item) => (
              <li key={item.id} className="flex justify-between font-body text-xs text-secondary-light">
                <span>
                  {item.name} × {item.quantity}
                </span>
                <span className="shrink-0 pl-2 font-medium text-secondary">{formatPrice(item.totalPrice)}</span>
              </li>
            ))}
          </ul>
          <div className="mt-4 border-t border-secondary/10 pt-4">
            <label className="mb-1.5 block font-body text-xs font-medium text-secondary-light">
              İndirim Kodu
            </label>
            {appliedCoupon ? (
              <div className="flex items-center justify-between rounded-xl border border-primary/30 bg-primary/5 px-4 py-3">
                <div>
                  <p className="font-body text-sm font-semibold text-secondary">{appliedCoupon.code}</p>
                  {appliedCoupon.description && (
                    <p className="font-body text-xs text-secondary-light">{appliedCoupon.description}</p>
                  )}
                </div>
                <button
                  type="button"
                  onClick={handleRemoveCoupon}
                  className="font-body text-xs font-medium text-secondary-light transition-colors hover:text-red-600"
                >
                  Kaldır
                </button>
              </div>
            ) : (
              <div className="flex gap-2">
                <input
                  type="text"
                  value={couponCode}
                  onChange={(e) => setCouponCode(e.target.value)}
                  placeholder="Örn: FLAS20"
                  className="w-full rounded-xl border border-secondary/15 px-4 py-2.5 font-body text-sm text-secondary focus:border-primary focus:outline-none"
                />
                <button
                  type="button"
                  onClick={handleApplyCoupon}
                  disabled={couponLoading || !couponCode.trim()}
                  className="btn-sweep shrink-0 rounded-xl border border-primary/30 px-4 py-2.5 font-body text-xs font-semibold text-secondary disabled:opacity-60"
                >
                  {couponLoading ? "..." : "Uygula"}
                </button>
              </div>
            )}
            {couponError && <p className="mt-2 font-body text-xs font-medium text-red-600">{couponError}</p>}
          </div>

          <div className="mt-4 space-y-1.5 border-t border-secondary/10 pt-4 font-body text-sm">
            <div className="flex items-center justify-between">
              <span className="text-secondary-light">Ara Toplam</span>
              <span className="font-medium text-secondary">{formatPrice(subtotal)}</span>
            </div>
            {appliedCoupon && (
              <div className="flex items-center justify-between text-primary">
                <span>İndirim ({appliedCoupon.code})</span>
                <span className="font-medium">-{formatPrice(appliedCoupon.discountAmount)}</span>
              </div>
            )}
            {installationTotal > 0 && (
              <div className="flex items-center justify-between">
                <span className="text-secondary-light">Kurulum/Montaj Hizmeti</span>
                <span className="font-medium text-secondary">{formatPrice(installationTotal)}</span>
              </div>
            )}
            <div className="flex items-center justify-between pt-1">
              <span className="font-semibold text-secondary">Toplam</span>
              <span className="font-semibold text-secondary">{formatPrice(total)}</span>
            </div>
          </div>

          <div className="mt-4 space-y-2 border-t border-secondary/10 pt-4">
            <label className="mb-1.5 block font-body text-xs font-medium text-secondary-light">
              Ödeme Yöntemi
            </label>
            {PAYMENT_METHOD_OPTIONS.filter((option) => option.value !== "CARD" || paytrEnabled).map((option) => (
              <label
                key={option.value}
                className={`flex cursor-pointer items-center gap-3 rounded-xl border px-4 py-3 font-body text-sm transition-colors ${
                  paymentMethod === option.value
                    ? "border-primary bg-primary/5 text-secondary"
                    : "border-secondary/15 text-secondary-light hover:border-secondary/30"
                }`}
              >
                <input
                  type="radio"
                  name="paymentMethod"
                  value={option.value}
                  checked={paymentMethod === option.value}
                  onChange={() => setPaymentMethod(option.value)}
                  className="h-4 w-4 accent-primary"
                />
                {option.label}
              </label>
            ))}
          </div>

          <label className="mt-4 flex items-start gap-2.5 border-t border-secondary/10 pt-4 font-body text-xs text-secondary-light">
            <input
              type="checkbox"
              checked={contractAccepted}
              onChange={(e) => setContractAccepted(e.target.checked)}
              className="mt-0.5 h-4 w-4 shrink-0 accent-primary"
            />
            <span>
              <Link href="/mesafeli-satis-sozlesmesi" target="_blank" className="font-medium text-primary underline underline-offset-2 hover:text-primary/80">
                Ön Bilgilendirme Formu&apos;nu ve Mesafeli Satış Sözleşmesi&apos;ni
              </Link>{" "}
              okudum, içeriğini onaylıyorum.
            </span>
          </label>

          {error && <p className="mt-3 font-body text-xs font-medium text-red-600">{error}</p>}

          <button
            type="submit"
            disabled={isSubmitting || !contractAccepted}
            className="btn-sweep mt-5 w-full rounded-full border border-primary/30 py-3.5 font-body text-sm font-semibold text-secondary hover:scale-[1.02] active:scale-95 disabled:opacity-60 disabled:hover:scale-100"
          >
            {isSubmitting
              ? paymentMethod === "CARD"
                ? "Ödeme sayfası hazırlanıyor..."
                : "Sipariş oluşturuluyor..."
              : "Siparişi Onayla"}
          </button>
        </div>
      </form>
    </div>
  );
}

function Field({
  label,
  value,
  onChange,
  required,
  type = "text",
  placeholder,
}: {
  label: string;
  value: string;
  onChange: (e: React.ChangeEvent<HTMLInputElement>) => void;
  required?: boolean;
  type?: string;
  placeholder?: string;
}) {
  return (
    <div>
      <label className="mb-1.5 block font-body text-xs font-medium text-secondary-light">{label}</label>
      <input
        type={type}
        required={required}
        placeholder={placeholder}
        value={value}
        onChange={onChange}
        className="w-full rounded-xl border border-secondary/15 px-4 py-3 font-body text-sm text-secondary focus:border-primary focus:outline-none"
      />
    </div>
  );
}

export function SelectField({
  label,
  value,
  onChange,
  required,
  options,
  placeholder,
  disabled,
}: {
  label: string;
  value: string;
  onChange: (e: React.ChangeEvent<HTMLSelectElement>) => void;
  required?: boolean;
  options: { label: string; value: string }[];
  placeholder?: string;
  disabled?: boolean;
}) {
  return (
    <div>
      <label className="mb-1.5 block font-body text-xs font-medium text-secondary-light">{label}</label>
      <select
        required={required}
        value={value}
        onChange={onChange}
        disabled={disabled}
        className="w-full rounded-xl border border-secondary/15 px-4 py-3 font-body text-sm text-secondary focus:border-primary focus:outline-none bg-transparent disabled:opacity-60"
      >
        <option value="" disabled>
          {placeholder || "Seçiniz"}
        </option>
        {options.map((opt) => (
          <option key={opt.value} value={opt.value}>
            {opt.label}
          </option>
        ))}
      </select>
    </div>
  );
}
