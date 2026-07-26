import AnnouncementBar from "@/components/layout/AnnouncementBar";
import Navbar from "@/components/layout/Navbar";
import ContactInfoBar from "@/components/layout/ContactInfoBar";
import Footer from "@/components/layout/Footer";
import { contactInfo } from "@/lib/data/homepage-mock";

// Tüm (marketing) sayfalarının paylaştığı ortak çerçeve: üst duyuru barı,
// navbar ve alt iletişim/footer şeridi. Yeni bir sayfa eklerken bu dosyaları
// tekrar import etmeye gerek yok — sadece bu grup altına bir route eklemek yeterli.
export default function MarketingLayout({ children }: { children: React.ReactNode }) {
  return (
    <>
      <AnnouncementBar />
      <Navbar />
      {children}
      <ContactInfoBar items={contactInfo} />
      <Footer />
    </>
  );
}
