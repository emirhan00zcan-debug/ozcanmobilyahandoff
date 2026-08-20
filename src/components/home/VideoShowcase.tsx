"use client";

import { useRef, useState } from "react";
import { FaVolumeMute, FaVolumeUp } from "react-icons/fa";

// "Biz Kimiz?" bölümünün hemen üstünde köprü görevi gören sinematik video vitrin —
// HeroSlider ile aynı rounded-3xl/max-w-7xl kalıbı, ama modern ajans sitelerindeki
// gibi minimal metin + alt köşede ses aç/kapa kontrolü (autoplay tarayıcı kuralları
// gereği sessiz başlar, kullanıcı isterse sesi açabilir).
export default function VideoShowcase() {
  const videoRef = useRef<HTMLVideoElement>(null);
  const [muted, setMuted] = useState(true);

  const toggleSound = () => {
    const video = videoRef.current;
    if (!video) return;
    video.muted = !video.muted;
    setMuted(video.muted);
  };

  return (
    <section className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
      <div className="relative isolate flex h-[420px] items-end overflow-hidden rounded-3xl bg-secondary sm:h-[560px]">
        <video
          ref={videoRef}
          autoPlay
          muted
          loop
          playsInline
          className="absolute inset-0 h-full w-full object-cover"
        >
          <source src="/videos/anasayfa-vitrin.mp4" type="video/mp4" />
        </video>
        <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/10 to-black/0" />

        <div className="relative z-10 max-w-xl px-6 pb-10 text-white sm:px-10 sm:pb-14">
          <p className="font-body text-xs font-semibold uppercase tracking-[0.25em] text-white/80">
            Sinop&apos;taki Atölyemizden
          </p>
          <h2 className="mt-3 font-display text-3xl font-bold leading-tight sm:text-4xl">
            Her Parça Özenle Elinizden Geçiyor
          </h2>
        </div>

        <button
          type="button"
          onClick={toggleSound}
          aria-label={muted ? "Videonun sesini aç" : "Videonun sesini kapat"}
          className="absolute bottom-6 right-6 z-10 flex h-11 w-11 items-center justify-center rounded-full bg-white/15 text-white backdrop-blur-sm transition-colors hover:bg-white/25 sm:bottom-8 sm:right-8"
        >
          {muted ? <FaVolumeMute className="h-4 w-4" /> : <FaVolumeUp className="h-4 w-4" />}
        </button>
      </div>
    </section>
  );
}
