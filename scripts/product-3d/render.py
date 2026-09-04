"""Blender headless render — parts.json'dan urun fotografi uretir.

Kullanim:
  blender --background --python scripts/product-3d/render.py -- \
      --parts out/<id>/<id>-60x90.parts.json --color beyaz --shot hero --out foo.png

Cikti: beyaz fonlu packshot (film transparent + shadow catcher -> saf beyaz kompozit).
"""

import argparse
import json
import math
import sys
from pathlib import Path

import bpy
import bmesh
from mathutils import Vector, Euler

MM = 0.001


# ----------------------------------------------------------------------------
# sahne temizligi / motor
# ----------------------------------------------------------------------------

def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.length_unit = "MILLIMETERS"
    return scene


def setup_cycles(scene, samples, res, transparent=True):
    scene.render.engine = "CYCLES"
    scene.cycles.samples = samples
    scene.cycles.use_denoising = True
    scene.cycles.denoiser = "OPENIMAGEDENOISE"
    scene.cycles.use_adaptive_sampling = True
    scene.cycles.adaptive_threshold = 0.01
    scene.cycles.max_bounces = 12
    scene.cycles.transmission_bounces = 8
    scene.cycles.caustics_reflective = False
    scene.cycles.caustics_refractive = False

    scene.render.resolution_x = res
    scene.render.resolution_y = res
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = transparent
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA" if transparent else "RGB"
    scene.render.image_settings.compression = 15

    prefs = bpy.context.preferences.addons["cycles"].preferences
    for backend in ("OPTIX", "CUDA", "NONE"):
        if backend == "NONE":
            scene.cycles.device = "CPU"
            print("[render] GPU bulunamadi, CPU kullaniliyor")
            break
        try:
            prefs.compute_device_type = backend
        except TypeError:
            continue
        prefs.get_devices()
        gpus = [d for d in prefs.devices if d.type == backend]
        if gpus:
            for d in prefs.devices:
                d.use = d.type in (backend, "CPU")
            scene.cycles.device = "GPU"
            print(f"[render] {backend}: {', '.join(d.name for d in gpus)}")
            break


# ----------------------------------------------------------------------------
# malzemeler
# ----------------------------------------------------------------------------

def hex_to_linear(hexstr):
    h = hexstr.lstrip("#")
    srgb = [int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)]
    return tuple(c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in srgb) + (1.0,)


def _new_mat(name):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    out.location = (400, 0)
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    return mat, nt, bsdf


def mat_melamine_solid(name, hexstr, roughness):
    """Duz renk melamin kapli suntalam: ince kabartma dokusu + hafif parlaklik."""
    mat, nt, bsdf = _new_mat(name)
    bsdf.inputs["Base Color"].default_value = hex_to_linear(hexstr)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["IOR"].default_value = 1.5

    coord = nt.nodes.new("ShaderNodeTexCoord")
    coord.location = (-900, -300)
    noise = nt.nodes.new("ShaderNodeTexNoise")
    noise.location = (-700, -300)
    noise.inputs["Scale"].default_value = 900.0
    noise.inputs["Detail"].default_value = 4.0
    noise.inputs["Roughness"].default_value = 0.6
    bump = nt.nodes.new("ShaderNodeBump")
    bump.location = (-450, -300)
    bump.inputs["Strength"].default_value = 0.12
    bump.inputs["Distance"].default_value = 0.0003
    nt.links.new(coord.outputs["Object"], noise.inputs["Vector"])
    nt.links.new(noise.outputs["Fac"], bump.inputs["Height"])
    nt.links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])

    # parlaklik dalgalanmasi — tek duze roughness plastik gibi durur
    rough_noise = nt.nodes.new("ShaderNodeTexNoise")
    rough_noise.location = (-700, -80)
    rough_noise.inputs["Scale"].default_value = 420.0
    rough_noise.inputs["Detail"].default_value = 3.0
    rmap = nt.nodes.new("ShaderNodeMapRange")
    rmap.location = (-450, -80)
    rmap.inputs["From Min"].default_value = 0.3
    rmap.inputs["From Max"].default_value = 0.7
    rmap.inputs["To Min"].default_value = max(0.05, roughness - 0.025)
    rmap.inputs["To Max"].default_value = roughness + 0.025
    nt.links.new(coord.outputs["Object"], rough_noise.inputs["Vector"])
    nt.links.new(rough_noise.outputs["Fac"], rmap.inputs["Value"])
    nt.links.new(rmap.outputs["Result"], bsdf.inputs["Roughness"])
    return mat


