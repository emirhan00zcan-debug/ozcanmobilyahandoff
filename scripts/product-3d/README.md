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

### İki kapaklı dolap (`kurulum/iki_kapakli_dolap.rb`)

69 × 65 × 34,5 cm alt dolap: iki tam bindirme kapak (menteşeler dış yanlarda), iki raf
(eşit üç bölme), üst tabla yanların üstünde ve kapakları örter, 5 cm ayarlı ayak.
`OzcanKurulum::IkiKapakliDolap.kur / oynat / kumanda / kaydet`. Adımlar: sol yan +
arkalık → ayaklar + alt tabla → sağ yan → üst tabla → raflar → kapaklar → düğme
kulplar (demonte gelir; kapak açılır, kulp önden, kulp vidası arkadan sıkılır).

### Fırın mikrodalga dolabı (`kurulum/firin_mikrodalga_dolabi.rb`)

60 × 180 × 62 cm boy dolap (ayaksız 175): üstte 51 cm sola açılan kapaklı bölme
(içinde pimli raf), mikrodalga nişi (36,4 cm), fırın nişi (59 cm), altta 25 cm öne
yatan klapa kapaklı bölme; 5 cm ayak. `OzcanKurulum::FirinMikrodalgaDolabi.kur /
oynat / kumanda / kaydet`. Farkları:

- Her köşede 3 açılı şeffaf çektirme; alt ve üst tabla sol yana yandan kayar, sağ yan
  ikisine birden oturur.
- Arkalık (3 mm, beyaz) arkadan hazır deliklere 24 çiviyle çakılır; çekiç animasyonlu.
- Üç ara tabla gömme rafix'li: yanlardaki rafix pimlerine oturur, rafix'ler alttan
  tornavidayla çeyrek tur çevrilir.
- Üst kapağın menteşeleri sol yanda, alt klapanınkiler alt tablanın üstünde.
- Krom çubuk kulp (192 mm): üst kapakta sağda dikey, klapada üstte yatay; ikişer kulp
  vidası arkadan.
- Adımlar: ayaklar + alt tabla → üst tabla → sağ yan → arkalık (çivi) → raf → ara
  tablalar → kapaklar → kulplar.

### Fırın dolabı, tablasız (`kurulum/firin_dolabi.rb`)

60 × 86 × 60 cm (kapakla 62) ankastre fırın alt dolabı: yanlar yere kadar iner, alt
tabla 10 cm bazanın üstünde; alt tablanın üstünde 15,5 cm çekmece kapağı (öne yatan
klapa, arkasında 12 cm bölme), orta bölme üstünde 58,5 cm fırın nişi; üstte yanlardan
vidalı ön destek parçası. Ayak ve arkalık yok. `OzcanKurulum::FirinDolabi.kur / oynat /
kumanda / kaydet`. Farkları:

- Orta bölme iki yanın arasına yukarıdan iner (erkek bölmenin altında, dişi yanlarda);
  baza önden alt tablanın altına kayar, vidaları arkadan sıkılır. Bu dar yerlerde kısa
  tornavida kullanılır.
- Siyah süslü kulp (160 mm vida aralığı), kapağın üst kenarından 4 cm aşağıda.
- Adımlar: alt tabla → sağ yan → orta bölme → üst destek → baza → çekmece kapağı → kulp.
- Tablalı varyasyon: `OzcanKurulum::FirinDolabi.kur(yol, varyant: :tablali)`. Üstte
  60 × 65 × 3,6 cm dolu tabla (iki kat 18 mm, önde kapağı 3 cm geçer); yanların iç yüzünde
  üstte köşebentler takılı gelir, tabla son adımda bunlara alttan 4 vidayla bağlanır.
  Varyant modelde saklanır; kaydedilmiş dosya açılınca oynatma doğru varyantla kurulur.

### Kitaplık (`kurulum/kitaplik.rb`)

80 × 97 × 22 cm, üç gözlü açık kitaplık: iki yan arasında dört yatay tabla, her gözde bir
dikey bölme (alt ve üst gözde solda, ortada sağda), arka köşelerde dört 45° üçgen köşe
parçası; arkalık yok. Ölçüler fotoğraflardan (18 mm panel kalınlığı referans).
`OzcanKurulum::Kitaplik.kur / oynat / kumanda / kaydet`. Farkları:

- Tüm birleşimler alyan (konfirmat 7×50) vida: panellerde Ø10 havşa yuvası açık gelir,
  vidalar demonte; tornavida yerine L alyan anahtarı döner. En son tıpalar takılır.
