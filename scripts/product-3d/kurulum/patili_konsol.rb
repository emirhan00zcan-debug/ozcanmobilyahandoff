# encoding: UTF-8
# Patili Konsol — kedi yatağı + mama istasyonu + depolama (120 x 70 x 51 cm) — model ve kurulum kılavuzu.
# Özcan Mobilya tasarımı (müşterinin gösterdiği evcil hayvan konsolundan esinlenildi, aynısı değil).
# Beyaz 18 mm sunta, gömme kulplu önler, önde 6 cm baza.
#   Solda kedi yatağı: yuvarlak tepeli ağız paneli; altta 17,5 cm eşik olan çekilir yatak tepsisi (minderle
#   birlikte öne çıkar, içi kolay temizlenir); sol yanda üç oval pencere, arkalıkta havalandırma delikleri ve
#   ısıtmalı ped için kablo deliği.
#   Sağda mama kolonu: altta çekilir kap çekmecesi (iki paslanmaz kap, çıkarılabilir kap tablası ve damlama
#   tepsisi; kap ağzı yerden ~16 cm), ortada mama çekmecesi (kapaklı mama kabı), üstte aksesuar çekmecesi.
#   Sağ yanda iki tasma askısı.
#
# Her panel ayrı bileşen; fabrikada takılı gelenler (şeffaf çektirme erkek/dişi, minifix eksantrik ve bulonları,
# makaralı ray parçaları, kaydırma pabuçları) panelin içinde. Çiviler, tasma askıları ve vidaları, minder, kaplar,
# kap tablası, damlama tepsisi ve mama kabı ayrı gelir.
#   1 sol yan + alt tabla  2 sağ yan  3 ara dikme  4 baza  5 ağız paneli  6 üst tabla  7 arkalık (çivi)
#   8-11 mama çekmecesi (yanlar/minifix, eksantrikler, dip, raylar)  12 aksesuar çekmecesi
#   13 kap çekmecesi ve yatak tepsisi (kaydırma pabuçlarıyla alt tablada kayar)  14 minder  15 kaplar
#   16 mama kabı  17 tasma askıları
#
# SketchUp > Pencere > Ruby Konsolu:
#   load 'C:/.../scripts/product-3d/kurulum/patili_konsol.rb'
#   OzcanKurulum::PatiliKonsol.kur               # AÇIK MODELİ TEMİZLER, modeli sıfırdan kurar
#   OzcanKurulum::PatiliKonsol.oynat             # montaj animasyonunu ekranda oynatır
#   OzcanKurulum::PatiliKonsol.kumanda           # klavyeyle adım adım: → ← Enter, K serbest kamera, Esc
#   (konsoldan: sonraki, onceki, durdur, devam, adim(3), git(3), bitir)
#   OzcanKurulum::PatiliKonsol.kaydet('C:/kareler') # animasyonu PNG karelere yazar
#
# Koordinatlar mm: X genişlik (0 = sol dış yüz), Y derinlik (0 = gövde ön yüzü, +Y arkaya;
# önler Y<0'da, arkalık Y=477..480), Z yükseklik (0 = zemin).