def _axis_scale(axis, value):
    return tuple(value if i == "XYZ".index(axis) else 1.0 for i in "XYZ")


def mat_melamine_wood(name, hexstr, dark_hex, roughness, long_axis="Z", mid_axis="X"):
    """Ahsap desenli melamin (Sonoma mese vb.).

    Mese deseni = damar boyunca uzun, surekli ve DUZENSIZ cizgiler.
      - long_axis: damarin uzadigi eksen (panelin en uzun kenari)
      - mid_axis : desenin degistigi eksen (panelin ikinci uzun kenari) -> bant yonu
    Koordinatlar long_axis'te sikistirilir; boylece bozulma gurultusu o yonde yavas
    degisir ve cizgiler kopmadan uzar. Ikinci bir gerilmis gurultu, cizgi araligini
    ve kontrastini yer yer degistirerek "oluklu panel" gorunumunu kirar.
    """
    mat, nt, bsdf = _new_mat(name)
    bsdf.inputs["IOR"].default_value = 1.5

    coord = nt.nodes.new("ShaderNodeTexCoord")
    coord.location = (-1400, 0)

    mapping = nt.nodes.new("ShaderNodeMapping")
    mapping.location = (-1200, 0)
    mapping.inputs["Scale"].default_value = _axis_scale(long_axis, 0.09)
    nt.links.new(coord.outputs["Object"], mapping.inputs["Vector"])

    wave = nt.nodes.new("ShaderNodeTexWave")
    wave.location = (-950, 120)
    wave.wave_type = "BANDS"
    wave.bands_direction = mid_axis
    wave.wave_profile = "SIN"
    wave.inputs["Scale"].default_value = 6.5
    wave.inputs["Distortion"].default_value = 6.0
    wave.inputs["Detail"].default_value = 4.0
    wave.inputs["Detail Scale"].default_value = 1.6
    nt.links.new(mapping.outputs["Vector"], wave.inputs["Vector"])

    # damar araligini/kontrastini bozan, damar boyunca gerilmis gurultu
    figure = nt.nodes.new("ShaderNodeTexNoise")
    figure.location = (-950, -120)
    figure.inputs["Scale"].default_value = 5.5
    figure.inputs["Detail"].default_value = 5.0
    figure.inputs["Roughness"].default_value = 0.55
    nt.links.new(mapping.outputs["Vector"], figure.inputs["Vector"])

    blend = nt.nodes.new("ShaderNodeMix")
    blend.data_type = "FLOAT"
    blend.location = (-720, 0)
    blend.inputs["Factor"].default_value = 0.62
    nt.links.new(wave.outputs["Fac"], blend.inputs[2])
    nt.links.new(figure.outputs["Fac"], blend.inputs[3])

    # ince gozenek cizgileri
    pore = nt.nodes.new("ShaderNodeTexWave")
    pore.location = (-950, -360)
    pore.wave_type = "BANDS"
    pore.bands_direction = mid_axis
    pore.wave_profile = "SIN"
    pore.inputs["Scale"].default_value = 48.0
    pore.inputs["Distortion"].default_value = 3.0
    pore.inputs["Detail"].default_value = 2.0
    nt.links.new(mapping.outputs["Vector"], pore.inputs["Vector"])

    grain = nt.nodes.new("ShaderNodeMix")
    grain.data_type = "FLOAT"
    grain.location = (-520, -80)
    grain.inputs["Factor"].default_value = 0.11
    nt.links.new(blend.outputs[0], grain.inputs[2])
    nt.links.new(pore.outputs["Fac"], grain.inputs[3])

    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.location = (-320, 0)
    ramp.color_ramp.interpolation = "B_SPLINE"
    ramp.color_ramp.elements[0].position = 0.40
    ramp.color_ramp.elements[0].color = hex_to_linear(dark_hex)
    ramp.color_ramp.elements[1].position = 0.72
    ramp.color_ramp.elements[1].color = hex_to_linear(hexstr)
    nt.links.new(grain.outputs[0], ramp.inputs["Fac"])
    nt.links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])

    rmap = nt.nodes.new("ShaderNodeMapRange")
    rmap.location = (-320, -300)
    rmap.inputs["To Min"].default_value = roughness + 0.05
    rmap.inputs["To Max"].default_value = max(0.05, roughness - 0.03)
    nt.links.new(grain.outputs[0], rmap.inputs["Value"])
    nt.links.new(rmap.outputs["Result"], bsdf.inputs["Roughness"])

    # melamin baskidir; kabartma neredeyse yok — fazlasi "oluklu panel" yapar
    bump = nt.nodes.new("ShaderNodeBump")
    bump.location = (-320, -520)
    bump.inputs["Strength"].default_value = 0.04
    bump.inputs["Distance"].default_value = 0.0002
    nt.links.new(grain.outputs[0], bump.inputs["Height"])
    nt.links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
    return mat


