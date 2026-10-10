# encoding: UTF-8
# 4 Çekmeceli Şifonyer (80 x 90 x 54 cm) — kurulum kılavuzu modeli.
# Ahşap desenli (safir meşe) 18 mm sunta gövde ve çekmeceler, siyah kulplar, çakma arkalık, önde 8 cm baza.
# Ölçüler Drive'daki ölçülü ürün görselinden (scripts/kesim-listesi/urun-sifonyer.json): dış 80 x 90 x 54,
# çekmece önleri 80 x 20, çekmece iç 70 x 46 x 13,5, gövde iç 76,4 x 51, baza 8.
# Raylar fotoğraftaki teleskopik ray değil: kullanıcının istediği düz beyaz makaralı (tekerlekli) ray —
# dolap parçasında önde, çekmece parçasında arkada naylon tekerlek.
#
# Her panel ayrı bileşen; fabrikada takılı gelen parçalar (şeffaf çektirme erkek/dişi, minifix eksantrik ve
# bulonları, ray parçaları) panelin içinde ayrı bileşen. Kulplar, kulp vidaları ve çiviler demonte gelir.
#   1 sol yan + alt tabla  2 sağ yan  3 baza  4 üst tabla  5 arkalık (çivi)
#   6 1. çekmece (minifix, dip çivisi, kulp, raylara itilir)  7 diğer üç çekmece
#
# SketchUp > Pencere > Ruby Konsolu:
#   load 'C:/.../scripts/product-3d/kurulum/sifonyer.rb'
#   OzcanKurulum::Sifonyer.kur               # AÇIK MODELİ TEMİZLER, modeli sıfırdan kurar
#   OzcanKurulum::Sifonyer.oynat             # montaj animasyonunu ekranda oynatır
#   OzcanKurulum::Sifonyer.kumanda           # klavyeyle adım adım: → ← Enter, K serbest kamera, Esc
#   (konsoldan: sonraki, onceki, durdur, devam, adim(3), git(3), bitir)
#   OzcanKurulum::Sifonyer.kaydet('C:/kareler') # animasyonu PNG karelere yazar
#
# Koordinatlar mm: X genişlik (0 = sol dış yüz), Y derinlik (0 = gövde ön yüzü, +Y arkaya;
# çekmece önleri Y<0'da, arkalık Y=510..513), Z yükseklik (0 = zemin).

