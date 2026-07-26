// Referans sitedeki kayan güven şeridiyle birebir aynı 5 mesaj
const MESSAGES = [
  "Hızlı Teslimat",
  "30 Gün İçinde Koşulsuz İade",
  "Güvenli Ödeme",
  "Anında İletişime Geçin",
  "Sürdürülebilir Malzemeler",
];

export default function TrustMarquee() {
  return (
    <div className="overflow-hidden bg-primary py-4">
      <div className="flex w-max animate-marquee gap-16">
        {[...MESSAGES, ...MESSAGES].map((message, i) => (
          <span key={i} className="whitespace-nowrap font-display text-lg font-semibold text-white">
            {message}
          </span>
        ))}
      </div>
    </div>
  );
}
