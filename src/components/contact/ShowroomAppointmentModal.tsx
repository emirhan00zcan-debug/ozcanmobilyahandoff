"use client";

import { useState } from "react";
import { FaCalendarAlt, FaTimes, FaCheckCircle, FaSearchLocation } from "react-icons/fa";

export default function ShowroomAppointmentModal() {
    const [isOpen, setIsOpen] = useState(false);
    const [formState, setFormState] = useState<"idle" | "submitting" | "success">("idle");

    const openModal = () => setIsOpen(true);
    const closeModal = () => {
        if (formState === "submitting") return;
        setIsOpen(false);
        setTimeout(() => setFormState("idle"), 300); // Reset after close animation
    };

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        setFormState("submitting");
        // Simulate API call for now (can hook up to actual server action)
        setTimeout(() => {
            setFormState("success");
        }, 1200);
    };

    return (
        <>
            <button
                onClick={openModal}
                className="mt-3 ml-4 inline-flex items-center gap-2 rounded-lg bg-secondary/5 px-3 py-1.5 font-body text-xs font-semibold text-secondary transition-colors hover:bg-primary hover:text-white"
            >
                <FaCalendarAlt className="h-3 w-3" />
                Randevu Al
            </button>

            {isOpen && (
                <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
                    <div
                        className="fixed inset-0 bg-secondary/80 backdrop-blur-sm transition-opacity"
                        onClick={closeModal}
                    ></div>

                    <div
                        className="relative z-10 w-full max-w-lg overflow-hidden rounded-2xl bg-white shadow-2xl"
                        role="dialog"
                        aria-modal="true"
                    >
                        <div className="flex items-center justify-between border-b border-secondary/10 px-6 py-4">
                            <h3 className="font-display text-lg font-semibold text-secondary flex items-center gap-2">
                                <FaSearchLocation className="text-primary" />
                                Showroom Ziyaret Randevusu
                            </h3>
                            <button
                                onClick={closeModal}
                                className="rounded-full p-2 text-secondary-light transition-colors hover:bg-secondary/5 hover:text-secondary focus:outline-none"
                            >
                                <FaTimes className="h-4 w-4" />
                            </button>
                        </div>

                        <div className="p-6">
                            {formState === "success" ? (
                                <div className="flex flex-col items-center justify-center py-6 text-center">
                                    <FaCheckCircle className="h-14 w-14 text-emerald-500 mb-4" />
                                    <h4 className="font-display text-xl font-semibold text-secondary">Randevunuz Alındı!</h4>
                                    <p className="mt-2 text-sm text-secondary-light font-body">
                                        Ziyaret talebinizi aldık. Ziyaret öncesinde girdiğiniz numara üzerinden sizi arayarak teyit edeceğiz.
                                    </p>
                                    <button
                                        onClick={closeModal}
                                        className="mt-6 rounded-full bg-secondary px-8 py-2.5 text-sm font-semibold text-white transition-colors hover:bg-primary"
                                    >
                                        Kapat
                                    </button>
                                </div>
                            ) : (
                                <form onSubmit={handleSubmit} className="space-y-4">
                                    <p className="mb-4 text-sm text-secondary-light font-body leading-relaxed">
                                        Sinop Merkez&apos;deki showroom&apos;umuzda ürünleri yakından incelemek ve özel ölçü fikirlerinizi tartışmak için randevu oluşturun. Sizin için hazırlık yapalım!
                                    </p>

                                    <div className="grid grid-cols-2 gap-4">
                                        <div className="relative">
                                            <input id="modal-name" required type="text" placeholder=" " className="peer w-full rounded-xl border border-secondary/15 bg-white px-4 pb-2.5 pt-5 font-body text-sm text-secondary placeholder-transparent transition-colors focus:border-primary focus:outline-none" />
                                            <label htmlFor="modal-name" className="pointer-events-none absolute left-4 top-5 font-body text-sm text-secondary-light transition-all peer-focus:top-2.5 peer-focus:text-[11px] peer-focus:text-primary peer-[:not(:placeholder-shown)]:top-2.5 peer-[:not(:placeholder-shown)]:text-[11px]">
                                                Adınız Soyadınız
                                            </label>
                                        </div>
                                        <div className="relative">
                                            <input id="modal-phone" required type="tel" placeholder=" " className="peer w-full rounded-xl border border-secondary/15 bg-white px-4 pb-2.5 pt-5 font-body text-sm text-secondary placeholder-transparent transition-colors focus:border-primary focus:outline-none" />
                                            <label htmlFor="modal-phone" className="pointer-events-none absolute left-4 top-5 font-body text-sm text-secondary-light transition-all peer-focus:top-2.5 peer-focus:text-[11px] peer-focus:text-primary peer-[:not(:placeholder-shown)]:top-2.5 peer-[:not(:placeholder-shown)]:text-[11px]">
                                                Telefon Numarası
                                            </label>
                                        </div>
                                    </div>

                                    <div className="grid grid-cols-2 gap-4">
                                        <div className="relative">
                                            <input id="modal-date" required type="date" placeholder=" " className="peer w-full rounded-xl border border-secondary/15 bg-white px-4 pb-2.5 pt-5 font-body text-sm text-secondary placeholder-transparent transition-colors focus:border-primary focus:outline-none" />
                                            <label htmlFor="modal-date" className="pointer-events-none absolute left-4 top-5 font-body text-sm text-secondary-light transition-all peer-focus:top-2.5 peer-focus:text-[11px] peer-focus:text-primary peer-[:not(:placeholder-shown)]:top-2.5 peer-[:not(:placeholder-shown)]:text-[11px]">
                                                Ziyaret Tarihi (Tahmini)
                                            </label>
                                        </div>
                                        <div className="relative">
                                            <select id="modal-interest" required defaultValue="" className="peer w-full rounded-xl border border-secondary/15 bg-white px-4 pb-2.5 pt-5 font-body text-sm text-secondary transition-colors focus:border-primary focus:outline-none appearance-none">
                                                <option value="" disabled hidden></option>
                                                <option value="wardrobe">Gardırop</option>
                                                <option value="tv-unit">TV Ünitesi</option>
                                                <option value="hall-tree">Portmanto</option>
                                                <option value="kitchen">Mutfak/Banyo Dolabı</option>
                                                <option value="other">Diğer (Proje)</option>
                                            </select>
                                            <label htmlFor="modal-interest" className="pointer-events-none absolute left-4 top-2.5 text-[11px] font-body text-primary transition-all">
                                                İlgilendiğiniz Ürün Tipi
                                            </label>
                                        </div>
                                    </div>

                                    <div className="relative">
                                        <textarea id="modal-note" rows={3} placeholder=" " className="peer w-full rounded-xl border border-secondary/15 bg-white px-4 pb-2.5 pt-5 font-body text-sm text-secondary placeholder-transparent transition-colors focus:border-primary focus:outline-none" />
                                        <label htmlFor="modal-note" className="pointer-events-none absolute left-4 top-5 font-body text-sm text-secondary-light transition-all peer-focus:top-2.5 peer-focus:text-[11px] peer-focus:text-primary peer-[:not(:placeholder-shown)]:top-2.5 peer-[:not(:placeholder-shown)]:text-[11px]">
                                            Ek bilgi veya talepleriniz (Opsiyonel)
                                        </label>
                                    </div>

                                    <button
                                        type="submit"
                                        disabled={formState === "submitting"}
                                        className="w-full rounded-full bg-secondary py-3.5 mt-2 font-body text-sm font-semibold text-white transition-all duration-200 hover:bg-primary active:scale-95 disabled:opacity-60"
                                    >
                                        {formState === "submitting" ? "Gönderiliyor..." : "Randevu Talebi Gönder"}
                                    </button>
                                </form>
                            )}
                        </div>
                    </div>
                </div >
            )
            }
        </>
    );
}
