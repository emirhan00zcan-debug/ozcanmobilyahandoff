"use client";

import { useState, useActionState } from "react";
import { FaStar } from "react-icons/fa";
import { submitReviewAction, type ReviewActionState } from "@/lib/actions/review-actions";

const EMPTY_STATE: ReviewActionState = { success: false, error: null };

function StarPicker({ rating, onChange }: { rating: number; onChange: (n: number) => void }) {
  return (
    <div className="flex gap-1">
      {[1, 2, 3, 4, 5].map((n) => (
        <button
          key={n}
          type="button"
          onClick={() => onChange(n)}
          aria-label={`${n} yıldız`}
          className="text-[#F5B800]"
        >
          <FaStar className={n <= rating ? "h-5 w-5" : "h-5 w-5 opacity-25"} />
        </button>
      ))}
    </div>
  );
}

export type ExistingReview = { rating: number; comment: string };

export default function OrderItemReview({
  productId,
  canReview,
  existingReview,
}: {
  productId: string;
  canReview: boolean;
  existingReview: ExistingReview | null;
}) {
  const [open, setOpen] = useState(false);
  const [rating, setRating] = useState(5);
  const [state, formAction, isPending] = useActionState(submitReviewAction, EMPTY_STATE);

  if (existingReview) {
    return (
      <div className="mt-2 rounded-lg bg-secondary/[0.03] p-3">
        <div className="flex items-center gap-1 text-[#F5B800]">
          {Array.from({ length: existingReview.rating }).map((_, i) => (
            <FaStar key={i} className="h-3.5 w-3.5" />
          ))}
        </div>
        <p className="mt-1 font-body text-xs text-secondary-light">{existingReview.comment}</p>
      </div>
    );
  }

  if (!canReview) return null;

  if (state.success) {
    return (
      <p className="mt-2 font-body text-xs font-medium text-emerald-600">
        Değerlendirmeniz için teşekkürler!
      </p>
    );
  }

  if (!open) {
    return (
      <button
        onClick={() => setOpen(true)}
        className="mt-2 font-body text-xs font-medium text-primary hover:underline"
      >
        Ürünü Değerlendir
      </button>
    );
  }

  return (
    <form
      action={formAction}
      className="mt-3 space-y-2.5 rounded-xl border border-secondary/10 bg-secondary/[0.02] p-3"
    >
      <input type="hidden" name="productId" value={productId} />
      <input type="hidden" name="rating" value={rating} />
      <StarPicker rating={rating} onChange={setRating} />
      <textarea
        name="comment"
        required
        rows={3}
        placeholder="Ürün hakkındaki deneyiminizi paylaşın..."
        className="w-full rounded-lg border border-secondary/15 px-3 py-2 font-body text-xs text-secondary focus:border-primary focus:outline-none"
      />
      {state.error && <p className="font-body text-xs font-medium text-red-600">{state.error}</p>}
      <div className="flex gap-2">
        <button
          type="submit"
          disabled={isPending}
          className="btn-sweep rounded-full border border-primary/30 px-4 py-1.5 font-body text-xs font-semibold text-secondary disabled:opacity-60"
        >
          {isPending ? "Gönderiliyor..." : "Yorumu Gönder"}
        </button>
        <button
          type="button"
          onClick={() => setOpen(false)}
          className="btn-sweep rounded-full border border-primary/30 px-4 py-1.5 font-body text-xs font-semibold text-secondary"
        >
          Vazgeç
        </button>
      </div>
    </form>
  );
}
