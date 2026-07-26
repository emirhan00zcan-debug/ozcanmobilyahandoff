"use client";

import { SessionProvider } from "next-auth/react";
import { useCartHydration } from "@/hooks/use-cart-hydration";

export default function Providers({ children }: { children: React.ReactNode }) {
  useCartHydration();
  return <SessionProvider>{children}</SessionProvider>;
}
