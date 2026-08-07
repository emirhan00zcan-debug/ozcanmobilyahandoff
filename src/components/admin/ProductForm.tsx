"use client";

import { useActionState } from "react";
import {
  createProductAction,
  updateProductAction,
  type ProductFormState,
} from "@/lib/actions/admin-product-actions";

type Option = { id: string; name: string };

type ProductFormValues = {
  id: string;
  name: string;
  slug: string;
  shortDescription: string;
  description: string;
  basePrice: number;
  compareAtPrice: number | null;
  stock: number;
  categoryId: string;
  roomId: string;
  isActive: boolean;
  isFeatured: boolean;
  installationAvailable: boolean;
  installationPrice: number | null;
  images: string[];
};

type Props = {
  mode: "create" | "edit";
  categories: Option[];
  rooms: Option[];
  product?: ProductFormValues;
};

const initialState: ProductFormState = { error: null };

export default function ProductForm({ mode, categories, rooms, product }: Props) {
  const action =
    mode === "edit" && product
      ? updateProductAction.bind(null, product.id)
      : createProductAction;
  const [state, formAction, isPending] = useActionState(action, initialState);

  return (
    <form action={formAction} className="mt-6 max-w-2xl space-y-5">
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <Field label="Ürün Adı" name="name" defaultValue={product?.name} required />
        <Field
          label="URL (slug)"
          name="slug"
          defaultValue={product?.slug}
          placeholder="boş bırakılırsa isimden oluşturulur"
        />
      </div>

      <Field
        label="Kısa Açıklama (opsiyonel)"
        name="shortDescription"
        defaultValue={product?.shortDescription}
      />

      <div>
        <label className="mb-1.5 block font-body text-xs font-medium text-secondary-light">
          Açıklama
        </label>
        <textarea
          name="description"
          required
          rows={4}
          defaultValue={product?.description}
          className="w-full rounded-xl border border-secondary/15 px-4 py-3 font-body text-sm text-secondary focus:border-primary focus:outline-none"
        />
      </div>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <Field
          label="Satış Fiyatı (TL)"
          name="basePrice"
          type="number"
          step="0.01"
          min="0"
          defaultValue={product?.basePrice}
          required
        />
        <Field
          label="Eski Fiyat (opsiyonel)"
          name="compareAtPrice"
          type="number"
          step="0.01"
          min="0"
          defaultValue={product?.compareAtPrice ?? undefined}
        />
        <Field
          label="Stok Adedi"
          name="stock"
          type="number"
          step="1"
          min="0"
          defaultValue={product?.stock ?? 0}
          required
        />
      </div>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <div>
          <label className="mb-1.5 block font-body text-xs font-medium text-secondary-light">
            Kategori
          </label>
          <select
            name="categoryId"
            required
            defaultValue={product?.categoryId ?? ""}
            className="w-full rounded-xl border border-secondary/15 bg-white px-4 py-3 font-body text-sm text-secondary focus:border-primary focus:outline-none"
          >
            <option value="" disabled>
              Kategori seçin
            </option>
            {categories.map((cat) => (
              <option key={cat.id} value={cat.id}>
                {cat.name}
              </option>
            ))}
          </select>
        </div>
        <div>
          <label className="mb-1.5 block font-body text-xs font-medium text-secondary-light">
            Oda (opsiyonel)
          </label>
          <select
            name="roomId"
            defaultValue={product?.roomId ?? ""}
            className="w-full rounded-xl border border-secondary/15 bg-white px-4 py-3 font-body text-sm text-secondary focus:border-primary focus:outline-none"
          >
            <option value="">— Seçilmedi —</option>
            {rooms.map((room) => (
              <option key={room.id} value={room.id}>
                {room.name}
              </option>
            ))}
          </select>
        </div>
      </div>

      <div>
        <label className="mb-1.5 block font-body text-xs font-medium text-secondary-light">
          Görsel URL&apos;leri (her satıra bir tane, ilk satır kapak görseli olur)
        </label>
        <textarea
          name="images"
          rows={4}
          defaultValue={product?.images.join("\n")}
          placeholder={"/media/urun-foto-1.jpg\n/media/urun-foto-2.jpg"}
          className="w-full rounded-xl border border-secondary/15 px-4 py-3 font-body text-sm text-secondary focus:border-primary focus:outline-none"
        />
      </div>

      <div className="flex gap-6">
        <label className="flex items-center gap-2 font-body text-sm text-secondary">
          <input
            type="checkbox"
            name="isActive"
            defaultChecked={product?.isActive ?? true}
            className="accent-primary"
          />
          Sitede yayında
        </label>
        <label className="flex items-center gap-2 font-body text-sm text-secondary">
          <input
            type="checkbox"
            name="isFeatured"
            defaultChecked={product?.isFeatured ?? false}
            className="accent-primary"
          />
          Öne çıkan modellerde göster
        </label>
        <label className="flex items-center gap-2 font-body text-sm text-secondary">
          <input
            type="checkbox"
            name="installationAvailable"
            defaultChecked={product?.installationAvailable ?? false}
            className="accent-primary"
          />
          Kurulum/Montaj Hizmeti Sunulur
        </label>
      </div>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <Field
          label="Kurulum/Montaj Ücreti (TL, opsiyonel)"
          name="installationPrice"
          type="number"
          step="0.01"
          min="0"
          defaultValue={product?.installationPrice ?? undefined}
        />
      </div>

      {state.error && <p className="font-body text-xs font-medium text-red-600">{state.error}</p>}

      <button
        type="submit"
        disabled={isPending}
        className="rounded-full bg-secondary px-8 py-3 font-body text-sm font-semibold text-white transition-colors hover:bg-primary disabled:opacity-60"
      >
        {isPending ? "Kaydediliyor..." : mode === "create" ? "Ürünü Oluştur" : "Değişiklikleri Kaydet"}
      </button>
    </form>
  );
}

function Field({
  label,
  name,
  defaultValue,
  type = "text",
  required,
  placeholder,
  step,
  min,
}: {
  label: string;
  name: string;
  defaultValue?: string | number;
  type?: string;
  required?: boolean;
  placeholder?: string;
  step?: string;
  min?: string;
}) {
  return (
    <div>
      <label className="mb-1.5 block font-body text-xs font-medium text-secondary-light">{label}</label>
      <input
        type={type}
        name={name}
        required={required}
        placeholder={placeholder}
        step={step}
        min={min}
        defaultValue={defaultValue}
        className="w-full rounded-xl border border-secondary/15 px-4 py-3 font-body text-sm text-secondary focus:border-primary focus:outline-none"
      />
    </div>
  );
}