def mat_metal(name, hexstr, roughness):
    mat, nt, bsdf = _new_mat(name)
    bsdf.inputs["Base Color"].default_value = hex_to_linear(hexstr)
    bsdf.inputs["Metallic"].default_value = 1.0
    bsdf.inputs["Roughness"].default_value = roughness
    return mat


def mat_plastic(name, hexstr, roughness):
    mat, nt, bsdf = _new_mat(name)
    bsdf.inputs["Base Color"].default_value = hex_to_linear(hexstr)
    bsdf.inputs["Roughness"].default_value = roughness
    return mat


def panel_axes(size_mm):
    """Panelin (damar ekseni, desen ekseni) ciftini olculerinden cikarir.

    En uzun kenar damar yonu, ikinci uzun kenar desenin degistigi yon, en kisa
    kenar da panel kalinligidir. Boylece kapak, yan panel ve raf ayni levhadan
    kesilmis gibi dogru yonde desenlenir.
    """
    order = sorted(zip(size_mm, "XYZ"), reverse=True)
    return order[0][1], order[1][1]


def build_materials(model, color_code):
    """Govde malzemesini panel eksenine gore veren bir fabrika dondurur."""
    color = next(c for c in model["colors"] if c["code"] == color_code)
    cache = {}

    def body(size_mm):
        if color.get("kind") != "wood":
            if "solid" not in cache:
                cache["solid"] = mat_melamine_solid("OM Govde", color["hex"], color["roughness"])
            return cache["solid"]
        key = panel_axes(size_mm)
        if key not in cache:
            cache[key] = mat_melamine_wood(f"OM Govde {key[0]}{key[1]}", color["hex"],
                                           color["grain_dark"], color["roughness"], *key)
        return cache[key]

    return {
        "body": body,
        "hardware": mat_metal("OM Kulp", "#1C1C1E", 0.35),
        "foot": mat_plastic("OM Ayak", "#202124", 0.55),
    }, color


# ----------------------------------------------------------------------------
# geometri
# ----------------------------------------------------------------------------

def add_box(name, pos_mm, size_mm, origin_shift):
    dx, dy, dz = (v * MM for v in size_mm)
    mesh = bpy.data.meshes.new(name)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)

    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bmesh.ops.scale(bm, vec=Vector((dx, dy, dz)), verts=bm.verts)
    bm.to_mesh(mesh)
    bm.free()

    obj.location = (
        (pos_mm[0] + size_mm[0] / 2) * MM + origin_shift[0],
        (pos_mm[1] + size_mm[1] / 2) * MM + origin_shift[1],
        (pos_mm[2] + size_mm[2] / 2) * MM + origin_shift[2],
    )
    return obj


