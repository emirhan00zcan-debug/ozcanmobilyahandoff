"use client";

import { useActionState, useRef } from "react";
import {
  sendNewsletterCampaignAction,
  type NewsletterCampaignState,
} from "@/lib/actions/admin-newsletter-actions";

const initialState: NewsletterCampaignState = { status: "idle" };

export default function NewsletterCampaignForm({ subscriberCount }: { subscriberCount: number }) {
  const [state, formAction, isPending] = useActionState(sendNewsletterCampaignAction, initialState);
  const formRef = useRef<HTMLFormElement>(null);

  return (
    <form
      ref={formRef}
      action={formAction}
      onSubmit={(e) => {
        if (!confirm(`Bu e-posta ${subscriberCount} aboneye gönderilecek. Onaylıyor musunuz?`)) {
          e.preventDefault();
        }
      }}
      className="mt-6 max-w-2xl space-y-5"
    >
      <div>
        <label className="mb-1.5 block font-body text-xs font-medium text-secondary-light">Konu</label>
        <input
          type="text"
          name="subject"
          required
          placeholder="Örn: Bu Hafta Sonuna Özel %15 İndirim"
          className="w-full rounded-xl border border-secondary/15 px-4 py-3 font-body text-sm text-secondary focus:border-primary focus:outline-none"
        />
      </div>

      <div>
        <label className="mb-1.5 block font-body text-xs font-medium text-secondary-light">Mesaj</label>
        <textarea
          name="message"
          required
          rows={8}
          placeholder="Fırsatın detaylarını yazın..."
          className="w-full rounded-xl border border-secondary/15 px-4 py-3 font-body text-sm text-secondary focus:border-primary focus:outline-none"
        />
      </div>

      {state.status === "error" && (
        <p className="font-body text-xs font-medium text-red-600">{state.error}</p>
      )}
      {state.status === "success" && (
        <div>
          <p className="font-body text-xs font-medium text-primary">
            Gönderildi: {state.sentCount} başarılı
            {state.failedCount > 0 ? `, ${state.failedCount} başarısız` : ""}.
          </p>
          {state.lastError && (
            <p className="mt-1 font-body text-xs font-medium text-red-600">Hata: {state.lastError}</p>
          )}
        </div>
      )}

      <button
        type="submit"
        disabled={isPending || subscriberCount === 0}
        className="rounded-full bg-secondary px-8 py-3 font-body text-sm font-semibold text-white transition-colors hover:bg-primary disabled:opacity-60"
      >
        {isPending ? "Gönderiliyor..." : `${subscriberCount} Aboneye Gönder`}
      </button>
    </form>
  );
}
