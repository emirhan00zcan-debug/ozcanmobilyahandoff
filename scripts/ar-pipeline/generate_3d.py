"""
ADIM 1 / script 1 - Fotograftan 3D'ye
4 urun fotografini (On, Yan, Arka, Doku/Detay) Meshy AI'nin Multi-Image to 3D API'sine
gonderir, isi bekler ve ham (henuz gercek olcuye kilitlenmemis) .glb dosyasini indirir.

Bu ham model, gercek cm olculerine 1:1 kilitlenmek ve son .glb/.usdz ciktilarini
uretmek uzere scale_and_export.py'ye (Blender) gecirilir - bkz. run.py.

API referansi: https://docs.meshy.ai/en/api/multi-image-to-3d
Kurulum: pip install -r requirements.txt
Ortam degiskeni: MESHY_API_KEY (https://www.meshy.ai hesap panelinden alinir)
"""

from __future__ import annotations

import argparse
import base64
import mimetypes
import os
import sys
import time
from pathlib import Path

import requests
from dotenv import load_dotenv

# Repo kokundeki .env dosyasini otomatik yukler (MESHY_API_KEY orada tanimliysa
# ayrica `set MESHY_API_KEY=...` yapmaya gerek kalmaz). Zaten ortamda tanimliysa
# (ornegin CI'da) .env'deki deger onu ezmez.
load_dotenv(Path(__file__).resolve().parents[2] / ".env")

API_BASE = "https://api.meshy.ai/openapi/v1/multi-image-to-3d"
POLL_INTERVAL_SECONDS = 10
POLL_TIMEOUT_SECONDS = 20 * 60  # Meshy'de bir gorev genelde birkac dakika suruyor


def _api_key() -> str:
    key = os.environ.get("MESHY_API_KEY")
    if not key:
        sys.exit("Hata: MESHY_API_KEY ortam degiskeni tanimli degil (bkz. README.md).")
    return key


def _image_to_data_uri(path: Path) -> str:
    mime, _ = mimetypes.guess_type(path.name)
    if mime is None:
        mime = "image/jpeg"
    data = base64.b64encode(path.read_bytes()).decode("ascii")
    return f"data:{mime};base64,{data}"


def create_task(image_paths: list[Path]) -> str:
    headers = {"Authorization": f"Bearer {_api_key()}", "Content-Type": "application/json"}
    payload = {
        "image_urls": [_image_to_data_uri(p) for p in image_paths],
        "should_texture": True,
        "texture_resolution": "2k",
        "topology": "quad",
        "target_polycount": 20000,
        "should_remesh": True,
        # Olcek Blender asamasinda (scale_and_export.py) urunun gercek cm olculerine
        # kilitlenecegi icin Meshy'nin kendi otomatik boyutlandirmasina guvenmiyoruz.
        "target_formats": ["glb"],
    }
    res = requests.post(API_BASE, headers=headers, json=payload, timeout=60)
    if not res.ok:
        sys.exit(f"Hata: Meshy gorevi baslatilamadi ({res.status_code}): {res.text}")
    return res.json()["result"]


def wait_for_result(task_id: str) -> dict:
    headers = {"Authorization": f"Bearer {_api_key()}"}
    started = time.time()
    while True:
        res = requests.get(f"{API_BASE}/{task_id}", headers=headers, timeout=30)
        res.raise_for_status()
        data = res.json()
        status = data.get("status")
        print(f"  [Meshy] {status} - %{data.get('progress', 0)}")

        if status == "SUCCEEDED":
            return data
        if status in ("FAILED", "EXPIRED"):
            sys.exit(f"Hata: Meshy gorevi {status} durumunda sonuclandi.")
        if time.time() - started > POLL_TIMEOUT_SECONDS:
            sys.exit("Hata: Meshy gorevi zaman asimina ugradi.")
        time.sleep(POLL_INTERVAL_SECONDS)


def download(url: str, output_path: Path) -> None:
    res = requests.get(url, timeout=120)
    res.raise_for_status()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_bytes(res.content)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="4 urun fotografindan (on/yan/arka/doku) Meshy AI ile ham 3D model (.glb) uretir."
    )
    parser.add_argument("--front", required=True, type=Path, help="On gorunum fotografi")
    parser.add_argument("--side", required=True, type=Path, help="Yan gorunum fotografi")
    parser.add_argument("--back", required=True, type=Path, help="Arka gorunum fotografi")
    parser.add_argument("--detail", required=True, type=Path, help="Doku/detay fotografi")
    parser.add_argument("--output", required=True, type=Path, help="Ham .glb cikti yolu")
    args = parser.parse_args()

    for path in (args.front, args.side, args.back, args.detail):
        if not path.is_file():
            sys.exit(f"Hata: Fotograf bulunamadi: {path}")

    print("Meshy AI'ye 4 fotograf gonderiliyor...")
    task_id = create_task([args.front, args.side, args.back, args.detail])
    print(f"Gorev baslatildi: {task_id}")

    result = wait_for_result(task_id)
    glb_url = result["model_urls"]["glb"]
    print(f"Model hazir, indiriliyor -> {args.output}")
    download(glb_url, args.output)
    print(f"Tamamlandi: ham model -> {args.output}")


if __name__ == "__main__":
    main()
