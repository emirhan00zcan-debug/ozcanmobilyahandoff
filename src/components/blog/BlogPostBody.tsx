import Image from "next/image";
import type { BlogBlock } from "@/lib/data/blog-posts";

type Props = { blocks: BlogBlock[] };

export default function BlogPostBody({ blocks }: Props) {
  return (
    <div className="space-y-6">
      {blocks.map((block, i) => {
        switch (block.type) {
          case "paragraph":
            return (
              <p key={i} className="font-body text-base leading-relaxed text-secondary-light">
                {block.text}
              </p>
            );
          case "heading":
            return (
              <h2 key={i} className="pt-4 font-display text-xl font-semibold text-secondary sm:text-2xl">
                {block.text}
              </h2>
            );
          case "quote":
            return (
              <blockquote
                key={i}
                className="border-l-2 border-primary py-1 pl-5 font-display text-lg italic leading-relaxed text-secondary"
              >
                {block.text}
              </blockquote>
            );
          case "image":
            return (
              <figure key={i} className="relative overflow-hidden rounded-xl">
                <div className="relative aspect-[16/10] w-full overflow-hidden rounded-xl bg-secondary/[0.04]">
                  <Image
                    src={block.src}
                    alt={block.alt}
                    fill
                    sizes="(max-width: 768px) 100vw, 720px"
                    className="object-cover"
                  />
                </div>
                {block.caption && (
                  <figcaption className="mt-2 font-body text-xs text-secondary-light">
                    {block.caption}
                  </figcaption>
                )}
              </figure>
            );
          default:
            return null;
        }
      })}
    </div>
  );
}
