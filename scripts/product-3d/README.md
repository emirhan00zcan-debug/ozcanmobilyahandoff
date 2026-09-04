# Ürün 3D Hattı — SketchUp modeli + ürün fotoğrafı

Tek bir mm cinsinden ürün tanımından (`specs/*.json`) üç çıktı üretir:

| Çıktı | Ne işe yarar |
|---|---|
| `*.rb` | SketchUp Ruby Console'a yapıştırılan, modeli mm hassasiyetinde çizen kod |
| `*-kesim-listesi.csv` | Üretim için panel kesim listesi (adet, uzunluk, genişlik, kalınlık, bantlı kenar) |
| `*.parts.json` | Blender'ın render için okuduğu açık panel listesi |

**Neden tek kaynak:** SketchUp modeli ile render aynı `parts.json`'u okur. Spec'te
bir ölçü değişirse üretim çizimi, kesim listesi ve tüm ürün fotoğrafları birlikte
değişir; ikisinin birbirinden kayması mümkün değil.

## Kullanım

### 1. Spec'ten model ve kesim listesi üret

```bash
python scripts/product-3d/build.py scripts/product-3d/specs/ayakkabilik-tek-kapakli.json
```

Çıktılar `scripts/product-3d/out/<ürün-id>/` altına yazılır.

### 2. SketchUp'ta aç

SketchUp'ta **Window → Ruby Console**, sonra üretilen `.rb` dosyasının içeriğini
yapıştırıp Enter. Model orijinde, mm biriminde, her panel ayrı isimlendirilmiş
grup olarak oluşur.

### 3. Ürün fotoğrafı render et

Beyaz fon (packshot) — `hero` (3/4), `front` (ön görünüş), `detail` (kapak açık):

```bash
blender --background --python scripts/product-3d/render.py -- --parts scripts/product-3d/out/ayakkabilik-tek-kapakli/ayakkabilik-tek-kapakli-60x90.parts.json --color beyaz --shot hero --out render.png --samples 256 --res 2000
```

Mekan görseli (hazır oda fotoğrafına kompozit):

```bash
blender --background --python scripts/product-3d/render.py -- --parts scripts/product-3d/out/ayakkabilik-tek-kapakli/ayakkabilik-tek-kapakli-60x90.parts.json --color beyaz --shot room --backdrop scripts/product-3d/backdrops/antre.json --out antre.png --samples 384
```

`blender` PATH'te değilse tam yol verin:
`"C:\Program Files\Blender Foundation\Blender 4.5\blender.exe"`.

## Hattın çalışma mantığı

### Ölçüler
Koordinat sistemi mm: **X** genişlik (0 = sol dış yüz), **Y** derinlik
(0 = kapağın ön yüzü, +Y arkaya), **Z** yükseklik (0 = zemin). Dış ölçü kapağı ve
arkalığı içerir.

### Otomatik pozlama
Her render öncesi düşük çözünürlüklü bir ön-render alınır ve **tüm malzemeler
nötr mat beyaza çevrilir**. Ölçüm ürünün renginden değil sahnedeki ışıktan
yapıldığı için beyaz, meşe ve antrasit birbiriyle tutarlı çıkar — elle pozlama
ayarı gerekmez.

- Beyaz fon: en parlak yüzey hedefe kilitlenir (packshot standardı).
- Mekan: ürünün ön yüzü, arka plan fotoğrafındaki duvarla aynı parlaklığa
  getirilir; böylece kompozit yapıştırma gibi durmaz.

### Beyaz fon
`film_transparent` + gölge yakalayıcı zemin ile render edilir, kompozitte saf
beyaz (255) üzerine bindirilir. Fon gerçekten 255 beyaz olur, gölge korunur.

### Mekan kompoziti
Arka plan fotoğrafının kamerası ölçülerek yeniden kurulur. Fotoğrafta dikey
çizgiler paralelse makine eğimsizdir ve ufuk tam kare ortasındadır; bu durumda
duvar dibindeki çizginin piksel yüksekliği kamerayı tek başına belirler:

```
mesafe = odak(px) × kamera_yüksekliği / (zemin_çizgisi_px − kare_ortası_px)
```

Kalibrasyon değerleri `backdrops/*.json` içinde, nasıl ölçüldüğü `_kalibrasyon`
alanında yazılıdır. Zemin ve duvar görünmez ama gölge tutar.

## Yeni ürün ekleme

`specs/` altına yeni bir JSON. `archetype` alanı hangi üretecin çalışacağını
seçer; şu an `carcass` var (gövde + raf + kapak + arkalık + ayak + kulp).
Çekmeceli ürünler (masa altı keson) için yeni bir archetype gerekir.

## Yeni mekan ekleme

`backdrops/` altına yeni bir JSON + `ArkaPlan_Gorselleri/` altına oda fotoğrafı.
Gereken tek ölçüm: fotoğraftaki duvar-zemin çizgisinin piksel yüksekliği ve
süpürgelik yüksekliği (ölçek için).
