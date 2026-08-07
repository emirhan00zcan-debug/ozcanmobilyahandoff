import Link from "next/link";
import { notFound } from "next/navigation";
import { prisma } from "@/lib/prisma";
import { requireAdmin } from "@/lib/auth";

function formatDate(date: Date) {
  return new Intl.DateTimeFormat("tr-TR", { dateStyle: "long", timeStyle: "short" }).format(date);
}

export default async function AdminMessageDetailPage({ params }: { params: Promise<{ id: string }> }) {
  await requireAdmin();
  const { id } = await params;

  const message = await prisma.contactMessage.findUnique({ where: { id } });
  if (!message) notFound();

  // Detay sayfası açıldığında otomatik "okundu" işaretlenir (standart gelen kutusu davranışı).
  if (!message.isRead) {
    await prisma.contactMessage.update({ where: { id }, data: { isRead: true } });
  }

  return (
    <div className="max-w-2xl">
      <Link href="/admin/mesajlar" className="font-body text-xs text-secondary-light hover:text-primary">
        ← Mesajlara Dön
      </Link>

      <div className="mt-4 rounded-2xl border border-secondary/10 bg-white p-6">
        <h1 className="font-display text-xl font-bold text-secondary">
          {message.subject || "Konu belirtilmemiş"}
        </h1>
        <p className="mt-1 font-body text-xs text-secondary-light">{formatDate(message.createdAt)}</p>

        <dl className="mt-5 grid grid-cols-1 gap-3 border-t border-secondary/10 pt-5 sm:grid-cols-2">
          <div>
            <dt className="font-body text-xs font-medium text-secondary-light">Ad Soyad</dt>
            <dd className="font-body text-sm font-medium text-secondary">{message.name}</dd>
          </div>
          <div>
            <dt className="font-body text-xs font-medium text-secondary-light">E-posta</dt>
            <dd className="font-body text-sm font-medium text-secondary">
              <a href={`mailto:${message.email}`} className="text-primary hover:underline">
                {message.email}
              </a>
            </dd>
          </div>
          <div>
            <dt className="font-body text-xs font-medium text-secondary-light">Telefon</dt>
            <dd className="font-body text-sm font-medium text-secondary">{message.phone || "-"}</dd>
          </div>
        </dl>

        <div className="mt-5 border-t border-secondary/10 pt-5">
          <p className="font-body text-xs font-medium text-secondary-light">Mesaj</p>
          <p className="mt-2 whitespace-pre-wrap font-body text-sm leading-relaxed text-secondary">
            {message.message}
          </p>
        </div>

        <a
          href={`mailto:${message.email}?subject=${encodeURIComponent("Re: " + (message.subject || "İletişim Formu Mesajınız"))}`}
          className="mt-6 inline-block rounded-full bg-secondary px-6 py-2.5 font-body text-sm font-semibold text-white transition-colors hover:bg-primary"
        >
          E-posta ile Yanıtla
        </a>
      </div>
    </div>
  );
}
