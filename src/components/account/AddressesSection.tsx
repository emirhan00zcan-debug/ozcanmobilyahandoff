"use client";

import { useEffect, useState, useActionState } from "react";
import { FaMapMarkerAlt } from "react-icons/fa";
import {
  createAddressAction,
  updateAddressAction,
  deleteAddressAction,
  setDefaultAddressAction,
  type AddressActionState,
} from "@/lib/actions/address-actions";

export type AccountAddress = {
  id: string;
  title: string;
  fullName: string;
  phone: string;
  city: string;
  district: string;
  addressLine: string;
  postalCode: string | null;
  isDefault: boolean;
  isUsedInOrder: boolean;
};

const EMPTY_STATE: AddressActionState = { success: false, error: null };

function Field({
  label,
  name,
  defaultValue,
  required,
  type = "text",
}: {
  label: string;
  name: string;
  defaultValue?: string;
  required?: boolean;
  type?: string;
}) {
  return (
    <div>
      <label className="mb-1.5 block font-body text-xs font-medium text-secondary-light">{label}</label>
      <input
        name={name}
        type={type}
        required={required}
        defaultValue={defaultValue}
        className="w-full rounded-xl border border-secondary/15 px-4 py-2.5 font-body text-sm text-secondary focus:border-primary focus:outline-none"
      />
    </div>
  );
}

function AddressForm({ address, onDone }: { address?: AccountAddress; onDone: () => void }) {
  const action = address ? updateAddressAction : createAddressAction;
  const [state, formAction, isPending] = useActionState(action, EMPTY_STATE);

  useEffect(() => {
    if (state.success) onDone();
  }, [state.success, onDone]);

  return (
    <form
      action={formAction}
      className="grid grid-cols-1 gap-3 rounded-xl border border-secondary/10 bg-secondary/[0.02] p-4 sm:grid-cols-2"
    >
      {address && <input type="hidden" name="addressId" value={address.id} />}
      <Field label="Adres Başlığı" name="title" defaultValue={address?.title ?? "Ev"} />
      <Field label="Ad Soyad" name="fullName" defaultValue={address?.fullName} required />
      <Field label="Telefon" name="phone" type="tel" defaultValue={address?.phone} required />
      <Field label="Posta Kodu" name="postalCode" defaultValue={address?.postalCode ?? ""} />
      <Field label="Şehir" name="city" defaultValue={address?.city} required />
      <Field label="İlçe" name="district" defaultValue={address?.district} required />
      <div className="sm:col-span-2">
        <label className="mb-1.5 block font-body text-xs font-medium text-secondary-light">Açık Adres</label>
        <textarea
          name="addressLine"
          required
          rows={2}
          defaultValue={address?.addressLine}
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
          className="rounded-full bg-secondary px-5 py-2.5 font-body text-xs font-semibold text-white transition-colors hover:bg-primary disabled:opacity-60"
        >
          {isPending ? "Kaydediliyor..." : address ? "Güncelle" : "Adresi Kaydet"}
        </button>
        <button
          type="button"
          onClick={onDone}
          className="rounded-full border border-secondary/20 px-5 py-2.5 font-body text-xs font-semibold text-secondary transition-colors hover:border-primary hover:text-primary"
        >
          Vazgeç
        </button>
      </div>
    </form>
  );
}

export default function AddressesSection({ addresses }: { addresses: AccountAddress[] }) {
  const [addingNew, setAddingNew] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);

  return (
    <div className="rounded-2xl border border-secondary/10 bg-white p-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h2 className="font-display text-lg font-semibold text-secondary">Adreslerim</h2>
        {!addingNew && (
          <button
            onClick={() => setAddingNew(true)}
            className="rounded-full bg-secondary px-5 py-2 font-body text-xs font-semibold text-white transition-colors hover:bg-primary"
          >
            + Yeni Adres Ekle
          </button>
        )}
      </div>

      {addingNew && (
        <div className="mt-4">
          <AddressForm onDone={() => setAddingNew(false)} />
        </div>
      )}

      <div className="mt-4 space-y-3">
        {addresses.length === 0 && !addingNew && (
          <div className="flex flex-col items-center gap-3 rounded-xl border border-dashed border-secondary/15 py-10 text-center">
            <span className="flex h-12 w-12 items-center justify-center rounded-full bg-secondary/[0.04] text-secondary-light">
              <FaMapMarkerAlt className="h-5 w-5" />
            </span>
            <p className="font-body text-sm text-secondary-light">Henüz kayıtlı adresiniz yok.</p>
          </div>
        )}
        {addresses.map((address) =>
          editingId === address.id ? (
            <AddressForm key={address.id} address={address} onDone={() => setEditingId(null)} />
          ) : (
            <div key={address.id} className="rounded-xl border border-secondary/10 p-4">
              <div className="flex flex-wrap items-start justify-between gap-3">
                <div>
                  <p className="flex items-center gap-2 font-body text-sm font-semibold text-secondary">
                    {address.title}
                    {address.isDefault && (
                      <span className="rounded-full bg-primary/10 px-2 py-0.5 text-[11px] font-medium text-primary">
                        Varsayılan
                      </span>
                    )}
                  </p>
                  <p className="mt-1 font-body text-xs text-secondary-light">
                    {address.fullName} — {address.phone}
                  </p>
                  <p className="mt-0.5 font-body text-xs text-secondary-light">
                    {address.addressLine}, {address.district}/{address.city}
                    {address.postalCode ? ` (${address.postalCode})` : ""}
                  </p>
                </div>
                <div className="flex shrink-0 flex-wrap gap-3">
                  {!address.isDefault && (
                    <form action={setDefaultAddressAction}>
                      <input type="hidden" name="addressId" value={address.id} />
                      <button
                        type="submit"
                        className="font-body text-xs font-medium text-secondary-light transition-colors hover:text-primary"
                      >
                        Varsayılan Yap
                      </button>
                    </form>
                  )}
                  <button
                    onClick={() => setEditingId(address.id)}
                    className="font-body text-xs font-medium text-primary hover:underline"
                  >
                    Düzenle
                  </button>
                  {!address.isUsedInOrder && (
                    <form action={deleteAddressAction}>
                      <input type="hidden" name="addressId" value={address.id} />
                      <button
                        type="submit"
                        className="font-body text-xs font-medium text-secondary-light transition-colors hover:text-red-600"
                      >
                        Sil
                      </button>
                    </form>
                  )}
                </div>
              </div>
            </div>
          ),
        )}
      </div>
    </div>
  );
}
