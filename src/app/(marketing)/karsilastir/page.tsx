import { Metadata } from "next";
import ComparePageClient from "./ComparePageClient";

export const metadata: Metadata = {
    title: "Ürün Karşılaştırma | Özcan Mobilya",
    description: "Seçtiğiniz mobilyaları ölçü, fiyat ve özelliklerine göre yan yana karşılaştırın.",
};

export default function ComparePage() {
    return <ComparePageClient />;
}
