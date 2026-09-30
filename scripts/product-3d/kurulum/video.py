"""Kurulum animasyonu karelerini adım başlıklı MP4'e çevirir.

Kareler SketchUp'ta üretilir:
    OzcanKurulum::Ayakkabilik.kaydet('C:/kareler')
Aynı klasördeki basliklar.json her adımın başlangıç saniyesini ve yazısını verir.

    python scripts/product-3d/kurulum/video.py C:/kareler kurulum.mp4
"""
import argparse
import glob
import json
import os
import shutil
import subprocess

from PIL import Image, ImageDraw, ImageFont

KOYU = (31, 35, 40)
FONT_DIR = os.path.join(os.environ.get("WINDIR", "C:/Windows"), "Fonts")


def yazi_tipi(boyut, kalin=False):
    for ad in ("segoeuib.ttf", "arialbd.ttf") if kalin else ("segoeui.ttf", "arial.ttf"):
        yol = os.path.join(FONT_DIR, ad)
        if os.path.exists(yol):
            return ImageFont.truetype(yol, boyut)
    return ImageFont.load_default()


def baslik_ciz(im, metin, alfa, ilerleme):
    w, h = im.size
    s = h / 720
    kat = Image.new("RGBA", im.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(kat)
    a = int(255 * alfa)
    no, _, govde = metin.partition(" · ")
    if not govde:  # numarasız başlık (kutu içeriği, bitiş)
        no, govde = "", metin
    f = yazi_tipi(round(26 * s))
    x, y, pad = round(36 * s), round(32 * s), round(14 * s)
    rozet = round(46 * s) if no else 0
    tw = d.textlength(govde, font=f)
    kutu_h = round(46 * s)
    d.rounded_rectangle([x, y, x + rozet + tw + 2 * pad, y + kutu_h], radius=round(10 * s),
                        fill=(255, 255, 255, int(235 * alfa)), outline=(210, 212, 216, a), width=max(1, round(s)))
    if no:
        d.rounded_rectangle([x, y, x + rozet, y + kutu_h], radius=round(10 * s), fill=KOYU + (a,))
        fn = yazi_tipi(round(26 * s), kalin=True)
        d.text((x + rozet / 2, y + kutu_h / 2), no, font=fn, fill=(255, 255, 255, a), anchor="mm")
    d.text((x + rozet + pad, y + kutu_h / 2), govde, font=f, fill=KOYU + (a,), anchor="lm")
    # alt ilerleme çubuğu
    d.rectangle([0, h - round(5 * s), round(w * ilerleme), h], fill=KOYU + (200,))
    return Image.alpha_composite(im.convert("RGBA"), kat).convert("RGB")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("kareler")
    ap.add_argument("cikti")
    ap.add_argument("--fps", type=int, default=25)
    a = ap.parse_args()

    with open(os.path.join(a.kareler, "basliklar.json"), encoding="utf-8") as f:
        basliklar = json.load(f)
    kareler = sorted(glob.glob(os.path.join(a.kareler, "f[0-9]*.png")))
    toplam = len(kareler) / a.fps
    ara = os.path.join(a.kareler, "_yazili")
    os.makedirs(ara, exist_ok=True)
    for yol in kareler:
        t = int(os.path.basename(yol)[1:6]) / a.fps
        bas, metin = [b for b in basliklar if b[0] <= t + 1e-6][-1]
        alfa = min(1.0, (t - bas) / 0.4)
        baslik_ciz(Image.open(yol), metin, alfa, t / toplam).save(os.path.join(ara, os.path.basename(yol)))

    ffmpeg = shutil.which("ffmpeg") or "ffmpeg"
    subprocess.run([ffmpeg, "-y", "-loglevel", "error", "-framerate", str(a.fps), "-i", os.path.join(ara, "f%05d.png"),
                    "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "18", "-movflags", "+faststart", a.cikti],
                   check=True)
    shutil.rmtree(ara)
    print(f"{a.cikti}: {len(kareler)} kare, {toplam:.1f} sn")


if __name__ == "__main__":
    main()
