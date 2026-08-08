import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import { notFound } from "next/navigation";
import BlogCard from "@/components/blog/BlogCard";
import BlogPostBody from "@/components/blog/BlogPostBody";
import { getAllBlogSlugs, getBlogPostBySlug, getRelatedBlogPosts, formatBlogDate } from "@/lib/data/blog-posts";
import { absoluteUrl, truncateForMeta } from "@/lib/seo";

export async function generateStaticParams() {
  return getAllBlogSlugs().map((slug) => ({ slug }));
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}): Promise<Metadata> {
  const { slug } = await params;
  const post = getBlogPostBySlug(slug);

  if (!post) {
    return { title: "Yazı Bulunamadı | Özcan Mobilya" };
  }

  const title = `${post.title} | Özcan Mobilya Blog`;
  const description = truncateForMeta(post.excerpt);
  const url = absoluteUrl(`/blog/${post.slug}`);

  return {
    title,
    description,
    alternates: { canonical: url },
    openGraph: {
      title,
      description,
      url,
      siteName: "Özcan Mobilya",
      images: [{ url: post.coverImage }],
    },
  };
}

export default async function BlogPostPage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const post = getBlogPostBySlug(slug);

  if (!post) {
    notFound();
  }

  const relatedPosts = getRelatedBlogPosts(post.slug);

  const articleJsonLd = {
    "@context": "https://schema.org",
    "@type": "Article",
    headline: post.title,
    description: post.excerpt,
    image: [absoluteUrl(post.coverImage)],
    datePublished: post.publishedAt,
    author: { "@type": "Organization", name: "Özcan Mobilya" },
  };

  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(articleJsonLd).replace(/</g, "\\u003c") }}
      />

      <div className="mx-auto max-w-3xl px-4 py-10 sm:px-6 lg:px-8">
        <nav className="mb-6 flex items-center gap-2 font-body text-xs text-secondary-light">
          <Link href="/" className="font-medium text-secondary hover:text-primary">
            Ana sayfa
          </Link>
          <span>|</span>
          <Link href="/blog" className="font-medium text-secondary hover:text-primary">
            Blog
          </Link>
          <span>|</span>
          <span className="text-secondary-light">{post.title}</span>
        </nav>

        <span className="inline-block rounded-full bg-primary/10 px-3 py-1 font-body text-xs font-semibold text-primary">
          {post.category}
        </span>
        <h1 className="mt-4 font-display text-3xl font-bold leading-snug text-secondary sm:text-4xl">
          {post.title}
        </h1>
        <p className="mt-3 font-body text-sm text-secondary-light">
          {formatBlogDate(post.publishedAt)} · {post.readMinutes} dk okuma
        </p>

        <div className="relative mt-8 aspect-[16/9] w-full overflow-hidden rounded-xl bg-secondary/[0.04]">
          <Image
            src={post.coverImage}
            alt={post.title}
            fill
            sizes="(max-width: 768px) 100vw, 768px"
            priority
            className="object-cover"
          />
        </div>

        <div className="mt-10">
          <BlogPostBody blocks={post.blocks} />
        </div>

        <div className="mt-12 rounded-xl bg-secondary/[0.04] p-6 text-center">
          <p className="font-display text-lg font-semibold text-secondary">
            Doğru ürünü bulmak için yardıma mı ihtiyacınız var?
          </p>
          <p className="mt-1.5 font-body text-sm text-secondary-light">
            Kataloğumuzu inceleyin ya da ücretsiz kumaş/ahşap numunesi isteyin.
          </p>
          <Link
            href="/katalog"
            className="btn-sweep mt-4 inline-block rounded-full border border-primary/30 px-6 py-3 font-body text-sm font-semibold text-secondary"
          >
            Kataloğu İncele
          </Link>
        </div>
      </div>

      {relatedPosts.length > 0 && (
        <div className="border-t border-secondary/10 bg-secondary/[0.02] py-14">
          <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            <h2 className="font-display text-xl font-semibold text-secondary sm:text-2xl">
              Diğer Yazılar
            </h2>
            <div className="mt-8 grid grid-cols-1 gap-x-8 gap-y-12 sm:grid-cols-2 lg:grid-cols-3">
              {relatedPosts.map((related) => (
                <BlogCard key={related.slug} post={related} />
              ))}
            </div>
          </div>
        </div>
      )}
    </>
  );
}
