import type { OrderStatus, PaymentStatus, PaymentMethodType } from "@prisma/client";

export const ORDER_STATUS_LABELS: Record<OrderStatus, string> = {
  PENDING: "Ödeme Bekleniyor",
  PROCESSING: "Hazırlanıyor",
  SHIPPED: "Kargoya Verildi",
  DELIVERED: "Teslim Edildi",
  CANCELLED: "İptal Edildi",
  REFUNDED: "İade Edildi",
};

export const PAYMENT_STATUS_LABELS: Record<PaymentStatus, string> = {
  PENDING: "Bekleniyor",
  PAID: "Ödendi",
  FAILED: "Başarısız",
  REFUNDED: "İade Edildi",
};

export const PAYMENT_METHOD_LABELS: Record<PaymentMethodType, string> = {
  CASH_ON_DELIVERY: "Kapıda Ödeme",
  BANK_TRANSFER: "Havale / EFT",
  CARD: "Kredi Kartı (PayTR)",
};
