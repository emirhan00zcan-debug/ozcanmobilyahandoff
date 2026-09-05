"""Spec (mm) -> parca listesi -> SketchUp Ruby + kesim listesi.

Koordinat sistemi (hepsi mm):
  X = genislik, 0 = sol dis yuz
  Y = derinlik, 0 = kapagin on yuzu, +Y arkaya dogru
  Z = yukseklik, 0 = zemin

Kullanim:
  python scripts/product-3d/build.py scripts/product-3d/specs/ayakkabilik-tek-kapakli.json
"""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent

EDGE_LABELS = {
    "front": "on",
    "back": "arka",
    "top": "ust",
    "bottom": "alt",
    "left": "sol",
    "right": "sag",
    "all": "4 kenar",
}


def box(pid, name, pos, size, material, edges=(), count=1):
    return {
        "id": pid,
        "name": name,
        "shape": "box",
        "pos": [round(v, 2) for v in pos],
        "size": [round(v, 2) for v in size],
        "material": material,
        "edges": list(edges),
        "count": count,
    }


def cyl(pid, name, base, direction, diameter, length, material):
    return {
        "id": pid,
        "name": name,
        "shape": "cylinder",
        "pos": [round(v, 2) for v in base],
        "dir": list(direction),
        "d": diameter,
        "len": length,
        "material": material,
        "edges": [],
        "count": 1,
    }


def handle_parts(handle, door_id, cx, cz):
    """Kulp parcalari. Dugme kulp: sap + bas. Cubuk kulp: 2 ayak + dikey boru."""
    parts = []
    if handle["type"] == "knob":
        head_len = 10
        stem_len = handle["projection"] - head_len
        parts.append(cyl(f"kulp-sap-{door_id}", "Kulp Sapi", (cx, 0, cz), (0, -1, 0),
                         handle["stem_diameter"], stem_len, "hardware"))
        parts.append(cyl(f"kulp-bas-{door_id}", "Kulp Basi", (cx, -stem_len, cz), (0, -1, 0),
                         handle["diameter"], head_len, "hardware"))
    else:
        half = handle["centers"] / 2.0
        stand = handle["projection"] - handle["bar_diameter"] / 2.0
        yatay = handle.get("orientation") == "horizontal"
        # yatay kulpta ayaklar X'te ayrilir ve boru X boyunca uzanir
        for sign, tag in ((-1, "sol" if yatay else "alt"), (1, "sag" if yatay else "ust")):
            ayak = (cx + sign * half, 0, cz) if yatay else (cx, 0, cz + sign * half)
            parts.append(cyl(f"kulp-ayak-{tag}-{door_id}", "Kulp Ayagi", ayak, (0, -1, 0),
                             handle["post_diameter"], stand, "hardware"))
        yari_bar = handle["bar_diameter"] / 2.0
        boru_baz = ((cx - half - yari_bar, -stand, cz) if yatay
                    else (cx, -stand, cz - half - yari_bar))
        parts.append(cyl(f"kulp-boru-{door_id}", "Kulp Borusu", boru_baz,
                         (1, 0, 0) if yatay else (0, 0, 1),
                         handle["bar_diameter"], handle["centers"] + handle["bar_diameter"],
                         "hardware"))
    for p in parts:
        p["parent"] = door_id
    return parts


