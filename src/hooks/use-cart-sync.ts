"use client";

import { useEffect, useRef } from "react";
import { useSession } from "next-auth/react";
import { useCartStore } from "@/store/cart-store";
import { CartItem } from "@/store/cart-store";

export function useCartSync() {
    const { status } = useSession();

    const items = useCartStore((state) => state.items);
    const setItems = useCartStore((state: any) => state.setItems);
    const hasHydrated = useCartStore((state) => state.hasHydrated);

    const prevItemsRef = useRef<string | null>(null);
    const isFirstLoadRef = useRef(true);

    useEffect(() => {
        if (status !== "authenticated" || !hasHydrated) return;

        if (isFirstLoadRef.current) {
            isFirstLoadRef.current = false;

            const fetchInitial = async () => {
                try {
                    const res = await fetch("/api/cart/sync", {
                        method: "POST",
                        headers: { "Content-Type": "application/json" },
                        body: JSON.stringify({ items, mode: "merge" }), // local items ile DB'yi birleştir
                    });
                    if (res.ok) {
                        const data = await res.json();
                        if (data.items) {
                            setItems(data.items);
                            prevItemsRef.current = JSON.stringify(data.items);
                        }
                    }
                } catch (e) {
                    console.error("Initial cart sync failed:", e);
                }
            };

            fetchInitial();
            return;
        }

        // Degisiklik algilama (ilk yukleme sonrasi)
        const currentStr = JSON.stringify(items);
        if (currentStr === prevItemsRef.current) return;

        // Birden fazla urun eklendiginde vs cok fazla API cagrisi atmamak icin
        // basit bir debounce mekanizmasi uyguluyoruz.
        const timer = setTimeout(async () => {
            try {
                const res = await fetch("/api/cart/sync", {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({ items, mode: "overwrite" }),
                });

                if (res.ok) {
                    const data = await res.json();
                    if (data.items) {
                        // Eger UI coktan guncellendiyse (debounce sureci bitmeden)
                        // arayuzu ezmemek adina state'e dokunmuyoruz, sadece referansi guncelliyoruz.
                        // DB'ye gonderdigimiz basarili olduysa, local state'in gecerli oldugunu varsayabiliriz.
                        prevItemsRef.current = currentStr;
                    }
                }
            } catch (e) {
                console.error("Cart sync fetch failed:", e);
            }
        }, 1000);

        return () => clearTimeout(timer);
    }, [items, status, hasHydrated, setItems]);
}
