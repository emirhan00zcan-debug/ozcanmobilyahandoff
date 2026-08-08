"""
ADIM 1 / script 2 - Gercek olcuye kilitleme ve disa aktarim (Blender, arka planda)
generate_3d.py'nin urettigi ham .glb dosyasini Blender icinde islerini yapar:
  1) Urunun gercek cm olculerine (widthCm/heightCm/depthCm - bkz. prisma/schema.prisma
     Product modeli) gore X/Y/Z eksenlerinde 1:1 olcek kilitler (non-uniform scale).
  2) Orijini modelin taban-orta noktasina tasir; AR'da zemin algilandiginda mobilya
     tam zeminin ustune oturur (ARCore Scene Viewer / ARKit Quick Look yerlestirmeyi
     modelin orijinine gore yapar).
  3) Son .glb (Android / WebXR) ve .usdz (iOS Quick Look) dosyalarini yazar.

Bu dosya normal `python` ile degil, Blender'in kendi Python yorumlayicisiyla,
arka planda (--background) calisir - bkz. run.py / README.md.

  blender --background --factory-startup --python scale_and_export.py -- \\
    --in ham_model.glb --out-glb model.glb --out-usdz model.usdz \\
    --width-cm 120 --height-cm 200 --depth-cm 60

NOT (eksen varsayimi): Blender'in gltf ice aktaricisi glTF'in Y-up eksenini Blender'in
Z-up eksenine cevirir. Bu script varsayilan olarak X=Genislik, Y=Derinlik, Z=Yukseklik
kabul eder. Uretilen model yanlis yone bakiyorsa (genislik/derinlik ters olculuyorsa)
--swap-width-depth bayragini kullanin.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

import bpy


def parse_args() -> argparse.Namespace:
    argv = sys.argv
    argv = argv[argv.index("--") + 1 :] if "--" in argv else []

    parser = argparse.ArgumentParser()
    parser.add_argument("--in", dest="input", required=True, type=Path)
    parser.add_argument("--out-glb", required=True, type=Path)
    parser.add_argument("--out-usdz", required=True, type=Path)
    parser.add_argument("--width-cm", required=True, type=float)
    parser.add_argument("--height-cm", required=True, type=float)
    parser.add_argument("--depth-cm", required=True, type=float)
    parser.add_argument(
        "--swap-width-depth",
        action="store_true",
        help="Model yanlis yone bakiyorsa X/Y eksenlerini takas eder.",
    )
    return parser.parse_args(argv)


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for block_collection in (bpy.data.meshes, bpy.data.cameras, bpy.data.lights):
        for block in list(block_collection):
            if block.users == 0:
                block_collection.remove(block)


def import_and_join(path: Path):
    bpy.ops.import_scene.gltf(filepath=str(path))
    mesh_objects = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    if not mesh_objects:
        sys.exit("Hata: Ice aktarilan dosyada mesh bulunamadi.")

    bpy.ops.object.select_all(action="DESELECT")
    for obj in mesh_objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = mesh_objects[0]
    if len(mesh_objects) > 1:
        bpy.ops.object.join()
    return bpy.context.view_layer.objects.active


def world_bounds(obj):
    if not obj.data.vertices:
        sys.exit("Hata: Model bos (vertex yok).")
    corners = [obj.matrix_world @ v.co for v in obj.data.vertices]
    xs = [c.x for c in corners]
    ys = [c.y for c in corners]
    zs = [c.z for c in corners]
    return (min(xs), max(xs)), (min(ys), max(ys)), (min(zs), max(zs))


def main() -> None:
    args = parse_args()
    if not args.input.is_file():
        sys.exit(f"Hata: Girdi dosyasi bulunamadi: {args.input}")

    clear_scene()
    obj = import_and_join(args.input)

    (x_min, x_max), (y_min, y_max), (z_min, z_max) = world_bounds(obj)
    current_width = x_max - x_min
    current_depth = y_max - y_min
    current_height = z_max - z_min
    if min(current_width, current_depth, current_height) < 1e-6:
        sys.exit("Hata: Modelin bir veya daha fazla boyutu sifira cok yakin, olceklenemiyor.")

    target_width_m = args.width_cm / 100.0
    target_depth_m = args.depth_cm / 100.0
    target_height_m = args.height_cm / 100.0
    if args.swap_width_depth:
        target_width_m, target_depth_m = target_depth_m, target_width_m

    # Non-uniform olcek: her eksen kendi hedef gercek olcusune kilitlenir (pinch-to-scale
    # kullaniciya acilmayacagi icin - bkz. ArModelViewer ar-scale="fixed" - bu tek kilitleme
    # noktasidir).
    obj.scale.x *= target_width_m / current_width
    obj.scale.y *= target_depth_m / current_depth
    obj.scale.z *= target_height_m / current_height
    bpy.context.view_layer.update()
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)

    # Origin'i taban-orta noktasina tasi: AR zemin yerlestirmesi modelin origin'ine gore
    # yapilir, aksi halde mobilya zeminin altinda/ustunde havada gorunur.
    (x_min, x_max), (y_min, y_max), (z_min, z_max) = world_bounds(obj)
    obj.location.x -= (x_min + x_max) / 2
    obj.location.y -= (y_min + y_max) / 2
    obj.location.z -= z_min
    bpy.context.view_layer.update()
    bpy.ops.object.transform_apply(location=True, rotation=False, scale=False)

    args.out_glb.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(args.out_glb), export_format="GLB")
    print(f"Yazildi: {args.out_glb}")

    args.out_usdz.parent.mkdir(parents=True, exist_ok=True)
    # .usdz uzantisi Blender'in USD disa aktaricisina dokulari da iceren sikistirilmis
    # (zip) bir USD paketi uretmesini soyler (Universal Scene Description belgeleri).
    bpy.ops.wm.usd_export(filepath=str(args.out_usdz))
    print(f"Yazildi: {args.out_usdz}")


if __name__ == "__main__":
    main()