def build_carcass(spec, size):
    """Govde + raf + kapak + arkalik + ayak + kulp. Tum kesimler duz dikdortgen."""
    s = spec["standards"]
    t = s["panel_t"]
    back_t = s["back_t"]
    door_t = s["door_t"]
    gap = s["door_gap"]
    setback = s["shelf_setback"]
    foot_h = s["foot_h"]

    W, H, D = size["w"], size["h"], size["d"]
    carcass_h = H - foot_h
    carcass_d = D - back_t - door_t
    inner_w = W - 2 * t
    inner_h = carcass_h - 2 * t

    n = size["compartments"]
    shelf_count = n - 1
    net_h = (inner_h - shelf_count * t) / n

    y0 = door_t  # govde on yuzu
    z0 = foot_h  # govde alt yuzu
    door_count = size.get("doors", 1)

    parts = [
        box("yan-sol", "Yan Panel (Sol)", (0, y0, z0), (t, carcass_d, carcass_h),
            "body", ["front", "top"]),
        box("yan-sag", "Yan Panel (Sag)", (W - t, y0, z0), (t, carcass_d, carcass_h),
            "body", ["front", "top"]),
        box("alt", "Alt Panel", (t, y0, z0), (inner_w, carcass_d, t),
            "body", ["front"]),
        box("ust", "Ust Panel", (t, y0, z0 + carcass_h - t), (inner_w, carcass_d, t),
            "body", ["front"]),
    ]

    for k in range(1, shelf_count + 1):
        z = round(z0 + t + k * net_h + (k - 1) * t)
        parts.append(
            box(f"raf-{k}", f"Raf {k}", (t, y0 + setback, z),
                (inner_w, carcass_d - setback, t), "body", ["front"])
        )

    parts.append(
        box("arkalik", "Arkalik", (0, y0 + carcass_d, z0), (W, back_t, carcass_h),
            "back", [])
    )

    # Kapaklar: tek kapakta menteseler solda, cift kapakta her kapak kendi dis
    # kenarindan doner ve kulplar ortada bulusur.
    door_h = carcass_h - 2 * gap
    door_w = (W - (door_count + 1) * gap) / door_count
    door_z = z0 + gap
    handle = spec["hardware"]["handle"]

    for i in range(door_count):
        door_x = gap + i * (door_w + gap)
        hinge_left = door_count == 1 or i == 0
        door_id = f"kapak-{i + 1}" if door_count > 1 else "kapak"
        label = f"Kapak {i + 1}" if door_count > 1 else "Kapak"
        door = box(door_id, label, (door_x, 0, door_z), (door_w, door_t, door_h),
                   "body", ["all"])
        door["pivot"] = [door_x if hinge_left else door_x + door_w, door_t, door_z]
        door["hinge_side"] = "left" if hinge_left else "right"
        parts.append(door)

        # kulp acilan kenara yakin durur
        opening_edge = door_x + door_w if hinge_left else door_x
        offset = -handle["inset_x"] if hinge_left else handle["inset_x"]
        parts.extend(handle_parts(handle, door_id, opening_edge + offset,
                                  door_z + door_h / 2.0))

    foot = spec["hardware"]["foot"]
    fi = foot["inset"]
    for i, (fx, fy) in enumerate(
        [(fi, y0 + fi), (W - fi, y0 + fi), (fi, y0 + carcass_d - fi), (W - fi, y0 + carcass_d - fi)],
        start=1,
    ):
        parts.append(cyl(f"ayak-{i}", f"Ayak {i}", (fx, fy, 0), (0, 0, 1),
                         foot["diameter"], foot_h, "foot"))

    return parts, {
        "carcass_h": carcass_h,
        "carcass_d": carcass_d,
        "inner_w": inner_w,
        "inner_h": inner_h,
        "net_compartment_h": round(net_h, 2),
        "shelf_count": shelf_count,
    }


