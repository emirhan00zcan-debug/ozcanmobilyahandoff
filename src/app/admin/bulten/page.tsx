import { prisma } from "@/lib/prisma";
import { requireAdmin } from "@/lib/auth";
import NewsletterCampaignForm from "@/components/admin/NewsletterCampaignForm";

export default async function AdminNewsletterPage() {
  await requireAdmin();

  const subscriberCount = await prisma.newsletterSubscriber.count();

  return (
    <div>
      <div className="flex flex-wrap items-center gap-3">
        <h1 className="font-display text-2xl font-bold text-secondary">Bülten</h1>
        <span className="rounded-full bg-primary/10 px-2.5 py-1 font-body text-xs font-semibold text-primary">
          {subscriberCount} abone
        </span>
      </div>
      <p className="mt-2 font-body text-sm text-secondary-light">
        Aşağıdaki mesaj, e-bültene kayıtlı tüm abonelere e-posta olarak gönderilir.
      </p>

      <NewsletterCampaignForm subscriberCount={subscriberCount} />
    </div>
  );
}