def add_cylinder(name, pos_mm, direction, dia_mm, len_mm, origin_shift):
    r = dia_mm / 2 * MM
    depth = len_mm * MM
    mesh = bpy.data.meshes.new(name)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)

    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=64,
                          radius1=r, radius2=r, depth=depth)
    bm.to_mesh(mesh)
    bm.free()

    d = Vector(direction).normalized()
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = d.to_track_quat("Z", "Y")
    center = Vector((pos_mm[0] * MM, pos_mm[1] * MM, pos_mm[2] * MM)) + d * (depth / 2) + Vector(origin_shift)
    obj.location = center
    return obj


def bevel_and_smooth(obj, width_mm):
    mod = obj.modifiers.new("Pah", "BEVEL")
    mod.width = width_mm * MM
    mod.segments = 2
    mod.limit_method = "ANGLE"
    mod.angle_limit = math.radians(30)
    mod.harden_normals = False
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.shade_smooth_by_angle(angle=math.radians(35))
    obj.select_set(False)


def build_product(model, materials, door_open_deg=0.0):
    W = model["outer_mm"]["w"]
    D = model["outer_mm"]["d"]
    bevel = model["standards"]["render_bevel"]
    shift = (-W / 2 * MM, -D / 2 * MM, 0.0)

    objects = []
    door_obj = None
    door_part = None

    for part in model["parts"]:
        if part["shape"] == "box":
            obj = add_box(part["name"], part["pos"], part["size"], shift)
            if part["material"] in ("body", "back"):
                obj.data.materials.append(materials["body"](part["size"]))
            else:
                obj.data.materials.append(materials[part["material"]])
            bevel_and_smooth(obj, bevel)
            if part["id"] == "kapak":
                door_obj, door_part = obj, part
        else:
            obj = add_cylinder(part["name"], part["pos"], part["dir"], part["d"], part["len"], shift)
            obj.data.materials.append(materials[part["material"]])
            bevel_and_smooth(obj, 0.2)
        objects.append(obj)

    if door_open_deg and door_obj is not None:
        pivot = Vector((door_part["pivot"][0] * MM + shift[0],
                        door_part["pivot"][1] * MM + shift[1],
                        0.0))
        angle = math.radians(-door_open_deg)
        knobs = [o for o in objects if o.name.startswith("Kulp")]
        for o in [door_obj] + knobs:
            rel = o.location - pivot
            cos_a, sin_a = math.cos(angle), math.sin(angle)
            o.location = pivot + Vector((rel.x * cos_a - rel.y * sin_a,
                                         rel.x * sin_a + rel.y * cos_a,
                                         rel.z))
            o.rotation_mode = "XYZ"
            o.rotation_euler.rotate(Euler((0, 0, angle), "XYZ"))

    return objects


def world_bbox(objects):
    lo = Vector((1e9, 1e9, 1e9))
    hi = Vector((-1e9, -1e9, -1e9))
    deps = bpy.context.evaluated_depsgraph_get()
    for obj in objects:
        ev = obj.evaluated_get(deps)
        for corner in ev.bound_box:
            p = ev.matrix_world @ Vector(corner)
            lo = Vector((min(lo[i], p[i]) for i in range(3)))
            hi = Vector((max(hi[i], p[i]) for i in range(3)))
    return lo, hi


# ----------------------------------------------------------------------------
# isik / kamera
# ----------------------------------------------------------------------------

def add_area_light(name, loc, target, size, power, spread=None):
    data = bpy.data.lights.new(name, type="AREA")
    data.shape = "RECTANGLE" if isinstance(size, (list, tuple)) else "SQUARE"
    if isinstance(size, (list, tuple)):
        data.size, data.size_y = size
    else:
        data.size = size
    data.energy = power
    if spread is not None:
        data.spread = math.radians(spread)
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    obj.location = loc
    direction = (Vector(target) - Vector(loc)).normalized()
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = direction.to_track_quat("-Z", "Y")
    return obj


