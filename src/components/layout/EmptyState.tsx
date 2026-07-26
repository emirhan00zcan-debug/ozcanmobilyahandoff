import Link from "next/link";

type Props = { message: string };

// Ürünü henüz olmayan kategori/oda sayfalarında gösterilir.
export default function EmptyState({ message }: Props) {
  return (
    <div className="flex flex-col items-center gap-4 py-20 text-center">
      <p className="font-body text-base text-secondary-light">{message}</p>
      <Link
        href="/"
        className="rounded-full bg-secondary px-7 py-3.5 font-body text-sm font-semibold text-white transition-all duration-200 hover:scale-105 hover:bg-primary active:scale-95"
      >
        Ana Sayfaya Dön
      </Link>
    </div>
  );
}
