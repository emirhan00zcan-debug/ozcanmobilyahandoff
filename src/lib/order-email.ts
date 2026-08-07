import type { OrderStatus } from "@prisma/client";
import { ORDER_STATUS_LABELS } from "@/lib/order-labels";

export type OrderEmailItem = {
  name: string;
  quantity: number;
  unitPrice: number;
  installationRequested: boolean;
  installationPrice: number;
};
export type OrderEmailAddress = {
  fullName: string;
  phone: string;
  city: string;
  district: string;
  addressLine: string;
};

export type OrderEmailData = {
  orderNumber: string;
  status: OrderStatus;
  items: OrderEmailItem[];
  subtotal: number;
  discountAmount: number;
  installationTotal: number;
  totalAmount: number;
  address: OrderEmailAddress;
  customerName: string | null;
  customerEmail: string;
  note?: string;
};

function formatPrice(value: number) {
  return new Intl.NumberFormat("tr-TR", { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(value) + " TL";
}

function formatItemsList(items: OrderEmailItem[]) {
  return items
    .map((i) => {
      const installationNote = i.installationRequested
        ? ` (+ Kurulum/Montaj: ${formatPrice(i.installationPrice)})`
        : "";
      return `- ${i.name} x${i.quantity} — ${formatPrice(i.unitPrice * i.quantity)}${installationNote}`;
    })
    .join("\n");
}

function formatAddress(address: OrderEmailAddress) {
  return `${address.fullName} — ${address.phone}\n${address.addressLine}, ${address.district}/${address.city}`;
}

function formatTotals(data: OrderEmailData) {
  const discountLine = data.discountAmount > 0 ? `İndirim: -${formatPrice(data.discountAmount)}\n` : "";
  const installationLine =
    data.installationTotal > 0 ? `Kurulum/Montaj: ${formatPrice(data.installationTotal)}\n` : "";
  return `Ara Toplam: ${formatPrice(data.subtotal)}\n${discountLine}${installationLine}Toplam: ${formatPrice(data.totalAmount)}`;
}

export function buildCustomerOrderEmail(data: OrderEmailData) {
  return {
    subject: `Siparişiniz Alındı — ${data.orderNumber}`,
    text: `Merhaba ${data.customerName ?? ""},

Siparişiniz alındı, teşekkür ederiz!

Sipariş No: ${data.orderNumber}
Durum: ${ORDER_STATUS_LABELS[data.status]}

Ürünler:
${formatItemsList(data.items)}

${formatTotals(data)}

Teslimat Adresi:
${formatAddress(data.address)}

Sipariş durumunuzu "Hesabım" sayfanızdan takip edebilirsiniz.

Özcan Mobilya`,
  };
}

export function buildAdminOrderAlertEmail(data: OrderEmailData) {
  return {
    subject: `Yeni Sipariş — ${data.orderNumber} (${formatPrice(data.totalAmount)})`,
    text: `Yeni bir sipariş alındı.

Sipariş No: ${data.orderNumber}
Müşteri: ${data.customerName ?? "-"} <${data.customerEmail}>

Ürünler:
${formatItemsList(data.items)}

${formatTotals(data)}

Teslimat Adresi:
${formatAddress(data.address)}
${data.note ? `\nSipariş Notu: ${data.note}` : ""}

Yönetim panelinden sipariş detayına bakabilirsiniz: /admin/siparisler`,
  };
}