def setup_studio(scene, lo, hi):
    """Klasik packshot: tek golge veren key + golgesiz dolgu/rim/tepe softbox.

    Isik gucleri diag^2 ile olceklenir -> her urun boyutunda ayni pozlama.
    """
    center = (lo + hi) / 2
    height = hi.z - lo.z
    diag = (hi - lo).length
    k = diag * diag

    world = bpy.data.worlds.new("Studio")
    scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    bg.inputs["Color"].default_value = (0.55, 0.56, 0.58, 1.0)
    bg.inputs["Strength"].default_value = 0.45

    key = add_area_light("Key", (-diag * 0.95, -diag * 1.10, height * 1.45),
                         (center.x, center.y, center.z),
                         (diag * 1.05, diag * 1.05), 95 * k)

    # Dolgu yandan gelmeli — fazla one alinirsa gorunen yan yuz karanlik kalir
    fill = add_area_light("Fill", (diag * 1.70, -diag * 0.30, height * 0.85),
                          (center.x, center.y, center.z),
                          (diag * 2.0, diag * 2.0), 78 * k)

    rim = add_area_light("Rim", (diag * 0.60, diag * 1.35, height * 1.70),
                         (center.x, center.y, center.z * 1.15),
                         (diag * 1.0, diag * 1.0), 46 * k)

    top = add_area_light("Top", (0, -diag * 0.20, height * 2.4),
                         (center.x, center.y, center.z),
                         (diag * 1.2, diag * 1.2), 60 * k)

    # Key + tepe golge dusursun (temas golgesi); dolgu ve rim golgesiz kalsin
    for light in (fill, rim):
        light.data.use_shadow = False

    ground = bpy.data.meshes.new("Zemin")
    floor = bpy.data.objects.new("Zemin", ground)
    bpy.context.collection.objects.link(floor)
    bm = bmesh.new()
    bmesh.ops.create_grid(bm, x_segments=1, y_segments=1, size=diag * 6)
    bm.to_mesh(ground)
    bm.free()
    floor.location = (0, 0, lo.z)
    floor.is_shadow_catcher = True
    return floor


def frame_camera(scene, objects, azimuth, elevation, lens, margin, look_at_frac=0.5):
    from bpy_extras.object_utils import world_to_camera_view

    lo, hi = world_bbox(objects)
    target = Vector((0.0, (lo.y + hi.y) / 2, lo.z + (hi.z - lo.z) * look_at_frac))
    diag = (hi - lo).length

    cam_data = bpy.data.cameras.new("Kamera")
    cam_data.lens = lens
    cam_data.sensor_width = 36
    cam = bpy.data.objects.new("Kamera", cam_data)
    bpy.context.collection.objects.link(cam)
    scene.camera = cam

    az, el = math.radians(azimuth), math.radians(elevation)
    dir_v = Vector((math.sin(az) * math.cos(el), -math.cos(az) * math.cos(el), math.sin(el)))

    dist = diag * 2.0
    for _ in range(6):
        cam.location = target + dir_v * dist
        cam.rotation_mode = "QUATERNION"
        cam.rotation_quaternion = (-dir_v).to_track_quat("-Z", "Y")
        bpy.context.view_layer.update()

        worst = 0.0
        for obj in objects:
            for corner in obj.bound_box:
                p = obj.matrix_world @ Vector(corner)
                ndc = world_to_camera_view(scene, cam, p)
                worst = max(worst, abs(ndc.x - 0.5) * 2, abs(ndc.y - 0.5) * 2)
        if worst <= 0:
            break
        dist *= worst / margin
    return cam


# ----------------------------------------------------------------------------
# kompozit: saf beyaz fon
# ----------------------------------------------------------------------------

def composite_on_white(scene, exposure_stops=0.0):
    """Urunu saf beyaz (255) fon uzerine bindirir.

    Pozlama burada, alpha-over'dan ONCE yalnizca urun katmanina uygulanir;
    sahne pozlamasi kullanilsaydi beyaz fon da kararirdi.
    """
    scene.use_nodes = True
    nt = scene.node_tree
    nt.nodes.clear()
    rl = nt.nodes.new("CompositorNodeRLayers")
    rl.location = (-700, 0)
    expo = nt.nodes.new("CompositorNodeExposure")
    expo.location = (-450, 0)
    expo.inputs["Exposure"].default_value = exposure_stops
    white = nt.nodes.new("CompositorNodeRGB")
    white.location = (-450, -250)
    white.outputs[0].default_value = (1.0, 1.0, 1.0, 1.0)
    over = nt.nodes.new("CompositorNodeAlphaOver")
    over.location = (-150, 0)
    comp = nt.nodes.new("CompositorNodeComposite")
    comp.location = (150, 0)
    nt.links.new(rl.outputs["Image"], expo.inputs["Image"])
    nt.links.new(white.outputs[0], over.inputs[1])
    nt.links.new(expo.outputs["Image"], over.inputs[2])
    nt.links.new(over.outputs[0], comp.inputs["Image"])