def build_bench(spec, size):
    """Bank: solda kapakli bolme, sagda acik raf(lar), ustte minder.

    Ic bolme genisligi acik bolmeden geriye kalandir; boylece acik bolme her
    olcude ayakkabi sigacak genislikte kalir. Tum kesimler duz dikdortgen.
    """
    s = spec["standards"]
    t, back_t, door_t = s["panel_t"], s["back_t"], s["door_t"]
    gap, setback, foot_h = s["door_gap"], s["shelf_setback"], s["foot_h"]
    cushion_t = s["cushion_t"]

    W, H, D = size["w"], size["h"], size["d"]
    open_w = size["open_bay_w"]
    shelves = size.get("open_shelves", 1)

    carcass_h = H - cushion_t - foot_h
    carcass_d = D - back_t - door_t
    inner_w = W - 2 * t
    inner_h = carcass_h - 2 * t
    closed_w = inner_w - t - open_w
    if closed_w < 200:
        raise SystemExit(f"{size['code']}: acik bolme {open_w} mm cok genis, "
                         f"kapakli bolmeye {closed_w:.0f} mm kaliyor")
    div_x = t + closed_w

    y0, z0 = door_t, foot_h
    parts = [
        box("yan-sol", "Yan Panel (Sol)", (0, y0, z0), (t, carcass_d, carcass_h),
            "body", ["front", "top"]),
        box("yan-sag", "Yan Panel (Sag)", (W - t, y0, z0), (t, carcass_d, carcass_h),
            "body", ["front", "top"]),
        box("alt", "Alt Panel", (t, y0, z0), (inner_w, carcass_d, t), "body", ["front"]),
        box("ust", "Ust Panel", (t, y0, z0 + carcass_h - t), (inner_w, carcass_d, t),
            "body", ["front"]),
        box("orta-bolme", "Orta Bolme", (div_x, y0, z0 + t), (t, carcass_d, inner_h),
            "body", ["front"]),
    ]

    # acik bolmenin raflari esit araliklarla
    net_h = (inner_h - shelves * t) / (shelves + 1)
    for k in range(1, shelves + 1):
        z = round(z0 + t + k * net_h + (k - 1) * t, 2)
        parts.append(box(f"raf-{k}", f"Raf {k}", (div_x + t, y0 + setback, z),
                         (open_w, carcass_d - setback, t), "body", ["front"]))

    parts.append(box("arkalik", "Arkalik", (0, y0 + carcass_d, z0), (W, back_t, carcass_h),
                     "back", []))
    parts.append(box("minder", "Minder", (0, 0, z0 + carcass_h), (W, D, cushion_t),
                     "cushion", []))

    # kapak orta bolmenin yarisina kadar biner
    door_w = div_x + t / 2.0 - gap
    door_h = carcass_h - 2 * gap
    door = box("kapak", "Kapak", (gap, 0, z0 + gap), (door_w, door_t, door_h),
               "body", ["all"])
    door["pivot"] = [gap, door_t, z0 + gap]
    door["hinge_side"] = "left"
    parts.append(door)

    handle = spec["hardware"]["handle"]
    parts.extend(handle_parts(handle, "kapak", gap + door_w / 2.0,
                              z0 + gap + door_h - handle["inset_z"]))

    return parts, {
        "carcass_h": carcass_h,
        "carcass_d": carcass_d,
        "inner_w": inner_w,
        "inner_h": inner_h,
        "closed_bay_w": round(closed_w, 2),
        "open_bay_w": open_w,
        "open_shelf_h": round(net_h, 2),
        "door_w": round(door_w, 2),
    }


BUILDERS = {"carcass": build_carcass, "bench": build_bench}


def build_size(spec, size):
    parts, derived = BUILDERS[spec["archetype"]](spec, size)
    return {
        "product_id": spec["id"],
        "product_name": spec["name"],
        "size_code": size["code"],
        "size_label": size["label"],
        "outer_mm": {"w": size["w"], "h": size["h"], "d": size["d"]},
        "standards": spec["standards"],
        "derived": derived,
        "colors": spec["colors"],
        "parts": parts,
    }


def cut_rows(model):
    """Kesim listesi: sadece panel (box) parcalari, ayni olcudekiler gruplanir."""
    grouped = {}
    for p in model["parts"]:
        if p["shape"] != "box":
            continue
        dx, dy, dz = p["size"]
        # Uzunluk/genislik/kalinlik: kalinlik en kucuk boyut
        dims = sorted([dx, dy, dz])
        thickness, width, length = dims[0], dims[1], dims[2]
        key = (length, width, thickness, p["material"], tuple(p["edges"]))
        grouped.setdefault(key, {"count": 0, "names": []})
        grouped[key]["count"] += p["count"]
        base_name = p["name"].split(" (")[0].rstrip("0123456789 ")
        if base_name not in grouped[key]["names"]:
            grouped[key]["names"].append(base_name)

    rows = []
    for (length, width, thickness, material, edges), v in grouped.items():
        if edges == ("all",):
            band = "4 kenar"
        elif edges:
            band = " + ".join(EDGE_LABELS.get(e, e) for e in edges)
        else:
            band = "-"
        rows.append({
            "Parca": " / ".join(v["names"]),
            "Adet": v["count"],
            "Uzunluk (mm)": f"{length:g}",
            "Genislik (mm)": f"{width:g}",
            "Kalinlik (mm)": f"{thickness:g}",
            "Malzeme": {"body": "Melamin Suntalam", "back": "Melamin Arkalik",
                        "cushion": "Minder (dosemeli)"}.get(material, material),
            "Bantli Kenar": band,
        })
    rows.sort(key=lambda r: (-float(r["Uzunluk (mm)"]), -float(r["Genislik (mm)"])))
    return rows


