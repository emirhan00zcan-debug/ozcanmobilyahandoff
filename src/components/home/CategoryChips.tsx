import Link from "next/link";
import { FaCheck } from "react-icons/fa";

type Props = { chips: string[] };

function slugify(label: string) {
  return label
    .toLocaleLowerCase("tr-TR")
    .replace(/ı/g, "i")
    .replace(/ş/g, "s")
    .replace(/ğ/g, "g")
    .replace(/ü/g, "u")
    .replace(/ö/g, "o")
    .replace(/ç/g, "c")
    .replace(/&/g, "")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

export default function CategoryChips({ chips }: Props) {
  return (
    <section className="mx-auto max-w-7xl px-4 py-10 sm:px-6 lg:px-8">
      <div className="scrollbar-hide flex gap-3 overflow-x-auto">
        {chips.map((chip) => (
          <Link
            key={chip}
            href={`/kategori/${slugify(chip)}`}
            className="flex shrink-0 items-center gap-2 rounded-full border border-secondary/15 px-4 py-2.5 font-body text-xs font-medium text-secondary transition-colors hover:border-secondary/40"
          >
            <FaCheck className="h-2.5 w-2.5 text-primary" />
            {chip}
          </Link>
        ))}
      </div>
    </section>
  );
}
