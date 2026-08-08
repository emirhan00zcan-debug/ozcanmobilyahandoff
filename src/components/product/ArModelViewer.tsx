"use client";

import { useEffect, useState, useRef } from "react";
import React from "react";
import Image from "next/image";

const ModelViewer = "model-viewer" as any;

type ArModelViewerProps = {
    src: string;
    iosSrc?: string;
    alt?: string;
    dimensions?: { widthCm: string; heightCm: string; depthCm: string };
    onAddToCart?: () => void;
};

export default function ArModelViewer({
    src,
    iosSrc,
    alt = "3D Mobilya Modeli",
    dimensions,
    onAddToCart,
}: ArModelViewerProps) {
    const [scriptLoaded, setScriptLoaded] = useState(false);
    const modelViewerRef = useRef<any>(null);

    useEffect(() => {
        // Load model-viewer script dynamically to avoid SSR issues
        if (typeof window !== "undefined" && !customElements.get("model-viewer")) {
            const script = document.createElement("script");
            script.type = "module";
            script.src =
                "https://ajax.googleapis.com/ajax/libs/model-viewer/4.0.0/model-viewer.min.js";
            script.onload = () => setScriptLoaded(true);
            document.head.appendChild(script);
        } else {
            setScriptLoaded(true);
        }
    }, []);

    if (!scriptLoaded) {
        return (
            <div className="flex aspect-square w-full items-center justify-center rounded-lg bg-secondary/[0.04]">
                <div className="flex flex-col items-center gap-3 text-secondary-light">
                    <div className="h-6 w-6 animate-spin rounded-full border-2 border-primary border-t-transparent"></div>
                    <span className="font-body text-sm">3D AR Motoru Yükleniyor...</span>
                </div>
            </div>
        );
    }

    return (
        <div className="relative aspect-square w-full overflow-hidden rounded-lg bg-secondary/[0.02]">
            <ModelViewer
                ref={modelViewerRef}
                src={src}
                ios-src={iosSrc}
                alt={alt}
                ar="true"
                ar-modes="webxr scene-viewer quick-look"
                camera-controls="true"
                touch-action="pan-y"
                shadow-intensity="1.2"
                shadow-softness="1"
                ar-scale="fixed"
                style={{ width: "100%", height: "100%", backgroundColor: "transparent" }}
                className="group"
            >
                {/* Buton: AR modunu başlatıcı. slot="ar-button" model-viewer'ın otomatik tıklama
                    algılamasını da devreye sokar, ama iOS Quick Look'un çalışması için activateAR()
                    kullanıcı tıklamasından SENKRON çağrılmalı (bkz. model-viewer AR dokümantasyonu) —
                    bu bileşen sekme geçişiyle sonradan (lazy) monte edildiği için otomatik algılamaya
                    güvenmek yerine burada açıkça çağırıyoruz. */}
                <button
                    slot="ar-button"
                    onClick={() => {
                        const el = modelViewerRef.current;
                        // GEÇİCİ TEŞHİS: gerçek cihazda sessizce başarısız olan AR tetiklemesinin
                        // asıl sebebini görmek için — kalıcı değil, sorun bulununca kaldırılacak.
                        if (!el) {
                            alert("Teşhis: model-viewer referansı yok (el=null)");
                            return;
                        }
                        if (typeof el.activateAR !== "function") {
                            alert("Teşhis: activateAR fonksiyon değil, tip=" + typeof el.activateAR);
                            return;
                        }
                        if (!el.canActivateAR) {
                            alert("Teşhis: canActivateAR=false (model-viewer AR'ı desteklemediğini/hazır olmadığını düşünüyor). loaded=" + el.loaded + " arStatus=" + el.arStatus);
                        }
                        try {
                            el.activateAR();
                            alert("Teşhis: activateAR() çağrıldı, hata fırlatmadı. canActivateAR=" + el.canActivateAR + " loaded=" + el.loaded);
                        } catch (err) {
                            alert("Teşhis: activateAR() hata fırlattı: " + (err instanceof Error ? err.message : String(err)));
                        }
                    }}
                    className="btn-sweep absolute bottom-4 left-1/2 flex -translate-x-1/2 items-center justify-center rounded-full border border-primary/30 px-6 py-3 font-body text-sm font-semibold text-secondary shadow-xl ring-4 ring-primary/20 focus:outline-none focus:ring-4 hover:scale-105 active:scale-95"
                >
                    Odanızda Görün (AR)
                </button>

                {/* DOM Overlay için UI (WebXR AR destekli cihazlarda gösterilir) */}
                {/* Sepete Ekle - AR içinde yapışkan olarak kullanılır */}
                <div className="absolute inset-x-0 bottom-0 z-50 flex flex-col items-center justify-end p-6 opacity-0 transition-opacity duration-300 group-[[ar-tracking]]:opacity-100">
                    <div className="pointer-events-auto flex w-full max-w-sm justify-between gap-4">
                        <button
                            onClick={onAddToCart}
                            className="btn-sweep w-full rounded-full border border-primary/30 py-3.5 font-body text-sm font-bold text-secondary shadow-2xl hover:scale-105"
                        >
                            Sepete Ekle
                        </button>
                    </div>
                </div>

                {/* Ölçü Rozeti - AR üst katmanı */}
                {dimensions && (
                    <div className="absolute right-4 top-4 z-50 pointer-events-none rounded-xl bg-black/60 px-4 py-3 text-white opacity-0 shadow-lg backdrop-blur-sm transition-opacity duration-300 group-[[ar-tracking]]:opacity-100">
                        <p className="font-body text-[11px] font-medium uppercase tracking-wider text-white/70">
                            Gerçek Ölçüler
                        </p>
                        <p className="mt-1 font-body text-sm font-semibold leading-tight">
                            G:{dimensions.widthCm} <span className="mx-1 text-white/40">×</span>
                            Y:{dimensions.heightCm} <span className="mx-1 text-white/40">×</span>
                            D:{dimensions.depthCm}
                        </p>
                    </div>
                )}

                {/* Zemin Tarama Yardımcısı - AR kamera ilk açıldığında gösterilir */}
                <div
                    id="ar-prompt"
                    slot="ar-prompt"
                    className="absolute inset-0 z-40 hidden flex-col items-center justify-center bg-black/40 pointer-events-none group-[[ar-tracking]]:hidden group-[[ar-status='session-started']]:flex"
                >
                    <div className="relative flex h-24 w-24 items-center justify-center">
                        {/* Animasyonlu grid */}
                        <div className="absolute inset-0 rounded-full border-2 border-white/30 border-t-white animate-spin"></div>
                        {/* El ikonu */}
                        <div className="animate-bounce">
                            <svg
                                className="w-10 h-10 text-white"
                                fill="none" stroke="currentColor" viewBox="0 0 24 24"
                            >
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" d="M7 11.5V14m0-2.5v-6a1.5 1.5 0 113 0m-3 6a1.5 1.5 0 00-3 0v2a7.5 7.5 0 0015 0v-5a1.5 1.5 0 00-3 0m-6-3V11m0-5.5v-1a1.5 1.5 0 013 0v1m0 0V11m0-5.5a1.5 1.5 0 013 0v3m0 0V11" />
                            </svg>
                        </div>
                    </div>
                    <p className="mt-6 font-body text-sm font-semibold text-white drop-shadow-md">
                        Lütfen zemini tarayarak telefonu sağa-sola hareket ettirin.
                    </p>
                </div>
            </ModelViewer>
        </div>
    );
}
