# encoding: UTF-8
# Kora Kombi Kabini (70 x 41,8 x 120 cm, duvara asma) — model ve kurulum kılavuzu.
# Tarif: research_notes/Urun firsatlari 2026-11-21/tarif-A-kora-kombi-kabini.txt (A1; 21.11.2026).
# Duvardaki kombinin etrafını saran, arkası açık kabin. Kombinin yüksekliğine göre asılır (kabinin altı = kombinin
# altı − 250 mm). Alt tabla ve üst ön tabla 200 mm derin: arkadaki 200 mm boru ve baca geçişi; üstteki arka şerit
# raf pimlerine oturur, sökülür. Beyaz MDF tam bindirme kapaklarda CNC havalandırma yarıkları (bej MDF kenar).
# Gövde beyaz mat 18 mm sunta, tablalar yanların arasında (minifiks + kavela). İki ayarlı askı + 664 mm ray, altta
# iki L köşebent duvara. Yalnız hermetik / yoğuşmalı kombi için (bacalı kombi kapalı dolaba konmaz).
#
# Her panel ayrı bileşen; fabrikada takılı gelenler (minifiks bulonları, menteşe tabanları, kapaklarda menteşe
# gövdeleri, askılar) panelin içinde. Minifiks gövdeleri, kavelalar, minifiks kapakları, raf pimleri, askı rayı,
# L köşebentler, kulplar ve vida-dübel ayrı gelir. Kombi YER TUTUCU (ürünle gelmez).
#   1 kavelalar  2 sol yan  3 sol minifiksler  4 sağ yan + minifiksler  5 minifiks kapakları  6 askı rayı
#   7 kabini asma  8 L köşebentler  9 raf pimleri + arka şerit  10 kapaklar  11 kulplar
#
# SketchUp > Pencere > Ruby Konsolu:
#   load 'C:/.../scripts/product-3d/kurulum/kora_kombi_kabini.rb'
#   OzcanKurulum::KoraKombiKabini.kur           # AÇIK MODELİ TEMİZLER, modeli sıfırdan kurar
#   OzcanKurulum::KoraKombiKabini.oynat         # montaj animasyonunu ekranda oynatır
#   OzcanKurulum::KoraKombiKabini.kumanda       # klavyeyle adım adım: → ← Enter, K serbest kamera, Esc
#   (konsoldan: sonraki, onceki, durdur, devam, adim(3), git(3), bitir)
#   OzcanKurulum::KoraKombiKabini.kaydet('C:/kareler') # animasyonu PNG karelere yazar
#
# Koordinatlar mm: X genişlik (0 = sol dış yüz), Y derinlik (0 = yanların ön kenarı, +Y duvara; kapaklar Y=-18..0,
# duvar Y=400), Z yükseklik (0 = zemin; kabinin alt kenarı modelde 1000). Tarifteki yükseklikler kabinin altından.