module OzcanKurulum
  module PatiliKonsol
    extend self

    # ------------------------------------------------------------------
    # Ölçüler (mm)
    # ------------------------------------------------------------------
    W = 1200.0           # gövde ve tabla genişliği
    T = 18.0             # panel kalınlığı
    D = 477.0            # yan derinliği; + 3 mm çakma arkalık = 480; önlerle 500, tabla 510
    ARKA_T = 3.0
    Z0 = 60.0            # baza yüksekliği = alt tablanın alt yüzü; yanlar yere kadar
    ZT = 682.0           # yanların üst kenarı; üstünde 18 mm tabla → 700
    TABLA_DER = 510.0    # tabla arkalıkla bir, önde önleri 1 cm geçer
    DIKME_X = 718.0      # ara dikmenin sol yüzü: yatak bölmesi iç 70 cm, mama kolonu iç 44,6 cm
    KAPI_PAY = 2.0
    SOL_X0 = 2.0         # yatak bölmesi önleri (ağız paneli, yatak tepsisi önü)
    SOL_W = 723.0
    SAG_X0 = 729.0       # mama kolonu önleri
    SAG_W = 469.0
    ALT_Z = [63.0, 112.0].freeze  # alt sıradaki önler (yatak tepsisi, kap çekmecesi): alt kenar, yükseklik
    AGIZ_Z = [178.0, 502.0].freeze
    AGIZ_W = 540.0       # ağız: 54 cm genişlik, eşikten 40 cm yükseklik, tepe köşeleri R150
    AGIZ_H = 400.0
    AGIZ_R = 150.0
    CEK_Y = [70.0, 400.0].freeze  # yan-alt, yan-üst ve dikme birleşimlerinde ikişer çektirme
    BAZA_X = [300.0, 900.0].freeze
    AGIZ_CEK_Z = [260.0, 600.0].freeze
    PENCERE_Y = [150.0, 240.0, 330.0].freeze # sol yandaki oval pencereler (4 x 24 cm)
    PENCERE_Z = [300.0, 460.0].freeze
    ASKI_Y = [130.0, 330.0].freeze           # sağ yanda tasma askıları
    ASKI_Z = 560.0
    KUTU_D = 450.0
    KUTU_T = 18.0
    KAYDIR = 3.0         # kaydırma pabucu: alt sıradaki çekmeceler alt tablanın üstünde kayar
    RAY_L = 450.0
    RAY_Y0 = 3.0
    KAM_ARA = 24.0       # minifix eksantriğinin panel ucuna uzaklığı (bulon başı eksantriğin içine gelir)
    SAG_KUTU = [DIKME_X + T + 14, W - T - 14].freeze # raylı kutular: yanlarda 14 mm ray boşluğu
    # on: [x, genişlik, alt kenar, yükseklik]; x: kutunun dış yüzleri; zb: kutunun alt yüzü; h: yan yüksekliği.
    # Alt sıradakiler raysız: alt tablada kayar, çektirmelerden uzak dursun diye yanlardan 40 mm içeride.
    CEKMECE = {
      mama:  { ad: 'Mama Çekmecesi', on: [SAG_X0, SAG_W, 178.0, 340.0], x: SAG_KUTU, zb: 200.0, h: 250.0, ray: true },
      aks:   { ad: 'Aksesuar Çekmecesi', on: [SAG_X0, SAG_W, 521.0, 159.0], x: SAG_KUTU, zb: 540.0, h: 100.0, ray: true },
      kap:   { ad: 'Kap Çekmecesi', on: [SAG_X0, SAG_W, *ALT_Z], x: [DIKME_X + T + 40, W - T - 40],
               zb: Z0 + T + KAYDIR, h: 60.0, ray: false },
      yatak: { ad: 'Yatak Tepsisi', on: [SOL_X0, SOL_W, *ALT_Z], x: [T + 40, DIKME_X - 40],
               zb: Z0 + T + KAYDIR, h: 76.0, ray: false }
    }.freeze
    CEKMECE_PAR = %w[on sol sag arka dip].freeze
    MINDER = [576.0, 406.0, 70.0].freeze # taban; kenar yastığı +55
    KAP_TABLA = [366.0, 220.0].freeze
    KAP_ARA = 180.0      # iki kabın merkezleri arası
    PLAKA_T = 3.0

    DIKEY_FOV = 30.0
    VIDEO_FOV = 50.0

    DICT = 'ozcan_kurulum'
    PARCA_CEKMECE = CEKMECE.keys.flat_map { |c| CEKMECE_PAR.map { |p| [:"#{c}_#{p}", [c, p]] } }.to_h.freeze
    CEKMECE_SIRA = PARCA_CEKMECE.keys.freeze
    EKLER = { yatak: %i[minder], kap: %i[tepsi kap_tablasi kaplar], mama: %i[mama_kabi] }.freeze
    EK_SIRA = EKLER.values.flatten.freeze
    SIRA = (%i[alt_tabla sol_yan sag_yan dikme baza agiz ust_tabla arkalik] + CEKMECE_SIRA + EK_SIRA).freeze
    AD = {
      alt_tabla: 'Alt Tabla', sol_yan: 'Sol Yan', sag_yan: 'Sağ Yan', dikme: 'Ara Dikme', baza: 'Baza',
      agiz: 'Ağız Paneli', ust_tabla: 'Üst Tabla', arkalik: 'Arkalık', minder: 'Minder', tepsi: 'Damlama Tepsisi',
      kap_tablasi: 'Kap Tablası', kaplar: 'Paslanmaz Kap (2)', mama_kabi: 'Mama Kabı'
    }.merge(PARCA_CEKMECE.map { |k, (c, p)|
      [k, "#{CEKMECE[c][:ad]} #{{ 'on' => 'Önü', 'sol' => 'Yanı (sol)', 'sag' => 'Yanı (sağ)', 'arka' => 'Arkası', 'dip' => 'Dibi' }[p]}"]
    }.to_h).freeze
    ETIKET = {
      alt_tabla: '01 Alt Tabla', sol_yan: '02 Sol Yan', sag_yan: '03 Sağ Yan', dikme: '04 Ara Dikme', baza: '05 Baza',
      agiz: '06 Ağız Paneli', ust_tabla: '07 Üst Tabla', arkalik: '08 Arkalık'
    }.merge(PARCA_CEKMECE.map { |k, (c, _)| [k, "#{format('%02d', 9 + CEKMECE.keys.index(c))} #{CEKMECE[c][:ad]}"] }.to_h)
     .merge(EK_SIRA.map { |k| [k, '13 Minder ve Kaplar'] }.to_h).freeze
    LISTE_TAG = '00 Parça Listesi'
    ARAC_TAG = '99 Tornavida'

    # Kamera noktaları [göz, hedef] (mm). c_*: mama çekmecesi önde, tezgah yüksekliğinde kurulurken.
    KAM = {
      liste:   [[3500, -3700, 6500], [3500, 1100, 0]],
      1 =>     [[1900, -1600, 1300], [500, 240, 250]],
      2 =>     [[-800, -1900, 1500], [700, 240, 300]],
      3 =>     [[1800, -1900, 1500], [700, 240, 300]],
      4 =>     [[2000, -2000, 600], [600, 200, 60]],
      5 =>     [[1500, -2100, 1300], [380, 0, 380]],
      6 =>     [[2300, -2600, 2300], [600, 240, 450]],
      7 =>     [[2400, 2800, 1700], [600, 240, 400]],
      c_yan:   [[1100, -380, 1140], [718, -690, 778]],
      c_kam:   [[980, -1400, 1900], [959, -480, 770]],
      c_dip:   [[2160, -1550, 150], [959, -470, 700]],
      c_ray:   [[2300, -1800, 1000], [900, -200, 350]],
      aks:     [[2300, -2600, 1500], [950, -400, 600]],
      alt:     [[1900, -2900, 1300], [600, -400, 200]],
      ek_yatak: [[1800, -2600, 1700], [520, -300, 200]],
      ek_kap:  [[2200, -2400, 1500], [880, -300, 180]],
      ek_mama: [[2200, -2500, 1900], [880, -300, 330]],
      aski:    [[3100, -1100, 1200], [1100, 240, 450]],
      bitti:   [[2200, -2600, 1500], [600, 200, 330]]
    }.freeze

    # Parçaların yerleşim orijini (bileşen orijini = parçanın min köşesi)
    ORIJIN = {
      alt_tabla: [T, 0, Z0], sol_yan: [0, 0, 0], sag_yan: [W - T, 0, 0], dikme: [DIKME_X, 0, Z0 + T], baza: [T, 0, 0],
      agiz: [SOL_X0, -T, AGIZ_Z[0]], ust_tabla: [0, D + ARKA_T - TABLA_DER, ZT], arkalik: [0, D, Z0],
      minder: [CEKMECE[:yatak][:x][0] + KUTU_T + 4, 20, Z0 + T + KAYDIR + ARKA_T],
      tepsi: [CEKMECE[:kap][:x][0] + KUTU_T, 18, Z0 + T + KAYDIR + ARKA_T],
      kap_tablasi: [CEKMECE[:kap][:x][0], 16, Z0 + T + KAYDIR + ARKA_T + CEKMECE[:kap][:h]],
      kaplar: [CEKMECE[:kap][:x][0], 16, Z0 + 2 * T + KAYDIR + ARKA_T + CEKMECE[:kap][:h]],
      mama_kabi: [CEKMECE[:mama][:x][0] + 34, 26, CEKMECE[:mama][:zb] + ARKA_T]
    }.merge(CEKMECE.flat_map { |c, h|
      kz = h[:zb] + ARKA_T
      x0, x1 = h[:x]
      [[:"#{c}_on", [h[:on][0], -(KAPI_PAY + T), h[:on][2]]], [:"#{c}_sol", [x0, -KAPI_PAY, kz]],
       [:"#{c}_sag", [x1 - KUTU_T, -KAPI_PAY, kz]], [:"#{c}_arka", [x0 + KUTU_T, KUTU_D - KAPI_PAY - KUTU_T, kz]],
       [:"#{c}_dip", [x0, -KAPI_PAY, h[:zb]]]]
    }.to_h).freeze

    # Arkalık çivileri: yanların, alt tablanın ve dikmenin arka kenarına (arkalık-yerel x, z)
    CIVI = [130, 280, 430, 580].flat_map { |z| [[T / 2, z - Z0], [W - T / 2, z - Z0]] } +
           [200, 500, 900, 1100].map { |x| [x, T / 2] } + [250, 450].map { |z| [DIKME_X + T / 2, z - Z0] }
    CIVILER = (1..CIVI.size).map { |i| format('civi_%02d', i) }.freeze
    DIP_CIVILER = CEKMECE.keys.flat_map { |c| (1..6).map { |i| "#{c}_civi_#{i}" } }.freeze
    ASKILAR = ASKI_Y.each_index.map { |i| "aski_#{i + 1}" }.freeze
    ASKI_VIDALARI = ASKI_Y.each_index.map { |i| "askivida_#{i + 1}" }.freeze
    DEMONTE = (CIVILER + DIP_CIVILER + ASKILAR + ASKI_VIDALARI).freeze

    # ------------------------------------------------------------------
    # Geometri yardımcıları
    # ------------------------------------------------------------------
    def P(x, y, z) Geom::Point3d.new(x.mm, y.mm, z.mm) end
    def yon(x, y, z) Geom::Vector3d.new(x, y, z).normalize end
    def tr(x, y, z) Geom::Transformation.translation(Geom::Vector3d.new(x.mm, y.mm, z.mm)) end

    # Yerel x ve z eksenleri verilen konum (y = z × x, sağ el kuralı)
    def eksen(o, x, z)
      xv = yon(*x)
      zv = yon(*z)
      Geom::Transformation.axes(P(*o), xv, zv * xv, zv)
    end

    def kutu(e, x0, y0, z0, x1, y1, z1)
      f = e.add_face(P(x0, y0, z0), P(x1, y0, z0), P(x1, y1, z0), P(x0, y1, z0))
      h = (z1 - z0).mm
      f.pushpull(f.normal.z > 0 ? h : -h)
    end

    # Var olan yüzeyin üstüne çizilen yüz ters yönlü oluşabiliyor: önce komşu
    # eş düzlemli yüze hizalanır. İtme bazen yerinde kopya yüz bırakıyor: tüm
    # kenarları 2'den fazla yüze bağlı iç yüzler silinir (katı kalsın).
    def itme(f, v, mesafe)
      e = f.parent.entities
      komsu = f.edges.flat_map(&:faces).find { |g| g != f && g.normal.parallel?(f.normal) }
      f.reverse! if komsu && !komsu.normal.samedirection?(f.normal)
      f.pushpull(f.normal % v > 0 ? mesafe.mm : -mesafe.mm)
      ic = e.grep(Sketchup::Face).select { |x| x.edges.all? { |k| k.faces.size > 2 } }
      e.erase_entities(ic) unless ic.empty?
    end

    # Noktalardan yüz çizip verilen yöne iter (var olan yüzeye çizilirse oyar).
    def it(e, pts, v, mesafe)
      itme(e.add_face(pts), v, mesafe)
    end

    def daire_it(e, c, n, r, v, mesafe, seg = 24)
      kenar = e.add_circle(c, n, r.mm, seg)
      f = kenar.first.faces.find { |x| x.outer_loop.edges.all? { |k| kenar.include?(k) } }
      itme(f || e.add_face(kenar), v, mesafe)
    end

    # x = sabit düzleminde, üstten açık U profili (yuvarlak dipli)
    def u_profil(x, r, zc, ztop, seg = 12)
      pts = [P(x, -r, ztop)]
      (0..seg).each do |i|
        a = Math::PI + Math::PI * i / seg
        pts << P(x, r * Math.cos(a), zc + r * Math.sin(a))
      end
      pts << P(x, r, ztop)
    end

    # Teğet çemberlerden plaka dış hattı (saat yönü tersine). daireler: [[x, y, r], ...].
    # 'ice' indisli kenar (daire i → i+1) içe doğru 'bukum' mm kavisli çizilir.
    def plaka_hatti(daireler, ice = nil, bukum = 0.0)
      n = daireler.size
      kenar = Array.new(n) do |i|
        ax, ay, ar = daireler[i]
        bx, by, br = daireler[(i + 1) % n]
        d = Math.hypot(bx - ax, by - ay)
        ux = (bx - ax) / d
        uy = (by - ay) / d
        c = (ar - br) / d
        s = Math.sqrt(1 - c * c)
        nx = ux * c + uy * s # dış normal: gidiş yönünün sağı
        ny = uy * c - ux * s
        [[ax + ar * nx, ay + ar * ny], [bx + br * nx, by + br * ny], [nx, ny]]
      end
      pts = []
      n.times do |i|
        cx, cy, r = daireler[i]
        a0 = Math.atan2(kenar[i - 1][1][1] - cy, kenar[i - 1][1][0] - cx)
        a1 = Math.atan2(kenar[i][0][1] - cy, kenar[i][0][0] - cx)
        a1 += 2 * Math::PI if a1 < a0 - 1e-9
        k = [((a1 - a0) / 0.25).ceil, 1].max
        (0..k).each { |j| a = a0 + (a1 - a0) * j / k; pts << [cx + r * Math.cos(a), cy + r * Math.sin(a)] }
        next unless i == ice
        p0, p1, (nx, ny) = kenar[i]
        kx = (p0[0] + p1[0]) / 2 - 2 * bukum * nx
        ky = (p0[1] + p1[1]) / 2 - 2 * bukum * ny
        (1..11).each do |j|
          t = j / 12.0
          pts << [(1 - t)**2 * p0[0] + 2 * (1 - t) * t * kx + t * t * p1[0],
                  (1 - t)**2 * p0[1] + 2 * (1 - t) * t * ky + t * t * p1[1]]
        end
      end
      pts
    end

    def yuvarlak_dik(x0, y0, x1, y1, r)
      plaka_hatti([[x0 + r, y0 + r, r], [x1 - r, y0 + r, r], [x1 - r, y1 - r, r], [x0 + r, y1 - r, r]])
    end

    # X ekseni etrafında döndürülmüş katı; prof = [[x, r], ...] kapalı profil (mm)
    def torna(e, prof, seg, mat)
      alan = 0.0
      prof.each_with_index { |(x1, r1), i| x2, r2 = prof[(i + 1) % prof.size]; alan += x1 * r2 - x2 * r1 }
      prof = prof.reverse if alan > 0 # normaller dışa baksın
      mesh = Geom::PolygonMesh.new
      nk = lambda do |x, r, j|
        a = 2 * Math::PI * j / seg
        Geom::Point3d.new(x.mm, (r * Math.cos(a)).mm, (r * Math.sin(a)).mm)
      end
      prof.each_with_index do |(x1, r1), i|
        x2, r2 = prof[(i + 1) % prof.size]
        next if r1 <= 0 && r2 <= 0
        seg.times do |j|
          pts = [nk.(x1, r1, j)]
          pts << nk.(x1, r1, j + 1) if r1 > 0
          pts << nk.(x2, r2, j + 1)
          pts << nk.(x2, r2, j) if r2 > 0
          mesh.add_polygon(pts)
        end
      end
      g = e.add_group
      g.entities.add_faces_from_mesh(mesh, Geom::PolygonMesh::AUTO_SOFTEN | Geom::PolygonMesh::SMOOTH_SOFT_EDGES, mat, mat)
      g
    end

    # Yıldız (+) vida yuvası: x düzleminde ince koyu artı işareti
    def yildiz(e, x, r)
      a = r * 0.62
      b = r * 0.16
      pts = [[a, b], [b, b], [b, a], [-b, a], [-b, b], [-a, b], [-a, -b], [-b, -b], [-b, -a], [b, -a], [b, -b], [a, -b]]
      g = e.add_group
      f = g.entities.add_face(pts.map { |y, z| P(x, y, z) })
      f.material = @mat[:yuva]
      f.back_material = @mat[:yuva]
      g
    end

    def boya(e, mat)
      e.grep(Sketchup::Face).each { |f| f.material = mat; f.back_material = mat }
    end

    def nitelik(e, h) h.each { |k, v| e.set_attribute(DICT, k.to_s, v) } end
    def nit(e, k) e.get_attribute(DICT, k.to_s) end

    # ------------------------------------------------------------------
    # Malzemeler
    # ------------------------------------------------------------------
    def malzemeler
      mk = lambda do |ad, rgb, alfa = 1.0|
        m = @m.materials[ad] || @m.materials.add(ad)
        m.color = Sketchup::Color.new(*rgb)
        m.alpha = alfa
        m
      end
      @mat = {
        govde: mk.('Mat Beyaz', [243, 243, 241]),
        arka: mk.('Arkalık (beyaz duralit)', [234, 234, 230]),
        dip: mk.('Çekmece Dibi (beyaz)', [236, 235, 230]),
        pabuc: mk.('Kaydırma Pabucu', [250, 250, 250]),
        minder: mk.('Minder (bukle)', [214, 206, 192]),
        paslanmaz: mk.('Paslanmaz Çelik', [196, 201, 207]),
        plastik: mk.('Gri Plastik', [150, 156, 164]),
        kab: mk.('Mama Kabı', [224, 229, 235]),
        kapak: mk.('Mama Kabı Kapağı', [120, 150, 182]),
        kulp: mk.('Siyah Askı', [32, 32, 34]),
        ray: mk.('Beyaz Ray', [242, 242, 238]),
        teker: mk.('Ray Tekerleği', [188, 190, 194]),
        seffaf: mk.('Şeffaf Plastik', [205, 225, 238], 0.35),
        cinko: mk.('Çinko Kaplama', [160, 164, 170]),
        pirinc: mk.('Pirinç Burç', [196, 158, 72]),
        celik: mk.('Çelik', [110, 113, 120]),
        ahsap: mk.('Çekiç Sapı', [176, 128, 78]),
        yuva: mk.('Vida Yuvası', [40, 40, 44]),
        sap: mk.('Tornavida Sapı', [226, 96, 24]),
        uc: mk.('Tornavida Ucu', [70, 72, 78])
      }
    end

    # ------------------------------------------------------------------
    # Hırdavat bileşenleri
    # ------------------------------------------------------------------
    # Vida: baş x∈[-bas_h, 0], gövde +x yönünde (vidalanma yönü)
    def vida_tanimi(ad, bas_r, bas_h, govde_r, boy)
      d = @m.definitions.add(ad)
      prof = [[-bas_h, 0], [-bas_h, bas_r * 0.82], [-bas_h * 0.35, bas_r], [0, bas_r], [0, govde_r],
              [boy - govde_r * 1.6, govde_r], [boy, govde_r * 0.3], [boy, 0]]
      torna(d.entities, prof, 20, @mat[:cinko])
      yildiz(d.entities, -bas_h - 0.05, bas_r * 0.82)
      d
    end

    # Havşa başlı vida: baş x∈[-2.2, 0] konik, gövde +x yönünde
    def havsa_vida_tanimi(ad = 'Sunta Vidası 3.5x16 (havşa)', boy = 16)
      d = @m.definitions.add(ad)
      torna(d.entities, [[-2.2, 0], [-2.2, 3.6], [0, 1.75], [boy - 2, 1.75], [boy, 0.5], [boy, 0]], 20, @mat[:cinko])
      yildiz(d.entities, -2.25, 3.2)
      d
    end

    # --- Şeffaf çektirme (açılı vidalı, iki parça) ---
    # İki yarım da "bağlantı çerçevesinde" çizilir: orijin iki panelin iç köşe
    # çizgisinde; y = köşe çizgisi boyunca, x = erkeğin panelinden uzağa (dişinin
    # paneli üzerinde), z = dişinin panelinden uzağa (erkeğin paneli üzerinde).
    # Erkek x=0 panelinde pahlı bir blok taşır. Dişi z=0 panelinde pahlı bir gövde
    # taşır; gövdedeki yuva yalnız erkeğin paneline açıktır (iki yanı kapalı), erkek
    # bloğu yandan ya da yukarıdan girer: dişi erkeğe geçer. Metal vida gövdenin pahlı
    # köşesinden 45° çapraz girip erkeğin pirinç burcuna vidalanır; sıkılınca iki
    # paneli birden köşeye çeker.
    VIDA_YON = [-1.0, 0.0, -1.0].freeze # vidalanma yönü (köşeye doğru)
    VIDA_OTURMA = [19 - 1.06, 0.0, 21 - 1.06].freeze # havşa dibi: vida başının alt yüzü

    def plaka_delikleri(e, delikler, n)
      delikler.each do |c|
        u = P(*c)
        daire_it(e, u, n, 3.8, n.reverse, 1.5, 16)
        daire_it(e, u.offset(n.reverse, 1.5.mm), n, 1.9, n.reverse, 1.5, 12)
      end
    end

    def erkek_tanimi
      d = @m.definitions.add('Çektirme Erkek (geçen parça)')
      e = d.entities
      it(e, yuvarlak_dik(-23.5, 5, 23.5, 19, 6.5).map { |y, z| P(0, y, z) }, yon(1, 0, 0), PLAKA_T)
      delik = [[PLAKA_T, -17, 12], [PLAKA_T, 17, 12]]
      plaka_delikleri(e, delik, X_AXIS)
      boya(e, @mat[:seffaf])
      g = e.add_group
      it(g.entities, [[3, 5], [15, 5], [15, 14], [12, 17], [3, 17]].map { |x, z| P(x, -8, z) }, yon(0, 1, 0), 16)
      boya(g.entities, @mat[:seffaf])
      torna(e, [[0, 1.7], [0, 3.5], [9, 3.5], [9, 1.7]], 16, @mat[:pirinc])
        .transform!(eksen([13.3, 0, 15.3], VIDA_YON, [0, 1, 0]))
      delik.each { |_, y, z| e.add_instance(@vida16h, eksen([-0.7, y, z], [-1, 0, 0], [0, 0, 1])) }
      d
    end

    def disi_tanimi
      d = @m.definitions.add('Çektirme Dişi (geçirilen parça)')
      e = d.entities
      it(e, yuvarlak_dik(0.5, -23.5, 35, 23.5, 7).map { |x, y| P(x, y, 0) }, yon(0, 0, 1), PLAKA_T)
      delik = [[29, -16.5, PLAKA_T], [29, 16.5, PLAKA_T]]
      plaka_delikleri(e, delik, Z_AXIS)
      boya(e, @mat[:seffaf])
      g = e.add_group
      govde = [[3.5, 3], [23, 3], [23, 17], [15, 25], [3.5, 25]]
      it(g.entities, govde.map { |x, z| P(x, -11, z) }, yon(0, 1, 0), 22)
      it(g.entities, [P(3.5, -9, 3), P(3.5, 9, 3), P(3.5, 9, 17.5), P(3.5, -9, 17.5)], yon(1, 0, 0), 12) # yuva
      daire_it(g.entities, P(19, 0, 21), Geom::Vector3d.new(1, 0, 1), 4.5, yon(-1, 0, -1), 1.5, 20)
      boya(g.entities, @mat[:seffaf])
      delik.each { |x, y, _| e.add_instance(@vida16h, eksen([x, y, -0.7], [0, 0, -1], [1, 0, 0])) }
      d
    end

    # Arkalık çivisi: baş x∈[-1.2, 0], gövde +x (çakılma yönü)
    def civi_tanimi
      d = @m.definitions.add('Arkalık Çivisi')
      torna(d.entities, [[-1.2, 0], [-1.2, 2.6], [0, 2.6], [0, 0.9], [18, 0.9], [20, 0], ], 12, @mat[:cinko])
      d
    end

    # Minifix eksantriği Ø15: yerel +x panelin içine (x=0 panel yüzü), yarım tur çevrilince
    # karşı paneldeki bulonun başını çeker.
    def kam_tanimi
      d = @m.definitions.add('Minifix Eksantrik Ø15')
      torna(d.entities, [[0, 0], [0, 7.5], [12, 7.5], [12, 0]], 24, @mat[:cinko])
      yildiz(d.entities, -0.05, 6)
      d
    end

    # Minifix bulonu: dişli kısmı panelde (x<0), başlı şaftı yerel +x yönünde 24 mm dışarıda.
    def bulon_tanimi
      d = @m.definitions.add('Minifix Bulonu')
      torna(d.entities, [[-8, 0], [-8, 2.5], [0, 2.5], [0, 3.5], [2, 3.5], [2, 2.5], [18, 2.5], [19, 4], [23, 4],
                         [24, 2], [24, 0]], 16, @mat[:cinko])
      d
    end

    # Çekiç: vuruş yüzü x=0'da, baş +x yönünde; sap aşağı (-z).
    def cekic_tanimi
      d = @m.definitions.add('Çekiç')
      torna(d.entities, [[0, 0], [0, 12], [2, 13], [26, 13], [30, 10], [34, 6], [40, 0]], 24, @mat[:celik])
      torna(d.entities, [[0, 0], [0, 9], [3, 10], [270, 13], [280, 12], [282, 0]], 20, @mat[:ahsap])
        .transform!(eksen([16, 0, -8], [0, 0, -1], [1, 0, 0]))
      d
    end

    def tornavida_tanimi
      d = @m.definitions.add('Tornavida')
      torna(d.entities, [[0, 0], [0, 0.9], [6, 2.2], [9, 3], [104, 3], [104, 0]], 20, @mat[:uc])
      torna(d.entities, [[100, 0], [100, 7], [106, 9], [112, 13], [118, 14], [186, 14], [194, 12.5],
                         [200, 9], [200, 0]], 28, @mat[:sap])
      d
    end

    # Dar yerler için (bazanın arkası) kısa tornavida
    def kisa_tornavida_tanimi
      d = @m.definitions.add('Kısa Tornavida')
      torna(d.entities, [[0, 0], [0, 0.9], [6, 2.2], [9, 3], [36, 3], [36, 0]], 20, @mat[:uc])
      torna(d.entities, [[32, 0], [32, 9], [38, 13], [44, 15], [82, 15], [88, 13], [92, 9], [92, 0]], 28, @mat[:sap])
      d
    end

    # ------------------------------------------------------------------
    # Panel bileşenleri
    # ------------------------------------------------------------------
    # Animasyonda dönen vida: parçanın içine ayrı örnek olarak eklenir.
    def vida_koy(e, defn, lt, p, d, strok, bas_h, w, id, kapi = false, kisa = false)
      i = e.add_instance(defn, lt)
      nitelik(i, vida: id, lt: lt.to_a, p: p.to_a, d: d.to_a, strok: strok, bas_h: bas_h, w: w.to_a, kapi: kapi,
                 kisa: kisa)
      i
    end

    def parca_tanimi(ad)
      @m.definitions.add(ad)
    end

    # Tasma askısı (siyah J kanca): yerel +x duvardan dışarı, z yukarı; plaka x∈[0, 3], vida plakanın üst yarısında.
    def aski_tanimi
      d = @m.definitions.add('Tasma Askısı')
      e = d.entities
      kutu(e, 0, -14, -28, 3, 14, 28)
      kutu(e, 3, -5, -26, 40, 5, -16)
      kutu(e, 32, -5, -16, 40, 5, 6)
      boya(e, @mat[:kulp])
      d
    end

    # Paslanmaz mama kabı: yerel +x yukarı (x=0 dip), ağız kenarı x=54..56'da tablaya oturur.
    def kap_tanimi
      d = @m.definitions.add('Paslanmaz Mama Kabı')
      torna(d.entities, [[0, 0], [0, 48], [52, 70], [54, 78], [56, 78], [56, 69], [2, 46], [2, 0]], 32, @mat[:paslanmaz])
      d
    end

    # Makaralı beyaz ray, dolap parçası: yanın iç yüzüne vidalı dik sac, altta kanal, önde naylon tekerlek.
    # xi panelin iç yüzü, sx içeri yönü, zb çekmecenin alt yüzü (panel-yerel).
    def ray_dolap(e, xi, sx, zb)
      a = ->(m) { xi + sx * m }
      g = e.add_group
      g.name = 'Ray (dolap parçası)'
      kutu(g.entities, a.(0), RAY_Y0, zb - 16, a.(1.5), RAY_Y0 + RAY_L, zb + 12)
      kutu(g.entities, a.(1.5), RAY_Y0, zb - 16, a.(12), RAY_Y0 + RAY_L, zb - 14.5)
      kutu(g.entities, a.(10.5), RAY_Y0 + 24, zb - 14.5, a.(12), RAY_Y0 + RAY_L, zb - 11)
      boya(g.entities, @mat[:ray])
      torna(e, [[0, 0], [0, 6], [5, 6], [5, 0]], 20, @mat[:teker])
        .transform!(eksen([a.(4), RAY_Y0 + 12, zb - 7.5], [sx, 0, 0], [0, 0, 1]))
    end

    # Ray, çekmece parçası: kutu yanının dış yüzüne vidalı L sac (altı dibin altına döner), arkada tekerlek.
    # xo yanın dış yüzü, sx dışarı yönü, zb kutunun alt yüzü (yan-yerel).
    def ray_cekmece(e, xo, sx, zb)
      a = ->(m) { xo + sx * m }
      g = e.add_group
      g.name = 'Ray (çekmece parçası)'
      kutu(g.entities, a.(0), 0, zb - 1.5, a.(1.5), RAY_L, zb + 26)
      kutu(g.entities, a.(0), 0, zb - 1.5, a.(-20), RAY_L, zb)
      kutu(g.entities, a.(0), RAY_L - 28, zb - 10, a.(1.5), RAY_L, zb - 1.5)
      boya(g.entities, @mat[:ray])
      torna(e, [[0, 0], [0, 6], [5, 6], [5, 0]], 20, @mat[:teker])
        .transform!(eksen([a.(4.5), RAY_L - 14, zb - 8.5], [sx, 0, 0], [0, 0, 1]))
    end

    # Tüm çektirmeler dünya koordinatında: k = iç köşe noktası, ex/ey/ez bağlantı çerçevesi
    # (x erkeğin panelinden uzağa, z dişinin panelinden uzağa). Alt tabla sol yana yandan kayar, sağ yan ona
    # oturur; dikme alt tablaya yukarıdan iner (çektirmeleri mama kolonu tarafında, yatak bölmesi temiz kalır);
    # baza alt tablanın altına önden kayar (vidaları arkadan, kısa tornavidayla); ağız paneli önden sol yana ve
    # dikmeye oturur (vidaları yatak bölmesinin içinden); üst tabla yukarıdan iner.
    def baglantilar
      l = []
      [[:sol_yan, T, 1, 'sol'], [:sag_yan, W - T, -1, 'sag']].each do |yan, xs, sx, taraf|
        CEK_Y.zip(%w[on arka]).each do |y, yer|
          l << { id: "alt_#{taraf}_#{yer}", disi: :alt_tabla, erkek: yan, k: [xs, y, Z0 + T], ex: [sx, 0, 0], ez: [0, 0, 1] }
          l << { id: "ust_#{taraf}_#{yer}", disi: yan, erkek: :ust_tabla, k: [xs, y, ZT], ex: [0, 0, -1], ez: [sx, 0, 0] }
        end
      end
      xd = DIKME_X + T
      CEK_Y.zip(%w[on arka]).each do |y, yer|
        l << { id: "dalt_#{yer}", disi: :alt_tabla, erkek: :dikme, k: [xd, y, Z0 + T], ex: [1, 0, 0], ez: [0, 0, 1] }
        l << { id: "dust_#{yer}", disi: :ust_tabla, erkek: :dikme, k: [xd, y, ZT], ex: [1, 0, 0], ez: [0, 0, -1] }
      end
      BAZA_X.each_with_index do |x, i|
        l << { id: "baza_#{i + 1}", disi: :alt_tabla, erkek: :baza, k: [x, T, Z0], ex: [0, 1, 0], ey: [1, 0, 0],
               ez: [0, 0, -1], kisa: true }
      end
      [[:sol_yan, T, 1, 'sol'], [:dikme, DIKME_X, -1, 'dikme']].each do |p, xs, sx, taraf|
        AGIZ_CEK_Z.zip(%w[alt ust]).each do |z, yer|
          l << { id: "agiz_#{taraf}_#{yer}", disi: p, erkek: :agiz, k: [xs, 0, z], ex: [0, 1, 0], ey: [0, 0, 1], ez: [sx, 0, 0] }
        end
      end
      l
    end

    # Verilen eksenlerle konum (sol el de olabilir: ayna simetrik yerleşim)
    def cerceve(k, x, y, z)
      v = ->(a) { Geom::Vector3d.new(*a) }
      Geom::Transformation.axes(P(*k), v.(x), v.(y), v.(z))
    end

    # Parçaya düşen çektirme yarımlarını ve dişideki (animasyonlu) açılı vidayı ekler.
    def cektirmeler(e, parca)
      ters = tr(*ORIJIN[parca]).inverse
      baglantilar.each do |b|
        j = ters * cerceve(b[:k], b[:ex], b[:ey] || [0, 1, 0], b[:ez])
        e.add_instance(@erkek, j) if b[:erkek] == parca
        next unless b[:disi] == parca
        e.add_instance(@disi, j)
        lt = j * eksen(VIDA_OTURMA, VIDA_YON, [0, 1, 0])
        d = Geom::Vector3d.new(*VIDA_YON).transform(j).normalize
        w = Geom::Vector3d.new(-d.x, -d.y, -d.z)
        vida_koy(e, @cvida, lt, P(*VIDA_OTURMA).transform(j), d, 9.0, 2.5, w, b[:id], false, b[:kisa] || false)
      end
    end

    # Yan: yere kadar iner. Sol yanda yatak bölmesine üç oval pencere; sağ yanda raylar ve tasma askıları.
    def dis_yan(k, sx)
      d = parca_tanimi(AD[k])
      e = d.entities
      kutu(e, 0, 0, 0, T, D, ZT)
      xi = sx > 0 ? T : 0.0 # iç yüz
      if k == :sol_yan
        PENCERE_Y.each do |y|
          it(e, plaka_hatti([[y, PENCERE_Z[0], 20], [y, PENCERE_Z[1], 20]]).map { |yy, zz| P(0, yy, zz) }, yon(1, 0, 0), T)
        end
      end
      boya(e, @mat[:govde])
      cektirmeler(e, k)
      CEKMECE.each_value { |h| ray_dolap(e, xi, sx, h[:zb]) if h[:ray] } if k == :sag_yan
      if k == :sag_yan # tasma askıları dış yüze, birer vidayla (demonte)
        ASKI_Y.each_with_index do |y, i|
          vida_koy(e, @aski, eksen([T, y, ASKI_Z], [1, 0, 0], [0, 0, 1]), P(T, y, ASKI_Z), Geom::Vector3d.new(-1, 0, 0),
                   60.0, 0.0, Geom::Vector3d.new(1, 0, 0), ASKILAR[i])
          o = [T + 3, y, ASKI_Z + 15]
          vida_koy(e, @vida16, eksen(o, [-1, 0, 0], [0, 0, 1]), P(*o), Geom::Vector3d.new(-1, 0, 0), 16.0, 2.5,
                   Geom::Vector3d.new(1, 0, 0), ASKI_VIDALARI[i])
        end
      end
      [d, ORIJIN[k]]
    end

    def sol_yan; dis_yan(:sol_yan, 1); end
    def sag_yan; dis_yan(:sag_yan, -1); end

    def alt_tabla
      d = parca_tanimi(AD[:alt_tabla])
      kutu(d.entities, 0, 0, 0, W - 2 * T, D, T)
      boya(d.entities, @mat[:govde])
      cektirmeler(d.entities, :alt_tabla)
      [d, ORIJIN[:alt_tabla]]
    end

    def ust_tabla
      d = parca_tanimi(AD[:ust_tabla])
      kutu(d.entities, 0, 0, 0, W, TABLA_DER, T)
      boya(d.entities, @mat[:govde])
      cektirmeler(d.entities, :ust_tabla)
      [d, ORIJIN[:ust_tabla]]
    end

    # Ara dikme: alt ve üst tabla arasında; mama kolonu yüzünde çektirmeler ve rayların dolap parçası.
    def dikme
      d = parca_tanimi(AD[:dikme])
      e = d.entities
      kutu(e, 0, 0, 0, T, D, ZT - Z0 - T)
      boya(e, @mat[:govde])
      cektirmeler(e, :dikme)
      CEKMECE.each_value { |h| ray_dolap(e, T, 1, h[:zb] - Z0 - T) if h[:ray] }
      [d, ORIJIN[:dikme]]
    end

    # Baza: yanların arasında, alt tablanın altında önde.
    def baza
      d = parca_tanimi(AD[:baza])
      kutu(d.entities, 0, 0, 0, W - 2 * T, T, Z0)
      boya(d.entities, @mat[:govde])
      cektirmeler(d.entities, :baza)
      [d, ORIJIN[:baza]]
    end

    # Ağız paneli: yatak bölmesinin önünü örter; altı açık, tepe köşeleri yuvarlak ağız (CNC). Eşiği yatak
    # tepsisinin önü oluşturur.
    def agiz
      d = parca_tanimi(AD[:agiz])
      gen, yuk = SOL_W, AGIZ_Z[1]
      a0 = (gen - AGIZ_W) / 2
      a1 = a0 + AGIZ_W
      kose = ->(cx, b0) { (0..8).map { |j| b = (b0 + 11.25 * j).degrees; [cx + AGIZ_R * Math.cos(b), AGIZ_H - AGIZ_R + AGIZ_R * Math.sin(b)] } }
      hat = [[0, 0], [a0, 0]] + kose.(a0 + AGIZ_R, 90).reverse + kose.(a1 - AGIZ_R, 0).reverse + [[a1, 0], [gen, 0], [gen, yuk], [0, yuk]]
      it(d.entities, hat.map { |x, z| P(x, 0, z) }, yon(0, 1, 0), T)
      boya(d.entities, @mat[:govde])
      cektirmeler(d.entities, :agiz)
      [d, ORIJIN[:agiz]]
    end

    # 3 mm çakma arkalık: yatak bölmesinin arkasında 15 havalandırma deliği ve ısıtmalı ped için kablo deliği.
    def arkalik
      d = parca_tanimi(AD[:arkalik])
      e = d.entities
      kutu(e, 0, 0, 0, W, ARKA_T, ZT - Z0)
      [180, 290, 400, 510, 620].product([230, 330, 430]).each do |x, z|
        daire_it(e, P(x, 0, z), Y_AXIS, 15, yon(0, 1, 0), ARKA_T, 24)
      end
      daire_it(e, P(640, 0, 70), Y_AXIS, 18, yon(0, 1, 0), ARKA_T, 24) # kablo deliği
      boya(e, @mat[:arka])
      CIVI.each_with_index do |(x, z), i|
        vida_koy(e, @civi, eksen([x, ARKA_T, z], [0, -1, 0], [0, 0, 1]), P(x, ARKA_T, z), Geom::Vector3d.new(0, -1, 0),
                 16.0, 1.2, Geom::Vector3d.new(0, 1, 0), CIVILER[i])
      end
      [d, ORIJIN[:arkalik]]
    end

    # --- Çekmece: gömme kulplu ön + kutu önü (minifix eksantrikleri), iki yan (bulonlar; raylıysa rayın
    # çekmece parçası), arka (eksantrikler), 3 mm dip (alttan çivilenir; raysızsa altında kaydırma pabuçları). ---
    def kutu_gen(c) CEKMECE[c][:x][1] - CEKMECE[c][:x][0] end

    # Minifix bulonunun gireceği Ø8 delikler: panelin iki ucunda, eksantriğin hizasına kadar.
    def bulon_delikleri(e, x0, gen, y, z)
      daire_it(e, P(x0, y, z), X_AXIS, 4, yon(1, 0, 0), KAM_ARA, 16)
      daire_it(e, P(x0 + gen, y, z), X_AXIS, 4, yon(-1, 0, 0), KAM_ARA, 16)
    end

    def cekmece_on(c)
      h = CEKMECE[c]
      ox, gen, oz, yuk = h[:on]
      d = parca_tanimi(AD[:"#{c}_on"])
      e = d.entities
      on_panel(e, gen, yuk, [gen * 0.35, 220].min)
      boya(e, @mat[:govde])
      g = e.add_group # kutu önü, önün arkasında
      x0 = h[:x][0] + KUTU_T - ox
      ic = kutu_gen(c) - 2 * KUTU_T
      zk = h[:zb] + ARKA_T - oz
      kutu(g.entities, x0, T, zk, x0 + ic, T + KUTU_T, zk + h[:h])
      bulon_delikleri(g.entities, x0, ic, T + KUTU_T / 2, zk + h[:h] / 2)
      boya(g.entities, @mat[:govde])
      [[x0 + KAM_ARA, 'sol'], [x0 + ic - KAM_ARA, 'sag']].each do |x, taraf|
        o = [x, T + KUTU_T, zk + h[:h] / 2]
        vida_koy(e, @kam, eksen(o, [0, -1, 0], [0, 0, 1]), P(*o), Geom::Vector3d.new(0, -1, 0), 0.01, 0.0,
                 Geom::Vector3d.new(0, 1, 0), "#{c}_kam_on_#{taraf}", false, true)
      end
      [d, ORIJIN[:"#{c}_on"]]
    end

    def cekmece_yan(c, taraf)
      h = CEKMECE[c]
      k = :"#{c}_#{taraf}"
      d = parca_tanimi(AD[k])
      e = d.entities
      kutu(e, 0, 0, 0, KUTU_T, KUTU_D, h[:h])
      boya(e, @mat[:govde])
      sol = taraf == 'sol'
      xi = sol ? KUTU_T : 0.0 # iç yüz
      [KUTU_T / 2, KUTU_D - KUTU_T / 2].each do |y| # ön ve arka panelin uç ortası
        e.add_instance(@bulon, eksen([xi, y, h[:h] / 2], [sol ? 1 : -1, 0, 0], [0, 0, 1]))
      end
      ray_cekmece(e, sol ? 0.0 : KUTU_T, sol ? -1 : 1, -ARKA_T) if h[:ray]
      [d, ORIJIN[k]]
    end

    def cekmece_arka(c)
      h = CEKMECE[c]
      k = :"#{c}_arka"
      d = parca_tanimi(AD[k])
      e = d.entities
      ic = kutu_gen(c) - 2 * KUTU_T
      kutu(e, 0, 0, 0, ic, KUTU_T, h[:h])
      bulon_delikleri(e, 0.0, ic, KUTU_T / 2, h[:h] / 2)
      boya(e, @mat[:govde])
      [[KAM_ARA, 'sol'], [ic - KAM_ARA, 'sag']].each do |x, taraf|
        o = [x, 0, h[:h] / 2]
        vida_koy(e, @kam, eksen(o, [0, 1, 0], [0, 0, 1]), P(*o), Geom::Vector3d.new(0, 1, 0), 0.01, 0.0,
                 Geom::Vector3d.new(0, -1, 0), "#{c}_kam_arka_#{taraf}", false, true)
      end
      [d, ORIJIN[k]]
    end

    def cekmece_dip(c)
      h = CEKMECE[c]
      k = :"#{c}_dip"
      gen = kutu_gen(c)
      d = parca_tanimi(AD[k])
      e = d.entities
      kutu(e, 0, 0, 0, gen, KUTU_D, ARKA_T)
      boya(e, @mat[:dip])
      civi = [[KUTU_T / 2, 60], [KUTU_T / 2, KUTU_D - 60], [gen - KUTU_T / 2, 60], [gen - KUTU_T / 2, KUTU_D - 60],
              [gen / 2, KUTU_T / 2], [gen / 2, KUTU_D - KUTU_T / 2]]
      civi.each_with_index do |(x, y), i|
        vida_koy(e, @civi, eksen([x, y, 0], [0, 0, 1], [1, 0, 0]), P(x, y, 0), Geom::Vector3d.new(0, 0, 1), 16.0, 1.2,
                 Geom::Vector3d.new(0, 0, -1), "#{c}_civi_#{i + 1}")
      end
      unless h[:ray] # kaydırma pabuçları (fabrikada takılı)
        [30, gen - 30].product([30, KUTU_D - 30]).each do |x, y|
          torna(e, [[0, 0], [0, 10], [KAYDIR, 10], [KAYDIR, 0]], 16, @mat[:pabuc]).transform!(eksen([x, y, 0], [0, 0, -1], [1, 0, 0]))
        end
      end
      [d, ORIJIN[k]]
    end

    def parca_yap(k)
      c, p = PARCA_CEKMECE[k]
      return send(k) unless c
      case p
      when 'on' then cekmece_on(c)
      when 'arka' then cekmece_arka(c)
      when 'dip' then cekmece_dip(c)
      else cekmece_yan(c, p)
      end
    end

    # --- Kutudan ayrı çıkan kullanım parçaları ---
    # Minder: 7 cm taban + arkada ve yanlarda 5,5 cm kabarık kenar (önü açık, kedi rahat girer).
    def minder
      d = parca_tanimi(AD[:minder])
      gen, der, kal = MINDER
      g = d.entities.add_group
      it(g.entities, yuvarlak_dik(0, 0, gen, der, 50).map { |x, y| P(x, y, 0) }, yon(0, 0, 1), kal)
      boya(g.entities, @mat[:minder])
      k = d.entities.add_group
      u = [[0, 0], [70, 0], [70, der - 70], [gen - 70, der - 70], [gen - 70, 0], [gen, 0], [gen, der], [0, der]]
      it(k.entities, u.map { |x, y| P(x, y, kal) }, yon(0, 0, 1), 55)
      boya(k.entities, @mat[:minder])
      [d, ORIJIN[:minder]]
    end

    def tepsi
      d = parca_tanimi(AD[:tepsi])
      e = d.entities
      kutu(e, 0, 0, 0, 330, 400, 15)
      it(e, [P(8, 8, 15), P(322, 8, 15), P(322, 392, 15), P(8, 392, 15)], yon(0, 0, -1), 12)
      boya(e, @mat[:plastik])
      [d, ORIJIN[:tepsi]]
    end

    def kap_merkezleri
      [-1, 1].map { |s| [KAP_TABLA[0] / 2 + s * KAP_ARA / 2, 110.0] }
    end

    def kap_tablasi
      d = parca_tanimi(AD[:kap_tablasi])
      e = d.entities
      kutu(e, 0, 0, 0, KAP_TABLA[0], KAP_TABLA[1], T)
      kap_merkezleri.each { |x, y| daire_it(e, P(x, y, 0), Z_AXIS, 72, yon(0, 0, 1), T, 48) }
      boya(e, @mat[:govde])
      [d, ORIJIN[:kap_tablasi]]
    end

    def kaplar
      d = parca_tanimi(AD[:kaplar])
      kap_merkezleri.each { |x, y| d.entities.add_instance(@kap, eksen([x, y, -54], [0, 0, 1], [1, 0, 0])) }
      [d, ORIJIN[:kaplar]]
    end

    # Kapaklı mama kabı (5-8 kg kuru mama): şeffaf gri gövde, mavi-gri kapak ve tutamak.
    def mama_kabi
      d = parca_tanimi(AD[:mama_kabi])
      g = d.entities.add_group
      kutu(g.entities, 0, 0, 0, 350, 380, 220)
      it(g.entities, [P(6, 6, 220), P(344, 6, 220), P(344, 374, 220), P(6, 374, 220)], yon(0, 0, -1), 210)
      boya(g.entities, @mat[:kab])
      k = d.entities.add_group
      kutu(k.entities, -3, -3, 220, 353, 383, 232)
      kutu(k.entities, 125, 160, 232, 225, 220, 248)
      boya(k.entities, @mat[:kapak])
      [d, ORIJIN[:mama_kabi]]
    end

    # ------------------------------------------------------------------
    # Model kurulumu
    # ------------------------------------------------------------------
    # Ön: üst kenara yakın gömme (frezeli) kulp oyuğu.
    def on_panel(e, gen, yuk, kulp_gen)
      kutu(e, 0, 0, 0, gen, T, yuk)
      it(e, yuvarlak_dik(gen / 2 - kulp_gen / 2, yuk - 27, gen / 2 + kulp_gen / 2, yuk - 5, 10).map { |x, z| P(x, 0, z) },
         yon(0, 1, 0), 8)
    end

    def kur(kayit_yolu = nil)
      @m = Sketchup.active_model
      @m.start_operation('Patili Konsol kurulum modeli', true)
      @m.entities.clear!
      @m.pages.to_a.each { |p| @m.pages.erase(p) }
      @m.definitions.purge_unused
      @m.materials.purge_unused
      @m.layers.purge_unused
      malzemeler

      @vida16 = vida_tanimi('Sunta Vidası 3.5x16', 3.8, 2.5, 1.75, 16)
      @vida16h = havsa_vida_tanimi
      @cvida = vida_tanimi('Çektirme Vidası (açılı)', 4, 2.5, 2.5, 14)
      @disi = disi_tanimi
      @erkek = erkek_tanimi
      @civi = civi_tanimi
      @kam = kam_tanimi
      @bulon = bulon_tanimi
      @aski = aski_tanimi
      @kap = kap_tanimi
      arac = tornavida_tanimi
      kisa = kisa_tornavida_tanimi
      cekic = cekic_tanimi

      tags = SIRA.map { |k| [k, @m.layers.add(ETIKET[k])] }.to_h
      liste_tag = @m.layers.add(LISTE_TAG)
      arac_tag = @m.layers.add(ARAC_TAG)

      SIRA.each do |k|
        d, o = parca_yap(k)
        i = @m.entities.add_instance(d, tr(*o))
        i.name = AD[k]
        i.layer = tags[k]
        nitelik(i, parca: k.to_s)
      end
      [[arac, 'tornavida'], [kisa, 'kisa_tornavida'], [cekic, 'cekic']].each do |d, ad|
        ti = @m.entities.add_instance(d, tr(0, 0, 0))
        ti.layer = arac_tag
        nitelik(ti, parca: ad)
      end

      parca_listesi(liste_tag)
      stil
      bagla
      son_durum
      sahneler
      @m.commit_operation
      @m.save(kayit_yolu) if kayit_yolu
      "Kuruldu: #{SIRA.size} parça, #{@vidalar.size} animasyonlu vida/eksantrik/çivi/askı, #{@m.pages.size} sahne"
    end

    # Kutu içeriği: paneller yere yatırılmış, fabrikada takılı hırdavat üstte; minder, kaplar, askılar, vidalar ve
    # çiviler ayrı.
    def parca_listesi(tag)
      rx = ->(a) { Geom::Transformation.rotation(ORIGIN, X_AXIS, a.degrees) }
      ry = ->(a) { Geom::Transformation.rotation(ORIGIN, Y_AXIS, a.degrees) }
      rz = ->(a) { Geom::Transformation.rotation(ORIGIN, Z_AXIS, a.degrees) }
      bir = Geom::Transformation.new
      yerlesim = {
        sol_yan: [rz.(90) * ry.(-90), 1300, 0], sag_yan: [rz.(90) * ry.(90), 1900, 0],
        dikme: [rz.(90) * ry.(90), 2500, 0], arkalik: [rx.(-90), 3100, 0], agiz: [rx.(90), 4450, 0],
        alt_tabla: [bir, 1300, 850], ust_tabla: [rx.(180), 2600, 850], baza: [rx.(90), 3950, 850],
        minder: [bir, 1300, -750], tepsi: [bir, 2150, -750], kap_tablasi: [bir, 2750, -750], kaplar: [bir, 3400, -750],
        mama_kabi: [bir, 4100, -750]
      }
      CEKMECE.each_with_index do |(c, h), i|
        x0 = 1300 + (i % 2) * 2900
        y = 1600 + (i / 2) * 750
        w, kh, gen = h[:on][1], h[:h], kutu_gen(c)
        yerlesim.merge!(:"#{c}_on" => [rx.(90), x0, y], :"#{c}_sol" => [ry.(90), x0 + w + 80, y],
                        :"#{c}_sag" => [ry.(-90), x0 + w + 120 + kh, y],
                        :"#{c}_arka" => [rx.(-90), x0 + w + 160 + 2 * kh, y],
                        :"#{c}_dip" => [bir, x0 + w + 240 + 2 * kh + gen - 2 * KUTU_T, y])
      end
      etiket = AD.merge(CEKMECE.map { |c, h| [:"#{c}_on", "#{h[:ad]} (5 parça)"] }.to_h)
      @m.entities.grep(Sketchup::ComponentInstance).select { |i| nit(i, :parca) && !%w[tornavida kisa_tornavida cekic].include?(nit(i, :parca)) }.each do |ana|
        k = nit(ana, :parca).to_sym
        rot, x, y = yerlesim[k]
        b = Geom::BoundingBox.new # demonte parçalar (askılar, vidalar, çiviler) yerleşime katılmasın
        ana.definition.entities.each { |g| b.add(g.bounds) unless g.is_a?(Sketchup::ComponentInstance) && DEMONTE.include?(nit(g, :vida)) }
        bb = Geom::BoundingBox.new
        8.times { |c| bb.add(b.corner(c).transform(rot)) }
        kay = Geom::Transformation.translation(P(x, y, 0) - bb.min)
        i = @m.entities.add_instance(ana.definition, kay * rot)
        i.layer = tag
        next if CEKMECE_SIRA.include?(k) && !k.to_s.end_with?('_on') # çekmece parçalarına tek etiket
        on = Geom::Point3d.new(bb.center.x, bb.min.y, bb.max.z).transform(kay) # üst yüzün ön kenarı (görünür)
        txt = @m.entities.add_text(etiket[k], on, Geom::Vector3d.new(0, -90.mm, 0))
        txt.layer = tag
      end
      ek = lambda do |defn, adet, x, dx, ad, eks|
        adet.times { |i| @m.entities.add_instance(defn, eksen([x + i * dx, -500, eks[2]], eks[0], eks[1])).layer = tag }
        @m.entities.add_text(ad, P(x, -620, 0), Geom::Vector3d.new(0, -90.mm, 0)).layer = tag
      end
      ek.(@aski, ASKILAR.size, 4800, 80, "Tasma Askısı (#{ASKILAR.size})", [[0, 0, 1], [1, 0, 0], 0])
      ek.(@vida16, ASKI_VIDALARI.size, 5350, 25, "Askı Vidası (#{ASKI_VIDALARI.size})", [[0, 1, 0], [0, 0, 1], 4])
      ek.(@civi, 8, 5850, 14, "Çivi (#{CIVILER.size + DIP_CIVILER.size})", [[0, 1, 0], [0, 0, 1], 3])
    end

    def stil
      ro = @m.rendering_options
      ro['BackgroundColor'] = Sketchup::Color.new(255, 255, 255)
      ro['DrawGround'] = false
      ro['DrawHorizon'] = false
      ro['DisplaySky'] = false if ro.keys.include?('DisplaySky')
      ro['ForegroundColor'] = Sketchup::Color.new(55, 55, 60)
      ro['EdgeColorMode'] = 0
      ro['DrawSilhouettes'] = true
      ro['SilhouetteWidth'] = 2
      ro['DrawDepthQue'] = false
      ro['ExtendLines'] = false
      ro['DisplayInstanceAxes'] = false
      @m.shadow_info['DisplayShadows'] = false
      @m.options['PageOptions']['TransitionTime'] = 1.2
      @m.styles.update_selected_style # sahneler stili yeniden uygulayınca ayarlar kaybolmasın
    end

    def kamera_kur(eye, hedef, oran = 0.0)
      c = @m.active_view.camera
      c.set(P(*eye), P(*hedef), Z_AXIS)
      c.perspective = true
      c.aspect_ratio = oran
      c.fov = DIKEY_FOV
    end

    def sahneler
      cek = ->(c) { CEKMECE_PAR.map { |p| :"#{c}_#{p}" } }
      tanim = [
        ['0 Kutu İçeriği', [], :liste, 'Paneller ve fabrikada takılı bağlantı elemanları; minder, kaplar, askılar, vidalar ve çiviler ayrı.'],
        ['1 Sol Yan + Alt Tabla', %i[sol_yan alt_tabla], 1, 'Alt tablayı sol yandaki 2 şeffaf çektirmeye geçirip vidaları sıkın.'],
        ['2 Sağ Yan', %i[sag_yan], 2, 'Sağ yanı alt tabladaki 2 çektirmeye oturtup vidaları sıkın.'],
        ['3 Ara Dikme', %i[dikme], 3, 'Ara dikmeyi alt tabladaki 2 çektirmeye oturtup vidaları sıkın.'],
        ['4 Baza', %i[baza], 4, 'Bazayı alt tablanın altına önden yerleştirin; 2 çektirme vidasını arkadan sıkın.'],
        ['5 Ağız Paneli', %i[agiz], 5, 'Ağız panelini yatak bölmesinin önüne oturtun; 4 çektirme vidasını içeriden sıkın.'],
        ['6 Üst Tabla', %i[ust_tabla], 6, 'Üst tablayı yanların ve dikmenin üstüne oturtun; 6 çektirme vidasını sıkın.'],
        ['7 Arkalık', %i[arkalik], 7, 'Arkalığı arkaya yerleştirip çivileri çakın.'],
        ['8-11 Mama Çekmecesi', cek.(:mama), :c_ray, 'Yanları minifixle öne ve arkaya bağlayın, eksantrikleri çevirin, dibi çakın, raylara oturtup itin.'],
        ['12 Aksesuar Çekmecesi', cek.(:aks), :aks, 'Aynı şekilde kurup raylara itin.'],
        ['13 Kap Çekmecesi + Yatak Tepsisi', cek.(:kap) + cek.(:yatak), :alt, 'Aynı şekilde kurun; kaydırma pabuçlarıyla alt tablanın üstüne itin.'],
        ['14-16 Minder ve Kaplar', EK_SIRA, :ek_kap, 'Minderi yatak tepsisine, tepsiyi, kap tablasını ve kapları kap çekmecesine, mama kabını mama çekmecesine koyun.'],
        ['17 Tasma Askıları', [], :aski, 'Tasma askılarını sağ yana birer vidayla takın.'],
        ['18 Bitmiş Ürün', [], :bitti, 'Kurulum tamamlandı.']
      ]
      acik = []
      tanim.each do |ad, yeni, kam, aciklama|
        acik += yeni
        liste = kam == :liste
        @m.layers.each do |l|
          k = ETIKET.key(l.name)
          l.visible = if l.name == LISTE_TAG then liste
                      elsif l.name == ARAC_TAG then false
                      elsif k then !liste && acik.include?(k)
                      else true
                      end
        end
        kamera_kur(*KAM[kam])
        p = @m.pages.add(ad)
        p.description = aciklama
      end
      @m.pages.selected_page = @m.pages[@m.pages.size - 1]
    end

    # ------------------------------------------------------------------
    # Animasyon
    # ------------------------------------------------------------------
    # Modeldeki nitelikleri okuyup animasyon referanslarını kurar (kaydedilmiş
    # dosya yeniden açıldığında da çalışır).
    def bagla
      @m = Sketchup.active_model
      @parca = {}
      @taban_tr = {}
      @arac = @kisa_arac = @cekic = nil
      @m.entities.grep(Sketchup::ComponentInstance).each do |i|
        k = nit(i, :parca)
        next unless k
        if k == 'tornavida' then @arac = i
        elsif k == 'kisa_tornavida' then @kisa_arac = i
        elsif k == 'cekic' then @cekic = i
        else
          @parca[k.to_sym] = i
          @taban_tr[k.to_sym] = i.transformation
        end
      end
      raise 'Model bulunamadı — önce OzcanKurulum::PatiliKonsol.kur' unless @parca.size == SIRA.size && @arac && @kisa_arac && @cekic
      @vidalar = []
      @parca.each do |k, ana|
        ana.definition.entities.each do |x|
          if x.is_a?(Sketchup::ComponentInstance) && nit(x, :vida)
            @vidalar << vida_kaydi(x, k, nil)
          elsif x.is_a?(Sketchup::Group)
            x.entities.grep(Sketchup::ComponentInstance).each { |y| @vidalar << vida_kaydi(y, k, x) if nit(y, :vida) }
          end
        end
      end
      # Aynı tanımı paylaşan parçalar olursa vidaları tek kez sayılsın
      @vidalar.uniq! { |v| v[:inst] }
      @liste_tag = @m.layers[LISTE_TAG]
      @arac_tag = @m.layers[ARAC_TAG]
      cizelge
      true
    end

    def vida_kaydi(i, parca, grup)
      { id: nit(i, :vida), inst: i, parca: parca, grup: grup,
        lt: Geom::Transformation.new(nit(i, :lt)), p: Geom::Point3d.new(*nit(i, :p)),
        d: Geom::Vector3d.new(*nit(i, :d)), strok: nit(i, :strok), bas_h: nit(i, :bas_h),
        w: Geom::Vector3d.new(*nit(i, :w)), kapi: nit(i, :kapi), kisa: nit(i, :kisa) }
    end

    # Vida: ang derece döner, adv (0 = sıkılı, 1 = gevşek) oranında geri çıkar
    def vida_tr(v, adv, ang)
      don = Geom::Transformation.rotation(v[:p], v[:d], ang.degrees) * v[:lt]
      return don if adv <= 1e-6
      geri = Geom::Vector3d.new(-v[:d].x, -v[:d].y, -v[:d].z)
      geri.length = (v[:strok] * adv).mm
      Geom::Transformation.translation(geri) * don
    end

    def lerp(a, b, u) a + (b - a) * u end
    def lerp3(a, b, u) [0, 1, 2].map { |i| lerp(a[i], b[i], u) } end
    def yumusat(u) u * u * (3 - 2 * u) end

    class Cizelge
      attr_reader :olaylar, :kameralar, :basliklar
      attr_accessor :t
      def initialize
        @t = 0.0
        @olaylar = []
        @kameralar = []
        @basliklar = []
      end

      def olay(sure, yumusak = true, &fn)
        @olaylar << [@t, @t + sure, yumusak, fn]
        @t += sure
      end

      def an(&fn) @olaylar << [@t, @t, false, fn] end
      def bekle(s) @t += s end
      def baslik(s) @basliklar << [@t, s] end

      def kamera(sure, kam)
        @kameralar << [@t, @t + sure, kam[0], kam[1]]
        @t += sure
      end

      # Konumu oynatma anında hesaplanan kamera (ör. sıkılan vidaya yakın çekim);
      # ilk hesaplanan [göz, hedef] saklanır.
      def kamera_dinamik(sure, &poz)
        @kameralar << [@t, @t + sure, poz, nil]
        @t += sure
      end
    end

    def hareket(k, a, b, sure)
      @cz.olay(sure) do |s, u|
        s[:p][k][:vis] = true
        s[:p][k][:off] = lerp3(a, b, u)
      end
    end

    # Sıkılan vidaya yakın çekim: önden-yukarıdan, tornavidanın geldiği yana kaymış
    # bakar; tornavida ve vida başı birlikte görünür. Konum oynatma anında hesaplanır.
    def yakin_kamera(id, sure = 0.7, yon: nil)
      @cz.kamera_dinamik(sure) do
        v = @vidalar.find { |x| x[:id] == id }
        ana = @parca[v[:parca]].transformation
        dunya = ana
        dunya *= v[:grup].transformation if v[:grup]
        dunya *= v[:inst].transformation
        bas = Geom::Point3d.new(-v[:bas_h].mm, 0, 0).transform(dunya)
        w = v[:kapi] ? v[:w] : v[:w].transform(ana).normalize
        bak = yon ? Geom::Vector3d.new(*yon).normalize : Geom::Vector3d.new(0.55 * w.x, 0.55 * w.y - 0.75, 0.55 * w.z + 0.45).normalize
        h = bas.to_a.map(&:to_mm)
        [h.zip(bak.to_a).map { |c, d| c + 450 * d }, h]
      end
    end

    def vida_sik(id, cek = nil, tur: 4, sure: 1.1, yakin: true, bak: nil)
      yakin_kamera(id, yon: bak) if yakin
      @cz.olay(0.45) { |s, u| s[:drv] = { id: id, uz: 1 - u, don: 0.0 } }
      @cz.olay(sure, false) do |s, u|
        s[:drv] = { id: id, uz: 0.0, don: 360.0 * tur * u }
        s[:v][id] = { adv: 1 - u, ang: 360.0 * tur * u }
        if cek
          k, a, b = cek
          s[:p][k][:off] = lerp3(a, b, u)
        end
      end
      @cz.olay(0.35) { |s, u| s[:drv] = u >= 1 ? nil : { id: id, uz: u, don: 360.0 * tur } }
    end

    # Çekiç çiviye gelir, iki kez vurur (çivi her vuruşta yarı yarıya girer), geri çekilir.
    def civi_cak(id)
      @cz.olay(0.25) { |s, u| s[:cekic] = { id: id, uz: 1 - u } }
      @cz.olay(0.45, false) do |s, u|
        s[:cekic] = { id: id, uz: 0.15 * Math.sin(Math::PI * 2 * u).abs }
        s[:v][id] = { adv: u < 0.5 ? 1.0 : (u < 1.0 ? 0.5 : 0.0), ang: 0.0 }
      end
      @cz.olay(0.2) { |s, u| s[:cekic] = u >= 1 ? nil : { id: id, uz: u } }
    end

    # İlk vidaya yakın çekim yapıp sıkar; sonra adım kamerasına dönüp kalanları sıkar.
    def sirayla_sik(ids, kam, cekler: [], tur: 4, bak: nil)
      ids.each_with_index do |id, i|
        @cz.kamera(0.8, kam) if i == 1
        vida_sik(id, cekler[i], tur: tur, sure: i.zero? ? 1.0 : 0.7, yakin: i.zero?, bak: bak)
      end
    end

    # Son milimetreleri çektirme vidaları kapatır: parça ofseti adım adım sıfıra iner.
    def cek_listesi(k, bas, n)
      (0...n).map { |i| [k, bas.map { |v| v * (n - i) / n.to_f }, bas.map { |v| v * (n - i - 1) / n.to_f }] }
    end

    def kam_idleri(c) %w[on_sol on_sag arka_sol arka_sag].map { |p| "#{c}_kam_#{p}" } end
    def dip_civileri(c) (1..6).map { |i| "#{c}_civi_#{i}" } end

    # Çekmecenin parçaları ve içine konan kullanım parçaları (birlikte taşınır)
    def cekmece_parcalari(c)
      CEKMECE_PAR.map { |p| :"#{c}_#{p}" } + EKLER.fetch(c, [])
    end

    # Bir ya da birkaç çekmeceyi içindekilerle taşır; henüz konmamış kullanım parçaları görünmez kalır.
    def cekmece_hareket(cler, a, b, sure)
      @cz.olay(sure) do |s, u|
        Array(cler).each do |c|
          cekmece_parcalari(c).each do |k|
            s[:p][k] = { vis: s[:p][k][:vis] || !EK_SIRA.include?(k), off: lerp3(a, b, u) }
          end
        end
      end
    end

    # İlk çekmece (mama) tezgah yüksekliğinde, her işlem ayrı adım: yanlar minifix bulonlarıyla ön ve arkanın
    # uçlarındaki deliklere geçer; eksantrikler yarım tur çevrilip bulonları çeker; dip alttan çakılır; çekmece
    # raylara oturtulup itilir.
    def cekmece_kur(c, n)
      z = @cz
      s0 = [0, -700, 450]
      yan = ->(dx) { [dx, -700, 450] }
      ad = CEKMECE[c][:ad]

      z.baslik("#{n} · #{ad}: yanları ön ve arka panele geçirin — yanlardaki minifix bulonları uçlardaki deliklere girer")
      z.kamera(1.2, KAM[:c_yan])
      z.an do |s, _|
        s[:p][:"#{c}_on"] = { vis: true, off: s0 }
        s[:p][:"#{c}_arka"] = { vis: true, off: s0 }
        s[:p][:"#{c}_sol"] = { vis: true, off: yan.(-160) }
        s[:p][:"#{c}_sag"] = { vis: true, off: yan.(160) }
      end
      z.bekle(0.6)
      z.olay(1.8) do |s, u|
        s[:p][:"#{c}_sol"][:off] = lerp3(yan.(-160), s0, u)
        s[:p][:"#{c}_sag"][:off] = lerp3(yan.(160), s0, u)
      end
      z.bekle(0.3)
      z.kamera(1.0, KAM[:c_kam])
      z.bekle(0.4)

      z.baslik("#{n + 1} · Dört minifix eksantriğini tornavidayla yarım tur saat yönünde çevirip sıkın")
      # ilk eksantriğe kutunun içinden, arkadan-yukarıdan bak
      sirayla_sik(kam_idleri(c), KAM[:c_kam], tur: 0.5, bak: [0.3, 1, 0.8])
      z.kamera(0.8, KAM[:c_kam])
      z.bekle(0.5)

      z.baslik("#{n + 2} · Dibi alttan kutuya oturtun; kenarları hizalayıp yanlara ikişer, öne ve arkaya birer çivi çakın")
      z.kamera(1.2, KAM[:c_dip])
      hareket(:"#{c}_dip", [0, -700, 230], s0, 1.4)
      ids = dip_civileri(c)
      z.an { |s, _| ids.each { |id| s[:v][id] = { adv: 1.0, ang: 0.0 } } }
      yakin_kamera(ids.first, yon: [0.35, -1, -0.75])
      civi_cak(ids.first)
      z.kamera(0.8, KAM[:c_dip])
      ids.drop(1).each { |id| civi_cak(id) }
      z.bekle(0.5)

      z.baslik("#{n + 3} · Çekmecenin arka tekerleklerini dolaptaki rayların kanalına oturtun, sonuna kadar itin")
      z.kamera(1.2, KAM[:c_ray])
      cekmece_hareket(c, s0, [0, -480, 0], 1.4)
      z.bekle(0.4)
      cekmece_hareket(c, [0, -480, 0], [0, 0, 0], 1.8)
      z.bekle(0.5)
    end

    # Kalan çekmeceler önde, aynı sırayla ama tek tek göstermeden kurulup yerine itilir.
    def cekmeceler_hizli(cler, kam)
      z = @cz
      s0 = [0, -650, 300]
      yan = ->(dx) { [dx, -650, 300] }
      z.kamera(1.2, kam)
      z.an do |s, _|
        cler.each do |c|
          s[:p][:"#{c}_on"] = { vis: true, off: s0 }
          s[:p][:"#{c}_arka"] = { vis: true, off: s0 }
        end
      end
      z.bekle(0.3)
      z.olay(1.0) do |s, u|
        cler.each do |c|
          s[:p][:"#{c}_sol"] = { vis: true, off: lerp3(yan.(-160), s0, u) }
          s[:p][:"#{c}_sag"] = { vis: true, off: lerp3(yan.(160), s0, u) }
        end
      end
      z.olay(0.6, false) { |s, u| cler.each { |c| kam_idleri(c).each { |id| s[:v][id] = { adv: 1 - u, ang: 180.0 * u } } } }
      z.olay(1.0) { |s, u| cler.each { |c| s[:p][:"#{c}_dip"] = { vis: true, off: lerp3([0, -650, 140], s0, u) } } }
      z.an { |s, _| cler.each { |c| dip_civileri(c).each { |id| s[:v][id] = { adv: 1.0, ang: 0.0 } } } }
      z.olay(0.6, false) { |s, u| cler.each { |c| dip_civileri(c).each { |id| s[:v][id] = { adv: 1 - u, ang: 0.0 } } } }
      z.bekle(0.3)
      cekmece_hareket(cler, s0, [0, -480, 0], 1.2)
      z.bekle(0.3)
      cekmece_hareket(cler, [0, -480, 0], [0, 0, 0], 1.8)
      z.bekle(0.3)
    end

    # Çekmeceler açılır, kullanım parçaları yukarıdan yerine iner, çekmeceler kapanır.
    ACIK = { yatak: 440, kap: 440, mama: 430 }.freeze

    # Çekmece açılır, kullanım parçaları sırayla yukarıdan yerine iner, çekmece kapanır.
    def cekmeceye_koy(c, parcalar, kam)
      z = @cz
      m = ACIK[c]
      z.kamera(1.2, kam)
      z.olay(1.0) { |s, u| cekmece_parcalari(c).each { |k| s[:p][k][:off] = [0, -m * u, 0] } }
      parcalar.each { |k| hareket(k, [0, -m, 350], [0, -m, 0], 1.0) }
      z.bekle(0.4)
      z.olay(0.7) { |s, u| cekmece_parcalari(c).each { |k| s[:p][k][:off] = [0, -m * (1 - u), 0] } }
      z.bekle(0.3)
    end

    def askilari_tak
      z = @cz
      z.kamera(1.2, KAM[:aski])
      z.olay(0.8) { |s, u| ASKILAR.each { |id| s[:v][id] = { adv: 3.0 * (1 - u), ang: 0.0 } } }
      ASKI_VIDALARI.each_with_index do |id, i|
        z.olay(0.4) { |s, u| s[:v][id] = { adv: 3.0 - 2.0 * u, ang: 0.0 } }
        vida_sik(id, nil, tur: 4, sure: 0.8, yakin: i.zero?, bak: [1, -0.5, 0.4])
      end
      z.kamera(0.8, KAM[:aski])
      z.bekle(0.3)
    end

    def cizelge
      @cz = z = Cizelge.new
      z.an { |s, _| DEMONTE.each { |id| s[:v][id] = { gizli: true } } } # takılana kadar görünmesin
      z.baslik('Kutu içeriği — bağlantı elemanları panellere takılı gelir; minder, kaplar, askılar ve vidalar ayrı')
      z.kamera(0, KAM[:liste])
      z.bekle(3.5)

      z.baslik('1 · Alt tablayı sol yandaki iki şeffaf çektirmeye geçirin, vidaları sıkın')
      z.an do |s, _|
        s[:liste] = false
        s[:p][:sol_yan][:vis] = true
        s[:p][:alt_tabla] = { vis: true, off: [500, 0, 0] }
      end
      z.kamera(1.2, KAM[1])
      hareket(:alt_tabla, [500, 0, 0], [2, 0, 0], 2.0)
      sirayla_sik(%w[on arka].map { |y| "alt_sol_#{y}" }, KAM[1], cekler: cek_listesi(:alt_tabla, [2, 0, 0], 2))
      z.kamera(0.8, KAM[1])
      z.bekle(0.3)

      z.baslik('2 · Sağ yanı alt tabladaki çektirmelere oturtun, vidaları sıkın')
      z.kamera(1.2, KAM[2])
      hareket(:sag_yan, [500, 0, 0], [2, 0, 0], 2.0)
      sirayla_sik(%w[on arka].map { |y| "alt_sag_#{y}" }, KAM[2], cekler: cek_listesi(:sag_yan, [2, 0, 0], 2))
      z.kamera(0.8, KAM[2])
      z.bekle(0.3)

      z.baslik('3 · Ara dikmeyi alt tabladaki çektirmelere oturtun (yatak bölmesi solda 70 cm kalır), vidaları sıkın')
      z.kamera(1.2, KAM[3])
      hareket(:dikme, [0, 0, 450], [0, 0, 2], 1.8)
      sirayla_sik(%w[on arka].map { |y| "dalt_#{y}" }, KAM[3], cekler: cek_listesi(:dikme, [0, 0, 2], 2))
      z.kamera(0.8, KAM[3])
      z.bekle(0.3)

      z.baslik('4 · Bazayı alt tablanın altına önden yerleştirin, çektirme vidalarını arkadan sıkın')
      z.kamera(1.2, KAM[4])
      hareket(:baza, [0, -400, 0], [0, -2, 0], 1.6)
      ids = BAZA_X.each_index.map { |i| "baza_#{i + 1}" }
      sirayla_sik(ids, KAM[4], cekler: cek_listesi(:baza, [0, -2, 0], ids.size), bak: [0.3, 1, -0.05])
      z.kamera(0.8, KAM[4])
      z.bekle(0.3)

      z.baslik('5 · Ağız panelini yatak bölmesinin önüne oturtun, dört çektirme vidasını içeriden sıkın')
      z.kamera(1.2, KAM[5])
      hareket(:agiz, [0, -400, 0], [0, -2, 0], 1.6)
      ids = %w[sol dikme].flat_map { |t| %w[alt ust].map { |y| "agiz_#{t}_#{y}" } }
      sirayla_sik(ids, KAM[5], cekler: cek_listesi(:agiz, [0, -2, 0], ids.size), bak: [0.3, 0.6, 0.75])
      z.kamera(0.8, KAM[5])
      z.bekle(0.3)

      z.baslik('6 · Üst tablayı yanların ve dikmenin üstüne oturtun, altı çektirme vidasını sıkın')
      z.kamera(1.2, KAM[6])
      hareket(:ust_tabla, [0, 0, 300], [0, 0, 2], 2.0)
      ids = %w[on arka].map { |y| "dust_#{y}" } + %w[sag sol].flat_map { |t| %w[on arka].map { |y| "ust_#{t}_#{y}" } }
      sirayla_sik(ids, KAM[6], cekler: cek_listesi(:ust_tabla, [0, 0, 2], ids.size))
      z.kamera(0.8, KAM[6])
      z.bekle(0.3)

      z.baslik('7 · Arkalığı arkaya yerleştirip çivileri çakın — delikler yatak bölmesinin arkasına gelir')
      z.kamera(1.2, KAM[7])
      hareket(:arkalik, [0, 450, 0], [0, 0, 0], 2.0)
      z.an { |s, _| CIVILER.each { |id| s[:v][id] = { adv: 1.0, ang: 0.0 } } }
      z.bekle(0.3)
      yakin_kamera(CIVILER.first, yon: [1.0, 0.75, 0.45])
      civi_cak(CIVILER.first)
      z.kamera(0.8, KAM[7])
      CIVILER.drop(1).each { |id| civi_cak(id) }
      z.bekle(0.3)

      cekmece_kur(:mama, 8) # adım 8-11

      z.baslik('12 · Aksesuar çekmecesini aynı şekilde kurup raylara itin')
      cekmeceler_hizli(%i[aks], KAM[:aks])

      z.baslik('13 · Kap çekmecesini ve yatak tepsisini aynı şekilde kurun; kaydırma pabuçlarıyla alt tablanın üstüne itin')
      cekmeceler_hizli(%i[kap yatak], KAM[:alt])

      z.baslik('14 · Yatak tepsisini çekin, minderi kabarık kenarı arkaya gelecek şekilde yerleştirin')
      cekmeceye_koy(:yatak, %i[minder], KAM[:ek_yatak])

      z.baslik('15 · Kap çekmecesine damlama tepsisini, kap tablasını ve iki paslanmaz kabı yerleştirin')
      cekmeceye_koy(:kap, %i[tepsi kap_tablasi kaplar], KAM[:ek_kap])

      z.baslik('16 · Mama kabını mama çekmecesine yerleştirin')
      cekmeceye_koy(:mama, %i[mama_kabi], KAM[:ek_mama])

      z.baslik('17 · Tasma askılarını sağ yana birer vidayla takın')
      askilari_tak

      z.baslik('Kurulum tamamlandı')
      z.kamera(1.6, KAM[:bitti])
      z.olay(1.3) { |s, u| ACIK.each { |c, m| cekmece_parcalari(c).each { |k| s[:p][k][:off] = [0, -0.7 * m * u, 0] } } }
      z.bekle(0.8)
      z.olay(1.3) { |s, u| ACIK.each { |c, m| cekmece_parcalari(c).each { |k| s[:p][k][:off] = [0, -0.7 * m * (1 - u), 0] } } }
      z.bekle(1.2)
      @cz
    end

    def sure
      @cz.t
    end

    def ilk_durum
      { liste: true,
        p: SIRA.map { |k| [k, { vis: false, off: [0, 0, 0] }] }.to_h,
        v: @vidalar.map { |v| [v[:id], { adv: 1.0, ang: 0.0 }] }.to_h,
        drv: nil,
        cekic: nil }
    end

    def durum(t)
      s = ilk_durum
      @cz.olaylar.each do |t0, t1, yumusak, fn|
        next if t < t0
        u = t1 > t0 ? ((t - t0) / (t1 - t0)).clamp(0.0, 1.0) : 1.0
        fn.call(s, yumusak ? yumusat(u) : u)
      end
      s
    end

    # Kamerayı hedef etrafında küresel koordinatla gezdirir (yörünge hissi)
    def kamera_at(t)
      ks = @cz.kameralar
      idx = ks.rindex { |k| k[0] <= t } || 0
      cur = ks[idx]
      prev = idx > 0 ? ks[idx - 1] : cur
      u = cur[1] > cur[0] ? yumusat(((t - cur[0]) / (cur[1] - cur[0])).clamp(0.0, 1.0)) : 1.0
      poz = ->(k) { k[2].is_a?(Proc) ? (k[3] ||= k[2].call) : [k[2], k[3]] }
      pg, ph = poz.(prev)
      cg, ch = poz.(cur)
      h = lerp3(ph, ch, u)
      kure = lambda do |e, c|
        v = [e[0] - c[0], e[1] - c[1], e[2] - c[2]]
        r = Math.sqrt(v.sum { |x| x * x })
        [r, Math.atan2(v[1], v[0]), Math.asin(v[2] / r)]
      end
      r0, a0, e0 = kure.(pg, ph)
      r1, a1, e1 = kure.(cg, ch)
      da = a1 - a0
      da -= 2 * Math::PI while da > Math::PI
      da += 2 * Math::PI while da < -Math::PI
      r = lerp(r0, r1, u)
      a = a0 + da * u
      el = lerp(e0, e1, u)
      eye = [h[0] + r * Math.cos(el) * Math.cos(a), h[1] + r * Math.cos(el) * Math.sin(a), h[2] + r * Math.sin(el)]
      [eye, h]
    end

    UZAK = [0, 0, -100_000].freeze

    def uygula(s)
      @liste_tag.visible = s[:liste] if @liste_tag.visible? != s[:liste]
      SIRA.each do |k|
        st = s[:p][k]
        t = tr(*(st[:vis] ? st[:off] : UZAK))
        @parca[k].move!(t * @taban_tr[k])
      end
      @vidalar.each do |v|
        st = s[:v][v[:id]]
        next v[:inst].move!(tr(*UZAK) * v[:lt]) if st[:gizli] # demonte parça: görüş dışında
        m = vida_tr(v, st[:adv], st[:ang])
        v[:inst].move!(m)
      end
      arac_yerlestir(s[:drv])
      cekic_yerlestir(s[:cekic])
    end

    # Tornavida (dar yerlerde kısa tornavida) vida başına, vidanın w yönünden gelir.
    def arac_yerlestir(drv)
      @arac.move!(tr(*UZAK))
      @kisa_arac.move!(tr(*UZAK))
      return unless drv
      v = @vidalar.find { |x| x[:id] == drv[:id] }
      dunya = @parca[v[:parca]].transformation
      dunya *= v[:grup].transformation if v[:grup]
      dunya *= v[:inst].transformation
      bas = Geom::Point3d.new(-v[:bas_h].mm, 0, 0).transform(dunya)
      # menteşe vidalarının ekseni dünyada sabit; diğerleri parçayla birlikte döner
      w = v[:kapi] ? v[:w] : v[:w].transform(@parca[v[:parca]].transformation).normalize
      uc = bas.offset(w, (drv[:uz] * (v[:kisa] ? 30 : 130)).mm)
      ax = w.axes
      (v[:kisa] ? @kisa_arac : @arac).move!(Geom::Transformation.axes(uc, w, ax[0], ax[1]) *
                                             Geom::Transformation.rotation(ORIGIN, X_AXIS, drv[:don].degrees))
    end

    def cekic_yerlestir(ck)
      return @cekic.move!(tr(*UZAK)) unless ck
      v = @vidalar.find { |x| x[:id] == ck[:id] }
      ana = @parca[v[:parca]].transformation
      bas = Geom::Point3d.new(-v[:bas_h].mm, 0, 0).transform(ana * v[:inst].transformation)
      w = v[:w].transform(ana).normalize
      yuz = bas.offset(w, (ck[:uz] * 150).mm)
      yy = Z_AXIS.cross(w)
      yy = X_AXIS.clone unless yy.valid? # alttan vuruşta (w dikey) çapraz çarpım sıfır
      yy.normalize!
      @cekic.move!(Geom::Transformation.axes(yuz, w, yy, w.cross(yy)))
    end

    def kamera_uygula(t)
      eye, h = kamera_at(t)
      @m.active_view.camera.set(P(*eye), P(*h), Z_AXIS)
    end

    def kare(t)
      @simdi = t
      uygula(durum(t))
      kamera_uygula(t) unless @serbest
      durum_yazisi
    end

    # Serbest kamera: oynatma kamerayı yönetmez, fareyle istenen açıdan bakılır.
    def serbest_kamera(acik = !@serbest)
      @serbest = acik
      durum_yazisi
      acik ? 'Serbest kamera açık: fareyle istediğin açıya çevir' : 'Serbest kamera kapalı: oynatma kamerası'
    end

    def hazirla(oran = 0.0)
      bagla unless @parca && @parca.values.all?(&:valid?)
      c = @m.active_view.camera
      unless @eski_tag # duraklatılmış oynatma zaten hazır: eski hali tekrar kaydetme
        @eski_tag = [@liste_tag.visible?, @arac_tag.visible?, SIRA.map { |k| @parca[k].layer.visible? }]
        @eski_kam = [c.eye, c.target, c.up, c.fov, c.aspect_ratio]
        @arac_tag.visible = true
        SIRA.each { |k| @parca[k].layer.visible = true }
      end
      return if @serbest && oran.zero? # serbest bakışta kullanıcının kamerasına dokunma
      c.perspective = true
      c.aspect_ratio = oran
      c.fov = oran > 0 ? VIDEO_FOV : DIKEY_FOV
    end

    # Montajlı son durum: tüm parçalar yerinde, vidalar, çiviler ve askılar takılı, çekmeceler kapalı.
    def son_durum
      s = ilk_durum
      SIRA.each { |k| s[:p][k] = { vis: true, off: [0, 0, 0] } }
      s[:v].each_key { |id| s[:v][id] = { adv: 0.0, ang: 0.0 } }
      s[:liste] = @liste_tag.visible?
      uygula(s)
      @arac.move!(Geom::Transformation.new)
      @kisa_arac.move!(Geom::Transformation.new)
      @cekic.move!(Geom::Transformation.new)
    end

    # Modeli montajlı hale ve eski kameraya döndürür. Duraklatılmış modeli
    # kaydetmeden önce mutlaka çağrılmalı (parçalar uzağa taşınmış durur).
    def bitir
      if @oynatici
        @oynatici = nil
        @m.active_view.animation = nil
      end
      @simdi = nil
      return unless @eski_tag
      son_durum
      @liste_tag.visible = @eski_tag[0]
      @arac_tag.visible = @eski_tag[1]
      SIRA.each_with_index { |k, i| @parca[k].layer.visible = @eski_tag[2][i] }
      c = @m.active_view.camera
      c.set(*@eski_kam[0, 3])
      c.aspect_ratio = @eski_kam[4]
      c.fov = @eski_kam[3]
      @eski_tag = nil
      @m.active_view.invalidate
      Sketchup.status_text = ''
    end

    # Ekranda oynatma: bas → son arası oynar, son'da durur; sahne o anda kalır.
    class Oynatici
      def initialize(mod, bas, son)
        @mod = mod
        @bas = bas
        @son = son
        @t0 = nil
      end

      def nextFrame(view)
        @t0 ||= Time.now
        t = [@bas + (Time.now - @t0), @son].min
        @mod.kare(t)
        view.show_frame
        return true if t < @son
        @mod.durakladi(self)
        @mod.bitir if t >= @mod.sure
        false
      end

      # Kamera fareyle çevrilince SketchUp animasyonu keser: olduğu yerde kalır.
      def stop
        @mod.durakladi(self)
      end
    end

    def durakladi(o)
      return unless @oynatici.equal?(o)
      @oynatici = nil
      durum_yazisi
    end

    def oynuyor?
      !@oynatici.nil?
    end

    def baslik_at(t)
      b = @cz.basliklar.select { |x| x[0] <= t }.last
      b && b[1]
    end

    def durum_yazisi
      return unless @simdi
      ek = oynuyor? ? '' : '   (durdu — → sonraki adım, ← önceki, Enter devam, K serbest kamera, Esc bitir)'
      Sketchup.status_text = "#{baslik_at(@simdi)}#{ek}#{@serbest ? '   [serbest kamera]' : ''}"
    end

    # ------------------------------------------------------------------
    # Oynatma kontrolü (Ruby Konsolu'ndan ya da `kumanda` ile klavyeden).
    # Adımlar başlıkların sırasıdır: 0 kutu içeriği, 1-17 montaj, 18 bitmiş ürün.
    # ------------------------------------------------------------------
    # Adım sınırında durulan an sınırdan biraz öncedir: sonraki adımın anlık ilk
    # işi (ör. parça listesini gizleme) uygulanmaz, bitmiş adım kendi kamerasıyla kalır.
    PAY = 0.002

    # n. adımın başlangıç ve bitiş durma noktaları (sn)
    def adim_araligi(n)
      b = @cz.basliklar
      [n.zero? ? 0.0 : b[n][0] - PAY, n + 1 < b.size ? b[n + 1][0] - PAY : sure]
    end

    # t anındaki adım; bir adımın bitiş durma noktası sonraki adımın başı sayılır.
    def adim_no(t)
      @cz.basliklar.rindex { |x| x[0] <= t + 2 * PAY } || 0
    end

    # bas'tan son'a oynatır (son verilmezse sona kadar).
    def oynat(bas = 0.0, son = nil)
      @m = Sketchup.active_model
      hazirla
      son ||= sure
      @oynatici = Oynatici.new(self, bas, son)
      @m.active_view.animation = @oynatici
      "Oynatılıyor: #{bas.round(1)} → #{son.round(1)} sn"
    end

    # Sadece n. adımı oynatır, adımın sonunda durur.
    def adim(n)
      bagla unless @cz
      oynat(*adim_araligi(n))
    end

    # Bulunduğu adımın sonuna kadar oynatıp durur (adım başındaysa o adımı oynatır).
    def sonraki
      bagla unless @cz
      t = @simdi || 0.0
      return 'Kurulum sonunda — baştan için git(0)' if t >= sure - 1e-3
      oynat(t, adim_araligi(adim_no(t))[1])
    end

    # Adımın ortasındaysa o adımın başına, adım başındaysa bir öncekinin başına döner.
    def onceki
      git(adim_no((@simdi || 0.0) - 3 * PAY))
    end

    # n. adımın başına atlar ve orada bekler.
    def git(n)
      @m = Sketchup.active_model
      bagla unless @cz
      durdur if oynuyor?
      hazirla
      kare(adim_araligi(n)[0])
      @m.active_view.invalidate
      baslik_at(@simdi)
    end

    # Olduğu yerde dondurur; devam ile sürer.
    def durdur
      return 'Oynamıyor' unless oynuyor?
      @oynatici = nil
      @m.active_view.animation = nil
      durum_yazisi
      "Durdu: #{@simdi.round(1)} sn — #{baslik_at(@simdi)}"
    end

    # Kaldığı yerden sona kadar oynatır (sondaysa baştan).
    def devam
      t = @simdi && @simdi < sure - 1e-3 ? @simdi : 0.0
      oynat(t)
    end

    # Klavye: → sonraki adım, ← önceki adım, Enter durdur/devam, Esc bitir.
    # (Boşluk SketchUp'ta Seç aracının kısayolu olduğu için kullanılmadı.)
    class Kumanda
      def initialize(mod) @mod = mod end

      def activate
        Sketchup.status_text = 'Kurulum: → sonraki adım · ← önceki adım · Enter durdur/devam · K serbest kamera · Esc bitir'
      end

      def onKeyDown(key, _repeat, _flags, _view)
        case key
        when VK_RIGHT then @mod.sonraki
        when VK_LEFT then @mod.onceki
        when 75 then @mod.serbest_kamera # K
        else return false
        end
        true
      end

      def onReturn(_view)
        @mod.oynuyor? ? @mod.durdur : @mod.devam
      end

      def onCancel(reason, _view)
        Sketchup.active_model.select_tool(nil) if reason.zero?
      end

      # Başka araca geçince model montajlı hale döner (yarım halde kaydedilmesin).
      def deactivate(_view)
        @mod.bitir
      end
    end

    def kumanda
      git(0)
      @m.select_tool(Kumanda.new(self))
      'Kumanda açık: çizim alanına bir kez tıkla, sonra → ile adım adım ilerle'
    end

    # Tek kare (video ayarlarıyla) — kadraj ayarlamak için.
    def onizle(t, dosya, gen: 1280, yuk: 720)
      @m = Sketchup.active_model
      serbest, @serbest = @serbest, false
      hazirla(gen.to_f / yuk)
      kare(t)
      @m.active_view.write_image(filename: dosya, width: gen, height: yuk, antialias: true, transparent: false)
      baslik_at(t)
    ensure
      bitir
      @serbest = serbest
    end

    # Animasyonu PNG karelere yazar; basliklar.json video üstü yazılar içindir.
    def kaydet(klasor, fps: 25, gen: 1280, yuk: 720, bas: 0.0, son: nil)
      @m = Sketchup.active_model
      Dir.mkdir(klasor) unless File.directory?(klasor)
      serbest, @serbest = @serbest, false
      hazirla(gen.to_f / yuk)
      son ||= sure
      n0 = (bas * fps).round
      n1 = (son * fps).round
      (n0...n1).each do |i|
        kare(i.to_f / fps)
        @m.active_view.write_image(filename: File.join(klasor, format('f%05d.png', i)), width: gen, height: yuk,
                                   antialias: true, transparent: false)
      end
      File.write(File.join(klasor, 'basliklar.json'),
                 '[' + @cz.basliklar.map { |t, b| "[#{t.round(3)}, \"#{b}\"]" }.join(', ') + ']', encoding: 'UTF-8')
      "#{n1 - n0} kare yazıldı (#{n0}..#{n1 - 1}), toplam süre #{sure.round(2)} sn"
    ensure
      bitir
      @serbest = serbest
    end
  end
end
