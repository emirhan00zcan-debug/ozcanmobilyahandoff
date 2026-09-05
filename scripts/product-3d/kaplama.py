r"""Kartela taramalarini urun panellerine kaplama olarak uygular.

packshot.py'den ONCE calistirilir, ikisi ayni argumanlari okur:

    blender sahne.blend -b --python kaplama.py --python packshot.py -- \
        --obj Dolap --govde vadimese --minder "koton gri" --out C:\cikti

Panel adina gore malzeme secer: Minder -> kumas, Kapak_Kulpu -> aluminyum,
Kapak -> kapak dekoru, geri kalan her sey -> govde dekoru.

Kutu izdusumu (box projection) + dunya konumu kullanilir: modelde UV olmasi
gerekmez, damar her yuzeyde dogru yonde akar ve modelin yerel birimi ne olursa
olsun olcek sasmaz. Gorselin piksel orani korunur; tarama gercek bir 2.1 m
yuksekliginde panel kabul edilir.
"""

import argparse
import sys
import unicodedata
from pathlib import Path

import bpy

KARTELA = Path(r"C:\Users\pc\OneDrive\Masaüstü\yıldız entegre kartela")
PANEL_YUKSEKLIGI_M = 2.1   # taramanin temsil ettigi gercek panel yuksekligi


def _sadelestir(ad):
    """Turkce karakter ve bosluklardan bagimsiz eslestirme icin."""
    ad = unicodedata.normalize("NFKD", ad.lower())
    return "".join(c for c in ad if c.isalnum())


def dekor_dosyasi(ad):
    hedef = _sadelestir(ad)
    for yol in sorted(KARTELA.iterdir()):
        if yol.suffix.lower() in (".jpg", ".png") and _sadelestir(yol.stem) == hedef:
            return yol
    secenek = ", ".join(sorted(y.stem for y in KARTELA.iterdir() if y.suffix.lower() in (".jpg", ".png")))
    raise SystemExit(f"Kartelada '{ad}' yok. Mevcut: {secenek}")


def dekor_materyali(ad, puruzluluk=0.38, kabartma=0.12):
    yol = dekor_dosyasi(ad)
    mat = bpy.data.materials.new(f"Kaplama {ad}")
    if bpy.app.version < (5, 0, 0):
        mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()

    gorsel = bpy.data.images.load(str(yol), check_existing=True)
    en_m = PANEL_YUKSEKLIGI_M * gorsel.size[0] / gorsel.size[1]

    # Dunya konumu: modelin yerel birimi (bu dosyada cm) ne olursa olsun dokunun
    # olcegi metre cinsinden dogru kalir; obje koordinati kullanilsa 100 kat kayardi
    koord = nt.nodes.new("ShaderNodeNewGeometry")
    esleme = nt.nodes.new("ShaderNodeMapping")
    esleme.inputs["Scale"].default_value = (1 / en_m, 1 / en_m, 1 / PANEL_YUKSEKLIGI_M)
    doku = nt.nodes.new("ShaderNodeTexImage")
    doku.image = gorsel
    doku.projection = "BOX"          # UV gerektirmez, her yuze dogru yonde duser
    doku.projection_blend = 0.2
    kabart = nt.nodes.new("ShaderNodeBump")
    kabart.inputs["Strength"].default_value = kabartma
    kabart.inputs["Distance"].default_value = 0.0004
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Roughness"].default_value = puruzluluk
    cikis = nt.nodes.new("ShaderNodeOutputMaterial")

    nt.links.new(koord.outputs["Position"], esleme.inputs["Vector"])
    nt.links.new(esleme.outputs["Vector"], doku.inputs["Vector"])
    nt.links.new(doku.outputs["Color"], bsdf.inputs["Base Color"])
    nt.links.new(doku.outputs["Color"], kabart.inputs["Height"])
    nt.links.new(kabart.outputs["Normal"], bsdf.inputs["Normal"])
    nt.links.new(bsdf.outputs["BSDF"], cikis.inputs["Surface"])
    return mat


def aluminyum():
    mat = bpy.data.materials.new("Aluminyum")
    if bpy.app.version < (5, 0, 0):
        mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Base Color"].default_value = (0.62, 0.63, 0.64, 1.0)
    bsdf.inputs["Metallic"].default_value = 1.0
    bsdf.inputs["Roughness"].default_value = 0.28
    cikis = nt.nodes.new("ShaderNodeOutputMaterial")
    nt.links.new(bsdf.outputs["BSDF"], cikis.inputs["Surface"])
    return mat


ap = argparse.ArgumentParser()
ap.add_argument("--obj", action="append", required=True)
ap.add_argument("--govde", default="vadimeşe")
ap.add_argument("--kapak", help="verilmezse govde ile ayni")
ap.add_argument("--minder", default="koton gri")
args, _ = ap.parse_known_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])

govde = dekor_materyali(args.govde)
kapak = govde if not args.kapak else dekor_materyali(args.kapak)
# keten dokusu piksel altinda kaldigi icin guclu kabartma moire/serit yapiyor;
# gercekte de bu dekor 1 m mesafeden duz gri okunur
minder = dekor_materyali(args.minder, puruzluluk=0.7, kabartma=0.05)
metal = aluminyum()

stack = [bpy.data.objects[ad] for ad in args.obj]
sayac = {}
while stack:
    obj = stack.pop()
    stack.extend(obj.children)
    if obj.type != "MESH":
        continue
    parca = (obj.parent.name if obj.parent else obj.name).rstrip("0123456789")
    mat = {"Minder": minder, "Kapak": kapak, "Kapak_Kulpu": metal}.get(parca, govde)
    obj.data.materials.clear()
    obj.data.materials.append(mat)
    sayac[mat.name] = sayac.get(mat.name, 0) + 1

print("[kaplama] " + ", ".join(f"{ad}: {n} panel" for ad, n in sorted(sayac.items())))
