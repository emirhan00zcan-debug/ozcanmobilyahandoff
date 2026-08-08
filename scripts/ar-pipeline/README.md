# Mobil AR Mobilya Yerleştirme Hattı

Ürün fotoğraflarından, telefonda "Odanızda Görün" ile açılan, zemine 1:1 gerçek
ölçüde oturan ve parmakla sürüklenip döndürülebilen AR mobilyaya giden uçtan uca hat.

## Nasıl çalışıyor (mimari özet)

Bu proje bir web sitesi (Next.js) olduğu için "mobil AR" burada native bir iOS/Android
uygulaması değil, **WebAR** ile çözülüyor: tarayıcıdaki bir buton, telefonun kendi
işletim sistemine ait AR görüntüleyicisini açıyor.

- **Android** → Google **Scene Viewer** (ARCore) — `.glb` dosyasını açar.
- **iOS** → Apple **AR Quick Look** (ARKit) — `.usdz` dosyasını açar.
- Bu iki sistem de telefonun kamerasını açma, **zemini algılama**, mobilyayı zemine
  yerleştirme, **parmakla sürükleme** ve **çevirme (rotate)** işini işletim sistemi
  seviyesinde, native olarak zaten yapıyor — bunun için ayrıca ARKit/ARCore kodu
  yazmamıza gerek yok, tetiklemek yeterli. Bu tetikleme `src/components/product/ArModelViewer.tsx`
  içinde `@google/model-viewer` ile zaten kurulu (`ar-modes="webxr scene-viewer quick-look"`).
- "Kullanıcı büyütüp küçültemesin" isteği de aynı bileşende `ar-scale="fixed"` ile
  karşılanıyor — AR içinde pinch-to-scale kapalı.

Bu klasördeki 3 script'in tek işi: her ürün için doğru ölçekte bir `.glb` ve `.usdz`
üretip `public/models/<slug>/` altına koymak ve veritabanına yazmak. Geri kalanı
(kamera açma, zemin algılama, sürükle-bırak) zaten `ArModelViewer` + telefonun
kendi AR sistemi tarafından karşılanıyor.

## Klasör yapısı

```
scripts/ar-pipeline/
  generate_3d.py        Adım 1: 4 fotoğraf -> Meshy AI -> ham (ölçeklenmemiş) .glb
  scale_and_export.py   Adım 2: Blender (arka planda) -> gerçek cm ölçüsüne 1:1 kilitli
                         model.glb + model.usdz
  run.py                Adım 1+2+3'ü sırayla çalıştıran orkestratör (asıl kullanacağınız komut)
  apply-model-urls.ts   Adım 3: public/ yollarını Product.glbUrl / usdzUrl'e yazar
  requirements.txt      Python bağımlılıkları

public/models/<slug>/
  model.glb             Android / WebXR
  model.usdz             iOS AR Quick Look
```

## Gereksinimler

1. **Python 3.10+** ve bağımlılıklar:
   ```
   pip install -r scripts/ar-pipeline/requirements.txt
   ```
2. **Meshy AI hesabı ve API anahtarı** (fotoğraftan 3D model üretimi için) —
   https://www.meshy.ai üzerinden alınır. `generate_3d.py` bunu repo kökündeki
   `.env` dosyasından (`MESHY_API_KEY="..."`) otomatik okur — zaten ayarlı.
   Değiştirmek isterseniz `.env` içindeki satırı güncelleyin, ya da o oturuma özel
   geçici olarak ezmek isterseniz: `set MESHY_API_KEY=xxxxxxxx` (PowerShell:
   `$env:MESHY_API_KEY = "xxxxxxxx"`).
3. **Blender 3.6+** (ücretsiz, https://www.blender.org/download/) — sadece ölçek
   kilitleme ve GLB/USDZ dışa aktarım için, arka planda (`--background`) çalışır,
   arayüzü açılmaz. `blender` komutu PATH'te değilse tam yolu şu şekilde verin:
   ```
   set BLENDER_PATH=C:\Program Files\Blender Foundation\Blender 4.2\blender.exe
   ```
4. Node bağımlılıkları zaten projede kurulu olmalı (`npm install`), veritabanı
   güncellemesi `npx tsx` ile bu depodaki Prisma client'ı kullanır.

## Kullanım — yeni bir ürüne AR ekleme

Elinizde her ürün için 4 fotoğraf olmalı: **Ön, Yan, Arka, Doku/Detay**. Ürünün
`widthCm` / `heightCm` / `depthCm` değerlerini veritabanındaki (Prisma) kayıttan alın.

```
python scripts/ar-pipeline/run.py \
  --slug 3-kapakli-gardirop-ceviz \
  --front C:\fotolar\on.jpg \
  --side  C:\fotolar\yan.jpg \
  --back  C:\fotolar\arka.jpg \
  --detail C:\fotolar\doku.jpg \
  --width-cm 120 --height-cm 200 --depth-cm 60
```

Bu komut sırayla:
1. 4 fotoğrafı Meshy AI'ye gönderir, ham 3D modeli indirir (birkaç dakika sürebilir).
2. Blender'da modeli 120×200×60 cm'e (metre cinsinden 1:1) kilitler, orijini taban
   ortasına taşır (AR'da zemine tam oturması için) ve `public/models/3-kapakli-gardirop-ceviz/`
   altına `model.glb` + `model.usdz` yazar.
3. Veritabanındaki ilgili `Product` satırının `glbUrl`/`usdzUrl` alanlarını günceller.

Bittiğinde ürün sayfasında (`/urun/<slug>`) galerinin üstünde "3D / Odanızda Görün"
sekmesi otomatik görünür (bkz. `ProductDetailClient.tsx` — `product.glbUrl` doluysa).

## Model yanlış yöne bakıyorsa

Blender, glTF'nin Y-up eksenini Z-up'a çevirir; script varsayılan olarak X=Genişlik,
Y=Derinlik, Z=Yükseklik kabul eder. Üretilen modelde genişlik/derinlik ters
ölçülüyorsa komuta `--swap-width-depth` ekleyip tekrar çalıştırın.

## Sadece dosya üretmek, veritabanını değiştirmemek isterseniz

```
python scripts/ar-pipeline/run.py ... --skip-db-update
```
