import Link from "next/link";
import CategoryGrid from "@/components/layout/CategoryGrid";
import { getRooms } from "@/lib/data/homepage-mock";

export const metadata = { title: "Odalara Göre | Özcan Mobilya" };

export default async function OdalarPage() {
  const rooms = await getRooms();

  return (
    <div className="mx-auto max-w-7xl px-4 py-10 sm:px-6 lg:px-8">
      <nav className="mb-6 flex items-center gap-2 font-body text-xs text-secondary-light">
        <Link href="/" className="font-medium text-secondary hover:text-primary">
          Ana sayfa
        </Link>
        <span>|</span>
        <span className="text-secondary-light">Odalara Göre</span>
      </nav>

      <h1 className="mb-10 font-display text-3xl font-semibold text-secondary">Odalara Göre</h1>

      <CategoryGrid items={rooms} basePath="/oda" />
    </div>
  );
}
