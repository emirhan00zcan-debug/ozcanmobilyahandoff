import Link from "next/link";
import BlogCard from "@/components/blog/BlogCard";
import { getAllBlogPosts } from "@/lib/data/blog-posts";

export const metadata = {
  title: "Blog | Özcan Mobilya",
  description:
    "Mobilya malzemesi, kapak tasarımları, ölçü rehberleri ve iç mekân ipuçları — Özcan Mobilya atölyesinden yazılar.",
};

export default function BlogIndexPage() {
  const posts = getAllBlogPosts();

  return (
    <div className="mx-auto max-w-7xl px-4 py-10 sm:px-6 lg:px-8">
      <nav className="mb-6 flex items-center gap-2 font-body text-xs text-secondary-light">
        <Link href="/" className="font-medium text-secondary hover:text-primary">
          Ana sayfa
        </Link>
        <span>|</span>
        <span className="text-secondary-light">Blog</span>
      </nav>

      <div className="mx-auto max-w-2xl text-center">
        <h1 className="font-display text-3xl font-bold leading-snug text-secondary sm:text-4xl">
          Atölyeden Yazılar
        </h1>
        <p className="mt-4 font-body text-base leading-relaxed text-secondary-light">
          Malzeme seçimi, kapak tasarımları, doğru ölçü ve iç düzen planlaması üzerine — Özcan Mobilya
          atölyesinin tecrübesiyle yazılmış rehberler.
        </p>
      </div>

      <div className="mt-14 grid grid-cols-1 gap-x-8 gap-y-12 sm:grid-cols-2 lg:grid-cols-3">
        {posts.map((post) => (
          <BlogCard key={post.slug} post={post} />
        ))}
      </div>
    </div>
  );
}
