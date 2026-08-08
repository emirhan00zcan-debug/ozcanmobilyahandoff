"""
Uctan uca calistirici - 4 urun fotografindan baslayip public/models/<slug>/ altina
model.glb + model.usdz uretir ve veritabanindaki Product.glbUrl/usdzUrl alanlarini gunceller.

Kullanim:
  python run.py --slug ornek-gardirop \\
    --front foto/on.jpg --side foto/yan.jpg --back foto/arka.jpg --detail foto/doku.jpg \\
    --width-cm 120 --height-cm 200 --depth-cm 60

Bkz. README.md - gereksinimler (MESHY_API_KEY, Blender kurulumu) ve adim adim aciklama icin.
"""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
import tempfile
from pathlib import Path

from dotenv import load_dotenv

REPO_ROOT = Path(__file__).resolve().parents[2]

# BLENDER_PATH (ve varsa MESHY_API_KEY) repo kokundeki .env'den otomatik yuklenir.
load_dotenv(REPO_ROOT / ".env")
PIPELINE_DIR = Path(__file__).resolve().parent


def run_generate_3d(front: Path, side: Path, back: Path, detail: Path, raw_output: Path) -> None:
    subprocess.run(
        [
            sys.executable,
            str(PIPELINE_DIR / "generate_3d.py"),
            "--front", str(front),
            "--side", str(side),
            "--back", str(back),
            "--detail", str(detail),
            "--output", str(raw_output),
        ],
        check=True,
    )


def run_scale_and_export(
    raw_glb: Path,
    out_glb: Path,
    out_usdz: Path,
    width_cm: float,
    height_cm: float,
    depth_cm: float,
    swap_width_depth: bool,
) -> None:
    blender_exe = os.environ.get("BLENDER_PATH", "blender")
    cmd = [
        blender_exe, "--background", "--factory-startup", "--python",
        str(PIPELINE_DIR / "scale_and_export.py"), "--",
        "--in", str(raw_glb),
        "--out-glb", str(out_glb),
        "--out-usdz", str(out_usdz),
        "--width-cm", str(width_cm),
        "--height-cm", str(height_cm),
        "--depth-cm", str(depth_cm),
    ]
    if swap_width_depth:
        cmd.append("--swap-width-depth")
    try:
        subprocess.run(cmd, check=True)
    except FileNotFoundError:
        sys.exit(
            f"Hata: Blender calistirilamadi ('{blender_exe}'). Blender'i kurun "
            "(https://www.blender.org/download/) ve PATH'e ekleyin ya da BLENDER_PATH "
            "ortam degiskenini blender.exe'nin tam yoluna ayarlayin."
        )


def apply_urls_to_db(slug: str, glb_public_path: str, usdz_public_path: str) -> None:
    subprocess.run(
        [
            "npx", "tsx", str(PIPELINE_DIR / "apply-model-urls.ts"),
            "--slug", slug,
            "--glb", glb_public_path,
            "--usdz", usdz_public_path,
        ],
        check=True,
        cwd=str(REPO_ROOT),
        shell=(os.name == "nt"),
    )


def main() -> None:
    parser = argparse.ArgumentParser(description="Fotograftan mobil AR modeline uctan uca hat.")
    parser.add_argument("--slug", required=True, help="Urunun Prisma slug'i (prisma/schema.prisma Product.slug)")
    parser.add_argument("--front", required=True, type=Path)
    parser.add_argument("--side", required=True, type=Path)
    parser.add_argument("--back", required=True, type=Path)
    parser.add_argument("--detail", required=True, type=Path)
    parser.add_argument("--width-cm", required=True, type=float)
    parser.add_argument("--height-cm", required=True, type=float)
    parser.add_argument("--depth-cm", required=True, type=float)
    parser.add_argument("--swap-width-depth", action="store_true")
    parser.add_argument(
        "--skip-db-update", action="store_true",
        help="Sadece model.glb/model.usdz dosyalarini uret, veritabanini guncelleme",
    )
    args = parser.parse_args()

    product_dir = REPO_ROOT / "public" / "models" / args.slug
    out_glb = product_dir / "model.glb"
    out_usdz = product_dir / "model.usdz"

    with tempfile.TemporaryDirectory() as tmp:
        raw_glb = Path(tmp) / "raw.glb"
        print(f"[1/3] '{args.slug}' icin ham 3D model uretiliyor (Meshy AI)...")
        run_generate_3d(args.front, args.side, args.back, args.detail, raw_glb)

        print("[2/3] Gercek olculere kilitleniyor ve GLB/USDZ disa aktariliyor (Blender)...")
        run_scale_and_export(
            raw_glb, out_glb, out_usdz,
            args.width_cm, args.height_cm, args.depth_cm, args.swap_width_depth,
        )

    if args.skip_db_update:
        print(f"Tamamlandi. Dosyalar hazir: {out_glb}, {out_usdz}")
        return

    print("[3/3] Veritabani guncelleniyor (Product.glbUrl / usdzUrl)...")
    apply_urls_to_db(args.slug, f"/models/{args.slug}/model.glb", f"/models/{args.slug}/model.usdz")
    print("Tamamlandi.")


if __name__ == "__main__":
    main()
