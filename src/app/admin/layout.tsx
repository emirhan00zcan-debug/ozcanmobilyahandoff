import type { Metadata } from "next";
import Link from "next/link";
import { requireAdmin, signOut } from "@/lib/auth";

export const metadata: Metadata = {
  title: "Yönetim Paneli | Özcan Mobilya",
  robots: { index: false, follow: false },
};

const NAV_LINKS = [
  { href: "/admin/siparisler", label: "Siparişler" },
  { href: "/admin/urunler", label: "Ürünler" },
  { href: "/admin/kuponlar", label: "Kuponlar" },
  { href: "/admin/mesajlar", label: "Mesajlar" },
  { href: "/admin/bulten", label: "Bülten" },
];

export default async function AdminLayout({ children }: { children: React.ReactNode }) {
  const session = await requireAdmin();

  async function handleSignOut() {
    "use server";
    await signOut({ redirectTo: "/" });
  }

  return (
    <div className="flex min-h-screen bg-secondary/[0.02]">
      {/* Kenar çubuğu — masaüstünde sabit, mobilde üstteki yatay menüyle değiştirilir */}
      <aside className="hidden w-60 shrink-0 flex-col border-r border-secondary/10 bg-white sm:flex">
        <Link
          href="/admin/siparisler"
          className="flex flex-col items-center gap-0.5 border-b border-secondary/10 px-4 py-6"
        >
          <span className="font-display text-xl font-bold tracking-wide text-brand">ÖZCAN</span>
          <span className="font-body text-[10px] font-medium tracking-[0.25em] text-secondary-light">
            YÖNETİM PANELİ
          </span>
        </Link>
        <nav className="flex flex-1 flex-col gap-1 p-3">
          {NAV_LINKS.map((link) => (
            <Link
              key={link.href}
              href={link.href}
              className="rounded-lg px-4 py-2.5 font-body text-sm font-medium text-secondary transition-colors hover:bg-secondary/[0.05] hover:text-primary"
            >
              {link.label}
            </Link>
          ))}
        </nav>
        <div className="border-t border-secondary/10 p-3">
          <Link
            href="/"
            className="block rounded-lg px-4 py-2.5 font-body text-xs font-medium text-secondary-light hover:text-primary"
          >
            ← Siteye Dön
          </Link>
        </div>
      </aside>

      <div className="flex flex-1 flex-col">
        <header className="flex flex-wrap items-center gap-4 border-b border-secondary/10 bg-white px-4 py-4 sm:px-8">
          <nav className="flex gap-4 overflow-x-auto sm:hidden">
            {NAV_LINKS.map((link) => (
              <Link
                key={link.href}
                href={link.href}
                className="whitespace-nowrap font-body text-xs font-semibold text-secondary"
              >
                {link.label}
              </Link>
            ))}
          </nav>
          <div className="ml-auto flex items-center gap-4">
            <span className="font-body text-xs text-secondary-light">
              {session?.user?.name ?? session?.user?.email}
            </span>
            <form action={handleSignOut}>
              <button
                type="submit"
                className="font-body text-xs font-medium text-secondary-light transition-colors hover:text-primary"
              >
                Çıkış
              </button>
            </form>
          </div>
        </header>
        <main className="flex-1 p-4 sm:p-8">{children}</main>
      </div>
    </div>
  );
}
