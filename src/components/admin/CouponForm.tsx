"use client";

import { useActionState } from "react";
import {
  createCouponAction,
  updateCouponAction,
  type CouponFormState,
} from "@/lib/actions/admin-coupon-actions";
import type { DiscountType } from "@prisma/client";

type Option = { id: string; name: string };

type CouponFormValues = {
  id: string;
  code: string;
  discountType: DiscountType;
  discountValue: number;
  description: string;
  minOrderAmount: number | null;
  maxDiscountAmount: number | null;
  categoryId: string;
  startsAt: string; // "YYYY-MM-DDTHH:mm" — datetime-local input formatında
  endsAt: string;
  usageLimit: number | null;
  isActive: boolean;
};

type Props = {
  mode: "create" | "edit";
  categories: Option[];
  coupon?: CouponFormValues;
};

const initialState: CouponFormState = { error: null };

export default function CouponForm({ mode, categories, coupon }: Props) {
  const action =
    mode === "edit" && coupon ? updateCouponAction.bind(null, coupon.id) : createCouponAction;
  const [state, formAction, isPending] = useActionState(action, initialState);

  return (
    <form action={formAction} className="mt-6 max-w-2xl space-y-5">
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <div>
          <label className="mb-1.5 block font-body text-xs font-medium text-secondary-light">Kupon Kodu</label>
          <input
            type="text"
            name="code"
            required
            defaultValue={coupon?.code}
            placeholder="Örn: FLAS20"
            className="w-full rounded-xl border border-secondary/15 px-4 py-3 font-body text-sm uppercase text-secondary focus:border-primary focus:outline-none"
          />
        </div>
        <div>
          <label className="mb-1.5 block font-body text-xs font-medium text-secondary-light">İndirim Tipi</label>
          <select
            name="discountType"
            defaultValue={coupon?.discountType ?? "PERCENTAGE"}
            className="w-full rounded-xl border border-secondary/15 bg-white px-4 py-3 font-body text-sm text-secondary focus:border-primary focus:outline-none"
          >
            <option value="PERCENTAGE">Yüzde (%)</option>
            <option value="FIXED_AMOUNT">Sabit Tutar (TL)</option>
          </select>
        </div>
      </div>

      <div>
        <label className="mb-1.5 block font-body text-xs font-medium text-secondary-light">
          Açıklama (opsiyonel)
        </label>
        <input
          type="text"
          name="description"
          defaultValue={coupon?.description}
          placeholder="Örn: Tüm gardırop ve TV ünitelerinde %20 indirim"
          className="w-full rounded-xl border border-secondary/15 px-4 py-3 font-body text-sm text-secondary focus:border-primary focus:outline-none"
        />
      </div>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <div>
          <label className="mb-1.5 block font-body text-xs font-medium text-secondary-light">
            İndirim Değeri
          </label>
          <input
            type="number"
            name="discountValue"
            required
            step="0.01"
            min="0"
            defaultValue={coupon?.discountValue}
            className="w-full rounded-xl border border-secondary/15 px-4 py-3 font-body text-sm text-secondary focus:border-primary focus:outline-none"
          />
        </div>
        <div>
          <label className="mb-1.5 block font-body text-xs font-medium text-secondary-light">
            Sadece Bu Kategoride Geçerli (opsiyonel)
          </label>
          <select
            name="categoryId"
            defaultValue={coupon?.categoryId ?? ""}
            className="w-full rounded-xl border border-secondary/15 bg-white px-4 py-3 font-body text-sm text-secondary focus:border-primary focus:outline-none"
          >
            <option value="">Tüm Kategoriler</option>
            {categories.map((cat) => (
              <option key={cat.id} value={cat.id}>
                {cat.name}
              </option>
            ))}
          </select>
        </div>
      </div>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <div>
          <label className="mb-1.5 block font-body text-xs font-medium text-secondary-light">
            Min. Sepet Tutarı (opsiyonel)
          </label>
          <input
            type="number"
            name="minOrderAmount"
            step="0.01"
            min="0"
            defaultValue={coupon?.minOrderAmount ?? undefined}
            className="w-full rounded-xl border border-secondary/15 px-4 py-3 font-body text-sm text-secondary focus:border-primary focus:outline-none"
          />
        </div>
        <div>
          <label className="mb-1.5 block font-body text-xs font-medium text-secondary-light">
            Üst İndirim Sınırı (opsiyonel, TL)
          </label>
          <input
            type="number"
            name="maxDiscountAmount"
            step="0.01"
            min="0"
            defaultValue={coupon?.maxDiscountAmount ?? undefined}
            className="w-full rounded-xl border border-secondary/15 px-4 py-3 font-body text-sm text-secondary focus:border-primary focus:outline-none"
          />
        </div>
      </div>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <div>
          <label className="mb-1.5 block font-body text-xs font-medium text-secondary-light">
            Başlangıç Tarihi
          </label>
          <input
            type="datetime-local"
            name="startsAt"
            required
            defaultValue={coupon?.startsAt}
            className="w-full rounded-xl border border-secondary/15 px-4 py-3 font-body text-sm text-secondary focus:border-primary focus:outline-none"
          />
        </div>
        <div>
          <label className="mb-1.5 block font-body text-xs font-medium text-secondary-light">
            Bitiş Tarihi
          </label>
          <input
            type="datetime-local"
            name="endsAt"
            required
            defaultValue={coupon?.endsAt}
            className="w-full rounded-xl border border-secondary/15 px-4 py-3 font-body text-sm text-secondary focus:border-primary focus:outline-none"
          />
        </div>
      </div>

      <div>
        <label className="mb-1.5 block font-body text-xs font-medium text-secondary-light">
          Kullanım Limiti (opsiyonel, boş = sınırsız)
        </label>
        <input
          type="number"
          name="usageLimit"
          step="1"
          min="1"
          defaultValue={coupon?.usageLimit ?? undefined}
          className="w-full max-w-[200px] rounded-xl border border-secondary/15 px-4 py-3 font-body text-sm text-secondary focus:border-primary focus:outline-none"
        />
      </div>

      <label className="flex items-center gap-2 font-body text-sm text-secondary">
        <input
          type="checkbox"
          name="isActive"
          defaultChecked={coupon?.isActive ?? true}
          className="accent-primary"
        />
        Aktif
      </label>

      {state.error && <p className="font-body text-xs font-medium text-red-600">{state.error}</p>}

      <button
        type="submit"
        disabled={isPending}
        className="rounded-full bg-secondary px-8 py-3 font-body text-sm font-semibold text-white transition-colors hover:bg-primary disabled:opacity-60"
      >
        {isPending ? "Kaydediliyor..." : mode === "create" ? "Kuponu Oluştur" : "Değişiklikleri Kaydet"}
      </button>
    </form>
  );
}
