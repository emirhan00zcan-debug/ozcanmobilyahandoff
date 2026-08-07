"use client";

import { useActionState } from "react";
import { resendOrderVerificationAction } from "@/lib/actions/order-verification-actions";

type Props = { orderNumber: string };

export default function ResendVerificationForm({ orderNumber }: Props) {
  const [state, formAction, isPending] = useActionState(resendOrderVerificationAction, { message: null });

  if (state.message) {
    return <p className="mt-6 font-body text-sm text-secondary-light">{state.message}</p>;
  }

  return (
    <form action={formAction} className="mt-6 w-full max-w-xs space-y-3">
      <input type="hidden" name="orderNumber" value={orderNumber} />
      <input
        type="email"
        name="email"
        required
        placeholder="Sipariş e-postanız"
        className="w-full rounded-xl border border-secondary/15 px-4 py-3 font-body text-sm text-secondary focus:border-primary focus:outline-none"
      />
      <button
        type="submit"
        disabled={isPending}
        className="w-full rounded-full bg-secondary py-3 font-body text-sm font-semibold text-white transition-colors hover:bg-primary disabled:opacity-60"
      >
        {isPending ? "Gönderiliyor..." : "Doğrulama Bağlantısını Yeniden Gönder"}
      </button>
    </form>
  );
}