module OzcanKurulum
  module Sifonyer
    extend self

    # ------------------------------------------------------------------
    # Ölçüler (mm)
    # ------------------------------------------------------------------
    W = 800.0            # gövde ve üst tabla genişliği
    T = 18.0             # panel kalınlığı
    D = 510.0            # yan derinliği (gövde iç derinliği 51); + 3 mm çakma arkalık
    ARKA_T = 3.0
    Z0 = 80.0            # baza yüksekliği = alt tablanın alt yüzü; yanlar yere kadar
    ZT = 882.0           # yanların üst kenarı; üstünde 18 mm üst tabla → 900
    TABLA_DER = 540.0    # üst tabla arkalıkla bir, önde çekmece önlerini ~7 mm geçer
    CEK_Y = [60.0, 450.0].freeze # yanlarda altta ve üstte ikişer çektirme
    BAZA_X = [200.0, W - 200.0].freeze
    KAPI_PAY = 2.0
    ON_W = 797.0         # çekmece önleri 80 x 20 (aralıklarla 79,7 x 19,7)
    ON_H = 197.0
    ON_X0 = (W - ON_W) / 2
    ON_ADIM = 200.0      # önler arası adım (3 mm aralık)
    KUTU_W = 736.0       # çekmece kutusu dış 73,6 x 49,6 x 13,5 (iç 70 x 46 x 13,5)
    KUTU_H = 135.0
    KUTU_D = 496.0
    KUTU_T = 18.0
    KUTU_X0 = (W - KUTU_W) / 2 # kutuyla yan arasında 14 mm ray boşluğu
    RAY_L = 450.0
    RAY_Y0 = 3.0
    KAM_ARA = 34.0       # minifix eksantriğinin panel ucuna uzaklığı
    KULP_ARA = 128.0     # kulp vida aralığı
    KULP_Z = ON_H - 62   # kulp ekseni önün üst kenarından 6,2 cm aşağıda
    # c1 en üstteki çekmece. Kutu önün altından 35 mm yukarıda (üst çekmecede üst çektirmelerin altında
    # kalır); en alttakinde 58 mm (rayı alt çektirmelerin üstünde kalır).
    CEKMECE = (1..4).map do |n|
      on_z = Z0 + 2 + ON_ADIM * (4 - n)
      [:"c#{n}", { ad: "#{n}. Çekmece", on_z: on_z, kutu_z: on_z + (n == 4 ? 58.0 : 35.0) + ARKA_T }]
    end.to_h.freeze
    CEKMECE_PAR = %w[on sol sag arka dip].freeze
    PLAKA_T = 3.0

    DIKEY_FOV = 30.0
    VIDEO_FOV = 50.0

    DICT = 'ozcan_kurulum'
    CEKMECE_SIRA = CEKMECE.keys.flat_map { |c| CEKMECE_PAR.map { |p| :"#{c}_#{p}" } }.freeze
    SIRA = (%i[sol_yan alt_tabla sag_yan baza ust_tabla arkalik] + CEKMECE_SIRA).freeze
    AD = {
      sol_yan: 'Sol Yan', alt_tabla: 'Alt Tabla', sag_yan: 'Sağ Yan', baza: 'Baza', ust_tabla: 'Üst Tabla',
      arkalik: 'Arkalık'
    }.merge(CEKMECE.flat_map { |c, h|
      { on: 'Önü', sol: 'Yanı (sol)', sag: 'Yanı (sağ)', arka: 'Arkası', dip: 'Dibi' }.map { |p, a| [:"#{c}_#{p}", "#{h[:ad]} #{a}"] }
    }.to_h).freeze
    ETIKET = {
      sol_yan: '01 Sol Yan', alt_tabla: '02 Alt Tabla', sag_yan: '03 Sağ Yan', baza: '04 Baza',
      ust_tabla: '05 Üst Tabla', arkalik: '06 Arkalık'
    }.merge(CEKMECE_SIRA.map { |k| n = k.to_s[1].to_i; [k, "#{format('%02d', 6 + n)} #{n}. Çekmece"] }.to_h).freeze
    LISTE_TAG = '00 Parça Listesi'
    ARAC_TAG = '99 Tornavida'

    # Kamera noktaları [göz, hedef] (mm)
    KAM = {
      liste:   [[3950, -3800, 6000], [3950, 720, 0]],
      1 =>     [[1500, -1500, 1300], [350, 255, 300]],
      2 =>     [[-600, -1700, 1400], [450, 255, 350]],
      3 =>     [[1500, -1700, 600], [400, 200, 80]],
      4 =>     [[1900, -2100, 2100], [400, 255, 550]],
      5 =>     [[2000, 2500, 1600], [400, 255, 450]],
      hepsi:   [[2300, -2900, 1400], [400, -400, 400]],
      bitti:   [[2100, -2400, 1600], [400, 200, 450]]
    }.freeze

    # Parçaların yerleşim orijini (bileşen orijini = parçanın min köşesi)
    ORIJIN = {
      sol_yan: [0, 0, 0], sag_yan: [W - T, 0, 0], alt_tabla: [T, 0, Z0], baza: [T, 0, 0],
      ust_tabla: [0, D + ARKA_T - TABLA_DER, ZT], arkalik: [0, D, Z0]
    }.merge(CEKMECE.flat_map { |c, h|
      kz = h[:kutu_z]
      [[:"#{c}_on", [ON_X0, -(KAPI_PAY + T), h[:on_z]]], [:"#{c}_sol", [KUTU_X0, -KAPI_PAY, kz]],
       [:"#{c}_sag", [KUTU_X0 + KUTU_W - KUTU_T, -KAPI_PAY, kz]],
       [:"#{c}_arka", [KUTU_X0 + KUTU_T, KUTU_D - KAPI_PAY - KUTU_T, kz]], [:"#{c}_dip", [KUTU_X0, -KAPI_PAY, kz - ARKA_T]]]
    }.to_h).freeze

    # Arkalık çivileri: yanların ve alt tablanın arka kenarına (arkalık-yerel x, z)
    CIVI = [160, 330, 500, 670, 840].flat_map { |z| [[T / 2, z - Z0], [W - T / 2, z - Z0]] } +
           [150, 400, 650].map { |x| [x, T / 2] }
    CIVILER = (1..CIVI.size).map { |i| format('civi_%02d', i) }.freeze
    # Çekmece dibi çivileri (dip-yerel x, y): yanlara ikişer, öne ve arkaya birer
    DIP_CIVI = [[KUTU_T / 2, 60], [KUTU_T / 2, KUTU_D - 60], [KUTU_W - KUTU_T / 2, 60], [KUTU_W - KUTU_T / 2, KUTU_D - 60],
                [KUTU_W / 2, KUTU_T / 2], [KUTU_W / 2, KUTU_D - KUTU_T / 2]].freeze
    DIP_CIVILER = CEKMECE.keys.flat_map { |c| (1..DIP_CIVI.size).map { |i| "#{c}_civi_#{i}" } }.freeze
    KULPLAR = CEKMECE.keys.flat_map { |c| ["#{c}_kulp", "#{c}_kulpvida_1", "#{c}_kulpvida_2"] }.freeze
    DEMONTE = (CIVILER + DIP_CIVILER + KULPLAR).freeze

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
        govde: mk.('Safir Meşe', [198, 152, 102]),
        arka: mk.('Arkalık (duralit)', [188, 156, 116]),
        dip: mk.('Çekmece Dibi', [228, 216, 192]),
        kulp: mk.('Siyah Kulp', [32, 32, 34]),
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

    # Siyah kulp, 128 mm vida aralığı: yerel +x önden dışarı, y kulp boyu; hafif aşağı kavisli yassı çubuk.
    def kulp_tanimi
      d = @m.definitions.add('Siyah Kulp 128')
      [-1, 1].each do |sy|
        g = d.entities.add_group
        kutu(g.entities, 0, sy * KULP_ARA / 2 - 4, -4, 20, sy * KULP_ARA / 2 + 4, 4)
        boya(g.entities, @mat[:kulp])
      end
      g = d.entities.add_group
      ust = (0..12).map { |i| y = -80 + 160.0 * i / 12; [y, 5 - 4 * (1 - (y / 80.0)**2)] }
      alt = ust.reverse.map { |y, z| [y, z - 10] }
      it(g.entities, (ust + alt).map { |y, z| P(20, y, z) }, yon(1, 0, 0), 6)
      boya(g.entities, @mat[:kulp])
      d
    end

    # Makaralı beyaz ray, dolap parçası: yanın iç yüzüne vidalı dik sac, altta kanal, önde naylon tekerlek.
    # xi yanın iç yüzü, sx içeri yönü, zb çekmecenin alt yüzü (yan-yerel).
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
    # (x erkeğin panelinden uzağa, z dişinin panelinden uzağa). Alt tabla sol yana yandan kayar,
    # sağ yan ona oturur; üst tabla yukarıdan iner (erkek tablada); baza alt tablanın altına
    # önden kayar, vidaları arkadaki boşluktan kısa tornavidayla.
    def baglantilar
      l = []
      [[:sol_yan, T, 1, 'sol'], [:sag_yan, W - T, -1, 'sag']].each do |yan, xs, sx, taraf|
        CEK_Y.zip(%w[on arka]).each do |y, yer|
          l << { id: "alt_#{taraf}_#{yer}", disi: :alt_tabla, erkek: yan, k: [xs, y, Z0 + T], ex: [sx, 0, 0], ez: [0, 0, 1] }
          l << { id: "ust_#{taraf}_#{yer}", disi: yan, erkek: :ust_tabla, k: [xs, y, ZT], ex: [0, 0, -1], ez: [sx, 0, 0] }
        end
      end
      BAZA_X.each_with_index do |x, i|
        l << { id: "baza_#{i + 1}", disi: :alt_tabla, erkek: :baza, k: [x, T, Z0], ex: [0, 1, 0], ey: [1, 0, 0],
               ez: [0, 0, -1], kisa: true }
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

    # Yan: yere kadar iner; çektirmeler ve her çekmece için rayın dolap parçası.
    def dis_yan(k, sx)
      d = parca_tanimi(AD[k])
      e = d.entities
      kutu(e, 0, 0, 0, T, D, ZT)
      boya(e, @mat[:govde])
      xi = sx > 0 ? T : 0.0 # iç yüz
      cektirmeler(e, k)
      CEKMECE.each_value { |h| ray_dolap(e, xi, sx, h[:kutu_z] - ARKA_T) }
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

    # Baza: yanların arasında, alt tablanın altında önde.
    def baza
      d = parca_tanimi(AD[:baza])
      kutu(d.entities, 0, 0, 0, W - 2 * T, T, Z0)
      boya(d.entities, @mat[:govde])
      cektirmeler(d.entities, :baza)
      [d, ORIJIN[:baza]]
    end

    # 3 mm çakma arkalık: yanların ve alt tablanın arka kenarına çivilenir; altında baza boşluğu kalır.
    def arkalik
      d = parca_tanimi(AD[:arkalik])
      e = d.entities
      kutu(e, 0, 0, 0, W, ARKA_T, ZT - Z0)
      boya(e, @mat[:arka])
      CIVI.each_with_index do |(x, z), i|
        vida_koy(e, @civi, eksen([x, ARKA_T, z], [0, -1, 0], [0, 0, 1]), P(x, ARKA_T, z), Geom::Vector3d.new(0, -1, 0),
                 16.0, 1.2, Geom::Vector3d.new(0, 1, 0), CIVILER[i])
      end
      [d, ORIJIN[:arkalik]]
    end

    # --- Çekmece: desenli ön + kutu önü (minifix eksantrikleri), iki yan (bulonlar ve rayın çekmece
    # parçası), arka (eksantrikler), 3 mm dip (alttan çivilenir). Yanlar ön ile arkanın uçlarını kavrar.
    # Kulp önden oturur, iki vidası kutunun içinden girer (demonte). ---
    def cekmece_on(c)
      h = CEKMECE[c]
      d = parca_tanimi(AD[:"#{c}_on"])
      e = d.entities
      kutu(e, 0, 0, 0, ON_W, T, ON_H)
      kx = ON_W / 2
      delik = [-1, 1].map { |s| [kx + s * KULP_ARA / 2, KULP_Z] }
      delik.each { |x, z| daire_it(e, P(x, 0, z), Y_AXIS, 2.5, yon(0, 1, 0), T, 16) } # kulp vida delikleri (Ø5)
      boya(e, @mat[:govde])
      g = e.add_group # kutu önü, desenli önün arkasında
      x0 = KUTU_X0 + KUTU_T - ON_X0
      zk = h[:kutu_z] - h[:on_z]
      kutu(g.entities, x0, T, zk, x0 + KUTU_W - 2 * KUTU_T, T + KUTU_T, zk + KUTU_H)
      boya(g.entities, @mat[:govde])
      [[x0 + KAM_ARA, 'sol'], [x0 + KUTU_W - 2 * KUTU_T - KAM_ARA, 'sag']].each do |x, taraf|
        o = [x, T + KUTU_T, zk + KUTU_H / 2]
        vida_koy(e, @kam, eksen(o, [0, -1, 0], [0, 0, 1]), P(*o), Geom::Vector3d.new(0, -1, 0), 0.01, 0.0,
                 Geom::Vector3d.new(0, 1, 0), "#{c}_kam_on_#{taraf}", false, true)
      end
      vida_koy(e, @kulp, eksen([kx, 0, KULP_Z], [0, -1, 0], [0, 0, 1]), P(kx, 0, KULP_Z), Geom::Vector3d.new(0, 1, 0),
               60.0, 0.0, Geom::Vector3d.new(0, -1, 0), "#{c}_kulp")
      wk = Geom::Vector3d.new(0, 0.77, 0.64) # kutunun içinden, üstten eğik
      delik.each_with_index do |(x, z), j|
        vida_koy(e, @kvida, eksen([x, T + KUTU_T, z], [0, -1, 0], [0, 0, 1]), P(x, T + KUTU_T, z),
                 Geom::Vector3d.new(0, -1, 0), 25.0, 2.3, wk, "#{c}_kulpvida_#{j + 1}")
      end
      [d, ORIJIN[:"#{c}_on"]]
    end

    def cekmece_yan(c, taraf)
      k = :"#{c}_#{taraf}"
      d = parca_tanimi(AD[k])
      e = d.entities
      kutu(e, 0, 0, 0, KUTU_T, KUTU_D, KUTU_H)
      boya(e, @mat[:govde])
      sol = taraf == 'sol'
      xi = sol ? KUTU_T : 0.0 # iç yüz
      [KUTU_T / 2, KUTU_D - KUTU_T / 2].each do |y| # ön ve arka panelin uç ortası
        e.add_instance(@bulon, eksen([xi, y, KUTU_H / 2], [sol ? 1 : -1, 0, 0], [0, 0, 1]))
      end
      ray_cekmece(e, sol ? 0.0 : KUTU_T, sol ? -1 : 1, -ARKA_T)
      [d, ORIJIN[k]]
    end

    def cekmece_arka(c)
      k = :"#{c}_arka"
      d = parca_tanimi(AD[k])
      e = d.entities
      gen = KUTU_W - 2 * KUTU_T
      kutu(e, 0, 0, 0, gen, KUTU_T, KUTU_H)
      boya(e, @mat[:govde])
      [[KAM_ARA, 'sol'], [gen - KAM_ARA, 'sag']].each do |x, taraf|
        o = [x, 0, KUTU_H / 2]
        vida_koy(e, @kam, eksen(o, [0, 1, 0], [0, 0, 1]), P(*o), Geom::Vector3d.new(0, 1, 0), 0.01, 0.0,
                 Geom::Vector3d.new(0, -1, 0), "#{c}_kam_arka_#{taraf}", false, true)
      end
      [d, ORIJIN[k]]
    end

    def cekmece_dip(c)
      k = :"#{c}_dip"
      d = parca_tanimi(AD[k])
      e = d.entities
      kutu(e, 0, 0, 0, KUTU_W, KUTU_D, ARKA_T)
      boya(e, @mat[:dip])
      DIP_CIVI.each_with_index do |(x, y), i|
        vida_koy(e, @civi, eksen([x, y, 0], [0, 0, 1], [1, 0, 0]), P(x, y, 0), Geom::Vector3d.new(0, 0, 1), 16.0, 1.2,
                 Geom::Vector3d.new(0, 0, -1), "#{c}_civi_#{i + 1}")
      end
      [d, ORIJIN[k]]
    end

    def parca_yap(k)
      c, p = k.to_s.split('_', 2)
      return send(k) unless CEKMECE.key?(c.to_sym)
      case p
      when 'on' then cekmece_on(c.to_sym)
      when 'arka' then cekmece_arka(c.to_sym)
      when 'dip' then cekmece_dip(c.to_sym)
      else cekmece_yan(c.to_sym, p)
      end
    end

    # ------------------------------------------------------------------
    # Model kurulumu
    # ------------------------------------------------------------------
    def kur(kayit_yolu = nil)
      @m = Sketchup.active_model
      @m.start_operation('Şifonyer kurulum modeli', true)
      @m.entities.clear!
      @m.pages.to_a.each { |p| @m.pages.erase(p) }
      @m.definitions.purge_unused
      @m.materials.purge_unused
      @m.layers.purge_unused
      malzemeler

      @vida16h = havsa_vida_tanimi
      @cvida = vida_tanimi('Çektirme Vidası (açılı)', 4, 2.5, 2.5, 14)
      @kvida = vida_tanimi('Kulp Vidası M4x40', 3.8, 2.3, 2, 40)
      @disi = disi_tanimi
      @erkek = erkek_tanimi
      @civi = civi_tanimi
      @kam = kam_tanimi
      @bulon = bulon_tanimi
      @kulp = kulp_tanimi
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
      "Kuruldu: #{SIRA.size} parça, #{@vidalar.size} animasyonlu vida/eksantrik/çivi/kulp, #{@m.pages.size} sahne"
    end

    # Kutu içeriği: paneller yere yatırılmış, fabrikada takılı hırdavat üstte; kulplar, vidaları ve çiviler ayrı.
    def parca_listesi(tag)
      rx = ->(a) { Geom::Transformation.rotation(ORIGIN, X_AXIS, a.degrees) }
      ry = ->(a) { Geom::Transformation.rotation(ORIGIN, Y_AXIS, a.degrees) }
      rz = ->(a) { Geom::Transformation.rotation(ORIGIN, Z_AXIS, a.degrees) }
      bir = Geom::Transformation.new
      yerlesim = {
        sol_yan: [rz.(90) * ry.(-90), 1300, 0], sag_yan: [rz.(90) * ry.(90), 1950, 0],
        arkalik: [rx.(-90), 2600, 0], ust_tabla: [bir, 3550, 0], alt_tabla: [bir, 4500, 0], baza: [rx.(90), 5400, 0]
      }
      CEKMECE.keys.each_with_index do |c, i|
        x0 = 1300 + (i % 2) * 3100
        y = 1150 + (i / 2) * 700
        yerlesim.merge!(:"#{c}_on" => [rx.(90), x0, y], :"#{c}_sol" => [ry.(90), x0 + 870, y],
                        :"#{c}_sag" => [ry.(-90), x0 + 1070, y], :"#{c}_arka" => [rx.(-90), x0 + 1270, y],
                        :"#{c}_dip" => [bir, x0 + 2040, y])
      end
      etiket = AD.merge(CEKMECE.map { |c, h| [:"#{c}_on", "#{h[:ad]} (5 parça)"] }.to_h)
      @m.entities.grep(Sketchup::ComponentInstance).select { |i| nit(i, :parca) && !%w[tornavida kisa_tornavida cekic].include?(nit(i, :parca)) }.each do |ana|
        k = nit(ana, :parca).to_sym
        rot, x, y = yerlesim[k]
        b = Geom::BoundingBox.new # demonte parçalar (kulp, vidalar, çiviler) yerleşime katılmasın
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
        adet.times { |i| @m.entities.add_instance(defn, eksen([x + i * dx, -450, eks[2]], eks[0], eks[1])).layer = tag }
        @m.entities.add_text(ad, P(x, -560, 0), Geom::Vector3d.new(0, -90.mm, 0)).layer = tag
      end
      ek.(@kulp, CEKMECE.size, 1300, 70, "Kulp (#{CEKMECE.size})", [[0, 0, 1], [1, 0, 0], 0])
      ek.(@kvida, 2 * CEKMECE.size, 2150, 25, "Kulp Vidası M4x40 (#{2 * CEKMECE.size})", [[0, 1, 0], [0, 0, 1], 4])
      ek.(@civi, 8, 3000, 14, "Çivi (#{CIVILER.size + DIP_CIVILER.size})", [[0, 1, 0], [0, 0, 1], 3])
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
        ['0 Kutu İçeriği', [], :liste, 'Paneller ve fabrikada takılı bağlantı elemanları; kulplar, vidaları ve çiviler ayrı.'],
        ['1 Sol Yan + Alt Tabla', %i[sol_yan alt_tabla], 1, 'Alt tablayı sol yandaki 2 şeffaf çektirmeye geçirip vidaları sıkın.'],
        ['2 Sağ Yan', %i[sag_yan], 2, 'Sağ yanı alt tabladaki 2 çektirmeye oturtup vidaları sıkın.'],
        ['3 Baza', %i[baza], 3, 'Bazayı alt tablanın altına önden yerleştirin; 2 çektirme vidasını arkadan sıkın.'],
        ['4 Üst Tabla', %i[ust_tabla], 4, 'Üst tablayı yanların üstüne oturtun; 4 çektirme vidasını sıkın.'],
        ['5 Arkalık', %i[arkalik], 5, 'Arkalığı arkaya yerleştirip çivileri çakın.'],
        ['6 1. Çekmece', CEKMECE_SIRA.select { |k| k.to_s.start_with?('c1') }, kam_cek(:c1), 'Yanları minifixle öne ve arkaya bağlayın, dibi çakın, kulpu takın, raylara oturtup itin.'],
        ['7 Diğer Çekmeceler', CEKMECE_SIRA.reject { |k| k.to_s.start_with?('c1') }, :hepsi, 'Diğer üç çekmeceyi aynı şekilde kurup raylara itin.'],
        ['8 Bitmiş Ürün', [], :bitti, 'Kurulum tamamlandı.']
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
        kamera_kur(*(kam.is_a?(Array) ? kam : KAM[kam]))
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
      raise 'Model bulunamadı — önce OzcanKurulum::Sifonyer.kur' unless @parca.size == SIRA.size && @arac && @kisa_arac && @cekic
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

    def cekmece_parcalari(c)
      CEKMECE_PAR.map { |p| :"#{c}_#{p}" }
    end

    # Bir ya da birkaç çekmecenin tüm parçalarını birlikte taşır.
    def cekmece_hareket(cler, a, b, sure)
      @cz.olay(sure) do |s, u|
        Array(cler).each { |c| cekmece_parcalari(c).each { |k| s[:p][k] = { vis: true, off: lerp3(a, b, u) } } }
      end
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
    def dip_civileri(c) (1..DIP_CIVI.size).map { |i| "#{c}_civi_#{i}" } end

    # Çekmecenin önde kurulduğu yere bakan kamera (yüksekliği çekmeceye göre)
    def kam_cek(c)
      z = CEKMECE[c][:on_z]
      [[1700, -2300, z + 650], [400, -520, z + 60]]
    end

    # Kulp önden oturur; iki kulp vidası kutunun içinden gelip sıkılır.
    def kulp_tak(c)
      z = @cz
      z.olay(0.8) { |s, u| s[:v]["#{c}_kulp"] = { adv: 3.0 * (1 - u), ang: 0.0 } }
      [1, 2].each do |j|
        id = "#{c}_kulpvida_#{j}"
        z.olay(0.5) { |s, u| s[:v][id] = { adv: 4.0 - 3.0 * u, ang: 0.0 } }
        vida_sik(id, nil, tur: 4, sure: 0.9, yakin: j == 1, bak: [0.25, 0.8, 0.9])
      end
    end

    # Çekmece önde kurulur: yanlar minifix bulonlarıyla ön ve arkanın uçlarına geçer, eksantrikler
    # yarım tur çevrilir, dip alttan çakılır, kulp takılır; sonra raylara oturtulup içeri itilir.
    def cekmece_kur(c)
      z = @cz
      s0 = [0, -650, 0]
      kam = kam_cek(c)
      z.kamera(1.2, kam)
      z.an do |s, _|
        s[:p][:"#{c}_on"] = { vis: true, off: s0 }
        s[:p][:"#{c}_arka"] = { vis: true, off: s0 }
      end
      z.bekle(0.4)
      hareket(:"#{c}_sol", [-160, -650, 0], s0, 1.0)
      hareket(:"#{c}_sag", [160, -650, 0], s0, 1.0)
      # ilk eksantriğe kutunun içinden, arkadan-yukarıdan bak (ön görüşü kapatmasın)
      sirayla_sik(kam_idleri(c), kam, tur: 0.5, bak: [0.3, 1, 0.8])
      hareket(:"#{c}_dip", [0, -650, -160], s0, 1.0)
      ids = dip_civileri(c)
      z.an { |s, _| ids.each { |id| s[:v][id] = { adv: 1.0, ang: 0.0 } } }
      yakin_kamera(ids.first, yon: [0.35, -1, -0.75])
      civi_cak(ids.first)
      z.kamera(0.8, kam)
      ids.drop(1).each { |id| civi_cak(id) }
      kulp_tak(c)
      z.kamera(0.8, kam)
      cekmece_hareket(c, s0, [0, 0, 0], 1.8)
      z.bekle(0.3)
    end

    # Kalan çekmeceler birlikte, aynı sırayla ama tek tek göstermeden kurulup raylara itilir.
    def cekmeceler_hizli(cler)
      z = @cz
      s0 = [0, -650, 0]
      z.kamera(1.2, KAM[:hepsi])
      z.an do |s, _|
        cler.each do |c|
          s[:p][:"#{c}_on"] = { vis: true, off: s0 }
          s[:p][:"#{c}_arka"] = { vis: true, off: s0 }
        end
      end
      z.bekle(0.3)
      z.olay(1.0) do |s, u|
        cler.each do |c|
          s[:p][:"#{c}_sol"] = { vis: true, off: lerp3([-160, -650, 0], s0, u) }
          s[:p][:"#{c}_sag"] = { vis: true, off: lerp3([160, -650, 0], s0, u) }
        end
      end
      z.olay(0.6, false) { |s, u| cler.each { |c| kam_idleri(c).each { |id| s[:v][id] = { adv: 1 - u, ang: 180.0 * u } } } }
      z.olay(1.0) { |s, u| cler.each { |c| s[:p][:"#{c}_dip"] = { vis: true, off: lerp3([0, -650, -160], s0, u) } } }
      z.an { |s, _| cler.each { |c| dip_civileri(c).each { |id| s[:v][id] = { adv: 1.0, ang: 0.0 } } } }
      z.olay(0.6, false) { |s, u| cler.each { |c| dip_civileri(c).each { |id| s[:v][id] = { adv: 1 - u, ang: 0.0 } } } }
      z.olay(0.8) { |s, u| cler.each { |c| s[:v]["#{c}_kulp"] = { adv: 3.0 * (1 - u), ang: 0.0 } } }
      z.olay(0.8, false) do |s, u|
        cler.each { |c| [1, 2].each { |j| s[:v]["#{c}_kulpvida_#{j}"] = { adv: 1 - u, ang: 1440.0 * u } } }
      end
      z.bekle(0.3)
      cekmece_hareket(cler, s0, [0, 0, 0], 1.8)
      z.bekle(0.3)
    end

    def cizelge
      @cz = z = Cizelge.new
      z.an { |s, _| DEMONTE.each { |id| s[:v][id] = { gizli: true } } } # takılana kadar görünmesin
      z.baslik('Kutu içeriği — bağlantı elemanları panellere takılı gelir; kulplar, vidaları ve çiviler ayrı')
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

      z.baslik('3 · Bazayı alt tablanın altına önden yerleştirin, çektirme vidalarını arkadan sıkın')
      z.kamera(1.2, KAM[3])
      hareket(:baza, [0, -400, 0], [0, -2, 0], 1.6)
      ids = BAZA_X.each_index.map { |i| "baza_#{i + 1}" }
      sirayla_sik(ids, KAM[3], cekler: cek_listesi(:baza, [0, -2, 0], ids.size), bak: [0.3, 1, -0.05])
      z.kamera(0.8, KAM[3])
      z.bekle(0.3)

      z.baslik('4 · Üst tablayı yanların üstüne oturtun, dört çektirme vidasını sıkın')
      z.kamera(1.2, KAM[4])
      hareket(:ust_tabla, [0, 0, 300], [0, 0, 2], 2.0)
      ids = %w[sol sag].flat_map { |t| %w[on arka].map { |y| "ust_#{t}_#{y}" } }
      sirayla_sik(ids, KAM[4], cekler: cek_listesi(:ust_tabla, [0, 0, 2], ids.size))
      z.kamera(0.8, KAM[4])
      z.bekle(0.3)

      z.baslik('5 · Arkalığı arkaya yerleştirip çivileri çekiçle çakın')
      z.kamera(1.2, KAM[5])
      hareket(:arkalik, [0, 450, 0], [0, 0, 0], 2.0)
      z.an { |s, _| CIVILER.each { |id| s[:v][id] = { adv: 1.0, ang: 0.0 } } }
      z.bekle(0.3)
      yakin_kamera(CIVILER.first, yon: [1.0, 0.75, 0.45])
      civi_cak(CIVILER.first)
      z.kamera(0.8, KAM[5])
      CIVILER.drop(1).each { |id| civi_cak(id) }
      z.bekle(0.3)

      z.baslik('6 · 1. çekmeceyi minifixle kurun, dibini çakın, kulpunu takın; raylara oturtup itin')
      cekmece_kur(:c1)

      z.baslik('7 · Diğer üç çekmeceyi aynı şekilde kurup raylara itin')
      cekmeceler_hizli(%i[c2 c3 c4])

      z.baslik('Kurulum tamamlandı')
      z.kamera(1.6, KAM[:bitti])
      cek = { c1: 360, c2: 0, c3: 240, c4: 0 } # makaralı rayları göstermek için iki çekmece açılır
      z.olay(1.3) { |s, u| cek.each { |c, m| cekmece_parcalari(c).each { |k| s[:p][k][:off] = [0, -m * u, 0] } } }
      z.bekle(0.8)
      z.olay(1.3) { |s, u| cek.each { |c, m| cekmece_parcalari(c).each { |k| s[:p][k][:off] = [0, -m * (1 - u), 0] } } }
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
      yy = X_AXIS.clone if yy.length < 1e-6
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

    # Montajlı son durum: tüm parçalar yerinde, vidalar ve çiviler sıkılı, çekmeceler kapalı.
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
