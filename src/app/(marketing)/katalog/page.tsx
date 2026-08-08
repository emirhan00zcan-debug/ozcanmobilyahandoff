import Link from "next/link";
import Image from "next/image";
import { FaFilePdf, FaEye } from "react-icons/fa";
import { getAllProducts } from "@/lib/data/products";

export const metadata = {
    title: "Katalog & Koleksiyon | Özcan Mobilya",
    description: "Özcan Mobilya'nın en yeni koleksiyonlarını ve özel tasarımlarını inceleyin. Kataloğumuzu online görüntüleyebilir veya PDF olarak indirebilirsiniz.",
};

export default async function KatalogPage() {
    const products = await getAllProducts();

    // Extract all product images to create a rich visual catalog
    const catalogImages = products
        .flatMap(p => p.images.map(img => ({
            url: img,
            productName: p.name,
            productSlug: p.slug
        })))
        .filter(img => img.url) // ensure no empty images
        .slice(0, 30); // keep it reasonable

    return (
        <div className="bg-white">
            {/* Hero Section */}
            <div className="relative bg-secondary overflow-hidden h-[50vh] min-h-[400px] flex items-center justify-center">
                {/* Subtle background pattern or image */}
                <div className="absolute inset-0 opacity-40">
                    <Image
                        src={catalogImages[0]?.url || "/media/hero1.jpg"}
                        alt="Katalog Arka Plan"
                        fill
                        className="object-cover"
                        priority
                    />
                    <div className="absolute inset-0 bg-gradient-to-t from-secondary via-secondary/80 to-secondary/30" />
                </div>

                <div className="relative z-10 text-center px-4 max-w-3xl animate-fade-in-up">
                    <span className="font-body text-xs font-bold tracking-[0.3em] text-white/70 uppercase mb-4 block">
                        Özcan Mobilya 2026
                    </span>
                    <h1 className="font-display text-4xl sm:text-5xl lg:text-6xl font-bold text-white mb-6">
                        Dijital Katalog
                    </h1>
                    <p className="font-body text-base text-white/80 mb-10 leading-relaxed max-w-xl mx-auto">
                        Yeni sezon koleksiyonlarımızı, doğal malzemelerin zarafetini ve modern çizgileri keşfedin. İster online inceleyin, ister PDF olarak indirin.
                    </p>

                    <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
                        <a
                            href="#online-galeri"
                            className="btn-sweep flex w-full sm:w-auto items-center justify-center gap-2 rounded-full px-8 py-3.5 font-body text-sm font-semibold text-secondary hover:scale-105"
                        >
                            <FaEye className="h-4 w-4" />
                            Kataloğa Göz At
                        </a>
                        <a
                            href="#yakinda"
                            className="flex w-full sm:w-auto items-center justify-center gap-2 rounded-full border border-white/30 bg-white/10 px-8 py-3.5 font-body text-sm font-semibold text-white backdrop-blur-md transition-colors hover:bg-white/20"
                            title="PDF Katalog Yakında Eklenecektir"
                        >
                            <FaFilePdf className="h-4 w-4" />
                            PDF İndir (Çok Yakında)
                        </a>
                    </div>
                </div>
            </div>

            {/* Online Gallery Section */}
            <div id="online-galeri" className="mx-auto max-w-7xl px-4 py-16 sm:px-6 lg:px-8">
                <div className="flex items-end justify-between mb-10">
                    <div>
                        <h2 className="font-display text-3xl font-bold text-secondary">Koleksiyon Kitabı</h2>
                        <p className="mt-2 font-body text-sm text-secondary-light">
                            Tasarım vizyonumuzu yansıtan seçili kareler
                        </p>
                    </div>
                </div>

                {/* Masonry / Grid Gallery */}
                <div className="columns-1 sm:columns-2 lg:columns-3 gap-6 space-y-6">
                    {catalogImages.map((img, i) => (
                        <Link
                            key={`${img.productSlug}-${i}`}
                            href={`/urun/${img.productSlug}`}
                            className="group relative block overflow-hidden rounded-xl bg-secondary/[0.04] mb-6 page-break-inside-avoid"
                        >
                            {/* Image Aspect ratio trick (Masonry fallback for images if they differ in height, but Next Image requires height or fill. We'll use layout responsive trick) */}
                            <Image
                                src={img.url}
                                alt={img.productName}
                                width={600}
                                height={800} // arbitrary high ratio to allow object-cover or let it determine naturally
                                className="w-full h-auto object-cover transition-transform duration-700 group-hover:scale-110"
                            />
                            <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/20 to-transparent opacity-0 transition-opacity duration-300 group-hover:opacity-100" />

                            <div className="absolute bottom-0 left-0 right-0 translate-y-4 p-6 text-white opacity-0 transition-all duration-300 group-hover:translate-y-0 group-hover:opacity-100">
                                <p className="font-body text-xs font-semibold tracking-wider text-white/70 uppercase">
                                    İncele
                                </p>
                                <p className="font-display text-lg font-bold">
                                    {img.productName}
                                </p>
                            </div>
                        </Link>
                    ))}
                </div>
            </div>

            {/* Showroom CTA */}
            <div className="border-t border-secondary/10 bg-secondary/[0.02] py-20">
                <div className="mx-auto max-w-3xl px-4 text-center">
                    <h2 className="font-display text-3xl font-bold text-secondary mb-4">
                        Ürünleri Yakından Görün
                    </h2>
                    <p className="font-body text-secondary-light leading-relaxed mb-8">
                        Dijital kataloğumuzda beğendiğiniz ürünleri showroom'umuzda canlı olarak inceleyebilir, kumaş ve ahşap dokularını test edebilirsiniz. Randevu alarak size özel mimari danışmanlık hizmetimizden faydalanın.
                    </p>
                    <Link
                        href="/iletisim"
                        className="btn-sweep inline-flex rounded-full border border-primary/30 px-8 py-3.5 font-body text-sm font-semibold text-secondary"
                    >
                        Showroom'u Ziyaret Et
                    </Link>
                </div>
            </div>
        </div>
    );
}
