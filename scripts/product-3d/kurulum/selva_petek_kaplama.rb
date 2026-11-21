# encoding: UTF-8
# Selva Petek Kaplama 100 (100 x 24 x 85 cm) — model ve kurulum kılavuzu.
# Tarif: research_notes/Urun firsatlari 2026-11-21/tarif-B-selva-petek-kaplama.txt (21.11.2026).
# Kalorifer peteğinin önüne konan, üstü dresuar olan kaplama: beyaz gövde, Safir Meşe üst tabla, beyaz MDF ön panelde
# CNC "çıta" yarıkları (yarık kenarları bantsız doğal bej MDF). Ön panel altta 2 raf pimine oturur, 4 mıknatısla
# tutulur, üstteki parmak oyuğundan çekilince çıkar (petek temizliği, purjör, vana). Yanların arka-alt köşesinde
# süpürgelik kesiği; arka kuşaktan duvara 2 vida. Selva 80 / 120 yalnız genişlik farkı (G, kuşak, panel, yarık sayısı).
#
# Üst tabla yanların üstünde, minifiks + kavelayla: bulonlar tablanın alt yüzünde (fabrikada takılı), eksantrik
# gövdeleri yanların iç yüzünde tablanın 36 mm altında (dresuar yüzü temiz kalır). Arka kuşak şeffaf açılı
# çektirmelerle yanlara (2) ve tablaya (3).
#   1 kavelalar  2 sol yan  3 sağ yan  4 arka kuşak  5 keçeler  6 duvara sabitleme  7 raf pimleri + ön panel
#
# SketchUp > Pencere > Ruby Konsolu:
#   load 'C:/.../scripts/product-3d/kurulum/selva_petek_kaplama.rb'
#   OzcanKurulum::SelvaPetekKaplama.kur          # AÇIK MODELİ TEMİZLER, modeli sıfırdan kurar
#   OzcanKurulum::SelvaPetekKaplama.oynat        # montaj animasyonunu ekranda oynatır
#   OzcanKurulum::SelvaPetekKaplama.kumanda      # klavyeyle adım adım: → ← Enter, K serbest kamera, Esc
#   (konsoldan: sonraki, onceki, durdur, devam, adim(3), git(3), bitir)
#   OzcanKurulum::SelvaPetekKaplama.kaydet('C:/kareler') # animasyonu PNG karelere yazar
#
# Koordinatlar mm: X genişlik (0 = sol dış yüz), Y derinlik (0 = yanların ön kenarı, +Y duvara; duvar Y=220,
# tabla önde Y=-20'ye taşar), Z yükseklik (0 = zemin).

