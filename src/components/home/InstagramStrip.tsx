import Link from "next/link";
import { FaInstagram } from "react-icons/fa";

type Props = { social: { instagram: string; instagramHandle: string } };

export default function InstagramStrip({ social }: Props) {
  return (
    <section className="mx-auto max-w-7xl px-4 py-16 text-center sm:px-6 lg:px-8">
      <h2 className="font-display text-2xl font-semibold text-secondary">Instagram&apos;dayız</h2>

      <div className="scrollbar-hide mt-8 flex justify-center gap-4 overflow-x-auto">
        {Array.from({ length: 5 }).map((_, i) => (
          <div key={i} className="aspect-square w-40 shrink-0 rounded-xl bg-secondary/[0.04]" />
        ))}
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
