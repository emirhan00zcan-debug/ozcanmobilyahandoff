import Link from "next/link";

type Props = { message: string };

// Ürünü henüz olmayan kategori/oda sayfalarında gösterilir.
export default function EmptyState({ message }: Props) {
  return (
    <div className="flex flex-col items-center gap-4 py-20 text-center">
      <p className="font-body text-base text-secondary-light">{message}</p>
      <Link
        href="/"
        className="btn-sweep rounded-full border border-primary/30 px-7 py-3.5 font-body text-sm font-semibold text-secondary hover:scale-105 active:scale-95"
      >
        Ana Sayfaya Dön
      </Link>
    </div>
  );
}
