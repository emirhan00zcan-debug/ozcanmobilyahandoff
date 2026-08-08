// run.py'nin son adimi: uretilen model.glb / model.usdz icin public/ altindaki yollari
// ilgili Product satirina yazar (bkz. prisma/schema.prisma Product.glbUrl/usdzUrl).
//
// Kullanim: npx tsx scripts/ar-pipeline/apply-model-urls.ts --slug <slug> --glb <path> --usdz <path>

import { prisma } from "../../src/lib/prisma";

function readArg(name: string): string {
  const idx = process.argv.indexOf(`--${name}`);
  const value = idx === -1 ? undefined : process.argv[idx + 1];
  if (!value) {
    console.error(`Eksik argüman: --${name}`);
    process.exit(1);
  }
  return value;
}

async function main() {
  const slug = readArg("slug");
  const glbUrl = readArg("glb");
  const usdzUrl = readArg("usdz");

  const product = await prisma.product.update({
    where: { slug },
    data: { glbUrl, usdzUrl },
  });

  console.log(`Güncellendi: ${product.name} (${product.slug})`);
  console.log(`  glbUrl:  ${glbUrl}`);
  console.log(`  usdzUrl: ${usdzUrl}`);
}

main()
  .catch((err) => {
    console.error(err);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
