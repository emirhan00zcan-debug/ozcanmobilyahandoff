"use client";

import { useActionState } from "react";
import { updateProfileAction } from "@/lib/actions/account-actions";

type Props = { name: string; email: string; phone: string };

export default function ProfileSection({ name, email, phone }: Props) {
  const [state, formAction, isPending] = useActionState(updateProfileAction, {
    success: false,
    error: null,
  });

  return (
    <div className="rounded-2xl border border-secondary/10 bg-white p-6">
      <h2 className="font-display text-lg font-semibold text-secondary">Profil Bilgilerim</h2>
      <form action={formAction} className="mt-4 grid grid-cols-1 gap-4 sm:grid-cols-2">
        <div>
          <label className="mb-1.5 block font-body text-xs font-medium text-secondary-light">Ad Soyad</label>
          <input
            name="name"
            defaultValue={name}
            required
            className="w-full rounded-xl border border-secondary/15 px-4 py-3 font-body text-sm text-secondary focus:border-primary focus:outline-none"
          />
        </div>
        <div>
          <label className="mb-1.5 block font-body text-xs font-medium text-secondary-light">E-posta</label>
          <input
            value={email}
            disabled
            className="w-full cursor-not-allowed rounded-xl border border-secondary/15 bg-secondary/[0.03] px-4 py-3 font-body text-sm text-secondary-light"
          />
        </div>
        <div>
          <label className="mb-1.5 block font-body text-xs font-medium text-secondary-light">Telefon</label>
          <input
            name="phone"
            type="tel"
            defaultValue={phone}
            placeholder="05XX XXX XX XX"
            className="w-full rounded-xl border border-secondary/15 px-4 py-3 font-body text-sm text-secondary focus:border-primary focus:outline-none"
          />
        </div>

        <div className="flex items-center gap-3 sm:col-span-2">
          <button
            type="submit"
            disabled={isPending}
            className="btn-sweep rounded-full border border-primary/30 px-6 py-3 font-body text-sm font-semibold text-secondary disabled:opacity-60"
          >
            {isPending ? "Kaydediliyor..." : "Bilgileri Kaydet"}
          </button>
          {state.success && (
            <span className="font-body text-xs font-medium text-primary">Kaydedildi ✓</span>
          )}
          {state.error && <span className="font-body text-xs font-medium text-red-600">{state.error}</span>}
        </div>
      </form>
    </div>
  );
}
