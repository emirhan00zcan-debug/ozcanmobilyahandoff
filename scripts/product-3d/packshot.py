"""Acik Blender sahnesindeki SECILI urunden beyaz fon urun fotografi alir.

Uc aci: hero (3/4 sag), front (tam on), angle (3/4 sol, yukaridan).

    GUI       : Scripting sekmesi -> bu dosyayi ac -> urunu sec -> Run
    Arka plan : blender sahne.blend --background --python packshot.py

Isik, oto-pozlama ve beyaz fon kompoziti render.py'dan gelir; bu sahneden
alinan fotograflar spec'ten uretilenlerle ayni gorunsun diye. Sahneye
dokunmaz: gecici bir sahne acar, urunu oraya baglar, sonunda temizler.
"""

import importlib.util
from pathlib import Path

import bpy

# --- ayarlar ---------------------------------------------------------------
RENDER_PY = Path(r"C:\Users\pc\Downloads\ozcan-mobilya-handoff\scripts\product-3d\render.py")
OUT_DIR = ""              # bos = .blend dosyasinin yanina "packshot" klasoru
SHOTS = ("hero", "front", "angle")
SAMPLES = 256
RES = 2000
# ---------------------------------------------------------------------------

spec = importlib.util.spec_from_file_location("om_render", RENDER_PY)
render = importlib.util.module_from_spec(spec)
spec.loader.exec_module(render)

objs = [o for o in bpy.context.selected_objects if o.type == "MESH"]
if not objs:
    raise RuntimeError("Once urun mesh'lerini sec (oda/zemin/duvar haric).")

out_dir = Path(OUT_DIR) if OUT_DIR else Path(bpy.data.filepath).parent / "packshot"
if not OUT_DIR and not bpy.data.filepath:
    raise RuntimeError("Dosya kaydedilmemis: OUT_DIR'i elle yaz.")
out_dir.mkdir(parents=True, exist_ok=True)

scene = bpy.data.scenes.new("Packshot")
for obj in objs:
    scene.collection.objects.link(obj)

with bpy.context.temp_override(scene=scene, view_layer=scene.view_layers[0],
                               collection=scene.collection):
    render.setup_cycles(scene, SAMPLES, RES)
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"

    lo, hi = render.world_bbox(objs)
    center = ((lo.x + hi.x) / 2, (lo.y + hi.y) / 2)
    render.setup_studio(scene, lo, hi, center_xy=center)

    for name in SHOTS:
        shot = render.SHOTS[name]
        render.frame_camera(scene, objs, shot["azimuth"], shot["elevation"],
                            shot["lens"], shot["margin"], shot["look"],
                            center_xy=center)
        render.composite_on_white(scene, render.auto_exposure(scene))
        scene.render.filepath = str(out_dir / f"{name}.png")
        bpy.ops.render.render(write_still=True)
        print(f"[packshot] yazildi: {scene.render.filepath}")

# --- gecici sahneyi ve kurdugu isik/kamera/zemini kaldir
for obj in list(scene.collection.objects):
    if obj not in objs:
        bpy.data.objects.remove(obj, do_unlink=True)
bpy.data.scenes.remove(scene)
