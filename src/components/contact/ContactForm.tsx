"use client";

import { useActionState } from "react";
import Link from "next/link";
import { FaCheckCircle } from "react-icons/fa";
import { sendContactMessageAction } from "@/lib/actions/contact-actions";

function Field({
  id,
  label,
  type = "text",
  required,
}: {
  id: string;
  label: string;
  type?: string;
  required?: boolean;
}) {
  return (
    <div className="relative">
      <input
        id={id}
        name={id}
        type={type}
        required={required}
        placeholder=" "
        className="peer w-full rounded-xl border border-secondary/15 bg-white px-4 pb-2.5 pt-5 font-body text-sm text-secondary placeholder-transparent transition-colors focus:border-primary focus:outline-none"
      />
      <label
        htmlFor={id}
        className="pointer-events-none absolute left-4 top-1/2 -translate-y-1/2 font-body text-sm text-secondary-light transition-all peer-focus:top-3.5 peer-focus:text-[11px] peer-focus:text-primary peer-[:not(:placeholder-shown)]:top-3.5 peer-[:not(:placeholder-shown)]:text-[11px]"
      >
        {label}
      </label>
    </div>
  );
}

export default function ContactForm() {
  const [state, formAction, isPending] = useActionState(sendContactMessageAction, {
    success: false,
    error: null,
  });

  if (state.success) {
    return (
      <div className="flex flex-col items-center justify-center rounded-2xl border border-secondary/10 p-10 text-center">
        <FaCheckCircle className="h-10 w-10 text-primary" />
        <p className="mt-4 font-display text-lg font-semibold text-secondary">Mesajınız Alındı</p>
        <p className="mt-1.5 font-body text-sm text-secondary-light">
          En kısa sürede size dönüş yapacağız. İlginiz için teşekkür ederiz.
        </p>
      </div>
    );
  }

  return (
    <form action={formAction} className="space-y-4">
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <Field id="name" label="Ad Soyad" required />
        <Field id="email" label="E-posta" type="email" required />
      </div>
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <Field id="phone" label="Telefon (opsiyonel)" type="tel" />
        <Field id="subject" label="Konu" />
      </div>

      <div className="relative">
        <textarea
          id="message"
          name="message"
          required
          rows={5}
          placeholder=" "
          className="peer w-full rounded-xl border border-secondary/15 bg-white px-4 pb-2.5 pt-5 font-body text-sm text-secondary placeholder-transparent transition-colors focus:border-primary focus:outline-none"
        />
        <label
          htmlFor="message"
          className="pointer-events-none absolute left-4 top-5 font-body text-sm text-secondary-light transition-all peer-focus:top-2.5 peer-focus:text-[11px] peer-focus:text-primary peer-[:not(:placeholder-shown)]:top-2.5 peer-[:not(:placeholder-shown)]:text-[11px]"
        >
          Mesajınız
        </label>
      </div>

      {state.error && <p className="font-body text-xs font-medium text-red-600">{state.error}</p>}

      <button
        type="submit"
        disabled={isPending}
        className="w-full rounded-full bg-secondary py-3.5 font-body text-sm font-semibold text-white transition-all duration-200 hover:scale-[1.02] hover:bg-primary active:scale-95 disabled:opacity-60 disabled:hover:scale-100 sm:w-auto sm:px-10"
      >
        {isPending ? "Gönderiliyor..." : "Mesaj Gönder"}
      </button>

      <p className="font-body text-xs text-secondary-light">
        Mesaj göndererek, talebinizin yanıtlanması amacıyla kişisel verilerinizin{" "}
        <Link href="/gizlilik-politikasi" className="underline underline-offset-2 hover:text-primary">
          Gizlilik Politikası ve KVKK Aydınlatma Metni
        </Link>{" "}
        kapsamında işlenmesini kabul etmiş olursunuz.
      </p>
    </form>
  );
}
