import Link from "next/link";

type Props = { title: string };

// Yasal sayfaların (KVKK, Mesafeli Satış Sözleşmesi, Kargo & İade, Hizmet Şartları) ortak
// breadcrumb'ı + taslak uyarısı. Bu metinler PayTR başvurusu ve tüketici mevzuatı için
// asgari çerçeveyi oluşturur; gerçek ticari unvan/vergi bilgisiyle ve bir hukuki
// onayla güncellenmeden yayına alınmamalıdır (bkz. kutu içi uyarı).
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

      <div className="mt-6 rounded-xl border border-amber-300/60 bg-amber-50 p-4">
        <p className="font-body text-xs leading-relaxed text-amber-900">
          <strong>Taslak metin:</strong> Bu sayfa, ödeme altyapısı (PayTR) başvurusu ve temel
          tüketici mevzuatı için gerekli asgari çerçeveyi oluşturmak amacıyla hazırlanmıştır.
          Yayına almadan önce mali müşavirinize/avukatınıza onaylatın ve köşeli parantez
          <code className="mx-1 rounded bg-amber-100 px-1 font-semibold">[ ]</code>
          içindeki bilgileri (ticari unvan, vergi dairesi/no, MERSİS no) gerçek işletme
          kayıtlarınızla doldurun.
        </p>
      </div>
    </div>
  );
}
