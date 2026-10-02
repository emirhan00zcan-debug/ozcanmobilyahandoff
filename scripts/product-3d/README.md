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

### 4. Elde kurulmuş bir sahneden çekim

Spec'ten değil de Blender'da açık bir sahneden (ör. hazır oda modeli içine
yerleştirilmiş ürün) fotoğraf almak için `packshot.py`. Ürünü seçip Scripting
sekmesinde çalıştırır; hero / front / angle açılarını beyaz fona render eder.

```bash
blender sahne.blend --background --python scripts/product-3d/packshot.py
```

Işık, oto-pozlama ve beyaz fon kompoziti `render.py`'dan geldiği için çıkan
görseller spec'ten üretilenlerle aynı görünür. Sahneye dokunmaz: geçici bir
sahne açar, ürünü oraya bağlar, sonunda temizler. Kapak açık `detail` çekimi
menteşe bilgisi gerektirdiği için sadece spec'li hatta var.

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

## Kurulum kılavuzu modeli (`kurulum/`)

Spec hattından ayrı: montaj animasyonu için **bağlantı elemanları dahil**
modellenmiş ürünler. `kurulum/ayakkabilik_tek_kapakli.rb` tek kapaklı (klapa)
ayakkabılığı (60 × 50 × 40 cm) SketchUp'ta kurar:

- Her panel ayrı bileşen ve ayrı etiket (tag). Fabrikada takılı gelen parçalar
  panelin içinde ayrı bileşen: raf pimleri, kulp ve
  - şeffaf çektirme — erkek (geçen parça: pimli blok + M6 vida) tablalarda, dişi
    (geçirilen parça: üstten açık pim yuvalı blok + kare somun) yanlarda ve bazada.
  - Ø35 gizli menteşe — taban (küçük parça: haç biçimli, oval delikli, çatal vidalı)
    alt tablada; kap (kare ağızlı flanş) + bağlantı kolu + kol (çatal uçlu, kare
    yuvada sabitleme vidası) kapakta.
- Arkalık yanlardaki ve alt tabladaki 4 × 8 mm kanala geçer; üst tabla yanların
  20 mm altında, arkalık yan üst kotuna kadar çıkar. Raf pimleri alt tablanın üst
  yüzünden 190 mm yukarıda, baza 564 × 100 mm.
- Sahneler: `0 Kutu İçeriği` → `1 Sol Yan + Arkalık` … `7 Baza` → `8 Bitmiş Ürün`.

SketchUp Ruby Konsolu:

```ruby
load 'C:/.../scripts/product-3d/kurulum/ayakkabilik_tek_kapakli.rb'
OzcanKurulum::Ayakkabilik.kur('C:/.../ayakkabilik_kurulum.skp') # açık modeli temizler!
OzcanKurulum::Ayakkabilik.oynat                                  # animasyonu ekranda oynatır
OzcanKurulum::Ayakkabilik.kumanda                                # klavyeyle adım adım (aşağıda)
OzcanKurulum::Ayakkabilik.kaydet('C:/kareler')                   # 1280×720, 25 fps PNG kareler
```

Kareleri adım başlıklı videoya çevirmek (ffmpeg gerekir):

```bash
python scripts/product-3d/kurulum/video.py C:/kareler kurulum.mp4
```

Animasyon zaman çizelgesi `cizelge` metodunda; her adım parça hareketi +
tornavida ile vida sıkma (vida döner ve 4 mm ilerler, parça son 2 mm'yi çeker)
olarak tanımlı. Kapak menteşesi
kinematik: kapak açık halde gelir, kolun çatalı tabandaki vidanın altına kayar;
kapak kapanırken kap kapakla döner, kol tabanda kalır, bağlantı kolu uzar.

### Adım adım oynatma

`kumanda` sonrası çizim alanına bir kez tıklayıp klavyeyle: **→** bir adımı oynatıp
sonunda durur, **←** bir adım geri alır, **Enter** olduğu yerde durdurur / devam
ettirir, **Esc** çıkar ve modeli montajlı hale döndürür. Aynısı konsoldan:
`sonraki`, `onceki`, `durdur`, `devam`, `adim(3)` (sadece 3. adım), `git(3)`
(3. adımın başına atla), `bitir`. Adımlar: 0 kutu içeriği, 1–7 montaj, 8 bitmiş ürün.
Durdurulmuş modeli kaydetmeden önce `bitir` (ya da Esc) — yoksa parçalar sökük kalır.

### Çok amaçlı dolap (`kurulum/cok_amacli_dolap.rb`)

34,7 × 170 × 34,1 cm boy dolabı: 80 cm üst kapak, 25 cm açık niş, 60 cm alt kapak,
5 cm ayarlı ayak. Kullanım ve oynatma kontrolleri ayakkabılıkla aynı
(`OzcanKurulum::CokAmacliDolap.kur / oynat / kumanda / kaydet`). Farkları:

- Arkalık dört kenardan kanala geçer (iki yan, alt ve üst tabla).
- Şeffaf çektirme açılı vidalı: dişi C kesitli kanal, erkek pahlı blok + pirinç burç;
  metal vida köşeye 45° girip iki paneli birden çeker. Alt tabla ve niş tablalarında
  dişi tablada, üst tablada (yukarıdan indiği için) dişi yanda.
- Ayaklar iki parça: tabla altında taban, krom ayak çevrilerek takılır.
- Kapaklar tam bindirme, menteşeler sol yanda; kapak açık halde gelip kol tabana kayar.
- Adımlar: sol yan + arkalık → alt tabla + ayaklar → sağ yan → üst tabla → niş üst →
  niş alt → raflar → kapaklar.