- Vida sayısı: yatay tablalar 16 (her yana 2), dikey bölmeler 12 (üstten 2, alttan 2),
  köşe parçaları 8 (yandan ve tabladan birer).
- Adımlar: sol yan + alt tabla → sağ yan (U) → ara tabla 1 → ara tabla 2 → üst tabla →
  dikey bölmeler (alttan yukarı) → köşe parçaları → tıpalar.

### Çapraz kitaplık (`kurulum/capraz_kitaplik.rb`)

60 × 140 × 30 cm ağaç biçimli kitaplık: yere basan dikey arka tablanın önünde, ayaklı alt
tablanın üstünde yedi adet 45° çapraz raf; '\' raflar sol, '/' raflar sağ yandan iner ve her
biri alttaki rafa oturur (zikzak). Ölçüler fotoğraflardan (18 mm panel kalınlığı referans).
`OzcanKurulum::CaprazKitaplik.kur / oynat / kumanda / kaydet`. Farkları:

- Rafların kesiti `RAFLAR` tablosundan (yön + yan kenardaki yükseklik) hesaplanır; uçları
  yan kenarda düşey, iç uçları alttaki rafın üst yüzüne oturacak biçimde kesilir.
- Alt tabla ve her raf arka tablaya arkadan ikişer alyan vidayla bağlanır (16 vida).
- Adımlar: ayaklar → arka tabla + alt tabla → 1.–7. raf alttan yukarı.

### Konsol (`kurulum/konsol.rb`)

145 × 72,5 × 44,5 cm TV konsolu: beyaz gövde, membran (latte) kapak ve çekmece önleri
(üst kenarda gömme kulp), 36 mm meşe üst tabla, kemerli baza. Yanlarda tek raflı kapaklı
bölme, ortada alt çekmece / açık niş (23,5 cm) / üst çekmece. Ölçüler kullanıcıdan;
fotoğrafla doğrulandı. `OzcanKurulum::Konsol.kur / oynat / kumanda / kaydet`. Farkları:

- Şeffaf çektirmeler: dış yanlarda altta ve üstte üçer (üst tabla yukarıdan iner), orta
  yanlarda ikişer (önden girip yana kayar), niş tablalarında her yanda iki (vidaları çekmece
  boşluğundan), bazada ön üç, yanlarda ikişer (vidaları arkadaki boşluktan).
- Çekmeceler minifixle kurulur: yanlardaki bulonlar ön ve arkanın uçlarına geçer, eksantrikler
  yarım tur çevrilir; dip alttan çivilenir. Ray parçaları orta yanlarda ve çekmece yanlarında
  takılı gelir; çekmece hizalanıp itilir.
- Arkalık, ana çerçeve (yanlar + alt + üst tabla) kurulunca çakılır.
- Adımlar: sol yan + alt tabla → sağ yan → üst tabla → arkalık → orta yanlar → alt çekmece →
  üst çekmece → niş tablaları → raflar → kapaklar → baza.

### Aren köşe saksılık (`kurulum/kose_saksilik.rb`)

Köşe merdiven raf, taban 63 × 63, yükseklik 175 cm: duvar köşesinde L oluşturan iki köşe
dikmesi, iki duvar boyunca yukarı doğru içe eğilen iki eğik dikme (krem, 6,5 cm) ve beş
çeyrek daire meşe raf (63, 50, 40, 30, 22 cm; en alttaki yerden 6 cm, aralar 40 cm). Ölçüler
ürün belgesinden. `OzcanKurulum::KoseSaksilik.kur / oynat / kumanda / kaydet`.

- Tüm birleşimler alyan vida (25): köşe dikmeleri birbirine 5, her raf köşe dikmelerine 2,
  eğik dikmeler raflara 5'er; vidalar dikmelerin duvar tarafındaki yuvalardan girer.
- Adımlar: köşe dikmeleri (L) → raflar alttan üste → sol eğik dikme → sağ eğik dikme.

**Kamera:** Vida sıkılırken kamera otomatik olarak o vidaya yaklaşır (tornavida ve vida
başı birlikte görünür), adım bitince genel görünüşe döner. `kumanda` sırasında **K**
serbest kamerayı açar/kapatır: fareyle istenen açıya çevrilir, oynatma o açıdan
sürer (konsoldan `serbest_kamera(true/false)`). Video ve önizleme her zaman oynatma
kamerasıyla çekilir.
