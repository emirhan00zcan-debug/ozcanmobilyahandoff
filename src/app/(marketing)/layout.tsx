import AnnouncementBar from "@/components/layout/AnnouncementBar";
import Navbar from "@/components/layout/Navbar";
import ContactInfoBar from "@/components/layout/ContactInfoBar";
import Footer from "@/components/layout/Footer";
import WhatsAppButton from "@/components/layout/WhatsAppButton";
import { contactInfo, getCategories, getRooms } from "@/lib/data/homepage-mock";

import CompareFloatingBar from "@/components/product/CompareFloatingBar";

// Tüm (marketing) sayfalarının paylaştığı ortak çerçeve: üst duyuru barı,
// navbar ve alt iletişim/footer şeridi. Yeni bir sayfa eklerken bu dosyaları
// tekrar import etmeye gerek yok — sadece bu grup altına bir route eklemek yeterli.
export default async function MarketingLayout({ children }: { children: React.ReactNode }) {
  const [categories, rooms] = await Promise.all([getCategories(), getRooms()]);

  return (
    <>
      <AnnouncementBar />
      <Navbar categories={categories} rooms={rooms} />
      {children}
      <ContactInfoBar items={contactInfo} />
      <Footer />
      <WhatsAppButton />
      <CompareFloatingBar />
    </>
  );
}
