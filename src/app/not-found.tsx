import type { Metadata } from "next";
import Link from "next/link";
import Image from "next/image";
import AnnouncementBar from "@/components/layout/AnnouncementBar";
import Navbar from "@/components/layout/Navbar";
import ContactInfoBar from "@/components/layout/ContactInfoBar";
import Footer from "@/components/layout/Footer";
import WhatsAppButton from "@/components/layout/WhatsAppButton";
import { contactInfo, getCategories, getRooms } from "@/lib/data/homepage-mock";
import { Home, ArrowRight, SearchX } from "lucide-react";

export const metadata: Metadata = {
    title: "Sayfa Bulunamadı | Özcan Mobilya",
    description: "Aradığınız sayfa bulunamadı veya taşınmış olabilir.",
};

export default async function NotFound() {
    const [categories, rooms] = await Promise.all([getCategories(), getRooms()]);

    // Sadece görseli olan popüler kategorileri alalım (en fazla 4 tane)
    const popularCategories = categories.filter(c => c.imageUrl).slice(0, 4);

    return (
        <div className="flex min-h-screen flex-col">
            <AnnouncementBar />
            <Navbar categories={categories} rooms={rooms} />

            <main className="flex-grow flex flex-col items-center justify-center px-4 py-20 lg:py-32 bg-[#F9FAFB] relative overflow-hidden">
                {/* Arka planda silik dev bir 404 yazısı */}
                <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 text-[40vw] font-black text-secondary/5 select-none pointer-events-none -mr-4">
                    404
                </div>

                <div className="max-w-3xl w-full text-center space-y-8 relative z-10">
                    <div className="mt-8">
                        <h1 className="text-4xl md:text-5xl lg:text-7xl font-bold tracking-tight text-secondary font-display uppercase">
                            Sayfa <span className="text-brand">Bulunamadı</span>
                        </h1>
                    </div>

                    <p className="text-lg md:text-xl text-secondary/70 max-w-2xl mx-auto font-body">
                        Aradığınız sayfa taşınmış veya silinmiş olabilir. Endişelenmeyin, en çok tercih edilen kategorilerimizle evinize uygun tasarımları keşfetmeye devam edebilirsiniz.
                    </p>

                    <div className="pt-6 pb-12 flex flex-col sm:flex-row items-center justify-center gap-4">
                        <Link
                            href="/"
                            className="group flex items-center gap-2 bg-brand text-white px-8 py-4 rounded-full font-medium hover:bg-brand/90 transition-all font-body w-full sm:w-auto shadow-md hover:shadow-lg shadow-brand/20 active:scale-95"
                        >
                            <Home className="w-5 h-5 transition-transform group-hover:-translate-y-0.5" />
                            Ana Sayfaya Dön
                        </Link>
                    </div>
                </div>

                {popularCategories.length > 0 && (
                    <div className="max-w-6xl w-full mx-auto mt-8 bg-white p-6 sm:p-10 md:p-12 rounded-3xl shadow-sm border border-secondary/5 relative z-10">
                        <div className="text-center mb-10">
                            <h2 className="text-2xl md:text-3xl font-bold text-secondary mb-3 font-display">
                                Popüler Kategoriler
                            </h2>
                            <p className="text-secondary/60 font-body">
                                İlginizi çekebilecek en popüler ürün gruplarımız
                            </p>
                        </div>

                        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 md:gap-6">
                            {popularCategories.map((category) => (
                                <Link
                                    key={category.id}
                                    href={`/kategori/${category.slug}`}
                                    className="group block relative overflow-hidden rounded-2xl aspect-[4/5] bg-secondary/5"
                                >
                                    <Image
                                        src={category.imageUrl!}
                                        alt={category.name}
                                        fill
                                        className="object-cover transition-transform duration-700 ease-in-out group-hover:scale-105"
                                    />
                                    <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/30 to-transparent flex flex-col justify-end p-6">
                                        <span className="text-white font-medium font-body text-xl lg:text-2xl flex items-center justify-between group-hover:-translate-y-1 transition-transform">
                                            {category.name}
                                            <ArrowRight className="w-6 h-6 opacity-0 -translate-x-4 group-hover:opacity-100 group-hover:translate-x-0 transition-all duration-300" />
                                        </span>
                                    </div>
                                </Link>
                            ))}
                        </div>
                    </div>
                )}
            </main>

            <div className="mt-auto">
                <ContactInfoBar items={contactInfo} />
                <Footer />
                <WhatsAppButton />
            </div>
        </div>
    );
}
