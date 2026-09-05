r"""Secili urune IKEA tipi urun fotografi acisi kurar (render almaz).

Blender'da Scripting sekmesi -> bu dosyayi ac -> urunu sec -> Run -> Numpad 0.

Acilar packshot.py ile ayni yerden (render.py'daki SHOTS) geldigi icin burada
gordugun kadraj, render'dan cikacak kadrajin aynisidir.
"""

import importlib.util
from pathlib import Path

import bpy

# --- ayarlar ---------------------------------------------------------------
ACI = "hero"     # hero = 3/4 sag | front = tam on | angle = 3/4 sol, yukaridan
RES = 2000       # kare (1:1) cikti
RENDER_PY = Path(r"C:\Users\pc\Downloads\ozcan-mobilya-handoff\scripts\product-3d\render.py")
# ---------------------------------------------------------------------------

spec = importlib.util.spec_from_file_location("om_render", RENDER_PY)
render = importlib.util.module_from_spec(spec)
spec.loader.exec_module(render)

# Secilenlerin altindaki tum mesh'ler: bos bir ust obje secmek de yeter
objs, stack, seen = [], list(bpy.context.selected_objects), set()
while stack:
    obj = stack.pop()
    if obj.name in seen:
        continue
    seen.add(obj.name)
    if obj.type == "MESH":
        objs.append(obj)
    stack.extend(obj.children)
if not objs:
    raise RuntimeError("Once urun mesh'lerini sec (oda/zemin/duvar haric).")

scene = bpy.context.scene
scene.render.resolution_x = scene.render.resolution_y = RES

# onceki calistirmadan kalan kamerayi temizle, tekrar tekrar birikmesinler
eski = bpy.data.objects.get("IKEA_Kamera")
if eski:
    bpy.data.objects.remove(eski, do_unlink=True)

lo, hi = render.world_bbox(objs)
shot = render.SHOTS[ACI]
cam = render.frame_camera(scene, objs, shot["azimuth"], shot["elevation"],
                          shot["lens"], shot["margin"], shot["look"],
                          center_xy=((lo.x + hi.x) / 2, (lo.y + hi.y) / 2))
cam.name = cam.data.name = "IKEA_Kamera"

print(f"[kamera] {ACI}: {shot['lens']}mm, az {shot['azimuth']}, el {shot['elevation']}  |  "
      f"{len(objs)} mesh, olcu {(hi.x - lo.x) * 1000:.0f} x {(hi.y - lo.y) * 1000:.0f} x "
      f"{(hi.z - lo.z) * 1000:.0f} mm")
