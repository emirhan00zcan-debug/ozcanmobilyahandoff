"use client";

import { useActionState, useEffect, useState, startTransition } from "react";
import { FaTimes, FaCheckCircle } from "react-icons/fa";
import { sendContactMessageAction } from "@/lib/actions/contact-actions";
import citiesData from "@/lib/data/cities.json";

type Props = {
    isOpen: boolean;
    onClose: () => void;
    productName: string;
};

export default function SampleRequestModal({ isOpen, onClose, productName }: Props) {
    const [state, formAction, isPending] = useActionState(sendContactMessageAction, {
        success: false,
        error: null,
    });
    const [city, setCity] = useState("");
    const [district, setDistrict] = useState("");

    const handleAction = (formData: FormData) => {
        const addressDetails = formData.get("addressDetails")?.toString() || "";
        const fullMessage = `${productName} ürünü için ahşap/kumaş numunesi rica ediyorum.\n\nİl: ${city}\nİlçe: ${district}\nAçık Adres:\n${addressDetails}`;
        formData.set("message", fullMessage);

        startTransition(() => {
            formAction(formData);
        });
    };

    // Modal açıkken arkada sayfanın kaymasını engelle
    useEffect(() => {
        if (isOpen) {
            document.body.style.overflow = "hidden";
        } else {
            document.body.style.overflow = "unset";
        }
        return () => {
            document.body.style.overflow = "unset";
        };
    }, [isOpen]);

    if (!isOpen) return null;

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4 sm:p-6">
            <div
                className="relative w-full max-w-lg overflow-hidden rounded-2xl bg-white shadow-2xl animate-fade-in"
            >
                {/* Başlık ve Kapatma */}
                <div className="flex items-center justify-between border-b border-secondary/10 px-6 py-4">
                    <h3 className="font-display text-lg font-semibold text-secondary">
                        Ücretsiz Numune İste
                    </h3>
                    <button
                        onClick={onClose}
                        className="rounded-full p-2 text-secondary-light transition-colors hover:bg-secondary/5 hover:text-secondary"
                    >
                        <FaTimes className="h-4 w-4" />
                    </button>
                </div>

                {/* İçerik */}
                <div className="px-6 py-6 max-h-[85vh] overflow-y-auto scrollbar-hide">
                    {state.success ? (
                        <div className="flex flex-col items-center justify-center p-6 text-center">
                            <FaCheckCircle className="h-10 w-10 text-primary" />
                            <p className="mt-4 font-display text-lg font-semibold text-secondary">Talebiniz Alındı</p>
                            <p className="mt-1.5 font-body text-sm text-secondary-light">
                                {productName} ürünü için numune talebinizi aldık. Müşteri temsilcimiz numune gönderim süreci için sizinle iletişime geçecektir.
                            </p>
                            <button
                                onClick={onClose}
                                className="btn-sweep mt-6 rounded-full border border-primary/30 px-8 py-2.5 font-body text-sm font-semibold text-secondary hover:scale-[1.02] active:scale-95"
                            >
                                Kapat
                            </button>
                        </div>
                    ) : (
                        <form action={handleAction} className="space-y-4">
                            {/* Gizli alanlar üzerinden bağlamı (product vb) iletiyoruz, böylece action bunu ContactMessage tablosuna subject/message olarak işleyebilir */}
                            <input type="hidden" name="subject" value={`Numune Talebi: ${productName}`} />

                            <div className="space-y-4">
                                <p className="font-body text-sm text-secondary-light mb-2">
                                    <span className="font-semibold text-secondary">{productName}</span> modeli için doğru karar verebilmeniz adına malzeme ve renk numunelerimizi adresinize ücretsiz gönderiyoruz.
                                </p>

                                <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                                    <div className="relative">
                                        <input
                                            id="sample-name"
                                            name="name"
                                            type="text"
                                            required
                                            placeholder=" "
                                            className="peer w-full rounded-xl border border-secondary/15 bg-secondary/[0.02] px-4 pb-2.5 pt-5 font-body text-sm text-secondary placeholder-transparent transition-colors focus:border-primary focus:outline-none"
                                        />
                                        <label
                                            htmlFor="sample-name"
                                            className="pointer-events-none absolute left-4 top-1/2 -translate-y-1/2 font-body text-sm text-secondary-light transition-all peer-focus:top-3.5 peer-focus:text-[11px] peer-focus:text-primary peer-[:not(:placeholder-shown)]:top-3.5 peer-[:not(:placeholder-shown)]:text-[11px]"
                                        >
                                            Ad Soyad
                                        </label>
                                    </div>

                                    <div className="relative">
                                        <input
                                            id="sample-phone"
                                            name="phone"
                                            type="tel"
                                            required
                                            placeholder=" "
                                            className="peer w-full rounded-xl border border-secondary/15 bg-secondary/[0.02] px-4 pb-2.5 pt-5 font-body text-sm text-secondary placeholder-transparent transition-colors focus:border-primary focus:outline-none"
                                        />
                                        <label
                                            htmlFor="sample-phone"
                                            className="pointer-events-none absolute left-4 top-1/2 -translate-y-1/2 font-body text-sm text-secondary-light transition-all peer-focus:top-3.5 peer-focus:text-[11px] peer-focus:text-primary peer-[:not(:placeholder-shown)]:top-3.5 peer-[:not(:placeholder-shown)]:text-[11px]"
                                        >
                                            Telefon
                                        </label>
                                    </div>
                                </div>

                                <div className="relative grid grid-cols-1">
                                    <input
                                        id="sample-email"
                                        name="email"
                                        type="email"
                                        required
                                        placeholder=" "
                                        className="peer w-full rounded-xl border border-secondary/15 bg-secondary/[0.02] px-4 pb-2.5 pt-5 font-body text-sm text-secondary placeholder-transparent transition-colors focus:border-primary focus:outline-none"
                                    />
                                    <label
                                        htmlFor="sample-email"
                                        className="pointer-events-none absolute left-4 top-1/2 -translate-y-1/2 font-body text-sm text-secondary-light transition-all peer-focus:top-3.5 peer-focus:text-[11px] peer-focus:text-primary peer-[:not(:placeholder-shown)]:top-3.5 peer-[:not(:placeholder-shown)]:text-[11px]"
                                    >
                                        E-posta
                                    </label>
                                </div>

                                <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                                    <div className="relative">
                                        <select
                                            name="city"
                                            required
                                            value={city}
                                            onChange={(e) => {
                                                setCity(e.target.value);
                                                setDistrict(""); // Şehir değişince ilçeyi sıfırla
                                            }}
                                            className="peer w-full appearance-none rounded-xl border border-secondary/15 bg-secondary/[0.02] px-4 pb-2.5 pt-5 font-body text-sm text-secondary focus:border-primary focus:outline-none"
                                        >
                                            <option value="" disabled>İl Seçiniz</option>
                                            {citiesData.map((c) => (
                                                <option key={c.name} value={c.name}>{c.name}</option>
                                            ))}
                                        </select>
                                        <label className="pointer-events-none absolute left-4 top-1.5 font-body text-[11px] text-secondary-light transition-all peer-focus:text-primary">
                                            Şehir
                                        </label>
                                    </div>
                                    <div className="relative">
                                        <select
                                            name="district"
                                            required
                                            value={district}
                                            onChange={(e) => setDistrict(e.target.value)}
                                            disabled={!city}
                                            className="peer w-full appearance-none rounded-xl border border-secondary/15 bg-secondary/[0.02] px-4 pb-2.5 pt-5 font-body text-sm text-secondary focus:border-primary focus:outline-none disabled:opacity-60"
                                        >
                                            <option value="" disabled>İlçe Seçiniz</option>
                                            {city &&
                                                citiesData
                                                    .find((c) => c.name === city)
                                                    ?.districts.map((d) => (
                                                        <option key={d.name} value={d.name}>{d.name}</option>
                                                    ))}
                                        </select>
                                        <label className="pointer-events-none absolute left-4 top-1.5 font-body text-[11px] text-secondary-light transition-all peer-focus:text-primary">
                                            İlçe
                                        </label>
                                    </div>
                                </div>

                                <div className="relative">
                                    <textarea
                                        id="sample-address"
                                        name="addressDetails"
                                        required
                                        rows={2}
                                        placeholder=" "
                                        className="peer w-full rounded-xl border border-secondary/15 bg-secondary/[0.02] px-4 pb-2.5 pt-5 font-body text-sm text-secondary placeholder-transparent transition-colors focus:border-primary focus:outline-none"
                                    />
                                    <label
                                        htmlFor="sample-address"
                                        className="pointer-events-none absolute left-4 top-5 font-body text-sm text-secondary-light transition-all peer-focus:top-2.5 peer-focus:text-[11px] peer-focus:text-primary peer-[:not(:placeholder-shown)]:top-2.5 peer-[:not(:placeholder-shown)]:text-[11px]"
                                    >
                                        Sokak, Mahalle, Kapı No vb.
                                    </label>
                                </div>

                                {state.error && <p className="font-body text-xs font-medium text-red-600">{state.error}</p>}

                                <button
                                    type="submit"
                                    disabled={isPending}
                                    className="btn-sweep w-full rounded-full border border-primary/30 py-3.5 font-body text-sm font-semibold text-secondary hover:scale-[1.02] active:scale-95 disabled:opacity-60 disabled:hover:scale-100"
                                >
                                    {isPending ? "Gönderiliyor..." : "Numune Talep Et"}
                                </button>
                                <p className="text-center font-body text-xs text-secondary-light">
                                    Kargo ücreti markamıza aittir, hiçbir ek ücret ödemezsiniz.
                                </p>
                            </div>
                        </form>
                    )}
                </div>
            </div>
        </div>
    );
}
