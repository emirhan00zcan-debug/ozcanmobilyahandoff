"use client";

import { useEffect, useRef, useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { FaInstagram } from "react-icons/fa";
import { motion, useMotionValue, useAnimationFrame } from "framer-motion";

type Props = { social: { instagram: string; instagramHandle: string } };

const PHOTOS = [
  "/media/instagram/ig-1.jpg",
  "/media/instagram/ig-2.jpg",
  "/media/instagram/ig-3.jpg",
  "/media/instagram/ig-4.jpg",
  "/media/instagram/ig-6.jpg",
  "/media/instagram/ig-7.jpg",
  "/media/instagram/ig-8.jpg",
];

const SPEED = 36; // px/saniye, otomatik kayma hızı

export default function InstagramStrip({ social }: Props) {
  const containerRef = useRef<HTMLDivElement>(null);
  const trackRef = useRef<HTMLDivElement>(null);
  const x = useMotionValue(0);
  const [isHovering, setIsHovering] = useState(false);
  const [isDragging, setIsDragging] = useState(false);
  const [bounds, setBounds] = useState({ setWidth: 0, dragLimit: 0 });

  useEffect(() => {
    if (!containerRef.current || !trackRef.current) return;
    const trackWidth = trackRef.current.scrollWidth;
    setBounds({
      setWidth: trackWidth / 2,
      dragLimit: trackWidth - containerRef.current.clientWidth,
    });
  }, []);

  // Sürekli kayan döngü: hover/sürükleme sırasında durur, bir set genişliği kadar ilerleyince başa sarar
  useAnimationFrame((_, delta) => {
    if (isHovering || isDragging || !bounds.setWidth) return;
    let next = x.get() - (SPEED * delta) / 1000;
    if (next <= -bounds.setWidth) next += bounds.setWidth;
    x.set(next);
  });

  return (
    <section className="mx-auto max-w-7xl px-4 py-16 text-center sm:px-6 lg:px-8">
      <h2 className="font-display text-2xl font-semibold text-secondary">Instagram&apos;dayız</h2>

      <div ref={containerRef} className="mt-8 overflow-hidden">
        <motion.div
          ref={trackRef}
          aria-hidden="true"
          className="flex w-max cursor-grab gap-4 active:cursor-grabbing"
          style={{ x }}
          drag="x"
          dragConstraints={{ left: -bounds.dragLimit, right: 0 }}
          dragElastic={0.08}
          onHoverStart={() => setIsHovering(true)}
          onHoverEnd={() => setIsHovering(false)}
          onDragStart={() => setIsDragging(true)}
          onDragEnd={() => setIsDragging(false)}
        >
          {[...PHOTOS, ...PHOTOS].map((src, i) => (
            <div key={i} className="relative aspect-square w-40 shrink-0 overflow-hidden rounded-xl bg-secondary/[0.04]">
              <Image src={src} alt="" draggable={false} fill sizes="160px" className="object-cover" />
            </div>
          ))}
        </motion.div>
      </div>

      <Link
        href={social.instagram}
        target="_blank"
        rel="noopener noreferrer"
        className="mt-6 inline-flex items-center gap-2 font-body text-sm font-medium text-secondary underline underline-offset-4 hover:text-primary"
      >
        <FaInstagram className="h-4 w-4" />
        {social.instagramHandle}
      </Link>
    </section>
  );
}