# ----------------------------------------------------------------------------
# mekan cekimi: hazir oda fotografina kamera eslestirmeli kompozit
# ----------------------------------------------------------------------------

def sample_backdrop(image, px, radius):
    """Arka plan fotografindan bir bolgenin ortalama DOGRUSAL parlakligini olcer."""
    import numpy as np
    w, h = image.size
    buf = np.array(image.pixels[:], dtype=np.float32).reshape(h, w, 4)[::-1]
    x, y = px
    patch = buf[max(0, y - radius):y + radius, max(0, x - radius):x + radius, :3]
    return float(patch.reshape(-1, 3).mean())


def setup_room(scene, cfg, lo, hi, repo_root):
    """Fotografla ayni perspektifte zemin + duvar (golge yakalayici) ve gun isigi.

    Urun fotograftaki bos duvarin onune, zemine 1:1 oturur. Zemin ve duvar
    gorunmez ama golge tutar; boylece urun sahneye gercekten degiyormus gibi olur.
    """
    img_path = (repo_root / cfg["image"]).resolve()
    backdrop = bpy.data.images.load(str(img_path))

    world = bpy.data.worlds.new("Oda")
    scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    bg.inputs["Color"].default_value = hex_to_linear(cfg["light"]["ambient_color"])
    bg.inputs["Strength"].default_value = cfg["light"]["ambient_strength"]

    light = cfg["light"]
    if light["sun_strength"] > 0:
        sun_data = bpy.data.lights.new("Gunes", type="SUN")
        sun_data.energy = light["sun_strength"]
        sun_data.color = hex_to_linear(light["sun_color"])[:3]
        sun_data.angle = math.radians(light["sun_angle_deg"])
        sun = bpy.data.objects.new("Gunes", sun_data)
        bpy.context.collection.objects.link(sun)
        az = math.radians(light["sun_azimuth_deg"])
        el = math.radians(light["sun_elevation_deg"])
        d = Vector((math.sin(az) * math.cos(el), -math.cos(az) * math.cos(el), math.sin(el)))
        sun.rotation_mode = "QUATERNION"
        sun.rotation_quaternion = (-d).to_track_quat("Z", "Y")

    # Pencere: yumusak ve yonlu ana isik. Golge dusurmezse urun zemine degmiyor gibi durur.
    win_az = math.radians(light["window_azimuth_deg"])
    dist = 2.6
    win = add_area_light(
        "Pencere",
        (math.sin(win_az) * dist, -math.cos(win_az) * dist, 1.35),
        ((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, hi.z * 0.45),
        (light["window_size_m"], light["window_size_m"]), light["window_strength"])
    win.data.use_shadow = light["window_shadow"]

    for name, size, loc, rot in (
        ("Zemin", 20.0, (0, 0, 0), (0, 0, 0)),
        ("Duvar", 20.0, (0, 0, 0), (math.radians(90), 0, 0)),
    ):
        mesh = bpy.data.meshes.new(name)
        obj = bpy.data.objects.new(name, mesh)
        bpy.context.collection.objects.link(obj)
        bm = bmesh.new()
        bmesh.ops.create_grid(bm, x_segments=1, y_segments=1, size=size)
        bm.to_mesh(mesh)
        bm.free()
        obj.location = loc
        obj.rotation_euler = rot
        obj.is_shadow_catcher = True

    return backdrop


def room_camera(scene, cfg, res_x):
    """Fotografin kamerasini yeniden kurar.

    Fotografta dikey cizgiler paralel -> makine egimsiz, ufuk tam kare ortasinda.
    Bu durumda duvarin dibindeki cizginin piksel yuksekligi kamerayi tek basina
    belirler:  mesafe = odak(px) x kamera_yuksekligi / (zemin_cizgisi - orta).
    Boylece urun fotograftaki zemine birebir oturur; goz karari kalmaz.
    """
    cam_cfg = cfg["camera"]
    f_px = cam_cfg["lens"] / 36.0 * res_x
    drop_px = cam_cfg["floor_line_px"] - res_x / 2.0
    height = cam_cfg["height_mm"] * MM
    distance = f_px * height / drop_px

    cam_data = bpy.data.cameras.new("Kamera")
    cam_data.lens = cam_cfg["lens"]
    cam_data.sensor_width = 36
    cam = bpy.data.objects.new("Kamera", cam_data)
    bpy.context.collection.objects.link(cam)
    scene.camera = cam

    cam.location = (0.0, -distance, height)
    cam.rotation_mode = "XYZ"
    cam.rotation_euler = (math.radians(90), 0.0, 0.0)  # tam yatay bakis
    print(f"[render] oda kamerasi: {cam_cfg['lens']}mm, h={cam_cfg['height_mm']}mm, "
          f"duvar mesafesi={distance / MM:.0f}mm, olcek={height / MM / drop_px:.2f} mm/px")
    return cam


def composite_on_backdrop(scene, backdrop, exposure_stops):
    scene.use_nodes = True
    nt = scene.node_tree
    nt.nodes.clear()
    rl = nt.nodes.new("CompositorNodeRLayers")
    rl.location = (-700, 100)
    expo = nt.nodes.new("CompositorNodeExposure")
    expo.location = (-450, 100)
    expo.inputs["Exposure"].default_value = exposure_stops
    img = nt.nodes.new("CompositorNodeImage")
    img.image = backdrop
    img.location = (-450, -220)
    over = nt.nodes.new("CompositorNodeAlphaOver")
    over.location = (-150, 0)
    comp = nt.nodes.new("CompositorNodeComposite")
    comp.location = (150, 0)
    nt.links.new(rl.outputs["Image"], expo.inputs["Image"])
    nt.links.new(img.outputs["Image"], over.inputs[1])
    nt.links.new(expo.outputs["Image"], over.inputs[2])
    nt.links.new(over.outputs[0], comp.inputs["Image"])


REFERENCE_ALBEDO = 0.80  # notr beyaz referans yuzey (fotografcinin gri karti)


def auto_exposure(scene, target_linear=1.08, percentile=99.5, probe_res=220, probe_samples=12):
    """Pozlamayi urun rengine gore degil, sahnedeki ISIGA gore ayarlar.

    On-render sirasinda tum malzemeler notr mat beyaza (REFERENCE_ALBEDO) cevrilir;
    boylece olcum ne urun renginden ne de kenar parlamalarindan etkilenir. Beyaz,
    mese ve antrasit ayni isikta, birbiriyle tutarli cikar.
    """
    import tempfile
    import numpy as np

    ref = bpy.data.materials.new("Pozlama Referansi")
    ref.use_nodes = True
    nt = ref.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    diff = nt.nodes.new("ShaderNodeBsdfDiffuse")
    diff.inputs["Color"].default_value = (REFERENCE_ALBEDO,) * 3 + (1.0,)
    nt.links.new(diff.outputs["BSDF"], out.inputs["Surface"])
    bpy.context.view_layer.material_override = ref

    keep = (scene.render.resolution_x, scene.render.resolution_y, scene.cycles.samples,
            scene.render.filepath, scene.render.image_settings.file_format,
            scene.use_nodes, scene.cycles.use_denoising)

    probe = Path(tempfile.gettempdir()) / "om_exposure_probe.exr"
    scene.render.resolution_x = scene.render.resolution_y = probe_res
    scene.cycles.samples = probe_samples
    scene.cycles.use_denoising = False
    scene.use_nodes = False
    scene.render.image_settings.file_format = "OPEN_EXR"
    scene.render.image_settings.color_depth = "32"
    scene.render.filepath = str(probe)
    bpy.ops.render.render(write_still=True)

    img = bpy.data.images.load(str(probe))
    px = np.array(img.pixels[:], dtype=np.float32).reshape(-1, 4)
    bpy.data.images.remove(img)
    bpy.context.view_layer.material_override = None
    bpy.data.materials.remove(ref)

    (scene.render.resolution_x, scene.render.resolution_y, scene.cycles.samples,
     scene.render.filepath, scene.render.image_settings.file_format,
     scene.use_nodes, scene.cycles.use_denoising) = keep
    scene.render.image_settings.color_depth = "8"

    product = px[px[:, 3] > 0.9][:, :3]
    if product.size == 0:
        return 0.0
    measured = float(np.percentile(product.max(axis=1), percentile))
    if measured <= 1e-6:
        return 0.0

    stops = math.log2(target_linear / measured)
    print(f"[render] oto-pozlama: p{percentile:g} = {measured:.3f} lin -> {stops:+.2f} stop")
    return stops


SHOTS = {
    "hero":   dict(azimuth=34, elevation=11, lens=85,  margin=0.82, door=0,   look=0.5),
    "front":  dict(azimuth=0,  elevation=3,  lens=135, margin=0.84, door=0,   look=0.5),
    "detail": dict(azimuth=30, elevation=16, lens=70,  margin=0.88, door=105, look=0.5),
    "angle":  dict(azimuth=-38, elevation=24, lens=80, margin=0.82, door=0,   look=0.5),
    "room":   dict(door=0),
}

REPO_ROOT = Path(__file__).resolve().parents[2]


def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument("--parts", type=Path, required=True)
    ap.add_argument("--color", default="beyaz")
    ap.add_argument("--shot", default="hero", choices=list(SHOTS))
    ap.add_argument("--backdrop", type=Path, help="mekan cekimi icin arka plan tanimi (json)")
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--samples", type=int, default=256)
    ap.add_argument("--res", type=int, default=2000)
    ap.add_argument("--exposure", type=float, default=0.0)
    ap.add_argument("--view", default="Standard")
    ap.add_argument("--no-auto-exposure", dest="auto_exposure", action="store_false")
    args = ap.parse_args(argv)

    args.parts = args.parts.resolve()
    args.out = args.out.resolve()

    model = json.loads(args.parts.read_text(encoding="utf-8"))
    shot = SHOTS[args.shot]
    room = args.shot == "room"
    cfg = json.loads(args.backdrop.resolve().read_text(encoding="utf-8")) if room else None

    scene = reset_scene()
    setup_cycles(scene, args.samples, args.res)
    scene.view_settings.view_transform = args.view
    scene.view_settings.look = "None"

    materials, _ = build_materials(model, args.color)
    objects = build_product(model, materials, door_open_deg=shot["door"])

    if room:
        # urunun arkasi duvara (y=0) dayansin, supurgelik payi kadar one gelsin
        back_y = world_bbox(objects)[1].y
        for obj in objects:
            obj.location.x += cfg["product"]["x_mm"] * MM
            obj.location.y -= back_y + cfg["product"]["wall_gap_mm"] * MM
        lo, hi = world_bbox(objects)
        backdrop = setup_room(scene, cfg, lo, hi, REPO_ROOT)
        scene.render.resolution_x, scene.render.resolution_y = backdrop.size
        room_camera(scene, cfg, backdrop.size[0])
        ref = cfg["reference"]
        target = sample_backdrop(backdrop, ref["wall_px"], ref["sample_radius_px"])
        # oda cekiminde urunun on yuzu, fotograftaki duvarla ayni parlaklikta olmali
        stops = auto_exposure(scene, target_linear=target, percentile=50) if args.auto_exposure else 0.0
        composite_on_backdrop(scene, backdrop, stops + args.exposure)
    else:
        lo, hi = world_bbox(objects)
        setup_studio(scene, lo, hi)
        frame_camera(scene, objects, shot["azimuth"], shot["elevation"],
                     shot["lens"], shot["margin"], shot["look"])
        stops = auto_exposure(scene) if args.auto_exposure else 0.0
        composite_on_white(scene, stops + args.exposure)

    args.out.parent.mkdir(parents=True, exist_ok=True)
    scene.render.filepath = str(args.out)
    bpy.ops.render.render(write_still=True)
    print(f"[render] yazildi: {args.out}")


if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    main(argv)
