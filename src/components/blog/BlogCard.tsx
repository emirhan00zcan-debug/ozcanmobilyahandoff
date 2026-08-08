import Image from "next/image";
import Link from "next/link";
import type { BlogPost } from "@/lib/data/blog-posts";
import { formatBlogDate } from "@/lib/data/blog-posts";

type Props = { post: BlogPost };

export default function BlogCard({ post }: Props) {
  return (
    <Link href={`/blog/${post.slug}`} className="group flex flex-col">
      <div className="relative aspect-[4/3] overflow-hidden rounded-xl bg-secondary/[0.04]">
        <Image
          src={post.coverImage}
          alt={post.title}
          fill
          sizes="(max-width: 640px) 100vw, (max-width: 1024px) 50vw, 33vw"
          className="object-cover transition-transform duration-500 ease-in-out group-hover:scale-105"
        />
        <span className="absolute left-3 top-3 rounded-full bg-white/90 px-2.5 py-1 font-body text-[11px] font-semibold text-secondary backdrop-blur-sm">
          {post.category}
        </span>
      </div>
      <div className="mt-3.5 space-y-1.5">
        <p className="font-body text-[11px] font-medium uppercase tracking-wider text-secondary-light">
          {formatBlogDate(post.publishedAt)} · {post.readMinutes} dk okuma
        </p>
        <h3 className="font-display text-base font-semibold leading-snug text-secondary transition-colors group-hover:text-primary">
          {post.title}
        </h3>
        <p className="font-body text-sm leading-relaxed text-secondary-light line-clamp-2">
          {post.excerpt}
        </p>
      </div>
    </Link>
  );
}
