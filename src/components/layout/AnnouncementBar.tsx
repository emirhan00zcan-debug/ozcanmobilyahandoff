// En üst bar: koyu zeminde ortalanmış tek satır duyuru metni.
// Referans Shopify sitesinde bu bar kaymıyor (tek slaytlık swiper, statik ortalanmış metin);
// Sayfa aşağı kaydırılsa bile bu bar normal akışta kalır (sticky olan Navbar'dır, bu bar değil).

const MESSAGE = "📢 Bu Sezona Özel %20'ye Varan İndirimler Sizi Beklyor 🏷️";

export default function AnnouncementBar() {
  return (
    <div className="bg-secondary py-2.5 text-white">
      <p className="text-center font-body text-xs font-medium tracking-wide">
        {MESSAGE}
      </p>
    </div>
  );
}
