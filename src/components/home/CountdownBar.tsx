"use client";

import { useEffect, useState } from "react";

type Props = {
  targetDate: Date;
  couponCode?: string;
};

type TimeLeft = { days: number; hours: number; minutes: number; seconds: number };

function getTimeLeft(target: Date): TimeLeft {
  const diff = Math.max(0, target.getTime() - Date.now());
  return {
    days: Math.floor(diff / (1000 * 60 * 60 * 24)),
    hours: Math.floor((diff / (1000 * 60 * 60)) % 24),
    minutes: Math.floor((diff / (1000 * 60)) % 60),
    seconds: Math.floor((diff / 1000) % 60),
  };
}

function pad(n: number) {
  return n.toString().padStart(2, "0");
}

export default function CountdownBar({ targetDate, couponCode = "FLAS20" }: Props) {
  const [timeLeft, setTimeLeft] = useState<TimeLeft | null>(null);
  const [copied, setCopied] = useState(false);

  const handleCopy = () => {
    navigator.clipboard.writeText(couponCode);
    setCopied(true);
    setTimeout(() => setCopied(false), 1500);
  };

  useEffect(() => {
    // İlk değer sadece client'ta hesaplanır (SSR/CSR hydration uyuşmazlığını önlemek için)
    setTimeLeft(getTimeLeft(targetDate));
    const interval = setInterval(() => setTimeLeft(getTimeLeft(targetDate)), 1000);
    return () => clearInterval(interval);
  }, [targetDate]);

  return (
    <section className="mx-auto max-w-7xl px-4 py-4 sm:px-6 lg:px-8">
    <div
      className="flex flex-col items-center justify-between gap-4 rounded-2xl px-6 py-6 text-white sm:flex-row lg:px-10"
      style={{ backgroundColor: "#1B2360" }}
    >
      <div>
        <p className="font-body text-xs font-medium uppercase tracking-[0.2em] text-white/60">
          Büyük Sezon İndirimi
        </p>
        <p className="mt-1 font-display text-lg">Kampanya Devam Ediyor</p>
      </div>

      {/* Sayaç: her rakam değişimi anlık (animasyonsuz), ciddiyet için */}
      <div className="flex items-center gap-2 font-body text-3xl font-bold tabular-nums sm:text-4xl">
        {timeLeft ? (
          <>
            <span>{pad(timeLeft.days)}</span>
            <span className="text-primary">:</span>
            <span>{pad(timeLeft.hours)}</span>
            <span className="text-primary">:</span>
            <span>{pad(timeLeft.minutes)}</span>
            <span className="text-primary">:</span>
            <span>{pad(timeLeft.seconds)}</span>
          </>
        ) : (
          <span className="opacity-40">00 : 00 : 00 : 00</span>
        )}
      </div>

      <div className="flex flex-col items-center gap-2 sm:items-end">
        <p className="max-w-[260px] text-center font-body text-xs text-white/70 sm:text-right">
          Bu aya özel tüm gardırop ve TV ünitelerinde %20&apos;ye varan fırsatları kaçırmayın.
        </p>
        <button
          onClick={handleCopy}
          className="btn-sweep rounded-full px-5 py-2 font-body text-xs font-semibold tracking-wide text-secondary hover:scale-105 active:scale-95"
        >
          {copied ? "Kopyalandı ✓" : `Kodu Kullan: ${couponCode}`}
        </button>
      </div>
    </div>
    </section>
  );
}