RUBY_TEMPLATE = '''# encoding: UTF-8
# ---------------------------------------------------------------------------
#  Özcan Mobilya · {product_name} — {size_label} ({w} × {h} × {d} mm)
#  Otomatik üretildi: scripts/product-3d/build.py
#  SketchUp Ruby Console'a yapıştırın ya da:  load "{rb_name}"
# ---------------------------------------------------------------------------

module OzcanMobilya
  PARTS = {parts_literal}

  MATERIALS = {materials_literal}

  MODEL_NAME = {model_name!r}

  def self.material(model, key)
    spec = MATERIALS[key]
    name = spec["name"]
    mat = model.materials[name] || model.materials.add(name)
    mat.color = Sketchup::Color.new(spec["hex"])
    mat
  end

  def self.box(ents, pos, size)
    x, y, z = pos
    dx, dy, dz = size
    g = ents.add_group
    pts = [[x, y, z], [x + dx, y, z], [x + dx, y + dy, z], [x, y + dy, z]]
    face = g.entities.add_face(pts.map {{ |p| p.map {{ |v| v.mm }} }})
    face.reverse! if face.normal.z < 0
    face.pushpull(dz.mm)
    g
  end

  def self.cylinder(ents, pos, dir, dia, len)
    g = ents.add_group
    center = Geom::Point3d.new(*pos.map {{ |v| v.mm }})
    normal = Geom::Vector3d.new(*dir)
    circle = g.entities.add_circle(center, normal, (dia / 2.0).mm, 48)
    face = g.entities.add_face(circle)
    face.reverse! if face.normal.dot(normal) < 0
    face.pushpull(len.mm)
    g
  end

  def self.generate!
    model = Sketchup.active_model
    model.options["UnitsOptions"]["LengthFormat"] = 0
    model.options["UnitsOptions"]["LengthUnit"] = 2
    model.options["UnitsOptions"]["LengthPrecision"] = 1

    model.start_operation("Özcan | #{{MODEL_NAME}}", true)

    existing = model.definitions[MODEL_NAME]
    model.definitions.remove(existing) if existing
    defn = model.definitions.add(MODEL_NAME)
    ents = defn.entities

    PARTS.each do |p|
      g = if p["shape"] == "box"
            box(ents, p["pos"], p["size"])
          else
            cylinder(ents, p["pos"], p["dir"], p["d"], p["len"])
          end
      g.name = p["name"]
      g.material = material(model, p["material"])
    end

    inst = model.active_entities.add_instance(defn, Geom::Transformation.new)
    model.commit_operation
    model.active_view.zoom(inst)
    puts "#{{MODEL_NAME}} olusturuldu — #{{PARTS.length}} parca."
    inst
  end
end

OzcanMobilya.generate!
'''


def _rb(value):
    """Python degeri -> Ruby literal.

    JSON kullanilamaz: Ruby'de {"a": 1} SEMBOL anahtar uretir ({:a => 1}), string
    anahtar degil. Uretilen kod p["name"] ile okudugu icin hash rocket sart.
    """
    if isinstance(value, bool):
        return "true" if value else "false"
    if value is None:
        return "nil"
    if isinstance(value, float):
        return str(int(value)) if value.is_integer() else repr(value)
    if isinstance(value, int):
        return str(value)
    if isinstance(value, str):
        return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'
    if isinstance(value, (list, tuple)):
        return "[" + ", ".join(_rb(v) for v in value) + "]"
    if isinstance(value, dict):
        return "{" + ", ".join(f"{_rb(k)} => {_rb(v)}" for k, v in value.items()) + "}"
    raise TypeError(f"Ruby'ye cevrilemeyen tur: {type(value)}")


