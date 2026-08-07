import Link from "next/link";
import { prisma } from "@/lib/prisma";
import { requireAdmin } from "@/lib/auth";
import { toggleMessageReadAction } from "@/lib/actions/admin-contact-actions";

function formatDate(date: Date) {
  return new Intl.DateTimeFormat("tr-TR", { dateStyle: "medium", timeStyle: "short" }).format(date);
}

export default async function AdminMessagesPage() {
  await requireAdmin();

  const messages = await prisma.contactMessage.findMany({ orderBy: { createdAt: "desc" } });
  const unreadCount = messages.filter((m) => !m.isRead).length;

  return (
    <div>
      <div className="flex flex-wrap items-center gap-3">
        <h1 className="font-display text-2xl font-bold text-secondary">Mesajlar</h1>
        {unreadCount > 0 && (
          <span className="rounded-full bg-primary/10 px-2.5 py-1 font-body text-xs font-semibold text-primary">
            {unreadCount} okunmamış
          </span>
        )}
      </div>

      <div className="mt-6 overflow-x-auto rounded-2xl border border-secondary/10 bg-white">
        <table className="w-full min-w-[720px] font-body text-sm">
          <thead>
            <tr className="border-b border-secondary/10 text-left text-xs font-medium uppercase tracking-wide text-secondary-light">
              <th className="px-5 py-3">Tarih</th>
              <th className="px-5 py-3">Ad Soyad</th>
              <th className="px-5 py-3">E-posta</th>
              <th className="px-5 py-3">Konu</th>
              <th className="px-5 py-3">Durum</th>
              <th className="px-5 py-3" />
            </tr>
          </thead>
          <tbody>
            {messages.map((m) => (
              <tr
                key={m.id}
                className={[
                  "border-b border-secondary/5 last:border-0 hover:bg-secondary/[0.02]",
                  !m.isRead ? "bg-primary/[0.03]" : "",
                ].join(" ")}
              >
                <td className="px-5 py-4 text-secondary-light">{formatDate(m.createdAt)}</td>
                <td className="px-5 py-4 font-semibold text-secondary">{m.name}</td>
                <td className="px-5 py-4 text-secondary-light">{m.email}</td>
                <td className="px-5 py-4 text-secondary-light">{m.subject || "-"}</td>
                <td className="px-5 py-4">
                  <form action={toggleMessageReadAction}>
                    <input type="hidden" name="messageId" value={m.id} />
                    <input type="hidden" name="isRead" value={String(m.isRead)} />
                    <button
                      type="submit"
                      className={[
                        "rounded-full px-3 py-1 text-xs font-medium transition-colors",
                        m.isRead
                          ? "bg-secondary/10 text-secondary-light hover:bg-secondary/20"
                          : "bg-primary/10 text-primary hover:bg-primary/20",
                      ].join(" ")}
                    >
                      {m.isRead ? "Okundu" : "Okunmadı"}
                    </button>
                  </form>
                </td>
                <td className="px-5 py-4 text-right">
                  <Link href={`/admin/mesajlar/${m.id}`} className="font-medium text-primary hover:underline">
                    Görüntüle
                  </Link>
                </td>
              </tr>
            ))}
            {messages.length === 0 && (
              <tr>
                <td colSpan={6} className="px-5 py-10 text-center text-secondary-light">
                  Henüz mesaj gelmemiş.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
