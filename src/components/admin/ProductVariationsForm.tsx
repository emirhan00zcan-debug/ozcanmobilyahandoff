"use client";

import { useActionState } from "react";
import {
  updateProductVariationsAction,
  type VariationsFormState,
} from "@/lib/actions/admin-product-actions";

type VariationRow = {
  id: string;
  sku: string;
  price: number;
  stock: number;
  label: string;
};

type Props = {
  productId: string;
  variations: VariationRow[];
};

const initialState: VariationsFormState = { error: null };

export default function ProductVariationsForm({ productId, variations }: Props) {
  const action = updateProductVariationsAction.bind(null, productId);
  const [state, formAction, isPending] = useActionState(action, initialState);

  return (
    <div className="mt-10 max-w-2xl">
      <h2 className="font-display text-lg font-bold text-secondary">Varyasyonlar</h2>
      <p className="mt-1 font-body text-xs text-secondary-light">
        Ürün sayfasında müşteriye gösterilen fiyat ve stok, seçilen varyasyona göre buradan belirlenir
        — yukarıdaki &quot;Satış Fiyatı&quot;/&quot;Stok Adedi&quot; alanları bu ürün için kullanılmaz.
      </p>

      <form action={formAction} className="mt-4 overflow-x-auto rounded-2xl border border-secondary/10 bg-white">
        <table className="w-full min-w-[520px] font-body text-sm">
          <thead>
            <tr className="border-b border-secondary/10 text-left text-xs font-medium uppercase tracking-wide text-secondary-light">
              <th className="px-5 py-3">Varyasyon</th>
              <th className="px-5 py-3">Fiyat (TL)</th>
              <th className="px-5 py-3">Stok Adedi</th>
            </tr>
          </thead>
          <tbody>
            {variations.map((v) => (
              <tr key={v.id} className="border-b border-secondary/5 last:border-0">
                <td className="px-5 py-3 text-secondary">{v.label || v.sku}</td>
                <td className="px-5 py-3">
                  <input
                    type="number"
                    name={`price_${v.id}`}
                    step="0.01"
                    min="0"
                    defaultValue={v.price}
                    className="w-32 rounded-lg border border-secondary/15 px-3 py-1.5 font-body text-sm text-secondary focus:border-primary focus:outline-none"
                  />
                </td>
                <td className="px-5 py-3">
                  <input
                    type="number"
                    name={`stock_${v.id}`}
                    step="1"
                    min="0"
                    defaultValue={v.stock}
                    className="w-24 rounded-lg border border-secondary/15 px-3 py-1.5 font-body text-sm text-secondary focus:border-primary focus:outline-none"
                  />
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        <div className="flex items-center gap-3 border-t border-secondary/10 px-5 py-4">
          <button
            type="submit"
            disabled={isPending}
            className="rounded-full bg-secondary px-6 py-2.5 font-body text-sm font-semibold text-white transition-colors hover:bg-primary disabled:opacity-60"
          >
            {isPending ? "Kaydediliyor..." : "Varyasyonları Kaydet"}
          </button>
          {state.error && <p className="font-body text-xs font-medium text-red-600">{state.error}</p>}
        </div>
      </form>
    </div>
  );
}
