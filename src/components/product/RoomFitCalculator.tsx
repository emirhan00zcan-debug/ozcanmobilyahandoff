"use client";

import { useState } from "react";
import { FaRulerCombined, FaTimes, FaCheckCircle, FaExclamationTriangle } from "react-icons/fa";

type DimensionRow = {
    label: string;
    widthCm: string;
    heightCm: string;
    depthCm: string;
};

type Props = {
    dimensions: DimensionRow[];
};

export default function RoomFitCalculator({ dimensions }: Props) {
    const [isOpen, setIsOpen] = useState(false);

    // Try to find the maximum width, height, and depth from dimensions
    const parseCm = (str: string) => {
        const num = parseInt(str.replace(/\D/g, ""));
        return isNaN(num) ? 0 : num;
    };

    const maxWidth = Math.max(...dimensions.map(d => parseCm(d.widthCm)));
    const maxHeight = Math.max(...dimensions.map(d => parseCm(d.heightCm)));
    const maxDepth = Math.max(...dimensions.map(d => parseCm(d.depthCm)));

    const [roomW, setRoomW] = useState("");
    const [roomH, setRoomH] = useState("");

    const [result, setResult] = useState<"fit" | "tight" | "fail" | null>(null);

    const handleCalculate = () => {
        const rw = parseInt(roomW);
        const rh = parseInt(roomH);

        if (isNaN(rw)) return;

        // Optional: if roomH is given
        const isHeightIssue = !isNaN(rh) && rh < maxHeight;

        if (rw < maxWidth || isHeightIssue) {
            setResult("fail");
        } else if (rw - maxWidth < 15) { // less than 15cm clearance
            setResult("tight");
        } else {
            setResult("fit");
        }
    };

    return (
        <>
            <button
                type="button"
                onClick={() => setIsOpen(true)}
                className="btn-sweep mt-3 flex w-full items-center justify-center gap-2 rounded-md border border-primary/30 px-4 py-2.5 font-body text-[13px] font-semibold text-secondary"
            >
                <FaRulerCombined className="h-4 w-4" />
                Odama Sığar Mı?
            </button>

            {isOpen && (
                <div
                    className="fixed inset-0 z-[120] flex items-end sm:items-center justify-center bg-black/60 sm:p-6 animate-fade-in"
                    onClick={() => setIsOpen(false)}
                >
                    <div
                        className="w-full max-w-sm rounded-t-2xl sm:rounded-xl bg-white p-6 shadow-2xl animate-fade-in-up"
                        onClick={(e) => e.stopPropagation()}
                    >
                        {/* Drawer line for mobile */}
                        <div className="mx-auto mb-4 h-1.5 w-12 rounded-full bg-secondary/20 sm:hidden"></div>

                        <div className="flex items-center justify-between border-b border-secondary/15 pb-4">
                            <h3 className="font-display text-lg font-bold text-secondary">Ölçü / Oda Uyumu</h3>
                            <button
                                onClick={() => setIsOpen(false)}
                                className="rounded-full bg-secondary/5 p-2 text-secondary-light hover:bg-secondary/10 hover:text-secondary"
                            >
                                <FaTimes className="h-4 w-4" />
                            </button>
                        </div>

                        <div className="mt-5 space-y-5">
                            <p className="font-body text-[13px] leading-relaxed text-secondary-light">
                                Ürün ölçüleri en dış noktalardan baz alınmıştır. Kurulum için duvarınızda minimum <strong className="text-secondary">{maxWidth + 10} cm</strong> alan olması önerilir.
                            </p>

                            <div className="space-y-4">
                                <div>
                                    <label className="mb-1.5 block font-body text-[13px] font-bold text-secondary">
                                        Boş Duvar Genişliği (cm)
                                    </label>
                                    <input
                                        type="number"
                                        value={roomW}
                                        onChange={(e) => setRoomW(e.target.value)}
                                        placeholder={`Örn: ${Math.max(maxWidth + 20, 200)}`}
                                        className="w-full rounded-lg border border-secondary/20 px-4 py-3 font-body text-sm text-secondary outline-none transition-all focus:border-primary focus:ring-1 focus:ring-primary/50"
                                    />
                                </div>

                                <div>
                                    <label className="mb-1.5 block font-body text-[13px] font-bold text-secondary">
                                        Tavan Yüksekliği (cm) <span className="font-normal text-secondary-light">(Opsiyonel)</span>
                                    </label>
                                    <input
                                        type="number"
                                        value={roomH}
                                        onChange={(e) => setRoomH(e.target.value)}
                                        placeholder="Örn: 270"
                                        className="w-full rounded-lg border border-secondary/20 px-4 py-3 font-body text-sm text-secondary outline-none transition-all focus:border-primary focus:ring-1 focus:ring-primary/50"
                                    />
                                </div>
                            </div>

                            <button
                                onClick={handleCalculate}
                                disabled={!roomW}
                                className="btn-sweep w-full rounded-full border border-primary/30 py-3.5 font-body text-sm font-semibold text-secondary disabled:cursor-not-allowed disabled:border-transparent disabled:bg-secondary-light disabled:text-white"
                            >
                                Uyumu Kontrol Et
                            </button>

                            {/* Sonuç Alanları */}
                            {result === "fit" && (
                                <div className="flex animate-fade-in gap-3 rounded-lg bg-emerald-50 p-4 text-emerald-800">
                                    <FaCheckCircle className="mt-0.5 h-4 w-4 shrink-0" />
                                    <p className="font-body text-[13px] leading-relaxed">
                                        <strong>Harika!</strong> Ürün odanıza rahatça sığıyor. Kurulum için de yeterli boşluk kalacak.
                                    </p>
                                </div>
                            )}

                            {result === "tight" && (
                                <div className="flex animate-fade-in gap-3 rounded-lg bg-amber-50 p-4 text-amber-800">
                                    <FaExclamationTriangle className="mt-0.5 h-4 w-4 shrink-0" />
                                    <p className="font-body text-[13px] leading-relaxed">
                                        <strong>Sığıyor ama sınırda.</strong> Ürünün tavsiye edilen alanı, belirttiğiniz ölçülerle çok yakın. Süpürgelik veya duvar eğriliğine dikkat edin.
                                    </p>
                                </div>
                            )}

                            {result === "fail" && (
                                <div className="flex animate-fade-in gap-3 rounded-lg bg-red-50 p-4 text-red-800">
                                    <span className="mt-0.5 flex h-4 w-4 shrink-0 items-center justify-center rounded-full bg-red-200">
                                        <FaTimes className="h-2.5 w-2.5 text-red-700" />
                                    </span>
                                    <p className="font-body text-[13px] leading-relaxed">
                                        <strong>Maalesef sığmıyor.</strong> Belirttiğiniz boşluk, ürünün ({maxWidth} cm) sığması için yeterli değil.
                                    </p>
                                </div>
                            )}
                        </div>
                    </div>
                </div>
            )}
        </>
    );
}