module OzcanKurulum
  module KoraKombiKabini
    extend self

    # ------------------------------------------------------------------
    # Ölçüler (mm)
    # ------------------------------------------------------------------
    W = 700.0            # genişlik
    T = 18.0             # panel kalınlığı
    D = 400.0            # derinlik (yan); kapakla 418
    H = 1200.0           # yükseklik
    Z0 = 1000.0          # kabinin alt dış yüzü (modelde yerden)
    ZT = Z0 + H          # üst kenar
    IW = W - 2 * T       # iç genişlik 664
    ON_D = 200.0         # alt tabla ve üst ön tabla derinliği; arkada 200 mm boru/baca geçişi açık
    # Minifiks: uzun kenardan 32, kısa kenardan 36 mm; kavela ortada
    MF_Y = [32.0, ON_D - 32].freeze
    KAM_ARA = 36.0
    KAVELA_Y = ON_D / 2
    KAVELA = { r: 4.0, tabla: 18.0, yan: 12.0 }.freeze
    PIM_Y = [240.0, 300.0].freeze # üst arka şeridin raf pimleri (yanların iç yüzünde)
    PIM_R = 2.5
    PIM_Z = ZT - T - PIM_R
    # Askı: yanların iç yüzünde üst-arka köşede (Y 340–388, Z 1090–1165); kanca duvardaki rayın kanalına
    ASKI = { x: 20.0, y0: 340.0, ust: ZT - 35, h: 75.0 }.freeze
    RAY = { z0: ZT - 35 - 17 - 55, z1: ZT - 35 - 17 }.freeze # 664 mm askı rayı, duvarda yanların arasında
    KOSE = { z0: Z0 + 40, k: 40.0 }.freeze # L köşebent 40 x 40, alt-arka köşede, duvara
    KOMBI = { gen: 440.0, h: 720.0, der: 330.0, z0: Z0 + 250 }.freeze # yer tutucu, ürünle gelmez
    # Kapaklar: beyaz MDF, tam bindirme, ortada 2 mm; her birinde 3 düz menteşe ve 16 CNC yarık
    KAPI_W = 347.0
    KAPI_Z = [Z0 + 2, ZT - 2].freeze
    MENTESE_Z = [100.0, 598.0, 1096.0].map { |z| KAPI_Z[0] + z }.freeze
    KAPI = {
      kapak_sol: { x0: 2.0, z: KAPI_Z, gen: KAPI_W, eksen: 2.0, py: -T, yon: -1, panel: T, sx: 1, mentese: MENTESE_Z },
      kapak_sag: { x0: W - 2 - KAPI_W, z: KAPI_Z, gen: KAPI_W, eksen: W - 2, py: -T, yon: 1, panel: W - T, sx: -1,
                   mentese: MENTESE_Z }
    }.freeze
    KAPILAR = KAPI.keys.freeze
    KAP_ZC = 2.0 + 22.5 - T # kap merkezi yan iç yüzünden 6,5 mm (kapak kenarından 22,5)
    YARIK = { x: [50.0, 297.0], h: 10.0, z: (0..7).map { |i| 80.0 + 22 * i } + (0..7).map { |i| 962.0 + 22 * i } }.freeze
    KULP_ARA = 128.0
    KULP = { kenar: 40.0, z: 400.0 }.freeze # iç kenardan 40, kapak altından 400 (dikey)
    DIS = [850.0, -400.0, -Z0].freeze     # askı rayı takılırken gövde yerde, sağda bekler
    KAPAK_DIS = [0.0, -450.0, 0.0].freeze # kapaklar 90° açık önden gelir
    PLAKA_T = 3.0

    DIKEY_FOV = 30.0
    VIDEO_FOV = 50.0

    DICT = 'ozcan_kurulum'
    GOVDE = %i[alt_tabla ust_tabla sol_yan sag_yan].freeze
    SIRA = (GOVDE + %i[serit ray] + KAPILAR).freeze
    TASINAN = GOVDE
    AD = {
      alt_tabla: 'Alt Tabla', ust_tabla: 'Üst Ön Tabla', sol_yan: 'Sol Yan', sag_yan: 'Sağ Yan',
      serit: 'Üst Arka Şerit (sökülür)', ray: 'Askı Rayı', kapak_sol: 'Sol Kapak', kapak_sag: 'Sağ Kapak'
    }.freeze
    ETIKET = {
      alt_tabla: '01 Tablalar', ust_tabla: '01 Tablalar', sol_yan: '02 Sol Yan', sag_yan: '03 Sağ Yan',
      ray: '04 Askı Rayı', serit: '05 Arka Şerit', kapak_sol: '06 Kapaklar', kapak_sag: '06 Kapaklar'
    }.freeze
    LISTE_TAG = '00 Parça Listesi'
    ARAC_TAG = '99 Tornavida'
    DUVAR_TAG = 'Duvar ve Zemin'
    KOMBI_TAG = 'Kombi (yer tutucu)'
    OLCU_TAG = 'Ölçüler'

    # Kamera noktaları [göz, hedef] (mm)
    KAM = {
      liste:   [[2650, -2650, 6000], [2650, 120, 0]],
      1 =>     [[1050, -1000, 1500], [350, 100, 1020]],
      '1b' =>  [[1050, -1000, 2700], [350, 100, 2190]],
      2 =>     [[-1500, -2700, 2600], [350, 200, 1600]],
      3 =>     [[1500, -2700, 2800], [350, 200, 1600]],
      4 =>     [[2200, -2600, 2500], [350, 200, 1600]],
      5 =>     [[900, -800, 2950], [350, 100, 2200]],
      6 =>     [[1700, -3600, 1900], [700, 200, 1300]],
      7 =>     [[1400, -3300, 2300], [350, 200, 1550]],
      8 =>     [[900, -1100, 1350], [350, 300, 1060]],
      9 =>     [[1000, -1300, 2550], [350, 280, 2120]],
      kapak:   [[1500, -2900, 2200], [350, -150, 1600]],
      10 =>    [[1300, -2400, 2000], [350, -200, 1450]],
      bitti:   [[1600, -3300, 2100], [350, 0, 1550]]
    }.freeze
    # Tanıtım görselleri (4:5): ad, kapak açıları, açık katmanlar (:duvar, :kombi, :olcu, :seritsiz), [göz, hedef]
    TANITIM = [
      ['1_kapali', {}, %i[duvar kombi], [[1100, -2900, 1750], [350, 100, 1520]]],
      ['2_kapaklar_acik', { kapak_sol: 100, kapak_sag: 100 }, %i[duvar kombi], [[1100, -3000, 1900], [350, 0, 1600]]],
      ['3_yariklar_ve_kulp', {}, %i[duvar kombi], [[1050, -1350, 1650], [360, -20, 1300]]],
      ['4_boru_ve_baca_gecisi', {}, %i[kombi seritsiz], [[1900, 2300, 2700], [350, 250, 1550]]],
      ['5_olculer', {}, %i[duvar olcu], [[1900, -3400, 1700], [300, 100, 1450]]]
    ].freeze

    # Parçaların yerleşim orijini (bileşen orijini = parçanın min köşesi)
    ORIJIN = {
      alt_tabla: [T, 0, Z0], ust_tabla: [T, 0, ZT - T], sol_yan: [0, 0, Z0], sag_yan: [W - T, 0, Z0],
      serit: [T + 1, ON_D, ZT - T], ray: [T, D - 10, 0],
      kapak_sol: [KAPI[:kapak_sol][:x0], -T, KAPI_Z[0]], kapak_sag: [KAPI[:kapak_sag][:x0], -T, KAPI_Z[0]]
    }.freeze

    KAVELALAR = %w[alt ust].flat_map { |t| %w[sol sag].map { |y| "kavela_#{t}_#{y}" } }.freeze
    KAMLAR = %w[sol sag].to_h { |y| [y, %w[alt ust].flat_map { |t| %w[on arka].map { |o| "mf_#{t}_#{y}_#{o}" } }] }.freeze
    KAPAKCIKLAR = %w[sol sag].flat_map { |y| %w[on arka].map { |o| "mfkapak_#{y}_#{o}" } }.freeze
    PIMLER = %w[sol sag].flat_map { |y| PIM_Y.each_index.map { |i| "pim_#{y}_#{i + 1}" } }.freeze
    ASKI_VIDALARI = %w[sol sag].map { |y| "aski_#{y}" }.freeze
    RAY_VIDALARI = (1..3).map { |i| "ray_vida_#{i}" }.freeze
    KOSELER = %w[sol sag].map { |y| "kose_#{y}" }.freeze
    KOSE_VIDALARI = %w[sol sag].flat_map { |y| ["kose_#{y}_yan", "kose_#{y}_duvar"] }.freeze
    KULPLAR = KAPILAR.map { |k| "kulp_#{k}" }.freeze
    KULP_VIDALARI = KULPLAR.flat_map { |k| ["#{k}_vida_1", "#{k}_vida_2"] }.freeze
    DEMONTE = (KAVELALAR + KAMLAR.values.flatten + KAPAKCIKLAR + PIMLER + RAY_VIDALARI + KOSELER + KOSE_VIDALARI +
               KULPLAR + KULP_VIDALARI).freeze

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
        govde: mk.('Beyaz Mat Sunta (D101)', [244, 243, 240]),
        mdf: mk.('Beyaz MDF Lam', [248, 248, 246]),
        bej: mk.('MDF Çekirdek (doğal bej)', [222, 200, 164]),
        kulp: mk.('Siyah Mat Kulp', [34, 34, 36]),
        aski: mk.('Askı Gövdesi (beyaz plastik)', [232, 232, 230]),
        kavela: mk.('Kavela (kayın)', [214, 182, 140]),
        mfkapak: mk.('Beyaz Minifiks Kapağı', [250, 250, 248]),
        kombi: mk.('Kombi (yer tutucu)', [236, 238, 240]),
        boru: mk.('Bakır Boru', [190, 120, 80]),
        baca: mk.('Baca (beyaz)', [228, 230, 232]),
        duvar: mk.('Duvar (açık bej)', [218, 209, 196]),
        zemin: mk.('Ahşap Zemin', [214, 180, 140]),
        olcu: mk.('Ölçü Çizgisi', [60, 64, 70]),
        cinko: mk.('Çinko Kaplama', [160, 164, 170]),
        nikel: mk.('Nikel', [192, 196, 202]),
        seffaf: mk.('Şeffaf Plastik', [205, 225, 238], 0.35),
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

    # Menteşe parçaları "menteşe çerçevesinde" çizilir: orijin kapak arka yüzünde, yan
    # panelin iç yüzü hizasında; x' menteşe ekseni, y' derinlik, z' panelden içeri.
    # Taban haç biçimli: oval delikli kanatlar, orta sırt; arka uçtaki vidanın
    # altına kolun çatalı kayar, ortadaki dişli deliğe kolun sabitleme vidası girer.
    def taban_tanimi
      d = @m.definitions.add('Menteşe Tabanı (küçük parça)')
      e = d.entities
      kutu(e, -7, 22, 0, 7, 62, 6)
      [-1, 1].each { |s| it(e, [[30, 0], [30, 2.5], [46, 2.5], [46, 0]].map { |y, z| P(7 * s, y, z) }, yon(s, 0, 0), 12) }
      it(e, [P(-4.5, 24, 6), P(4.5, 24, 6), P(4.5, 62, 6), P(-4.5, 62, 6)], yon(0, 0, 1), 2)
      [-1, 1].each { |s| it(e, plaka_hatti([[12 * s, 38, 2.2], [16 * s, 38, 2.2]]).map { |x, y| P(x, y, 2.5) }, yon(0, 0, -1), 2.5) }
      [34, 59].each { |y| daire_it(e, P(0, y, 8), Z_AXIS, 2, yon(0, 0, -1), 7, 16) }
      boya(e, @mat[:nikel])
      [-1, 1].each { |s| e.add_instance(@vida16, eksen([14 * s, 38, 2.5], [0, 0, -1], [1, 0, 0])) }
      e.add_instance(@tvida, eksen([0, 59, 9.6], [0, 0, -1], [1, 0, 0]))
      d
    end

    # Kol: ters U sac; ön uçta mafsal, ortada kare yuvada sabitleme vidası,
    # ayar deliği, arka uçta tabandaki vidaya geçen çatal.
    def kol_tanimi
      d = @m.definitions.add('Menteşe Kolu')
      e = d.entities
      u = [[-8, 2.5], [-7.2, 2.5], [-7.2, 8], [7.2, 8], [7.2, 2.5], [8, 2.5], [8, 9.5], [-8, 9.5]]
      it(e, u.map { |x, z| P(x, 16, z) }, yon(0, 1, 0), 48)
      catal = (0..10).map { |i| a = Math::PI + Math::PI * i / 10; P(2.2 * Math.cos(a), 56.2 + 2.2 * Math.sin(a), 9.5) }
      it(e, [P(-2.2, 64, 9.5)] + catal + [P(2.2, 64, 9.5)], yon(0, 0, -1), 1.5)
      it(e, yuvarlak_dik(-4.2, 29.8, 4.2, 38.2, 1).map { |x, y| P(x, y, 9.5) }, yon(0, 0, -1), 1.5)
      it(e, plaka_hatti([[0, 43.5, 2.2], [0, 48.5, 2.2]]).map { |x, y| P(x, y, 9.5) }, yon(0, 0, -1), 1.5)
      boya(e, @mat[:nikel])
      torna(e, [[-8, 0], [-8, 5.5], [8, 5.5], [8, 0]], 24, @mat[:nikel]).transform!(tr(0, 12, 14))
      [-1, 1].each do |s|
        torna(e, [[0, 0], [0, 1.6], [0.8, 1.6], [0.8, 0]], 12, @mat[:nikel])
          .transform!(eksen([8 * s, 22, 5.5], [s, 0, 0], [0, 0, 1]))
      end
      d
    end

    # Kap: Ø35 çanak + kapağın arka yüzünde kare ağızlı flanş ve iki vida kulağı.
    def kap_tanimi
      d = @m.definitions.add('Menteşe Kabı Ø35')
      e = d.entities
      zc = KAP_ZC
      torna(e, [[0, 16], [0, 17.5], [11.5, 17.5], [11.5, 0], [10.5, 0], [10.5, 16]], 32, @mat[:nikel])
        .transform!(eksen([0, 0, zc], [0, -1, 0], [0, 0, 1]))
      g = e.add_group
      f = g.entities.add_face(yuvarlak_dik(-19, zc - 19, 19, zc + 19, 8).map { |x, z| P(x, 0, z) })
      g.entities.add_face(yuvarlak_dik(-12, zc - 12, 12, zc + 12, 5).map { |x, z| P(x, 0, z) }).erase!
      itme(f, yon(0, 1, 0), 1.5)
      boya(g.entities, @mat[:nikel])
      [-1, 1].each do |s|
        k = e.add_group
        it(k.entities, plaka_hatti([[19 * s, zc + 6, 7], [24 * s, zc + 6, 7]]).map { |x, z| P(x, 0, z) }, yon(0, 1, 0), 1.2)
        boya(k.entities, @mat[:nikel])
        e.add_instance(@vida16h, eksen([24 * s, -1.0, zc + 6], [0, -1, 0], [0, 0, 1]))
      end
      torna(e, [[-6, 0], [-6, 4], [6, 4], [6, 0]], 20, @mat[:nikel]).transform!(tr(0, -4, zc - 7.5))
      d
    end

    def bag_tanimi
      d = @m.definitions.add('Menteşe Bağlantı Kolu')
      kutu(d.entities, 0, -5, -2.5, 10, 5, 2.5)
      boya(d.entities, @mat[:nikel])
      d
    end

    def pim_tanimi
      d = @m.definitions.add('Raf Pimi Ø5')
      torna(d.entities, [[-8, 0], [-8, 2.1], [-7.5, 2.5], [0, 2.5], [0, 3.5], [1, 3.5], [1, 2.5],
                         [7.5, 2.5], [8, 2.1], [8, 0]], 20, @mat[:nikel])
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

    # Dar yerler için kısa tornavida
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

    # Minifiks bulonu (36 mm eksantrik mesafesi): dişli kısmı yanda (x<0), başlı şaftı yerel +x yönünde tablaya girer.
    def bulon36_tanimi
      d = @m.definitions.add('Minifiks Bulonu (36)')
      torna(d.entities, [[-8, 0], [-8, 2.5], [0, 2.5], [0, 3.5], [2, 3.5], [2, 2.5], [30, 2.5], [31, 4], [35, 4],
                         [36, 2], [36, 0]], 16, @mat[:cinko])
      d
    end

    # Kavela Ø8 x 30: yerel +x tablanın ucuna giriş yönü; x∈[0, 18] tablada, x∈[-12, 0] yandaki deliğe girer.
    def kavela_tanimi
      d = @m.definitions.add('Kavela Ø8x30')
      torna(d.entities, [[-12, 0], [-12, 3.2], [-11, 4], [17, 4], [18, 3.2], [18, 0]], 16, @mat[:kavela])
      d
    end

    # Beyaz minifiks kapağı: yerel +x panele doğru; disk x∈[-1.5, 0], tırnak eksantriğin yuvasına girer.
    def mfkapak_tanimi
      d = @m.definitions.add('Minifiks Kapağı (beyaz)')
      torna(d.entities, [[-1.5, 0], [-1.5, 8.2], [-0.6, 9], [0, 9], [0, 3], [4, 3], [4, 0]], 24, @mat[:mfkapak])
      d
    end

    # L köşebent 40 x 40 (2 mm sac): yerel +x yanın iç yüzünden içeri (duvar kanadı), +y duvara doğru, z yukarı.
    # Yan kanadı x∈[0, 2] düzleminde y∈[-40, 0]; duvar kanadı y∈[-2, 0] düzleminde x∈[0, 40]. Orijin iç köşe çizgisi.
    def kose_tanimi
      d = @m.definitions.add('L Köşebent 40x40')
      e = d.entities
      kutu(e, 0, -KOSE[:k], 0, 2, 0, KOSE[:k])
      kutu(e, 2, -2, 0, KOSE[:k], 0, KOSE[:k])
      boya(e, @mat[:nikel])
      d
    end

    # Siyah mat çubuk kulp, 128 mm vida aralığı: yerel +x önden dışarı, y kulp boyu.
    def kulp_tanimi
      d = @m.definitions.add('Siyah Mat Çubuk Kulp 128')
      [-1, 1].each { |s| torna(d.entities, [[0, 0], [0, 4.5], [26, 4.5], [26, 0]], 16, @mat[:kulp]).transform!(tr(0, s * KULP_ARA / 2, 0)) }
      torna(d.entities, [[-78, 0], [-78, 4.5], [-76, 6], [76, 6], [78, 4.5], [78, 0]], 20, @mat[:kulp])
        .transform!(eksen([32, 0, 0], [0, 1, 0], [1, 0, 0]))
      d
    end

    # --- Duvar ve zemin (asma adımlarında ve tanıtımda) ---
    def duvar_tanimi
      d = @m.definitions.add('Duvar ve Zemin')
      e = d.entities
      g = e.add_group
      kutu(g.entities, -2600, D, 0, 3300, D + 20, 3400)
      boya(g.entities, @mat[:duvar])
      z = e.add_group
      kutu(z.entities, -2600, -4000, -12, 3300, D, 0)
      boya(z.entities, @mat[:zemin])
      (-2600..3300).step(180).drop(1).each { |x| z.entities.add_line(P(x, -4000, 0), P(x, D, 0)) } # parke derzleri
      d
    end

    # --- Yer tutucu kombi (ürünle gelmez): duvara yaslı beyaz gövde, altından 4 boru, üstünden koaksiyel baca ---
    def kombi_tanimi
      d = @m.definitions.add('Kombi (yer tutucu)')
      e = d.entities
      k = KOMBI
      x0 = (W - k[:gen]) / 2
      g = e.add_group
      kutu(g.entities, x0, D - k[:der], k[:z0], x0 + k[:gen], D, k[:z0] + k[:h])
      boya(g.entities, @mat[:kombi])
      p = e.add_group # ön panelde küçük gösterge şeridi
      kutu(p.entities, x0 + 120, D - k[:der] - 1, k[:z0] + 60, x0 + k[:gen] - 120, D - k[:der], k[:z0] + 100)
      boya(p.entities, @mat[:olcu])
      [-90, -30, 30, 90].each do |dx| # 4 boru Ø22, duvardan 60 mm önde, kombinin altından aşağı
        torna(e, [[0, 0], [0, 11], [k[:z0] - 700, 11], [k[:z0] - 700, 0]], 16, @mat[:boru])
          .transform!(eksen([W / 2 + dx, D - 60, k[:z0]], [0, 0, -1], [1, 0, 0]))
      end
      zb = k[:z0] + k[:h] + 120 # baca: kombi üstünden 120 mm yukarı, 90° dirsekle duvara
      torna(e, [[0, 0], [0, 50], [170, 50], [170, 0]], 24, @mat[:baca])
        .transform!(eksen([W / 2, D - k[:der] / 2, k[:z0] + k[:h]], [0, 0, 1], [1, 0, 0]))
      torna(e, [[0, 0], [0, 50], [k[:der] / 2 + 60, 50], [k[:der] / 2 + 60, 0]], 24, @mat[:baca])
        .transform!(eksen([W / 2, D - k[:der] / 2 - 50, zb], [0, 1, 0], [0, 0, 1]))
      d
    end

    # --- Ölçü görseli: çizgiler ve 3B yazı ---
    def cubuk(e, a, b, k = 3.0)
      fark = b.zip(a).map { |p, q| p - q }
      g = e.add_group
      kutu(g.entities, 0, -k / 2, -k / 2, Math.sqrt(fark.sum { |c| c * c }), k / 2, k / 2)
      x = Geom::Vector3d.new(*fark).normalize
      z = x.parallel?(Z_AXIS) ? X_AXIS.clone : Z_AXIS.clone
      yv = z.cross(x).normalize
      g.transform!(Geom::Transformation.axes(P(*a), x, yv, x.cross(yv)))
      boya(g.entities, @mat[:olcu])
    end

    # Yazı: dik düzlemde; yon :on (önden okunur), :dik (önden, aşağıdan yukarı)
    def yazi(e, metin, merkez, yon_ad, boy = 62.0)
      g = e.add_group
      g.entities.add_3d_text(metin, TextAlignLeft, 'Segoe UI', true, false, boy.mm, 0.0, 0.0, true, 0.0)
      c = g.bounds.center
      g.transform!(Geom::Transformation.translation(Geom::Vector3d.new(-c.x, -c.y, 0)))
      r = Geom::Transformation.rotation(ORIGIN, X_AXIS, 90.degrees)
      r = Geom::Transformation.rotation(ORIGIN, Y_AXIS, -90.degrees) * r if yon_ad == :dik
      g.transform!(Geom::Transformation.translation(P(*merkez) - ORIGIN) * r)
      boya(g.entities, @mat[:olcu])
    end

    def olcu_tanimi
      d = @m.definitions.add('Ölçüler')
      e = d.entities
      yo = -T - 1
      zu = ZT + 110 # genişlik
      cubuk(e, [0, yo, zu], [W, yo, zu])
      [0, W].each { |x| cubuk(e, [x, yo, ZT + 20], [x, yo, zu + 30], 1.6) }
      yazi(e, '700', [W / 2, yo, zu + 55], :on)
      xr = W + 130 # yükseklik
      cubuk(e, [xr, yo, Z0], [xr, yo, ZT])
      [ZT, Z0].each { |z| cubuk(e, [W + 4, yo, z], [xr + 30, yo, z], 1.6) }
      yazi(e, '1200', [xr + 55, yo, (Z0 + ZT) / 2], :dik)
      za = Z0 - 80 # derinlik (kapak dahil), sağ yanın altında
      cubuk(e, [W + 1, -T, za], [W + 1, D, za])
      [-T, D].each { |y| cubuk(e, [W + 1, y, za - 30], [W + 1, y, Z0 - 6], 1.6) }
      yazi(e, '418', [W + 75, -T - 1, za - 30], :on)
      xl = -130 # montaj kuralı: kabinin altı = kombinin altı − 250
      cubuk(e, [xl, yo, Z0], [xl, yo, KOMBI[:z0]])
      cubuk(e, [-4, yo, Z0], [xl - 30, yo, Z0], 1.6)
      cubuk(e, [W, yo, KOMBI[:z0]], [xl - 30, yo, KOMBI[:z0]], 1.2)
      yazi(e, '250', [xl - 60, yo, (Z0 + KOMBI[:z0]) / 2], :dik, 60.0)
      yazi(e, 'kombinin alt kenarı', [xl - 330, yo, KOMBI[:z0] + 50], :on, 56.0)
      yazi(e, 'kabinin altı = kombinin altı − 25 cm', [W / 2, yo, Z0 - 200], :on, 62.0)
      d
    end

    # Çektirme yok: tablalar yanlara minifiks + kavelayla bağlanır (tabla ve yan bileşenlerinde).
    def baglantilar
      []
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

    # Menteşe çerçevesi: orijin kapak arka yüzü / yanın iç yüzü / menteşe yüksekliği;
    # x' menteşe ekseni (dikey), y' = +Y derinlik, z' yandan içeri.
    def mentese_cerceve(o, sx)
      Geom::Transformation.axes(P(*o), Geom::Vector3d.new(0, 0, -sx), Y_AXIS, Geom::Vector3d.new(sx, 0, 0))
    end

    # ------------------------------------------------------------------
    # Panel bileşenleri
    # ------------------------------------------------------------------
    # Yan: alt ve üst tabla hizasında 2 minifiks bulonu + kavela deliği; iç yüzde 3 menteşe tabanı (fabrikada takılı),
    # üst-arka köşede askı (takılı), üstte 2 raf pimi deliği (pimler demonte), alt-arka köşede L köşebent (demonte).
    def yan(k, sx)
      d = parca_tanimi(AD[k])
      e = d.entities
      kutu(e, 0, 0, 0, T, D, H)
      xi = sx > 0 ? T : 0.0 # iç yüz
      [T / 2, H - T / 2].each { |z| daire_it(e, P(xi, KAVELA_Y, z), X_AXIS, KAVELA[:r], yon(-sx, 0, 0), KAVELA[:yan] + 1, 16) }
      PIM_Y.each { |y| daire_it(e, P(xi, y, PIM_Z - Z0), X_AXIS, PIM_R, yon(-sx, 0, 0), 10, 12) }
      boya(e, @mat[:govde])
      [T / 2, H - T / 2].each { |z| MF_Y.each { |y| e.add_instance(@bulon, eksen([xi, y, z], [sx, 0, 0], [0, 0, 1])) } }
      MENTESE_Z.each { |hz| e.add_instance(@taban, mentese_cerceve([xi, 0, hz - Z0], sx)) }
      t = sx > 0 ? 'sol' : 'sag'
      PIM_Y.each_with_index do |y, i|
        o = [xi, y, PIM_Z - Z0]
        vida_koy(e, @pim, eksen(o, [sx, 0, 0], [0, 0, 1]), P(*o), Geom::Vector3d.new(-sx, 0, 0), 20.0, 0.0,
                 Geom::Vector3d.new(sx, 0, 0), "pim_#{t}_#{i + 1}")
      end
      aski(e, xi, sx)
      kose(e, xi, sx, t)
      [d, ORIJIN[k]]
    end

    def sol_yan; yan(:sol_yan, 1); end
    def sag_yan; yan(:sag_yan, -1); end

    # Ayarlı asma dolap askısı (fabrikada takılı): gövdesi yanın iç yüzünde üst-arka köşede; kancası duvardaki rayın
    # kanalına oturur. Önündeki ayar vidası yüksekliği ayarlar.
    def aski(e, xi, sx)
      g = e.add_group
      g.name = 'Asma Dolap Askısı'
      x0, x1 = [xi, xi + sx * ASKI[:x]].minmax
      zt = ASKI[:ust] - Z0
      kutu(g.entities, x0, ASKI[:y0], zt - ASKI[:h], x1, D - 12, zt)
      boya(g.entities, @mat[:aski])
      k = e.add_group
      k.name = 'Askı Kancası'
      kx0, kx1 = [xi + sx * 5, xi + sx * 12].minmax
      zr = RAY[:z1] - Z0
      kutu(k.entities, kx0, D - 18, zr + 1, kx1, D - 3.5, zr + 6)
      kutu(k.entities, kx0, D - 6, zr - 14, kx1, D - 3.5, zr + 1)
      boya(k.entities, @mat[:celik])
      o = [xi + sx * ASKI[:x] / 2, ASKI[:y0], zt - ASKI[:h] + 18]
      vida_koy(e, @ayvida, eksen(o, [0, 1, 0], [0, 0, 1]), P(*o), Geom::Vector3d.new(0, 1, 0), 3.0, 2.0,
               Geom::Vector3d.new(0.25 * sx, -1, 0.35).normalize, "aski_#{sx > 0 ? 'sol' : 'sag'}")
    end

    # L köşebent (demonte): yan kanadı yanın iç yüzüne bir vidayla, duvar kanadı duvara vida + dübelle.
    def kose(e, xi, sx, t)
      o = [xi, D, KOSE[:z0] - Z0]
      lt = Geom::Transformation.axes(P(*o), Geom::Vector3d.new(sx, 0, 0), Y_AXIS, Z_AXIS) # sağda aynalı
      vida_koy(e, @kose, lt, P(*o), Geom::Vector3d.new(0, 1, 0), 60.0, 0.0, Geom::Vector3d.new(0, -1, 0), "kose_#{t}")
      zc = KOSE[:z0] - Z0 + KOSE[:k] / 2
      v1 = [xi + sx * 2, D - 22, zc]
      vida_koy(e, @vida16, eksen(v1, [-sx, 0, 0], [0, 0, 1]), P(*v1), Geom::Vector3d.new(-sx, 0, 0), 16.0, 2.5,
               Geom::Vector3d.new(sx, -0.6, 0.3).normalize, "kose_#{t}_yan")
      v2 = [xi + sx * 24, D - 2, zc]
      vida_koy(e, @avida, eksen(v2, [0, 1, 0], [0, 0, 1]), P(*v2), Geom::Vector3d.new(0, 1, 0), 40.0, 3.0,
               Geom::Vector3d.new(0.3 * sx, -1, 0.35).normalize, "kose_#{t}_duvar")
    end

    # Tabla (alt / üst ön, 664 x 200): yanların arasında; uçlarda bulon ve kavela delikleri; eksantrik yuvaları üst
    # yüzde (alt tablada iç, üst tablada dış yüz — kabin yüksekte, alt yüz aşağıdan görünür). Eksantrikler, kavelalar
    # ve üst tablanın minifiks kapakları demonte.
    def tabla(k)
      ust = k == :ust_tabla
      t = ust ? 'ust' : 'alt'
      d = parca_tanimi(AD[k])
      e = d.entities
      kutu(e, 0, 0, 0, IW, ON_D, T)
      uclar = [[0.0, 1, 'sol'], [IW, -1, 'sag']]
      uclar.each do |xu, sx, _|
        MF_Y.each do |y|
          daire_it(e, P(xu, y, T / 2), X_AXIS, 4, yon(sx, 0, 0), KAM_ARA - 8, 16)
          daire_it(e, P(xu + sx * KAM_ARA, y, T), Z_AXIS, 7.5, yon(0, 0, -1), 12.5, 24)
        end
        daire_it(e, P(xu, KAVELA_Y, T / 2), X_AXIS, KAVELA[:r], yon(sx, 0, 0), KAVELA[:tabla] + 1, 16)
      end
      boya(e, @mat[:govde])
      w = Geom::Vector3d.new(0, -0.45, 1).normalize
      uclar.each do |xu, sx, taraf|
        MF_Y.zip(%w[on arka]).each do |y, yer|
          o = [xu + sx * KAM_ARA, y, T]
          vida_koy(e, @kam, eksen(o, [0, 0, -1], [1, 0, 0]), P(*o), Geom::Vector3d.new(0, 0, -1), 14.0, 0.0, w,
                   "mf_#{t}_#{taraf}_#{yer}")
          next unless ust
          vida_koy(e, @mfkapak, eksen(o, [0, 0, -1], [1, 0, 0]), P(*o), Geom::Vector3d.new(0, 0, -1), 15.0, 1.5, w,
                   "mfkapak_#{taraf}_#{yer}")
        end
        o = [xu, KAVELA_Y, T / 2]
        vida_koy(e, @kavela, eksen(o, [sx, 0, 0], [0, 0, 1]), P(*o), Geom::Vector3d.new(sx, 0, 0), 25.0, 0.0,
                 Geom::Vector3d.new(-sx, 0, 0), "kavela_#{t}_#{taraf}")
      end
      [d, ORIJIN[k]]
    end

    def alt_tabla; tabla(:alt_tabla); end
    def ust_tabla; tabla(:ust_tabla); end

    # Üst arka şerit 662 x 200: raf pimlerine oturur, vidasız; baca tavana çıkıyorsa kesilir ya da takılmaz.
    def serit
      d = parca_tanimi(AD[:serit])
      kutu(d.entities, 0, 0, 0, IW - 2, D - ON_D, T)
      boya(d.entities, @mat[:govde])
      [d, ORIJIN[:serit]]
    end

    # Askı rayı 664 mm (duvarda, yanların arasında): sırt plakası + üstte U kanal; askı kancaları kanala oturur.
    def ray
      d = parca_tanimi(AD[:ray])
      e = d.entities
      z0 = RAY[:z0]
      z1 = RAY[:z1]
      kesit = [[8, z0], [10, z0], [10, z1], [8, z1], [8, z1 - 15], [3, z1 - 15], [3, z1], [1, z1], [1, z1 - 17],
               [8, z1 - 17]]
      it(e, kesit.map { |y, z| P(0, y, z) }, yon(1, 0, 0), IW)
      boya(e, @mat[:nikel])
      zv = (z0 + z1 - 17) / 2
      [60.0, IW / 2, IW - 60].each_with_index do |x, i|
        o = [x, 8, zv]
        vida_koy(e, @avida, eksen(o, [0, 1, 0], [0, 0, 1]), P(*o), Geom::Vector3d.new(0, 1, 0), 40.0, 3.0,
                 Geom::Vector3d.new(0.15, -1, 0.2).normalize, RAY_VIDALARI[i])
      end
      [d, ORIJIN[:ray]]
    end

    # Kapak: beyaz MDF tam bindirme; arkada 3 menteşe kabı + gövde (fabrikada takılı); altta ve üstte 8'er CNC yarık
    # (10 x 247, uçları R5, boydan boya; yarık iç kenarları bantsız doğal bej MDF). Kulp ve vidaları demonte.
    def kapak(k)
      h = KAPI[k]
      d = parca_tanimi(AD[k])
      e = d.entities
      gen = h[:gen]
      yuk = h[:z][1] - h[:z][0]
      kutu(e, 0, 0, 0, gen, T, yuk)
      hdler = h[:mentese].map { |hz| mentese_cerceve([h[:panel] - h[:x0], T, hz - h[:z][0]], h[:sx]) }
      hdler.each { |hd| daire_it(e, P(0, 0, KAP_ZC).transform(hd), Y_AXIS, 17.5, yon(0, -1, 0), 12.5, 32) }
      r = YARIK[:h] / 2
      x0, x1 = YARIK[:x]
      YARIK[:z].each do |zc|
        yay = ->(cx, a0) { (0..8).map { |i| a = (a0 + 22.5 * i).degrees; [cx + r * Math.cos(a), zc + r * Math.sin(a)] } }
        hat = yay.(x1 - r, -90) + yay.(x0 + r, 90)
        it(e, hat.map { |x, z| P(x, 0, z) }, yon(0, 1, 0), T)
      end
      boya(e, @mat[:mdf])
      e.grep(Sketchup::Face).each do |f| # yarık iç kenarları: doğal bej MDF
        next unless f.normal.y.abs < 0.01
        b = f.bounds
        next if b.min.x < 1.mm || b.max.x > (gen - 1).mm || b.min.z < 1.mm || b.max.z > (yuk - 1).mm
        f.material = @mat[:bej]
        f.back_material = @mat[:bej]
      end
      hdler.each_with_index do |hd, i|
        g = e.add_group
        g.name = 'Menteşe Gövdesi (büyük parça)'
        ge = g.entities
        ge.add_instance(@kap, hd)
        kol = ge.add_instance(@kol, hd)
        nitelik(kol, kol: true, lc: hd.to_a)
        a = P(0, -4, KAP_ZC - 7.5).transform(hd)
        b = P(0, 12, 14).transform(hd)
        bag = ge.add_instance(@bag, bar_tr(a, b))
        nitelik(bag, bar: true, a: a.to_a, b: b.to_a)
        lt = hd * eksen([0, 34, 8], [0, 0, -1], [1, 0, 0])
        zx = hd.zaxis
        w = Geom::Vector3d.new(zx.x * Math.cos(35.degrees), -Math.sin(35.degrees), zx.z * Math.cos(35.degrees))
        vida_koy(ge, @mvida, lt, P(0, 34, 8).transform(hd), Geom::Vector3d.new(0, 0, -1).transform(hd), 4.0, 2.3, w,
                 "mentese_#{k.to_s.sub('kapak_', '')}_#{i + 1}", true)
      end
      kx = h[:sx] > 0 ? gen - KULP[:kenar] : KULP[:kenar]
      kz = KULP[:z]
      delik = [-1, 1].map { |s| [kx, kz + s * KULP_ARA / 2] }
      kulp = "kulp_#{k}"
      vida_koy(e, @kulp, eksen([kx, 0, kz], [0, -1, 0], [1, 0, 0]), P(kx, 0, kz), Geom::Vector3d.new(0, 1, 0), 60.0, 0.0,
               Geom::Vector3d.new(0, -1, 0), kulp)
      delik.each_with_index do |(x, z), j|
        vida_koy(e, @kvida, eksen([x, T, z], [0, -1, 0], [0, 0, 1]), P(x, T, z), Geom::Vector3d.new(0, -1, 0), 25.0, 2.3,
                 Geom::Vector3d.new(0, 0.8, 0.6), "#{kulp}_vida_#{j + 1}")
      end
      [d, ORIJIN[k]]
    end

    def kapak_sol; kapak(:kapak_sol); end
    def kapak_sag; kapak(:kapak_sag); end


    def bar_tr(a, b)
      v = b - a
      x = v.normalize
      y = Geom::Vector3d.new(1, 0, 0)
      Geom::Transformation.axes(a, x, y, x * y) * Geom::Transformation.scaling(ORIGIN, v.length / 10.mm, 1, 1)
    end

    # ------------------------------------------------------------------
    # Model kurulumu
    # ------------------------------------------------------------------
    def kur(kayit_yolu = nil)
      @m = Sketchup.active_model
      @m.start_operation('Kora kombi kabini kurulum modeli', true)
      @m.entities.clear!
      @m.pages.to_a.each { |p| @m.pages.erase(p) }
      @m.definitions.purge_unused
      @m.materials.purge_unused
      @m.layers.purge_unused
      malzemeler

      @vida16 = vida_tanimi('Sunta Vidası 3.5x16', 3.8, 2.5, 1.75, 16)
      @vida16h = havsa_vida_tanimi
      @tvida = vida_tanimi('Taban Vidası M4', 3.5, 2.2, 2, 9)
      @mvida = vida_tanimi('Menteşe Sabitleme Vidası', 3.8, 2.3, 2, 4)
      @kvida = vida_tanimi('Kulp Vidası M4x25', 3.8, 2.3, 2, 25)
      @avida = vida_tanimi('Vida 5x60 + Dübel', 4.6, 3.0, 2.5, 60)
      @ayvida = vida_tanimi('Askı Ayar Vidası', 3.2, 2.0, 2.0, 10)
      @kam = kam_tanimi
      @bulon = bulon36_tanimi
      @kavela = kavela_tanimi
      @mfkapak = mfkapak_tanimi
      @pim = pim_tanimi
      @taban = taban_tanimi
      @kol = kol_tanimi
      @kap = kap_tanimi
      @bag = bag_tanimi
      @kose = kose_tanimi
      @kulp = kulp_tanimi
      arac = tornavida_tanimi
      kisa = kisa_tornavida_tanimi
      cekic = cekic_tanimi

      tags = SIRA.map { |k| [k, @m.layers.add(ETIKET[k])] }.to_h
      liste_tag = @m.layers.add(LISTE_TAG)
      arac_tag = @m.layers.add(ARAC_TAG)
      ek_tag = [DUVAR_TAG, KOMBI_TAG, OLCU_TAG].to_h { |t| [t, @m.layers.add(t)] }

      SIRA.each do |k|
        d, o = send(k)
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
      [[duvar_tanimi, DUVAR_TAG], [kombi_tanimi, KOMBI_TAG], [olcu_tanimi, OLCU_TAG]].each do |d, t|
        @m.entities.add_instance(d, Geom::Transformation.new).layer = ek_tag[t]
      end

      parca_listesi(liste_tag)
      stil
      bagla
      son_durum
      sahneler
      ek_tag[OLCU_TAG].visible = false
      @m.commit_operation
      @m.save(kayit_yolu) if kayit_yolu
      "Kuruldu: #{SIRA.size} parça, #{@vidalar.size} animasyonlu vida/eksantrik/kavela/pim, #{@m.pages.size} sahne"
    end

    # Kutu içeriği: paneller yere yatırılmış, fabrikada takılı hırdavat görünür; ayrı gelen küçük parçalar altta.
    def parca_listesi(tag)
      rx = ->(a) { Geom::Transformation.rotation(ORIGIN, X_AXIS, a.degrees) }
      ry = ->(a) { Geom::Transformation.rotation(ORIGIN, Y_AXIS, a.degrees) }
      rz = ->(a) { Geom::Transformation.rotation(ORIGIN, Z_AXIS, a.degrees) }
      bir = Geom::Transformation.new
      yerlesim = {
        sol_yan: [rz.(90) * ry.(-90), 1300, 0], sag_yan: [rz.(90) * ry.(90), 1850, 0],
        kapak_sol: [rx.(-90), 2400, 0], kapak_sag: [rx.(-90), 2900, 0],
        alt_tabla: [bir, 3450, 0], ust_tabla: [bir, 3450, 400], serit: [bir, 3450, 800], ray: [rx.(-90), 3450, 1200]
      }
      @m.entities.grep(Sketchup::ComponentInstance).each do |ana|
        k = nit(ana, :parca)&.to_sym
        next unless yerlesim.key?(k)
        rot, x, y = yerlesim[k]
        b = Geom::BoundingBox.new # demonte parçalar yerleşime katılmasın
        ana.definition.entities.each { |g| b.add(g.bounds) unless g.is_a?(Sketchup::ComponentInstance) && DEMONTE.include?(nit(g, :vida)) }
        bb = Geom::BoundingBox.new
        8.times { |c| bb.add(b.corner(c).transform(rot)) }
        kay = Geom::Transformation.translation(P(x, y, 0) - bb.min)
        i = @m.entities.add_instance(ana.definition, kay * rot)
        i.layer = tag
        nitelik(i, liste: k.to_s)
        on = Geom::Point3d.new(bb.center.x, bb.min.y, bb.max.z).transform(kay)
        @m.entities.add_text(AD[k], on, Geom::Vector3d.new(0, -110.mm, 0)).layer = tag
      end
      ek = lambda do |defn, adet, x, y, dx, ad, eks, anahtar|
        adet.times do |i|
          ins = @m.entities.add_instance(defn, eksen([x + i * dx, y, eks[2]], eks[0], eks[1]))
          ins.layer = tag
          nitelik(ins, liste: anahtar)
        end
        @m.entities.add_text(ad, P(x, y - 150, 0), Geom::Vector3d.new(0, -110.mm, 0)).layer = tag
      end
      ek.(@kam, 8, 1250, -500, 30, 'Minifiks Gövdesi (8)', [[0, 0, -1], [1, 0, 0], 12], 'kam')
      ek.(@kavela, 4, 1850, -500, 40, 'Kavela Ø8x30 (4)', [[0, 1, 0], [0, 0, 1], 4], 'kavela')
      ek.(@mfkapak, 4, 2450, -500, 35, 'Minifiks Kapağı (4)', [[0, 0, -1], [1, 0, 0], 1.5], 'mfkapak')
      ek.(@pim, 4, 3050, -500, 35, 'Raf Pimi Ø5 (4)', [[0, 1, 0], [0, 0, 1], 3], 'pim')
      ek.(@kose, 2, 3650, -500, 90, 'L Köşebent 40x40 (2)', [[1, 0, 0], [0, 0, 1], 0], 'kose')
      ek.(@kulp, 2, 1250, -950, 70, 'Kulp 128 (2)', [[0, 0, 1], [1, 0, 0], 6], 'kulp')
      ek.(@kvida, 4, 1850, -950, 35, 'Kulp Vidası (4)', [[0, 1, 0], [0, 0, 1], 4], 'kulp_vidasi')
      ek.(@vida16, 2, 2450, -950, 35, 'Köşebent Vidası (2)', [[0, 1, 0], [0, 0, 1], 4], 'kose_vidasi')
      ek.(@avida, 5, 3050, -950, 45, 'Vida + Dübel (5)', [[0, 1, 0], [0, 0, 1], 5], 'duvar_vidasi')
      @m.entities.add_text('Delme şablonu (1:1) ve kombi ayrı', P(3650, -880, 0), Geom::Vector3d.new(0, 0, 0)).layer = tag
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
      tanim = [
        ['0 Kutu İçeriği', [], :liste, 'Paneller ve fabrikada takılı bağlantılar; minifiks gövdeleri, kavelalar, kapaklar, pimler, ray, köşebentler, kulplar ve vidalar ayrı.'],
        ['1 Kavelalar', %i[alt_tabla ust_tabla], 1, 'Kavelaları alt tablanın ve üst ön tablanın uçlarındaki deliklere takın.'],
        ['2 Sol Yan', %i[sol_yan], 2, 'Sol yanı iki tablanın uçlarına geçirin: bulonlar ve kavelalar deliklere girer.'],
        ['3 Sol Minifiksler', [], 3, 'Sol taraftaki 4 minifiks gövdesini yerleştirip yarım tur çevirin.'],
        ['4 Sağ Yan', %i[sag_yan], 4, 'Sağ yanı iki tablaya geçirin; sağdaki 4 minifiks gövdesini çevirin.'],
        ['5 Minifiks Kapakları', [], 5, 'Üst ön tabladaki 4 minifiks gövdesinin üstüne beyaz kapaklarını bastırın.'],
        ['6 Askı Rayı', %i[ray], 6, 'Şablonla kabinin altını kombinin altının 25 cm aşağısına işaretleyin; rayı 3 vida ve dübelle duvara vidalayın.'],
        ['7 Kabini Asma', [], 7, 'Kabini kombinin önünden geçirip askılarla raya asın; askı vidalarıyla ayarlayın.'],
        ['8 L Köşebentler', [], 8, 'Alt-arka köşelerdeki iki L köşebenti yanlara ve duvara vidalayın.'],
        ['9 Arka Şerit', %i[serit], 9, 'Raf pimlerini takın, üst arka şeridi pimlere oturtun (baca yukarı çıkıyorsa kesin ya da takmayın).'],
        ['10 Kapaklar', %i[kapak_sol kapak_sag], :kapak, 'Kapakları menteşe tabanlarına geçirin, 6 menteşe vidasını sıkın.'],
        ['11 Kulplar', [], 10, 'Kulpları önden takıp vidalarını kapağın arkasından sıkın.'],
        ['12 Bitmiş Ürün', [], :bitti, 'Kurulum tamamlandı.']
      ]
      acik = []
      tanim.each_with_index do |(ad, yeni, kam, aciklama), n|
        acik += yeni
        liste = kam == :liste
        @m.layers.each do |l|
          k = ETIKET.key(l.name)
          l.visible = if l.name == LISTE_TAG then liste
                      elsif [DUVAR_TAG, KOMBI_TAG].include?(l.name) then n >= 6
                      elsif [ARAC_TAG, OLCU_TAG].include?(l.name) then false
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
      raise 'Model bulunamadı — önce OzcanKurulum::KoraKombiKabini.kur' unless @parca.size == SIRA.size && @arac && @kisa_arac && @cekic
      @vidalar = []
      @kollar = []
      @barlar = []
      @parca.each do |k, ana|
        ana.definition.entities.each do |x|
          if x.is_a?(Sketchup::ComponentInstance) && nit(x, :vida)
            @vidalar << vida_kaydi(x, k, nil)
          elsif x.is_a?(Sketchup::Group)
            x.entities.grep(Sketchup::ComponentInstance).each do |y|
              if nit(y, :vida) then @vidalar << vida_kaydi(y, k, x)
              elsif nit(y, :kol) then @kollar << { inst: y, parca: k, lc: Geom::Transformation.new(nit(y, :lc)) }
              elsif nit(y, :bar)
                @barlar << { inst: y, parca: k, a: Geom::Point3d.new(*nit(y, :a)), b: Geom::Point3d.new(*nit(y, :b)) }
              end
            end
          end
        end
      end
      # Aynı tanımı paylaşan parçalar olursa vidaları tek kez sayılsın
      @vidalar.uniq! { |v| v[:inst] }
      @liste_tag = @m.layers[LISTE_TAG]
      @arac_tag = @m.layers[ARAC_TAG]
      @duvar_tag = @m.layers[DUVAR_TAG]
      @ek_tag0 = @m.layers[KOMBI_TAG]
      cizelge
      true
    end

    def vida_kaydi(i, parca, grup)
      { id: nit(i, :vida), inst: i, parca: parca, grup: grup,
        lt: Geom::Transformation.new(nit(i, :lt)), p: Geom::Point3d.new(*nit(i, :p)),
        d: Geom::Vector3d.new(*nit(i, :d)), strok: nit(i, :strok), bas_h: nit(i, :bas_h),
        w: Geom::Vector3d.new(*nit(i, :w)), kapi: nit(i, :kapi), kisa: nit(i, :kisa) }
    end

    # aci > 0 açık: sol kapak sol ön dış köşesindeki, sağ kapak sağ ön dış köşesindeki dikey eksende açılır.
    def kapi_R(k, aci)
      h = KAPI[k]
      Geom::Transformation.rotation(P(h[:eksen], h[:py], 0), Z_AXIS, h[:yon] * aci.degrees)
    end

    def acik_aci(_k)
      105.0
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

    # Birkaç parçayı birlikte taşır (asma adımında gövdenin tamamı).
    def toplu(ks, a, b, sure)
      @cz.olay(sure) { |s, u| ks.each { |k| s[:p][k] = { vis: true, off: lerp3(a, b, u) } } }
    end

    # Demonte parçayı tornavida gelmeden önce gevşek konumda gösterir.
    def goster(ids)
      @cz.an { |s, _| ids.each { |id| s[:v][id] = { adv: 1.0, ang: 0.0 } } }
    end

    # Elle takılan parçalar (kavela, minifiks kapağı, raf pimi, köşebent): görünür olur, yerine itilir; alet yok.
    def elle_tak(ids, sure = 0.9)
      goster(ids)
      @cz.bekle(0.3)
      @cz.olay(sure) { |s, u| ids.each { |id| s[:v][id] = { adv: 1 - u, ang: 0.0 } } }
    end

    # Kapaklar açık (90°) gelir, menteşe gövdeleri tabanlara geçer, vidalar sıkılır; kapaklar açık kalır.
    def kapaklari_tak
      z = @cz
      z.kamera(1.2, KAM[:kapak])
      z.an { |s, _| KAPILAR.each { |k| s[:kapi][k] = 90.0 } }
      KAPILAR.each do |k|
        hareket(k, KAPAK_DIS, [0, 0, 0], 1.6)
        no = k.to_s.sub('kapak_', '')
        sirayla_sik((1..3).map { |i| "mentese_#{no}_#{i}" }, KAM[:kapak], tur: 3)
        z.kamera(0.6, KAM[:kapak])
      end
    end

    # Kulp önden oturur; iki vidası kapağın arkasından (kapak açıkken) gelip sıkılır.
    def kulp_tak(id, yakin)
      z = @cz
      z.olay(0.8) { |s, u| s[:v][id] = { adv: 3.0 * (1 - u), ang: 0.0 } }
      [1, 2].each do |j|
        v = "#{id}_vida_#{j}"
        z.olay(0.4) { |s, u| s[:v][v] = { adv: 4.0 - 3.0 * u, ang: 0.0 } }
        vida_sik(v, nil, tur: 4, sure: 0.8, yakin: yakin && j == 1, bak: [0.6, 0.8, 0.5])
      end
    end

    def cizelge
      @cz = z = Cizelge.new
      z.an { |s, _| DEMONTE.each { |id| s[:v][id] = { gizli: true } } } # takılana kadar görünmesin
      z.baslik('Kutu içeriği — bulon, askı ve menteşeler takılı; minifiks, kavela, pim, ray, köşebent, kulp ve vidalar ayrı')
      z.kamera(0, KAM[:liste])
      z.bekle(3.5)

      z.baslik('1 · Kavelaları alt tablanın ve üst ön tablanın uçlarındaki deliklere takın')
      z.an do |s, _|
        s[:liste] = false
        %i[alt_tabla ust_tabla].each { |k| s[:p][k] = { vis: true, off: [0, 0, 0] } }
      end
      z.kamera(1.2, KAM[1])
      elle_tak(KAVELALAR.first(2))
      z.kamera(1.0, KAM['1b'])
      elle_tak(KAVELALAR.last(2))
      z.bekle(0.3)

      z.baslik('2 · Sol yanı iki tablanın uçlarına geçirin: bulonlar ve kavelalar deliklere girer')
      z.kamera(1.2, KAM[2])
      hareket(:sol_yan, [-350, 0, 0], [-2, 0, 0], 2.0)
      z.bekle(0.4)

      z.baslik('3 · Sol taraftaki dört minifiks gövdesini yuvasına koyup yarım tur çevirin')
      z.kamera(1.0, KAM[3])
      ids = KAMLAR['sol']
      goster(ids)
      z.bekle(0.3)
      sirayla_sik(ids, KAM[3], cekler: cek_listesi(:sol_yan, [-2, 0, 0], ids.size), tur: 0.5, bak: [0.35, -1, 0.9])
      z.kamera(0.8, KAM[3])
      z.bekle(0.3)

      z.baslik('4 · Sağ yanı iki tablaya geçirin; sağdaki dört minifiks gövdesini yarım tur çevirin')
      z.kamera(1.2, KAM[4])
      hareket(:sag_yan, [350, 0, 0], [2, 0, 0], 2.0)
      ids = KAMLAR['sag']
      goster(ids)
      z.bekle(0.3)
      sirayla_sik(ids, KAM[4], cekler: cek_listesi(:sag_yan, [2, 0, 0], ids.size), tur: 0.5, bak: [-0.35, -1, 0.9])
      z.kamera(0.8, KAM[4])
      z.bekle(0.3)

      z.baslik('5 · Üst ön tabladaki dört minifiks gövdesinin üstüne beyaz kapaklarını bastırın')
      z.kamera(1.2, KAM[5])
      elle_tak(KAPAKCIKLAR, 1.0)
      z.bekle(0.4)

      z.baslik('6 · Şablonla işaretleyin (kabinin altı = kombinin altı − 25 cm); askı rayını duvara vidalayın')
      z.an { |s, _| s[:duvar] = true }
      z.kamera(1.2, KAM[6])
      toplu(TASINAN, [0, 0, 0], DIS, 1.4)
      hareket(:ray, [0, -300, 0], [0, 0, 0], 1.4)
      goster(RAY_VIDALARI)
      z.bekle(0.3)
      sirayla_sik(RAY_VIDALARI, KAM[6], tur: 4, bak: [0.3, -1, 0.3])
      z.kamera(0.8, KAM[6])
      z.bekle(0.3)

      z.baslik('7 · Kabini kombinin önünden geçirip askılarla raya asın; askı vidalarıyla ayarlayın')
      z.kamera(1.2, KAM[7])
      toplu(TASINAN, DIS, [0, -480, 45], 1.8)
      toplu(TASINAN, [0, -480, 45], [0, 0, 45], 1.6)
      toplu(TASINAN, [0, 0, 45], [0, 0, 0], 0.8)
      z.bekle(0.3)
      sirayla_sik(ASKI_VIDALARI, KAM[7], tur: 2, bak: [0.35, -1, -0.45])
      z.kamera(0.8, KAM[7])
      z.bekle(0.3)

      z.baslik('8 · Alt-arka köşelerdeki iki L köşebenti yanlara ve duvara vidalayın')
      z.kamera(1.2, KAM[8])
      elle_tak(KOSELER)
      goster(KOSE_VIDALARI)
      z.bekle(0.3)
      sirayla_sik(KOSE_VIDALARI, KAM[8], tur: 4, bak: [0.4, -1, 0.5])
      z.kamera(0.8, KAM[8])
      z.bekle(0.3)

      z.baslik('9 · Raf pimlerini takın, arka şeridi oturtun (baca yukarı çıkıyorsa kesin ya da takmayın)')
      z.kamera(1.2, KAM[9])
      elle_tak(PIMLER)
      hareket(:serit, [0, 0, -260], [0, 0, 0], 1.6)
      z.bekle(0.4)

      z.baslik('10 · Kapakları menteşe tabanlarına geçirin; altı menteşe vidasını sıkın')
      kapaklari_tak
      z.bekle(0.3)

      z.baslik('11 · Kulpları önden takın; vidalarını kapağın arkasından sıkın, kapakları kapatın')
      z.kamera(1.2, KAM[10])
      KAPILAR.each_with_index { |k, i| kulp_tak("kulp_#{k}", i.zero?) }
      z.kamera(0.8, KAM[10])
      z.olay(1.4) { |s, u| KAPILAR.each { |k| s[:kapi][k] = 90.0 * (1 - u) } }
      z.kamera(1.0, KAM[:bitti])
      z.bekle(0.3)

      z.baslik('Kurulum tamamlandı')
      z.kamera(1.6, KAM[:bitti])
      z.olay(1.3) { |s, u| KAPILAR.each { |k| s[:kapi][k] = 100.0 * u } }
      z.bekle(1.0)
      z.olay(1.3) { |s, u| KAPILAR.each { |k| s[:kapi][k] = 100.0 * (1 - u) } }
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
        kapi: KAPILAR.map { |k| [k, 0.0] }.to_h,
        duvar: false,
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
      @duvar_tag.visible = s[:duvar] if @duvar_tag.visible? != s[:duvar]
      @ek_tag0.visible = s[:duvar] if @ek_tag0.visible? != s[:duvar]
      rinv = KAPILAR.map do |k|
        c = @taban_tr[k]
        [k, c.inverse * kapi_R(k, s[:kapi][k]).inverse * c]
      end.to_h
      SIRA.each do |k|
        st = s[:p][k]
        t = tr(*(st[:vis] ? st[:off] : UZAK))
        t *= kapi_R(k, s[:kapi][k]) if KAPILAR.include?(k)
        @parca[k].move!(t * @taban_tr[k])
      end
      @kollar.each { |x| x[:inst].move!(rinv[x[:parca]] * x[:lc]) }
      @barlar.each { |x| x[:inst].move!(bar_tr(x[:a], x[:b].transform(rinv[x[:parca]]))) }
      @vidalar.each do |v|
        st = s[:v][v[:id]]
        next v[:inst].move!(tr(*UZAK) * v[:lt]) if st[:gizli] # demonte parça: görüş dışında
        m = vida_tr(v, st[:adv], st[:ang])
        m = rinv[v[:parca]] * m if v[:kapi]
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

    # Montajlı son durum: tüm parçalar yerinde, vidalar ve demonte parçalar takılı, kapaklar kapalı.
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
    # Adımlar başlıkların sırasıdır: 0 kutu içeriği, 1-11 montaj, 12 bitmiş ürün.
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
