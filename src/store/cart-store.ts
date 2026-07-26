import { create } from "zustand";
import { persist, createJSONStorage } from "zustand/middleware";

// ============================================================================
// TİPLER
// ============================================================================

// Mobilya sektörüne özgü varyasyon seçimleri. Her alan opsiyonel çünkü her ürün
// tipi aynı varyasyon eksenlerine sahip olmayabilir (örn. bir aksesuarda
// "doorType" olmayabilir).
export type SelectedVariations = {
  dimensions?: string; // örn: "200x220x60 cm"
  doorType?: string; // örn: "Aynalı Kapak", "Cam Kapak", "Çerçeve Kapak"
  colorDetails?: string; // örn: "Krom Kulp - Mat Beyaz Gövde"
};

export type CartItem = {
  id: string; // Satır kimliği (lineId): productId + varyasyon kombinasyonundan üretilir
  productId: string; // Asıl ürünün kimliği (Prisma Product.id ile eşleşir)
  name: string;
  basePrice: number; // Varyasyonsuz taban fiyat (referans/gösterim amaçlı)
  unitPrice: number; // Seçilen varyasyonların priceModifier'ları eklenmiş, TEK adet fiyatı
  totalPrice: number; // unitPrice * quantity (satırın toplam tutarı)
  image?: string;
  quantity: number;
  selectedVariations: SelectedVariations;
};

// addItem'a dışarıdan verilecek girdi: id/totalPrice store tarafından hesaplanır
export type AddCartItemInput = {
  productId: string;
  name: string;
  basePrice: number;
  unitPrice: number;
  image?: string;
  quantity?: number; // verilmezse 1 kabul edilir
  selectedVariations?: SelectedVariations;
};

type CartState = {
  items: CartItem[];
  isOpen: boolean;

  // Sepet çekmecesi (drawer) kontrolü
  openCart: () => void;
  closeCart: () => void;
  toggleCart: () => void;

  // Sepet işlemleri
  addItem: (input: AddCartItemInput) => void;
  removeItem: (lineId: string) => void;
  updateQuantity: (lineId: string, quantity: number) => void;
  clearCart: () => void;

  // Persist hydration takibi (SSR/CSR uyuşmazlığını önlemek için)
  hasHydrated: boolean;
  setHasHydrated: (state: boolean) => void;
};

// ============================================================================
// YARDIMCI: Satır kimliği üretimi
// ============================================================================
// Aynı ürün + BİREBİR AYNI varyasyon kombinasyonu -> aynı lineId -> quantity artar.
// Herhangi bir varyasyon farklıysa -> farklı lineId -> ayrı satır olarak eklenir.
// Varyasyon alanlarını alfabetik sıraya sokup birleştiriyoruz ki alan girme
// sırası farklı olsa bile (örn. önce doorType sonra colorDetails girilmiş olsa
// bile) aynı kombinasyon her zaman aynı kimliği üretsin.
function buildLineId(productId: string, variations?: SelectedVariations): string {
  const v = variations ?? {};
  const normalized = [
    ["dimensions", v.dimensions ?? ""],
    ["doorType", v.doorType ?? ""],
    ["colorDetails", v.colorDetails ?? ""],
  ]
    .map(([key, value]) => `${key}:${value}`)
    .join("|");

  return `${productId}__${normalized}`;
}

// ============================================================================
// STORE
// ============================================================================

export const useCartStore = create<CartState>()(
  persist(
    (set, get) => ({
      items: [],
      isOpen: false,
      hasHydrated: false,

      openCart: () => set({ isOpen: true }),
      closeCart: () => set({ isOpen: false }),
      toggleCart: () => set((state) => ({ isOpen: !state.isOpen })),

      addItem: (input) => {
        const quantityToAdd = input.quantity ?? 1;
        const lineId = buildLineId(input.productId, input.selectedVariations);

        set((state) => {
          const existingIndex = state.items.findIndex((item) => item.id === lineId);

          // Aynı ürün + aynı varyasyon kombinasyonu zaten sepette -> quantity'yi artır
          if (existingIndex !== -1) {
            const updatedItems = [...state.items];
            const existing = updatedItems[existingIndex];
            const newQuantity = existing.quantity + quantityToAdd;

            updatedItems[existingIndex] = {
              ...existing,
              quantity: newQuantity,
              totalPrice: existing.unitPrice * newQuantity,
            };

            return { items: updatedItems, isOpen: true };
          }

          // Farklı varyasyon (veya ilk kez ekleniyor) -> yeni satır
          const newItem: CartItem = {
            id: lineId,
            productId: input.productId,
            name: input.name,
            basePrice: input.basePrice,
            unitPrice: input.unitPrice,
            totalPrice: input.unitPrice * quantityToAdd,
            image: input.image,
            quantity: quantityToAdd,
            selectedVariations: input.selectedVariations ?? {},
          };

          return { items: [...state.items, newItem], isOpen: true };
        });
      },

      removeItem: (lineId) => {
        set((state) => ({
          items: state.items.filter((item) => item.id !== lineId),
        }));
      },

      updateQuantity: (lineId, quantity) => {
        // 0 veya altına düşülürse satırı tamamen kaldır
        if (quantity <= 0) {
          get().removeItem(lineId);
          return;
        }

        set((state) => ({
          items: state.items.map((item) =>
            item.id === lineId
              ? { ...item, quantity, totalPrice: item.unitPrice * quantity }
              : item,
          ),
        }));
      },

      clearCart: () => set({ items: [] }),

      setHasHydrated: (state) => set({ hasHydrated: state }),
    }),
    {
      name: "ozcan-cart-storage", // localStorage anahtarı
      storage: createJSONStorage(() => localStorage),
      // isOpen (UI state) sayfa yenilendiğinde sıfırlanmalı; sadece sepet
      // içeriğini kalıcı hafızaya yazıyoruz.
      partialize: (state) => ({ items: state.items }),
      // Next.js App Router'da server ve ilk client render'ın birebir eşleşmesi
      // için hydration'ı otomatik yapmıyoruz; bkz. useCartHydration hook'u.
      skipHydration: true,
      onRehydrateStorage: () => (state) => {
        state?.setHasHydrated(true);
      },
    },
  ),
);

// ============================================================================
// SELECTOR YARDIMCILARI (component'lerde gereksiz re-render'ı önlemek için)
// ============================================================================

export const useCartItems = () => useCartStore((state) => state.items);
export const useCartIsOpen = () => useCartStore((state) => state.isOpen);

export const useCartTotalQuantity = () =>
  useCartStore((state) => state.items.reduce((sum, item) => sum + item.quantity, 0));

export const useCartSubtotal = () =>
  useCartStore((state) => state.items.reduce((sum, item) => sum + item.totalPrice, 0));
