import Link from "next/link";

type Props = { title: string };

// Yasal sayfaların (KVKK, Mesafeli Satış Sözleşmesi, Kargo & İade, Hizmet Şartları) ortak
// breadcrumb'ı.
export default function LegalPageHeader({ title }: Props) {
  return (
    <div className="mx-auto max-w-3xl px-4 pt-6 sm:px-6 lg:px-8">
      <nav className="mb-6 flex items-center gap-2 font-body text-xs text-secondary-light">
        <Link href="/" className="font-medium text-secondary hover:text-primary">
          Ana sayfa
        </Link>
        <span>|</span>
        <span className="text-secondary-light">{title}</span>
      </nav>

      <h1 className="font-display text-2xl font-bold text-secondary sm:text-3xl">{title}</h1>
    </div>
  );
}