def ruby_literal(obj):
    """Liste ise her ogeyi ayri satira alir (parca listesi okunabilir kalsin)."""
    if isinstance(obj, list):
        return "[\n" + "".join(f"    {_rb(item)},\n" for item in obj) + "  ]"
    if isinstance(obj, dict):
        return "{\n" + "".join(f"    {_rb(k)} => {_rb(v)},\n" for k, v in obj.items()) + "  }"
    return _rb(obj)


def emit_ruby(model, spec, color, out_dir):
    model_name = f"OM-{spec['id']}-{model['size_code']}-{color['code']}".upper()
    rb_name = f"{spec['id']}-{model['size_code']}-{color['code']}.rb"

    materials = {
        "body": {"name": f"OM {color['label']}", "hex": color["hex"]},
        "back": {"name": f"OM {color['label']} (Arkalik)", "hex": color["hex"]},
        "hardware": {"name": "OM Kulp Mat Siyah", "hex": spec["hardware"]["handle"]["hex"]},
        "foot": {"name": "OM Ayak Siyah", "hex": spec["hardware"]["foot"]["hex"]},
    }

    parts = [
        {k: v for k, v in p.items() if k in ("name", "shape", "pos", "size", "dir", "d", "len", "material")}
        for p in model["parts"]
    ]

    src = RUBY_TEMPLATE.format(
        product_name=spec["name"],
        size_label=model["size_label"],
        w=model["outer_mm"]["w"],
        h=model["outer_mm"]["h"],
        d=model["outer_mm"]["d"],
        rb_name=rb_name,
        parts_literal=ruby_literal(parts),
        materials_literal=ruby_literal(materials),
        model_name=model_name,
    )
    path = out_dir / rb_name
    path.write_text(src, encoding="utf-8")
    return path


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("spec", type=Path)
    ap.add_argument("--out", type=Path, default=ROOT / "out")
    args = ap.parse_args()

    spec = json.loads(args.spec.read_text(encoding="utf-8"))
    out_dir = args.out / spec["id"]
    out_dir.mkdir(parents=True, exist_ok=True)

    hero_color = next((c for c in spec["colors"] if c.get("hero")), spec["colors"][0])
    all_rows = []

    for size in spec["sizes"]:
        model = build_size(spec, size)
        parts_path = out_dir / f"{spec['id']}-{size['code']}.parts.json"
        parts_path.write_text(json.dumps(model, indent=2, ensure_ascii=False), encoding="utf-8")

        rb = emit_ruby(model, spec, hero_color, out_dir)

        for row in cut_rows(model):
            all_rows.append({"Olcu": f"{size['w']}x{size['h']}x{size['d']}", **row})

        d = model["derived"]
        # ozet satiri arketipe gore degisir: raf yuksekligi ya da bolme genisligi
        if "net_compartment_h" in d:
            ayrinti = f"kat yuksekligi {d['net_compartment_h']:g} mm"
        else:
            ayrinti = (f"kapakli bolme {d['closed_bay_w']:g} mm  "
                       f"acik bolme {d['open_bay_w']:g} mm")
        print(f"{size['code']:>8}  {size['w']}x{size['h']}x{size['d']} mm  "
              f"ic {d['inner_w']:g}x{d['inner_h']:g}  {ayrinti}  "
              f"{len(model['parts'])} parca  -> {rb.name}")

    csv_path = out_dir / f"{spec['id']}-kesim-listesi.csv"
    with csv_path.open("w", encoding="utf-8-sig", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=list(all_rows[0].keys()), delimiter=";")
        writer.writeheader()
        writer.writerows(all_rows)

    print(f"\nKesim listesi: {csv_path}")
    print(f"Cikti klasoru: {out_dir}")


if __name__ == "__main__":
    main()