module OzcanKurulum
  module SelvaPetekKaplama
    extend self

    # ------------------------------------------------------------------
    # Ölçüler (mm)
    # ------------------------------------------------------------------
    W = 1000.0           # genişlik (Selva 100)
    T = 18.0             # panel kalınlığı
    D = 220.0            # yan derinliği (duvara kadar)
    TABLA_ON = 20.0      # üst tabla önde taşar → toplam derinlik 240
    ZY = 832.0           # yanların üst kenarı = tablanın alt yüzü
    H = ZY + T           # 850
    IW = W - 2 * T       # iç genişlik 964
    SUPURGE = [20.0, 100.0].freeze # süpürgelik kesiği (derinlik, yükseklik)
    KUSAK = { y: D - T, z: [ZY - 60, ZY] }.freeze # arka kuşak 964 x 60, duvar tarafında dik
    PANEL = { x: [T + 1, W - T - 1], z: [40.0, ZY - 2] }.freeze # ön panel 962 x 790 MDF, sökülür
    YARIK = { gen: 18.0, z: [70.0, 720.0], x0: 52.0, adim: 40.0 }.freeze # panel-yerel
    OYUK = { gen: 100.0, der: 30.0 }.freeze # parmak oyuğu (panelin üst kenarı ortası)
    # Minifiks (tabla → yan): bulon tablanın altında, eksantrik yanın iç yüzünde tablanın 36 mm altında; kavela ortada
    MF_Y = [36.0, D - 36].freeze
    KAM_ARA = 36.0
    KAVELA_Y = 110.0
    KAVELA = { r: 4.0, tabla: 12.0, yan: 18.0 }.freeze # Ø8 x 30: 12 mm tablada, 18 mm yanın üst ucunda
    CEK_X = [200.0, 500.0, 800.0].freeze # kuşak → tabla çektirmeleri
    CEK_Z = 802.0                        # kuşak → yan çektirmeleri
    PIM_Z = PANEL[:z][0] - 2.5           # panelin oturduğu raf pimleri (yanların iç yüzünde)
    PIM_Y = T / 2
    MIKNATIS_Z = [200.0, 700.0].freeze
    DUVAR_VIDA_X = [150.0, W - 150].freeze
    KECE_Y = [30.0, 170.0].freeze
    PETEK = { gen: 800.0, h: 600.0, der: 100.0, z0: 120.0, y0: D - 50 - 100 }.freeze # yer tutucu PKKP 600 x 800
    PLAKA_T = 3.0

    DIKEY_FOV = 30.0
    VIDEO_FOV = 50.0

    DICT = 'ozcan_kurulum'
    KAPI = {}.freeze
    KAPILAR = [].freeze
    GOVDE = %i[ust_tabla sol_yan sag_yan kusak].freeze
    SIRA = (GOVDE + %i[on_panel]).freeze
    TASINAN = GOVDE
    AD = {
      ust_tabla: 'Üst Tabla (Safir Meşe)', sol_yan: 'Sol Yan', sag_yan: 'Sağ Yan', kusak: 'Arka Kuşak',
      on_panel: 'Ön Panel (CNC çıta, sökülür)'
    }.freeze
    ETIKET = {
      ust_tabla: '01 Üst Tabla', sol_yan: '02 Yanlar', sag_yan: '02 Yanlar', kusak: '03 Arka Kuşak',
      on_panel: '04 Ön Panel'
    }.freeze
    LISTE_TAG = '00 Parça Listesi'
    ARAC_TAG = '99 Tornavida'
    DUVAR_TAG = 'Duvar ve Zemin'
    PETEK_TAG = 'Petek (yer tutucu)'
    DEKOR_TAG = 'Dekor (saksı, kitap, tepsi)'
    OLCU_TAG = 'Ölçüler'

    # Kamera noktaları [göz, hedef] (mm)
    KAM = {
      liste:   [[2950, -2300, 5000], [2950, 200, 0]],
      1 =>     [[1300, -1500, 1500], [500, 100, 820]],
      2 =>     [[-1500, -2300, 1600], [500, 100, 450]],
      3 =>     [[2500, -2300, 1600], [500, 100, 450]],
      4 =>     [[1800, 1900, 1500], [500, 150, 650]],
      5 =>     [[1500, -1500, 250], [500, 110, 0]],
      6 =>     [[2200, -2700, 1500], [500, 0, 450]],
      7 =>     [[1700, -2400, 1250], [500, 0, 430]],
      bitti:   [[1900, -2700, 1450], [500, 50, 430]]
    }.freeze
    # Tanıtım görselleri (4:5): ad, ön panel ofseti, açık katmanlar, [göz, hedef]
    TANITIM = [
      ['1_salonda', nil, %i[duvar dekor], [[1500, -2500, 1300], [500, 60, 700]]],
      ['2_on_panel_cikiyor', [0, -230, 40], %i[duvar petek], [[1700, -2100, 1250], [470, 0, 480]]],
      ['3_cita_yariklar_ve_mese_tabla', nil, %i[duvar], [[1150, -900, 1050], [650, 0, 650]]],
      ['4_supurgelik_kesigi', nil, %i[duvar], [[2000, -800, 750], [930, 170, 200]]],
      ['5_olculer', nil, %i[duvar olcu], [[1900, -2900, 1250], [500, 60, 470]]]
    ].freeze

    # Parçaların yerleşim orijini (bileşen orijini = parçanın min köşesi)
    ORIJIN = {
      ust_tabla: [0, -TABLA_ON, ZY], sol_yan: [0, 0, 0], sag_yan: [W - T, 0, 0], kusak: [T, KUSAK[:y], KUSAK[:z][0]],
      on_panel: [PANEL[:x][0], 0, PANEL[:z][0]]
    }.freeze

    KAVELALAR = %w[sol sag].map { |y| "kavela_#{y}" }.freeze
    KAMLAR = %w[sol sag].to_h { |y| [y, %w[on arka].map { |o| "mf_#{y}_#{o}" }] }.freeze
    PIMLER = %w[sol sag].map { |y| "pim_#{y}" }.freeze
    KECELER = %w[sol sag].flat_map { |y| %w[on arka].map { |o| "kece_#{y}_#{o}" } }.freeze
    DUVAR_VIDALARI = %w[sol sag].map { |y| "duvar_vida_#{y}" }.freeze
    CEKTIRME_IDLERI = (%w[kusak_sol kusak_sag] + CEK_X.each_index.map { |i| "kusak_tabla_#{i + 1}" }).freeze
    DEMONTE = (KAVELALAR + KAMLAR.values.flatten + PIMLER + KECELER + DUVAR_VIDALARI).freeze

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
        mese: mk.('Safir Meşe (A495)', [196, 156, 110]),
        mdf: mk.('Beyaz MDF Lam', [248, 248, 246]),
        bej: mk.('MDF Çekirdek (doğal bej)', [222, 200, 164]),
        miknatis: mk.('Mıknatıs Gövdesi (beyaz plastik)', [232, 232, 230]),
        kece: mk.('Keçe', [120, 112, 104]),
        kavela: mk.('Kavela (kayın)', [214, 182, 140]),
        petek: mk.('Petek (yer tutucu)', [238, 240, 242]),
        duvar: mk.('Duvar (beyaz)', [236, 234, 230]),
        supurge: mk.('Süpürgelik', [250, 250, 248]),
        zemin: mk.('Ahşap Zemin', [214, 180, 140]),
        cam: mk.('Pencere Camı', [196, 220, 236], 0.55),
        saksi: mk.('Saksı (seramik)', [210, 196, 176]),
        yesil: mk.('Bitki', [96, 128, 88]),
        kitap: mk.('Kitap', [70, 96, 120]),
        kitap2: mk.('Kitap 2', [176, 120, 80]),
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

    # Minifiks bulonu (36 mm eksantrik mesafesi): dişli kısmı tablada (x<0), başlı şaftı yerel +x yönünde yana girer.
    def bulon36_tanimi
      d = @m.definitions.add('Minifiks Bulonu (36)')
      torna(d.entities, [[-8, 0], [-8, 2.5], [0, 2.5], [0, 3.5], [2, 3.5], [2, 2.5], [30, 2.5], [31, 4], [35, 4],
                         [36, 2], [36, 0]], 16, @mat[:cinko])
      d
    end

    # Kavela Ø8 x 30: yerel +x tablanın alt yüzüne giriş yönü; x∈[0, 12] tablada, x∈[-18, 0] yanın üst ucuna girer.
    def kavela_tanimi
      d = @m.definitions.add('Kavela Ø8x30')
      torna(d.entities, [[-18, 0], [-18, 3.2], [-17, 4], [11, 4], [12, 3.2], [12, 0]], 16, @mat[:kavela])
      d
    end

    # Keçe Ø20 x 3: yerel +x yukarı (yanın alt kenarına yapışır).
    def kece_tanimi
      d = @m.definitions.add('Keçe Ø20')
      torna(d.entities, [[-3, 0], [-3, 10], [0, 10], [0, 0]], 20, @mat[:kece])
      d
    end

    # Mıknatıslı kapak tutucu (fabrikada takılı): yanın iç yüzünde, panelin hemen arkasında; ön yüzünde mıknatıs.
    def miknatis(e, xi, sx, z)
      g = e.add_group
      g.name = 'Mıknatıslı Tutucu'
      x0, x1 = [xi, xi + sx * 20].minmax
      kutu(g.entities, x0, T, z - 22, x1, T + 22, z + 22)
      boya(g.entities, @mat[:miknatis])
      m = e.add_group
      kutu(m.entities, [xi + sx * 5, xi + sx * 15].min, T - 0.01, z - 6, [xi + sx * 5, xi + sx * 15].max, T + 1, z + 6)
      boya(m.entities, @mat[:celik])
    end

    # --- Duvar, süpürgelik, pencere ve zemin (sabitleme adımında ve tanıtımda) ---
    def duvar_tanimi
      d = @m.definitions.add('Duvar ve Zemin')
      e = d.entities
      g = e.add_group
      kutu(g.entities, -2600, D, 0, 3600, D + 20, 3000)
      boya(g.entities, @mat[:duvar])
      s = e.add_group # süpürgelik: kaplamanın yanlarındaki kesik buna oturur
      kutu(s.entities, -2600, D - SUPURGE[0], 0, 3600, D, SUPURGE[1] - 2)
      boya(s.entities, @mat[:supurge])
      p = e.add_group # pencere (kaplamanın üstünde)
      kutu(p.entities, W / 2 - 650, D - 30, 1000, W / 2 + 650, D, 1060)
      kutu(p.entities, W / 2 - 650, D - 30, 2200, W / 2 + 650, D, 2260)
      kutu(p.entities, W / 2 - 650, D - 30, 1060, W / 2 - 590, D, 2200)
      kutu(p.entities, W / 2 + 590, D - 30, 1060, W / 2 + 650, D, 2200)
      kutu(p.entities, W / 2 - 30, D - 30, 1060, W / 2 + 30, D, 2200)
      boya(p.entities, @mat[:supurge])
      c = e.add_group
      kutu(c.entities, W / 2 - 590, D - 12, 1060, W / 2 + 590, D - 8, 2200)
      boya(c.entities, @mat[:cam])
      z = e.add_group
      kutu(z.entities, -2600, -4000, -12, 3600, D, 0)
      boya(z.entities, @mat[:zemin])
      (-2600..3600).step(180).drop(1).each { |x| z.entities.add_line(P(x, -4000, 0), P(x, D, 0)) } # parke derzleri
      d
    end

    # --- Yer tutucu petek (ürünle gelmez): PKKP 600 x 800, iki uçta vana, sağ üstte purjör ---
    def petek_tanimi
      d = @m.definitions.add('Petek (yer tutucu)')
      e = d.entities
      k = PETEK
      x0 = (W - k[:gen]) / 2
      g = e.add_group
      kutu(g.entities, x0, k[:y0], k[:z0], x0 + k[:gen], k[:y0] + k[:der], k[:z0] + k[:h])
      boya(g.entities, @mat[:petek])
      c = e.add_group # dikey kanal çizgileri
      (1..15).each { |i| kutu(c.entities, x0 + i * 50 - 2, k[:y0] - 1, k[:z0] + 20, x0 + i * 50 + 2, k[:y0], k[:z0] + k[:h] - 20) }
      boya(c.entities, @mat[:nikel])
      [[x0 - 70, x0], [x0 + k[:gen], x0 + k[:gen] + 40]].each do |a, b| # vanalar
        torna(e, [[0, 0], [0, 12], [b - a, 12], [b - a, 0]], 16, @mat[:nikel])
          .transform!(eksen([a, k[:y0] + 50, k[:z0] + 30], [1, 0, 0], [0, 0, 1]))
      end
      torna(e, [[0, 0], [0, 26], [80, 26], [80, 0]], 20, @mat[:petek]) # termostatik vana kafası (solda)
        .transform!(eksen([x0 - 50, k[:y0] + 50, k[:z0] + 30], [0, 0, 1], [1, 0, 0]))
      torna(e, [[0, 0], [0, 6], [25, 6], [25, 0]], 12, @mat[:nikel]) # purjör (sağ üst)
        .transform!(eksen([x0 + k[:gen], k[:y0] + 50, k[:z0] + k[:h] - 30], [1, 0, 0], [0, 0, 1]))
      d
    end

    # --- Tanıtım dekoru: tablada saksıda bitki, iki kitap ve küçük tepsi ---
    def dekor_tanimi
      d = @m.definitions.add('Dekor (saksı, kitap, tepsi)')
      e = d.entities
      zu = H
      torna(e, [[0, 0], [0, 62], [140, 75], [150, 75], [150, 0]], 28, @mat[:saksi]).transform!(eksen([180, 100, zu], [0, 0, 1], [1, 0, 0]))
      [[180, 100, 230, 90], [140, 70, 280, 70], [225, 130, 300, 65], [160, 140, 330, 55]].each do |x, y, z, r|
        torna(e, (0..8).map { |i| a = Math::PI * i / 8; [r * -Math.cos(a), r * Math.sin(a)] }, 16, @mat[:yesil])
          .transform!(eksen([x, y, zu + z], [0, 0, 1], [1, 0, 0]))
      end
      k = e.add_group
      kutu(k.entities, 560, 20, zu, 790, 190, zu + 32)
      boya(k.entities, @mat[:kitap])
      k2 = e.add_group
      kutu(k2.entities, 575, 35, zu + 32, 775, 175, zu + 58)
      boya(k2.entities, @mat[:kitap2])
      t = e.add_group
      kutu(t.entities, 820, 40, zu, 960, 180, zu + 12)
      boya(t.entities, @mat[:mese])
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
      yo = -TABLA_ON - 1
      zu = H + 110
      cubuk(e, [0, yo, zu], [W, yo, zu])
      [0, W].each { |x| cubuk(e, [x, yo, H + 20], [x, yo, zu + 30], 1.6) }
      yazi(e, '1000', [W / 2, yo, zu + 55], :on)
      xr = W + 130
      cubuk(e, [xr, yo, 0], [xr, yo, H])
      [0, H].each { |z| cubuk(e, [W + 4, yo, z], [xr + 30, yo, z], 1.6) }
      yazi(e, '850', [xr + 55, yo, H / 2], :dik)
      cubuk(e, [W + 1, -TABLA_ON, H + 60], [W + 1, D, H + 60])
      [-TABLA_ON, D].each { |y| cubuk(e, [W + 1, y, H + 20], [W + 1, y, H + 90], 1.6) }
      yazi(e, '240', [W + 80, yo, H + 130], :on, 52.0)
      yazi(e, 'İç ölçü: 964 × 202 × 832 mm', [W / 2, yo, H + 280], :on, 50.0)
      yazi(e, 'Petek + vanalar ≤ 944 · petek üstü ≤ 760 · duvardan ≤ 190 mm', [W / 2, yo, H + 360], :on, 38.0)
      d
    end

    # Şeffaf açılı çektirmeler (dünya koordinatında; k = iç köşe noktası, x erkeğin panelinden uzağa, z dişinin
    # panelinden uzağa). Arka kuşak (erkek) arkadan yanların arasına girer: yanlara birer (Z 802) ve tablanın altına
    # üç çektirme (X 200, 500, 800); vidalar kuşağın önünden sıkılır.
    def baglantilar
      l = []
      [[:sol_yan, T, 1, 'sol'], [:sag_yan, W - T, -1, 'sag']].each do |yan, xs, sx, t|
        l << { id: "kusak_#{t}", disi: yan, erkek: :kusak, k: [xs, KUSAK[:y], CEK_Z], ex: [0, -1, 0], ey: [0, 0, 1],
               ez: [sx, 0, 0] }
      end
      CEK_X.each_with_index do |x, i|
        l << { id: "kusak_tabla_#{i + 1}", disi: :ust_tabla, erkek: :kusak, k: [x, KUSAK[:y], ZY], ex: [0, -1, 0],
               ey: [1, 0, 0], ez: [0, 0, -1] }
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

    # Menteşe çerçevesi: orijin kapak arka yüzü / yanın iç yüzü / menteşe yüksekliği;
    # x' menteşe ekseni (dikey), y' = +Y derinlik, z' yandan içeri.
    def mentese_cerceve(o, sx)
      Geom::Transformation.axes(P(*o), Geom::Vector3d.new(0, 0, -sx), Y_AXIS, Geom::Vector3d.new(sx, 0, 0))
    end

    # ------------------------------------------------------------------
    # Panel bileşenleri
    # ------------------------------------------------------------------
    # Yan 220 x 832: arka-alt köşede süpürgelik kesiği; üst uçta bulon ve kavela delikleri, iç yüzde tablanın 36 mm
    # altında eksantrik yuvaları (eksantrikler demonte); kuşak çektirme dişisi; panel pimi deliği (pim demonte) ve iki
    # mıknatıslı tutucu (takılı); altta iki keçe (demonte).
    def yan(k, sx)
      d = parca_tanimi(AD[k])
      e = d.entities
      it(e, [[0, 0], [D - SUPURGE[0], 0], [D - SUPURGE[0], SUPURGE[1]], [D, SUPURGE[1]], [D, ZY], [0, ZY]].map { |y, z| P(0, y, z) },
         yon(1, 0, 0), T)
      xi = sx > 0 ? T : 0.0 # iç yüz
      xm = T / 2
      MF_Y.each do |y|
        daire_it(e, P(xm, y, ZY), Z_AXIS, 4, yon(0, 0, -1), KAM_ARA - 8, 16)
        daire_it(e, P(xi, y, ZY - KAM_ARA), X_AXIS, 7.5, yon(-sx, 0, 0), 12.5, 24)
      end
      daire_it(e, P(xm, KAVELA_Y, ZY), Z_AXIS, KAVELA[:r], yon(0, 0, -1), KAVELA[:yan] + 1, 16)
      daire_it(e, P(xi, PIM_Y, PIM_Z), X_AXIS, 2.5, yon(-sx, 0, 0), 10, 12)
      boya(e, @mat[:govde])
      cektirmeler(e, k)
      t = sx > 0 ? 'sol' : 'sag'
      w = Geom::Vector3d.new(sx * 0.8, -0.5, 0.3).normalize
      MF_Y.zip(%w[on arka]).each do |y, yer|
        o = [xi, y, ZY - KAM_ARA]
        vida_koy(e, @kam, eksen(o, [-sx, 0, 0], [0, 0, 1]), P(*o), Geom::Vector3d.new(-sx, 0, 0), 14.0, 0.0, w, "mf_#{t}_#{yer}")
      end
      o = [xi, PIM_Y, PIM_Z]
      vida_koy(e, @pim, eksen(o, [sx, 0, 0], [0, 0, 1]), P(*o), Geom::Vector3d.new(-sx, 0, 0), 20.0, 0.0,
               Geom::Vector3d.new(sx, 0, 0), "pim_#{t}")
      MIKNATIS_Z.each { |z| miknatis(e, xi, sx, z) }
      KECE_Y.zip(%w[on arka]).each do |y, yer|
        o = [xm, y, 0]
        vida_koy(e, @kece, eksen(o, [0, 0, 1], [1, 0, 0]), P(*o), Geom::Vector3d.new(0, 0, 1), 40.0, 0.0,
                 Geom::Vector3d.new(0, 0, -1), "kece_#{t}_#{yer}")
      end
      [d, ORIJIN[k]]
    end

    def sol_yan; yan(:sol_yan, 1); end
    def sag_yan; yan(:sag_yan, -1); end

    # Üst tabla 1000 x 240 Safir Meşe: yanların üstünde, önde 20 mm taşar. Altında minifiks bulonları (takılı),
    # kavela delikleri (kavelalar demonte) ve kuşak çektirme dişileri.
    def ust_tabla
      d = parca_tanimi(AD[:ust_tabla])
      e = d.entities
      kutu(e, 0, 0, 0, W, D + TABLA_ON, T)
      [T / 2, W - T / 2].each { |x| daire_it(e, P(x, KAVELA_Y + TABLA_ON, 0), Z_AXIS, KAVELA[:r], yon(0, 0, 1), KAVELA[:tabla] + 1, 16) }
      boya(e, @mat[:mese])
      cektirmeler(e, :ust_tabla)
      [T / 2, W - T / 2].each { |x| MF_Y.each { |y| e.add_instance(@bulon, eksen([x, y + TABLA_ON, 0], [0, 0, -1], [1, 0, 0])) } }
      [[T / 2, 'sol'], [W - T / 2, 'sag']].each do |x, t|
        o = [x, KAVELA_Y + TABLA_ON, 0]
        vida_koy(e, @kavela, eksen(o, [0, 0, 1], [1, 0, 0]), P(*o), Geom::Vector3d.new(0, 0, 1), 25.0, 0.0,
                 Geom::Vector3d.new(0, 0, -1), "kavela_#{t}")
      end
      [d, ORIJIN[:ust_tabla]]
    end

    # Arka kuşak 964 x 60: yanların arasında, duvar tarafında dik; çektirme erkekleri önünde. İki duvar vidası (demonte).
    def kusak
      d = parca_tanimi(AD[:kusak])
      e = d.entities
      kutu(e, 0, 0, 0, IW, T, KUSAK[:z][1] - KUSAK[:z][0])
      DUVAR_VIDA_X.each { |x| daire_it(e, P(x - T, 0, 30), Y_AXIS, 2.6, yon(0, 1, 0), T, 12) }
      boya(e, @mat[:govde])
      cektirmeler(e, :kusak)
      DUVAR_VIDA_X.zip(%w[sol sag]).each do |x, t|
        o = [x - T, 0, 30]
        vida_koy(e, @avida, eksen(o, [0, 1, 0], [0, 0, 1]), P(*o), Geom::Vector3d.new(0, 1, 0), 60.0, 3.0,
                 Geom::Vector3d.new(0.2, -1, 0.3).normalize, "duvar_vida_#{t}")
      end
      [d, ORIJIN[:kusak]]
    end

    # Ön panel 962 x 790 beyaz MDF: 22 dikey CNC çıta yarığı (18 x 650, uçları R9), üst kenarda 100 x 30 parmak oyuğu;
    # yarık ve oyuk kenarları bantsız doğal bej MDF. Arkasında mıknatısların karşısında 4 metal pul.
    def on_panel
      d = parca_tanimi(AD[:on_panel])
      e = d.entities
      gen = PANEL[:x][1] - PANEL[:x][0]
      yuk = PANEL[:z][1] - PANEL[:z][0]
      kutu(e, 0, 0, 0, gen, T, yuk)
      r = YARIK[:gen] / 2
      z0, z1 = YARIK[:z]
      n = ((gen - 2 * YARIK[:x0] + (YARIK[:adim] - YARIK[:gen])) / YARIK[:adim]).floor
      n.times do |i|
        xc = YARIK[:x0] + r + i * YARIK[:adim]
        ust = (0..8).map { |j| a = (22.5 * j).degrees; [xc + r * Math.cos(a), z1 - r + r * Math.sin(a)] }
        alt = (0..8).map { |j| a = (180 + 22.5 * j).degrees; [xc + r * Math.cos(a), z0 + r + r * Math.sin(a)] }
        it(e, (ust + alt).map { |x, z| P(x, 0, z) }, yon(0, 1, 0), T)
      end
      og = OYUK[:gen] / 2
      oyuk = (0..12).map { |j| a = (180 + 15 * j).degrees; [gen / 2 + og * Math.cos(a), yuk + OYUK[:der] * Math.sin(a)] }
      it(e, oyuk.map { |x, z| P(x, 0, z) }, yon(0, 1, 0), T)
      boya(e, @mat[:mdf])
      e.grep(Sketchup::Face).each do |f| # yarık ve oyuk iç kenarları: doğal bej MDF
        next unless f.normal.y.abs < 0.01
        b = f.bounds
        next if b.min.x < 1.mm || b.max.x > (gen - 1).mm || b.min.z < 1.mm
        next if b.max.z > (yuk - 1).mm && (b.max.x - b.min.x) > (OYUK[:gen] + 2).mm
        f.material = @mat[:bej]
        f.back_material = @mat[:bej]
      end
      g = e.add_group # metal pullar (arkada, mıknatısların karşısında)
      [9.0, gen - 9].each do |x|
        MIKNATIS_Z.each { |z| torna(g.entities, [[0, 0], [0, 6], [1, 6], [1, 0]], 16, @mat[:nikel]).transform!(eksen([x, T, z - PANEL[:z][0]], [0, 1, 0], [0, 0, 1])) }
      end
      @yarik_sayisi = n
      [d, ORIJIN[:on_panel]]
    end


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
      @m.start_operation('Selva petek kaplama kurulum modeli', true)
      @m.entities.clear!
      @m.pages.to_a.each { |p| @m.pages.erase(p) }
      @m.definitions.purge_unused
      @m.materials.purge_unused
      @m.layers.purge_unused
      malzemeler

      @vida16 = vida_tanimi('Sunta Vidası 3.5x16', 3.8, 2.5, 1.75, 16)
      @vida16h = havsa_vida_tanimi
      @tvida = vida_tanimi('Taban Vidası M4', 3.5, 2.2, 2, 9)
      @cvida = vida_tanimi('Çektirme Vidası (açılı)', 4, 2.5, 2.5, 14)
      @avida = vida_tanimi('Vida 5x60 + Dübel', 4.6, 3.0, 2.5, 60)
      @disi = disi_tanimi
      @erkek = erkek_tanimi
      @kam = kam_tanimi
      @bulon = bulon36_tanimi
      @kavela = kavela_tanimi
      @kece = kece_tanimi
      @pim = pim_tanimi
      arac = tornavida_tanimi
      kisa = kisa_tornavida_tanimi
      cekic = cekic_tanimi

      tags = SIRA.map { |k| [k, @m.layers.add(ETIKET[k])] }.to_h
      liste_tag = @m.layers.add(LISTE_TAG)
      arac_tag = @m.layers.add(ARAC_TAG)
      ek_tag = [DUVAR_TAG, PETEK_TAG, DEKOR_TAG, OLCU_TAG].to_h { |t| [t, @m.layers.add(t)] }

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
      [[duvar_tanimi, DUVAR_TAG], [petek_tanimi, PETEK_TAG], [dekor_tanimi, DEKOR_TAG], [olcu_tanimi, OLCU_TAG]].each do |d, t|
        @m.entities.add_instance(d, Geom::Transformation.new).layer = ek_tag[t]
      end

      parca_listesi(liste_tag)
      stil
      bagla
      son_durum
      sahneler
      [DEKOR_TAG, OLCU_TAG].each { |t| ek_tag[t].visible = false }
      @m.commit_operation
      @m.save(kayit_yolu) if kayit_yolu
      "Kuruldu: #{SIRA.size} parça, #{@vidalar.size} animasyonlu vida/eksantrik/kavela/pim/keçe, #{@yarik_sayisi} yarık, #{@m.pages.size} sahne"
    end

    # Kutu içeriği: paneller yere yatırılmış, fabrikada takılı hırdavat görünür; ayrı gelen küçük parçalar altta.
    def parca_listesi(tag)
      rx = ->(a) { Geom::Transformation.rotation(ORIGIN, X_AXIS, a.degrees) }
      ry = ->(a) { Geom::Transformation.rotation(ORIGIN, Y_AXIS, a.degrees) }
      rz = ->(a) { Geom::Transformation.rotation(ORIGIN, Z_AXIS, a.degrees) }
      bir = Geom::Transformation.new
      yerlesim = {
        sol_yan: [rz.(90) * ry.(-90), 1300, 0], sag_yan: [rz.(90) * ry.(90), 1750, 0],
        on_panel: [rx.(-90), 2250, 0], ust_tabla: [rx.(180), 3400, 0], kusak: [rx.(-90), 3400, 500]
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
      ek.(@kam, 4, 1300, -500, 30, 'Minifiks Gövdesi (4)', [[0, 0, -1], [1, 0, 0], 12], 'kam')
      ek.(@kavela, 2, 1900, -500, 40, 'Kavela Ø8x30 (2)', [[0, 1, 0], [0, 0, 1], 4], 'kavela')
      ek.(@pim, 2, 2500, -500, 40, 'Raf Pimi Ø5 (2)', [[0, 1, 0], [0, 0, 1], 3], 'pim')
      ek.(@kece, 4, 3100, -500, 40, 'Keçe Ø20 (4)', [[0, 0, 1], [1, 0, 0], 3], 'kece')
      ek.(@avida, 2, 3700, -500, 50, 'Duvar Vidası + Dübel (2)', [[0, 1, 0], [0, 0, 1], 5], 'duvar_vidasi')
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
        ['0 Kutu İçeriği', [], :liste, 'Paneller; bulonlar, mıknatıslı tutucular ve çektirmeler takılı; minifiks gövdeleri, kavelalar, pimler, keçeler ve duvar vidaları ayrı.'],
        ['1 Kavelalar', %i[ust_tabla], 1, 'Kavelaları üst tablanın altındaki iki deliğe takın.'],
        ['2 Sol Yan', %i[sol_yan], 2, 'Sol yanı tablanın altına oturtun; iki minifiks gövdesini yanın iç yüzünden yerleştirip yarım tur çevirin.'],
        ['3 Sağ Yan', %i[sag_yan], 3, 'Sağ yanı aynı şekilde takın; iki minifiks gövdesini çevirin.'],
        ['4 Arka Kuşak', %i[kusak], 4, 'Arka kuşağı yanların arasına arkadan yerleştirin; 5 çektirme vidasını sıkın.'],
        ['5 Keçeler', [], 5, 'Yanların altına 4 keçeyi yapıştırın.'],
        ['6 Duvara Sabitleme', [], 6, 'Kaplamayı peteğin önüne itin; arka kuşaktan 2 vida ve dübelle duvara sabitleyin.'],
        ['7 Ön Panel', %i[on_panel], 7, 'Raf pimlerini takın; ön paneli pimlere oturtup üstten itin, mıknatıslar tutar.'],
        ['8 Bitmiş Ürün', [], :bitti, 'Kurulum tamamlandı. Ön panel parmak oyuğundan çekilince çıkar.']
      ]
      acik = []
      tanim.each_with_index do |(ad, yeni, kam, aciklama), n|
        acik += yeni
        liste = kam == :liste
        @m.layers.each do |l|
          k = ETIKET.key(l.name)
          l.visible = if l.name == LISTE_TAG then liste
                      elsif [DUVAR_TAG, PETEK_TAG].include?(l.name) then n >= 6
                      elsif [ARAC_TAG, OLCU_TAG, DEKOR_TAG].include?(l.name) then false
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
      raise 'Model bulunamadı — önce OzcanKurulum::SelvaPetekKaplama.kur' unless @parca.size == SIRA.size && @arac && @kisa_arac && @cekic
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
      @ek_tag0 = @m.layers[PETEK_TAG]
      cizelge
      true
    end

    def vida_kaydi(i, parca, grup)
      { id: nit(i, :vida), inst: i, parca: parca, grup: grup,
        lt: Geom::Transformation.new(nit(i, :lt)), p: Geom::Point3d.new(*nit(i, :p)),
        d: Geom::Vector3d.new(*nit(i, :d)), strok: nit(i, :strok), bas_h: nit(i, :bas_h),
        w: Geom::Vector3d.new(*nit(i, :w)), kapi: nit(i, :kapi), kisa: nit(i, :kisa) }
    end

    # Kapak yok (ön panel elle takılır); motorun beklediği yöntemler.
    def kapi_R(_k, _aci)
      Geom::Transformation.new
    end

    def acik_aci(_k)
      0.0
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

    # Birkaç parçayı birlikte taşır (sabitleme adımında gövdenin tamamı).
    def toplu(ks, a, b, sure)
      @cz.olay(sure) { |s, u| ks.each { |k| s[:p][k] = { vis: true, off: lerp3(a, b, u) } } }
    end

    # Demonte parçayı tornavida gelmeden önce gevşek konumda gösterir.
    def goster(ids)
      @cz.an { |s, _| ids.each { |id| s[:v][id] = { adv: 1.0, ang: 0.0 } } }
    end

    # Elle takılan parçalar (kavela, keçe, raf pimi): görünür olur, yerine itilir; alet yok.
    def elle_tak(ids, sure = 0.9)
      goster(ids)
      @cz.bekle(0.3)
      @cz.olay(sure) { |s, u| ids.each { |id| s[:v][id] = { adv: 1 - u, ang: 0.0 } } }
    end

    def cizelge
      @cz = z = Cizelge.new
      z.an { |s, _| DEMONTE.each { |id| s[:v][id] = { gizli: true } } } # takılana kadar görünmesin
      z.baslik('Kutu içeriği — bulon, mıknatıs ve çektirmeler takılı; minifiks, kavela, pim, keçe ve duvar vidaları ayrı')
      z.kamera(0, KAM[:liste])
      z.bekle(3.5)

      z.baslik('1 · Kavelaları üst tablanın altındaki iki deliğe takın')
      z.an do |s, _|
        s[:liste] = false
        s[:p][:ust_tabla] = { vis: true, off: [0, 0, 0] }
      end
      z.kamera(1.2, KAM[1])
      elle_tak(KAVELALAR)
      z.bekle(0.3)

      z.baslik('2 · Sol yanı tablanın altına oturtun; iki minifiks gövdesini iç yüzden yerleştirip yarım tur çevirin')
      z.kamera(1.2, KAM[2])
      hareket(:sol_yan, [0, 0, -300], [0, 0, -2], 1.8)
      ids = KAMLAR['sol']
      goster(ids)
      z.bekle(0.3)
      sirayla_sik(ids, KAM[2], cekler: cek_listesi(:sol_yan, [0, 0, -2], ids.size), tur: 0.5, bak: [0.9, -0.6, 0.2])
      z.kamera(0.8, KAM[2])
      z.bekle(0.3)

      z.baslik('3 · Sağ yanı aynı şekilde takın; iki minifiks gövdesini yarım tur çevirin')
      z.kamera(1.2, KAM[3])
      hareket(:sag_yan, [0, 0, -300], [0, 0, -2], 1.8)
      ids = KAMLAR['sag']
      goster(ids)
      z.bekle(0.3)
      sirayla_sik(ids, KAM[3], cekler: cek_listesi(:sag_yan, [0, 0, -2], ids.size), tur: 0.5, bak: [-0.9, -0.6, 0.2])
      z.kamera(0.8, KAM[3])
      z.bekle(0.3)

      z.baslik('4 · Arka kuşağı yanların arasına arkadan yerleştirin; beş çektirme vidasını sıkın')
      z.kamera(1.2, KAM[4])
      hareket(:kusak, [0, 300, 0], [0, 2, 0], 1.6)
      sirayla_sik(CEKTIRME_IDLERI, KAM[4], cekler: cek_listesi(:kusak, [0, 2, 0], CEKTIRME_IDLERI.size), bak: [0.3, -1, -0.55])
      z.kamera(0.8, KAM[4])
      z.bekle(0.3)

      z.baslik('5 · Yanların altına dört keçeyi yapıştırın')
      z.kamera(1.2, KAM[5])
      elle_tak(KECELER)
      z.bekle(0.4)

      z.baslik('6 · Kaplamayı peteğin önüne itin; arka kuşaktan iki vida ve dübelle duvara sabitleyin')
      z.an { |s, _| s[:duvar] = true }
      z.kamera(1.2, KAM[6])
      toplu(TASINAN, [0, 0, 0], [0, -650, 0], 1.0)
      toplu(TASINAN, [0, -650, 0], [0, 0, 0], 1.8)
      goster(DUVAR_VIDALARI)
      z.bekle(0.3)
      sirayla_sik(DUVAR_VIDALARI, KAM[6], tur: 5, bak: [0.3, -1, -0.55])
      z.kamera(0.8, KAM[6])
      z.bekle(0.3)

      z.baslik('7 · Raf pimlerini takın; ön paneli pimlere oturtup üstten itin, mıknatıslar tutar')
      z.kamera(1.2, KAM[7])
      elle_tak(PIMLER)
      hareket(:on_panel, [0, -420, 30], [0, -40, 30], 1.4)
      hareket(:on_panel, [0, -40, 30], [0, -40, 0], 0.5)
      hareket(:on_panel, [0, -40, 0], [0, 0, 0], 0.7)
      z.bekle(0.4)

      z.baslik('Kurulum tamamlandı')
      z.kamera(1.6, KAM[:bitti])
      hareket(:on_panel, [0, 0, 0], [0, -200, 30], 1.2)
      z.bekle(0.8)
      hareket(:on_panel, [0, -200, 30], [0, 0, 0], 1.2)
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
    # Adımlar başlıkların sırasıdır: 0 kutu içeriği, 1-7 montaj, 8 bitmiş ürün.
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
