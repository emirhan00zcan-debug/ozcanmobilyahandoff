"use client";

import { useEffect, useRef, useState } from "react";

type Props = {
  children: React.ReactNode;
  delay?: number; // ms
  className?: string;
};

// Scroll Reveal: eleman görünüm alanına girdiğinde aşağıdan yukarı belirir.
// .reveal / .reveal.active geçişi globals.css'te tanımlı; burada sadece
// IntersectionObserver ile "active" class'ı ekleniyor. Tek seferlik
// tetiklenir, tekrar gizlenmez.
export default function Reveal({ children, delay = 0, className }: Props) {
  const ref = useRef<HTMLDivElement>(null);
  const [active, setActive] = useState(false);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setActive(true);
          observer.disconnect();
        }
      },
      { threshold: 0.15 },
    );
    observer.observe(el);
    return () => observer.disconnect();
  }, []);

  return (
    <div
      ref={ref}
      style={{ transitionDelay: `${delay}ms` }}
      className={["reveal", active ? "active" : "", className ?? ""].join(" ")}
    >
      {children}
    </div>
  );
}
