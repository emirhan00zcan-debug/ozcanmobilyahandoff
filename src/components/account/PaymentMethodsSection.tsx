"use client";

import { useEffect, useState, useActionState } from "react";
import { FaCreditCard } from "react-icons/fa";
import {
  createPaymentMethodAction,
  deletePaymentMethodAction,
  setDefaultPaymentMethodAction,
  type PaymentMethodActionState,
} from "@/lib/actions/payment-method-actions";

export type AccountPaymentMethod = {
  id: string;
  type: "CASH_ON_DELIVERY" | "BANK_TRANSFER" | "CARD";
  label: string | null;
  isDefault: boolean;
  cardLast4: string | null;
  cardBrand: string | null;
};

const TYPE_LABELS: Record<AccountPaymentMethod["type"], string> = {
  CASH_ON_DELIVERY: "Kapıda Ödeme",
  BANK_TRANSFER: "Havale / EFT",
  CARD: "Kredi Kartı",
};

const EMPTY_STATE: PaymentMethodActionState = { success: false, error: null };

function AddPaymentMethodForm({ onDone }: { onDone: () => void }) {
  const [state, formAction, isPending] = useActionState(createPaymentMethodAction, EMPTY_STATE);

  useEffect(() => {
    if (state.success) onDone();
  }, [state.success, onDone]);

  return (
    <form
      action={formAction}
      className="grid grid-cols-1 gap-3 rounded-xl border border-secondary/10 bg-secondary/[0.02] p-4 sm:grid-cols-2"
    >
      <div>
        <label className="mb-1.5 block font-body text-xs font-medium text-secondary-light">Yöntem</label>
        <select
          name="type"
          defaultValue="BANK_TRANSFER"
          className="w-full rounded-xl border border-secondary/15 px-4 py-2.5 font-body text-sm text-secondary focus:border-primary focus:outline-none"
        >
          <option value="BANK_TRANSFER">Havale / EFT</option>
        </select>
      </div>
      <div>
        <label className="mb-1.5 block font-body text-xs font-medium text-secondary-light">Not (opsiyonel)</label>
        <input
          name="label"
          placeholder="örn. İş siparişleri için"
          className="w-full rounded-xl border border-secondary/15 px-4 py-2.5 font-body text-sm text-secondary focus:border-primary focus:outline-none"
        />
      </div>

      {state.error && (
        <p className="font-body text-xs font-medium text-red-600 sm:col-span-2">{state.error}</p>
      )}

      <div className="flex gap-2 sm:col-span-2">
        <button
          type="submit"
          disabled={isPending}
          className="btn-sweep rounded-full border border-primary/30 px-5 py-2.5 font-body text-xs font-semibold text-secondary disabled:opacity-60"
        >
          {isPending ? "Kaydediliyor..." : "Kaydet"}
        </button>
        <button
          type="button"
          onClick={onDone}
          className="btn-sweep rounded-full border border-primary/30 px-5 py-2.5 font-body text-xs font-semibold text-secondary"
        >
          Vazgeç
        </button>
      </div>
    </form>
  );
}

export default function PaymentMethodsSection({ methods }: { methods: AccountPaymentMethod[] }) {
  const [addingNew, setAddingNew] = useState(false);

  return (
    <div className="rounded-2xl border border-secondary/10 bg-white p-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h2 className="font-display text-lg font-semibold text-secondary">Ödeme Yöntemlerim</h2>
        {!addingNew && (
          <button
            onClick={() => setAddingNew(true)}
            className="btn-sweep rounded-full border border-primary/30 px-5 py-2 font-body text-xs font-semibold text-secondary"
          >
            + Yöntem Ekle
          </button>
        )}
      </div>

      {addingNew && (
        <div className="mt-4">
          <AddPaymentMethodForm onDone={() => setAddingNew(false)} />
        </div>
      )}

      <div className="mt-4 space-y-3">
        {methods.length === 0 && !addingNew && (
          <div className="flex flex-col items-center gap-3 rounded-xl border border-dashed border-secondary/15 py-10 text-center">
            <span className="flex h-12 w-12 items-center justify-center rounded-full bg-secondary/[0.04] text-secondary-light">
              <FaCreditCard className="h-5 w-5" />
            </span>
            <p className="font-body text-sm text-secondary-light">Henüz kayıtlı bir ödeme yönteminiz yok.</p>
          </div>
        )}
        {methods.map((m) => (
          <div
            key={m.id}
            className="flex flex-wrap items-center justify-between gap-3 rounded-xl border border-secondary/10 p-4"
          >
            <div>
              <p className="flex items-center gap-2 font-body text-sm font-semibold text-secondary">
                {TYPE_LABELS[m.type]}
                {m.isDefault && (
                  <span className="rounded-full bg-primary/10 px-2 py-0.5 text-[11px] font-medium text-primary">
                    Varsayılan
                  </span>
                )}
              </p>
              {m.label && <p className="mt-0.5 font-body text-xs text-secondary-light">{m.label}</p>}
              {m.cardLast4 && (
                <p className="mt-0.5 font-body text-xs text-secondary-light">
                  {m.cardBrand ?? "Kart"} •••• {m.cardLast4}
                </p>
              )}
            </div>
            <div className="flex gap-3">
              {!m.isDefault && (
                <form action={setDefaultPaymentMethodAction}>
                  <input type="hidden" name="paymentMethodId" value={m.id} />
                  <button
                    type="submit"
                    className="font-body text-xs font-medium text-secondary-light transition-colors hover:text-primary"
                  >
                    Varsayılan Yap
                  </button>
                </form>
              )}
              <form action={deletePaymentMethodAction}>
                <input type="hidden" name="paymentMethodId" value={m.id} />
                <button
                  type="submit"
                  className="font-body text-xs font-medium text-secondary-light transition-colors hover:text-red-600"
                >
                  Sil
                </button>
              </form>
            </div>
          </div>
        ))}

        {/* PayTR entegrasyonu tamamlanınca aktif olacak — sahte bir "kart ekle" butonu yerine
            dürüstçe "yakında" gösteriliyor (bkz. prisma/schema.prisma PaymentMethod notu). */}
        <div className="flex items-center justify-between gap-3 rounded-xl border border-dashed border-secondary/20 p-4 opacity-60">
          <div>
            <p className="font-body text-sm font-semibold text-secondary">Kredi Kartı</p>
            <p className="mt-0.5 font-body text-xs text-secondary-light">
              PayTR entegrasyonu tamamlandığında kart ekleyebileceksiniz.
            </p>
          </div>
          <span className="shrink-0 rounded-full bg-secondary/10 px-3 py-1 font-body text-[11px] font-medium text-secondary-light">
            Yakında
          </span>
        </div>
      </div>
    </div>
  );
}
