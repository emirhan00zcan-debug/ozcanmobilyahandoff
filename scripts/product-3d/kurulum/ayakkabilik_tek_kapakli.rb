# encoding: UTF-8
# Tek Kapaklı Ayakkabılık (60 x 50 x 40 cm, klapa kapaklı) — kurulum kılavuzu modeli.
#
# Her panel ayrı bileşen; fabrikada takılı gelen bağlantı elemanları (çektirme
# erkek/dişi, raf pimleri, menteşe tabanı, menteşe gövdesi, kulp) panelin içinde
# ayrı bileşen olarak durur. Kurulum sırası kullanıcının anlattığı gibidir:
#   1 sol yan + arkalık  2 alt tabla  3 sağ yan  4 üst tabla  5 raf  6 kapak  7 baza
#
# SketchUp > Pencere > Ruby Konsolu:
#   load 'C:/.../scripts/product-3d/kurulum/ayakkabilik_tek_kapakli.rb'
#   OzcanKurulum::Ayakkabilik.kur                 # AÇIK MODELİ TEMİZLER, modeli sıfırdan kurar
#   OzcanKurulum::Ayakkabilik.oynat               # montaj animasyonunu ekranda oynatır
#   OzcanKurulum::Ayakkabilik.kaydet('C:/kareler') # animasyonu PNG karelere yazar
#
# Koordinatlar mm: X genişlik (0 = sol dış yüz), Y derinlik (0 = ön yüz, +Y arkaya),
# Z yükseklik (0 = zemin).

module OzcanKurulum
  module Ayakkabilik
    extend self

    # ------------------------------------------------------------------
    # Ölçüler (mm)
    # ------------------------------------------------------------------
    W = 600.0            # dış genişlik
    H = 500.0            # yan panel yüksekliği
    D = 400.0            # derinlik
    T = 18.0             # panel kalınlığı
    IW = W - 2 * T       # iç genişlik = baza genişliği (564)
    BAZA_H = 100.0
    ALT_Z = BAZA_H       # alt tablanın alt yüzü
    UST_Z = 462.0        # üst tablanın alt yüzü (üst yüzü yan panellerin 20 mm altında)
    KANAL_Y0 = 386.0     # arkalık kanalı: 4 mm geniş, 8 mm derin, arka kenardan 10 mm içeride
    KANAL_Y1 = 390.0
    KANAL_DER = 8.0
    ARKA_T = 3.0
    PIM_Z = ALT_Z + T + 190.0 # raf pimi ekseni alt tablanın üst yüzünden 190 mm yukarıda
    PIM_R = 2.5
    PIM_Y = [77.0, 347.0]     # rafın ön/arka kenarından 37 mm
    RAF_Y0 = 40.0
    KAPI_BOSLUK = 3.0
    MENTESE_X = [118.0, 482.0]          # menteşe eksenleri (yan panel iç yüzünden 100 mm)
    CEKTIRME_Y = [60.0, 340.0]          # yan bağlantıların Y merkezleri
    BAZA_CEKTIRME_X = [150.0, 450.0]
    PIVOT = [9.5, 110.5]     # kapağın (Y, Z) dönme ekseni: açılınca alt tablanın önüne yatar

    PLAKA_T = 3.0             # çektirme plakalarının kalınlığı
    VIDA_EKSEN = [15.0, 10.0] # dişi çerçevesinde çektirme vidası ekseninin (x, z) konumu

    KAPI_X0 = T + KAPI_BOSLUK
    KAPI_Z0 = ALT_Z + T + KAPI_BOSLUK
    KAPI_W = IW - 2 * KAPI_BOSLUK
    KAPI_H = (UST_Z - KAPI_BOSLUK) - KAPI_Z0

    # Görüş açısı: serbest en-boyda SketchUp FOV'u dikey, 16:9 sabitlenince
    # yatay uygular. İkisi de ~30° dikey görüşe denk gelsin.
    DIKEY_FOV = 30.0
    VIDEO_FOV = 50.0

    DICT = 'ozcan_kurulum'
    SIRA = %i[sol_yan arkalik alt_tabla sag_yan ust_tabla raf kapak baza].freeze
    ETIKET = {
      sol_yan: '01 Sol Yan', arkalik: '02 Arkalık', alt_tabla: '03 Alt Tabla',
      sag_yan: '04 Sağ Yan', ust_tabla: '05 Üst Tabla', raf: '06 Raf',
      kapak: '07 Kapak', baza: '08 Baza'
    }.freeze
    AD = {
      sol_yan: 'Sol Yan', arkalik: 'Arkalık', alt_tabla: 'Alt Tabla', sag_yan: 'Sağ Yan',
      ust_tabla: 'Üst Tabla', raf: 'Raf', kapak: 'Kapak', baza: 'Baza'
    }.freeze
    LISTE_TAG = '00 Parça Listesi'
    ARAC_TAG = '99 Tornavida'

    # Kamera noktaları [göz, hedef] (mm)
    KAM = {
      liste:  [[2700, -2650, 2450], [2700, -110, 0]],
      1 =>    [[1450, -1250, 1150], [230, 220, 230]],
      2 =>    [[1400, -1350, 950], [260, 200, 170]],
      3 =>    [[-900, -1300, 1000], [340, 200, 220]],
      4 =>    [[650, -1500, 1450], [300, 200, 330]],
      5 =>    [[1250, -1450, 950], [300, 200, 290]],
      6 =>    [[1300, -1350, 800], [300, 40, 170]],
      :"7a" => [[1250, -1600, 650], [300, 60, 180]],
      :"7b" => [[1100, 1250, 50], [300, 40, 110]],
      bitti:  [[1350, -1500, 1000], [300, 200, 230]]
    }.freeze

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
        beyaz: mk.('Beyaz Melamin', [240, 239, 234]),
        arka: mk.('Arkalık HDF', [224, 221, 212]),
        seffaf: mk.('Şeffaf Plastik', [160, 200, 228], 0.45),
        cinko: mk.('Çinko Kaplama', [160, 164, 170]),
        nikel: mk.('Nikel', [192, 196, 202]),
        pirinc: mk.('Pirinç Burç', [196, 158, 72]),
        yuva: mk.('Vida Yuvası', [40, 40, 44]),
        kulp: mk.('Kulp Beyaz', [250, 250, 250]),
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

    def havsa_vida_tanimi
      d = @m.definitions.add('Sunta Vidası 3.5x16 (havşa)')
      torna(d.entities, [[-2.2, 0], [-2.2, 3.6], [0, 1.75], [14, 1.75], [16, 0.5], [16, 0]], 20, @mat[:cinko])
      yildiz(d.entities, -2.25, 3.2)
      d
    end

    # Çektirmenin burçtaki vidası: başsız, ucu konik; ön ucu x=0'da.
    def cektirme_vidasi_tanimi
      d = @m.definitions.add('Çektirme Vidası M6 (burçta)')
      torna(d.entities, [[0, 0], [0, 3], [7.5, 3], [9, 1.2], [9, 0]], 20, @mat[:cinko])
      yildiz(d.entities, -0.05, 3.2)
      d
    end

    # --- Şeffaf çektirme: iki parçalı köşe bağlantısı ---
    # İki yarım da "bağlantı çerçevesinde" çizilir: orijin iki panelin iç köşe
    # çizgisinde; y = köşe çizgisi boyunca vida ekseni (vidalanma yönü), z = parçanın
    # vidalandığı panelden dışarı, x = karşı panelden uzağa. Böylece dişinin (x, z)'si
    # erkeğin (z, x)'ine denk gelir: dil yuvanın yarığına oturur.
    def plaka(e, daireler, ice, delikler)
      it(e, plaka_hatti(daireler, ice, 8).map { |x, y| P(x, y, 0) }, yon(0, 0, 1), PLAKA_T)
      delikler.each do |x, y|
        daire_it(e, P(x, y, PLAKA_T), Z_AXIS, 3.8, yon(0, 0, -1), 1.5, 16)
        daire_it(e, P(x, y, PLAKA_T - 1.5), Z_AXIS, 1.9, yon(0, 0, -1), 1.5, 12)
      end
    end

    def havsa_vidalari(e, delikler)
      delikler.each { |x, y| e.add_instance(@vida16h, eksen([x, y, PLAKA_T - 3.7], [0, 0, -1], [1, 0, 0])) }
    end

    # Dişi (geçirilen parça): köşede yarıklı yuva. Yarık hem karşı panele hem
    # içeri doğru açık — alt tabla yandan kayarak, üst tabla yukarıdan "cuk" diye girer.
    # Ön duvardaki pirinç burçta çektirme vidası durur.
    def disi_tanimi
      d = @m.definitions.add('Çektirme Dişi (geçirilen parça)')
      e = d.entities
      delik = [[46, 0], [12, 34]]
      plaka(e, [[6.5, -6.5, 3], [46, 0, 7], [12, 34, 7], [6.5, 6.5, 3]], 1, delik)
      it(e, [P(4.5, -7.5, 3), P(26, -7.5, 3), P(26, 7.5, 3), P(4.5, 7.5, 3)], yon(0, 0, 1), 17)
      it(e, [P(4.5, -2.7, 20), P(23.5, -2.7, 20), P(23.5, 2.7, 20), P(4.5, 2.7, 20)], yon(0, 0, -1), 16)
      x, z = VIDA_EKSEN
      daire_it(e, P(x, -7.5, z), Y_AXIS, 4.2, yon(0, 1, 0), 4.8, 20)
      boya(e, @mat[:seffaf])
      torna(e, [[0, 3], [0, 4.2], [4.8, 4.2], [4.8, 3]], 20, @mat[:pirinc])
        .transform!(eksen([x, -7.5, z], [0, 1, 0], [0, 0, 1]))
      havsa_vidalari(e, delik)
      d
    end

    # Erkek (geçen parça): köşede dik duran, üstü yuvarlak, delikli dil. Delik vida
    # ekseninden 2 mm uzakta: konik uç girince dili (ve paneli) karşı panele çeker.
    def erkek_tanimi
      d = @m.definitions.add('Çektirme Erkek (geçen parça)')
      e = d.entities
      delik = [[46, 0], [12, -34]]
      plaka(e, [[12, -34, 7], [46, 0, 7], [6.5, 6.5, 3]], 0, delik)
      boya(e, @mat[:seffaf])
      g = e.add_group
      dil = [[5, 3], [18, 3]] + (0..12).map { |i| a = Math::PI * i / 12; [11.5 + 6.5 * Math.cos(a), 16.5 + 6.5 * Math.sin(a)] }
      it(g.entities, dil.map { |x, z| P(x, -2.5, z) }, yon(0, 1, 0), 5)
      daire_it(g.entities, P(VIDA_EKSEN[1] + 2, -2.5, VIDA_EKSEN[0]), Y_AXIS, 3.3, yon(0, 1, 0), 5, 16)
      boya(g.entities, @mat[:seffaf])
      havsa_vidalari(e, delik)
      d
    end

    def pim_tanimi
      d = @m.definitions.add('Raf Pimi Ø5')
      torna(d.entities, [[-8, 0], [-8, 2.1], [-7.5, 2.5], [0, 2.5], [0, 3.5], [1, 3.5], [1, 2.5],
                         [7.5, 2.5], [8, 2.1], [8, 0]], 20, @mat[:nikel])
      d
    end

    # Menteşe parçaları "menteşe çerçevesinde" çizilir: orijin = (menteşe ekseni X,
    # kapak arka yüzü Y=18, alt tabla üst yüzü Z=118), eksenler dünya eksenleri.
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
      zc = 25.5
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
      torna(e, [[-6, 0], [-6, 4], [6, 4], [6, 0]], 20, @mat[:nikel]).transform!(tr(0, -4, 18))
      d
    end

    def bag_tanimi
      d = @m.definitions.add('Menteşe Bağlantı Kolu')
      kutu(d.entities, 0, -5, -2.5, 10, 5, 2.5)
      boya(d.entities, @mat[:nikel])
      d
    end

    def kulp_tanimi
      d = @m.definitions.add('Kulp')
      torna(d.entities, [[0, 0], [0, 20], [7, 20], [9.5, 19], [11, 17], [11, 13.5], [10, 12], [7.5, 11], [7.5, 0]],
            40, @mat[:kulp])
      d
    end

    def tornavida_tanimi
      d = @m.definitions.add('Tornavida')
      torna(d.entities, [[0, 0], [0, 0.9], [6, 2.2], [9, 3], [104, 3], [104, 0]], 20, @mat[:uc])
      torna(d.entities, [[100, 0], [100, 7], [106, 9], [112, 13], [118, 14], [186, 14], [194, 12.5],
                         [200, 9], [200, 0]], 28, @mat[:sap])
      d
    end

    # ------------------------------------------------------------------
    # Panel bileşenleri (her biri kendi min köşesinde orijinli)
    # ------------------------------------------------------------------
    # Animasyonda dönen vida: parçanın içine ayrı örnek olarak eklenir.
    def vida_koy(e, defn, lt, p, d, strok, bas_h, w, id, kapi = false)
      i = e.add_instance(defn, lt)
      nitelik(i, vida: id, lt: lt.to_a, p: p.to_a, d: d.to_a, strok: strok, bas_h: bas_h, w: w.to_a, kapi: kapi)
      i
    end

    ORIJIN = {
      sol_yan: [0, 0, 0], sag_yan: [W - T, 0, 0], alt_tabla: [T, 0, ALT_Z], ust_tabla: [T, 0, UST_Z], baza: [T, 0, 0]
    }.freeze

    # Tüm çektirmeler dünya koordinatında: k = iç köşe noktası, ns = dişinin panelinden
    # içeri, np = erkeğin panelinden içeri, ek = vida ekseni (vidalanma yönü; tornavida
    # karşı taraftan gelir: yanlarda önden, bazada ortadan).
    def baglantilar
      l = []
      [[:sol_yan, T, 1, 'sol'], [:sag_yan, W - T, -1, 'sag']].each do |yan, xs, sx, taraf|
        CEKTIRME_Y.each_with_index do |y, i|
          [[:alt_tabla, ALT_Z + T, 1, 'alt'], [:ust_tabla, UST_Z, -1, 'ust']].each do |pan, zp, sz, ad|
            l << { id: "#{ad}_#{taraf}_#{i.zero? ? 'on' : 'arka'}", erkek: pan, disi: yan,
                   k: [xs, y, zp], ns: [sx, 0, 0], np: [0, 0, sz], ek: [0, 1, 0] }
          end
        end
      end
      BAZA_CEKTIRME_X.each_with_index do |bx, i|
        l << { id: "baza_#{i.zero? ? 'sol' : 'sag'}", erkek: :alt_tabla, disi: :baza,
               k: [bx, T, ALT_Z], ns: [0, 1, 0], np: [0, 0, -1], ek: [i.zero? ? -1 : 1, 0, 0] }
      end
      l
    end

    # Verilen eksenlerle konum (sol el de olabilir: ayna simetrik yerleşim)
    def cerceve(k, x, y, z)
      v = ->(a) { Geom::Vector3d.new(*a) }
      Geom::Transformation.axes(P(*k), v.(x), v.(y), v.(z))
    end

    # Parçaya düşen çektirme yarımlarını ve dişideki (animasyonlu) vidayı ekler.
    def cektirmeler(e, parca)
      ters = tr(*ORIJIN[parca]).inverse
      baglantilar.each do |b|
        e.add_instance(@erkek, ters * cerceve(b[:k], b[:ns], b[:ek], b[:np])) if b[:erkek] == parca
        next unless b[:disi] == parca
        dt = ters * cerceve(b[:k], b[:np], b[:ek], b[:ns])
        e.add_instance(@disi, dt)
        x, z = VIDA_EKSEN
        lt = dt * eksen([x, -7, z], [0, 1, 0], [0, 0, 1])
        w = Geom::Vector3d.new(*[0, 1, 2].map { |i| -b[:ek][i] + 0.18 * b[:ns][i] + 0.09 * b[:np][i] }).normalize
        vida_koy(e, @cvida, lt, P(x, -7, z).transform(dt), Geom::Vector3d.new(*b[:ek]), 5.0, 0.0, w, b[:id])
      end
    end

    def parca_tanimi(ad)
      @m.definitions.add(ad)
    end

    def sol_yan
      d = parca_tanimi('Sol Yan')
      e = d.entities
      kutu(e, 0, 0, 0, T, D, H)
      it(e, [P(T, KANAL_Y0, 0), P(T, KANAL_Y1, 0), P(T, KANAL_Y1, H), P(T, KANAL_Y0, H)], yon(-1, 0, 0), KANAL_DER)
      boya(e, @mat[:beyaz])
      cektirmeler(e, :sol_yan)
      PIM_Y.each { |y| e.add_instance(@pim, eksen([T, y, PIM_Z], [1, 0, 0], [0, 0, 1])) }
      [d, ORIJIN[:sol_yan]]
    end

    def sag_yan
      d = parca_tanimi('Sağ Yan')
      e = d.entities
      kutu(e, 0, 0, 0, T, D, H)
      it(e, [P(0, KANAL_Y0, 0), P(0, KANAL_Y1, 0), P(0, KANAL_Y1, H), P(0, KANAL_Y0, H)], yon(1, 0, 0), KANAL_DER)
      boya(e, @mat[:beyaz])
      cektirmeler(e, :sag_yan)
      PIM_Y.each { |y| e.add_instance(@pim, eksen([0, y, PIM_Z], [-1, 0, 0], [0, 0, 1])) }
      [d, ORIJIN[:sag_yan]]
    end

    def arkalik
      d = parca_tanimi('Arkalık')
      bw = IW + 2 * KANAL_DER - 1
      bh = H - (ALT_Z + T - KANAL_DER + 0.5)
      kutu(d.entities, 0, 0, 0, bw, ARKA_T, bh)
      boya(d.entities, @mat[:arka])
      [d, [T - KANAL_DER + 0.5, KANAL_Y0 + 0.5, ALT_Z + T - KANAL_DER + 0.5]]
    end

    def alt_tabla
      d = parca_tanimi('Alt Tabla')
      e = d.entities
      kutu(e, 0, 0, 0, IW, D, T)
      it(e, [P(0, KANAL_Y0, T), P(IW, KANAL_Y0, T), P(IW, KANAL_Y1, T), P(0, KANAL_Y1, T)], yon(0, 0, -1), KANAL_DER)
      boya(e, @mat[:beyaz])
      cektirmeler(e, :alt_tabla)
      MENTESE_X.each { |hx| e.add_instance(@taban, tr(hx - T, T, T)) }
      [d, ORIJIN[:alt_tabla]]
    end

    def ust_tabla
      d = parca_tanimi('Üst Tabla')
      e = d.entities
      kutu(e, 0, 0, 0, IW, KANAL_Y0, T)
      boya(e, @mat[:beyaz])
      cektirmeler(e, :ust_tabla)
      [d, ORIJIN[:ust_tabla]]
    end

    def raf
      d = parca_tanimi('Raf')
      kutu(d.entities, 0, 0, 0, IW - 2, KANAL_Y0 - 2 - RAF_Y0, T)
      boya(d.entities, @mat[:beyaz])
      [d, [T + 1, RAF_Y0, PIM_Z + PIM_R]]
    end

    def bar_tr(a, b)
      v = b - a
      x = v.normalize
      y = Geom::Vector3d.new(1, 0, 0)
      Geom::Transformation.axes(a, x, y, x * y) * Geom::Transformation.scaling(ORIGIN, v.length / 10.mm, 1, 1)
    end

    def kapak
      d = parca_tanimi('Kapak')
      e = d.entities
      kutu(e, 0, 0, 0, KAPI_W, T, KAPI_H)
      MENTESE_X.each { |hx| daire_it(e, P(hx - KAPI_X0, T, 22.5), Y_AXIS, 17.5, yon(0, -1, 0), 12.5, 32) }
      boya(e, @mat[:beyaz])
      e.add_instance(@kulp, eksen([KAPI_W / 2, 0, KAPI_H - 42], [0, -1, 0], [0, 0, 1]))
      MENTESE_X.each_with_index do |hx, i|
        taraf = i.zero? ? 'sol' : 'sag'
        g = e.add_group
        g.name = 'Menteşe Gövdesi (büyük parça)'
        ge = g.entities
        o = [hx - KAPI_X0, T, ALT_Z + T - KAPI_Z0]
        ge.add_instance(@kap, tr(*o))
        kol = ge.add_instance(@kol, tr(*o))
        nitelik(kol, kol: taraf, lc: tr(*o).to_a)
        a = P(o[0], o[1] - 4, o[2] + 18)
        b = P(o[0], o[1] + 12, o[2] + 14)
        bag = ge.add_instance(@bag, bar_tr(a, b))
        nitelik(bag, bar: taraf, a: a.to_a, b: b.to_a)
        lt = tr(o[0], o[1] + 34, o[2] + 8) * eksen([0, 0, 0], [0, 0, -1], [1, 0, 0])
        w = Geom::Vector3d.new(0, -Math.sin(35.degrees), Math.cos(35.degrees))
        vida_koy(ge, @mvida, lt, P(o[0], o[1] + 34, o[2] + 8), Geom::Vector3d.new(0, 0, -1), 4.0, 2.3, w,
                 "mentese_#{taraf}", true)
      end
      [d, [KAPI_X0, 0, KAPI_Z0]]
    end

    def baza
      d = parca_tanimi('Baza')
      e = d.entities
      kutu(e, 0, 0, 0, IW, T, BAZA_H)
      boya(e, @mat[:beyaz])
      cektirmeler(e, :baza)
      [d, ORIJIN[:baza]]
    end

    # ------------------------------------------------------------------
    # Model kurulumu
    # ------------------------------------------------------------------
    def kur(kayit_yolu = nil)
      @m = Sketchup.active_model
      @m.start_operation('Ayakkabılık kurulum modeli', true)
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
      @cvida = cektirme_vidasi_tanimi
      @disi = disi_tanimi
      @erkek = erkek_tanimi
      @pim = pim_tanimi
      @taban = taban_tanimi
      @kol = kol_tanimi
      @kap = kap_tanimi
      @bag = bag_tanimi
      @kulp = kulp_tanimi
      arac = tornavida_tanimi

      tags = SIRA.map { |k| [k, @m.layers.add(ETIKET[k])] }.to_h
      liste_tag = @m.layers.add(LISTE_TAG)
      arac_tag = @m.layers.add(ARAC_TAG)

      SIRA.each do |k|
        d, o = send(k)
        i = @m.entities.add_instance(d, tr(*o))
        i.name = AD[k]
        i.layer = tags[k]
        nitelik(i, parca: k.to_s)
      end
      ti = @m.entities.add_instance(arac, tr(0, 0, 0))
      ti.layer = arac_tag
      nitelik(ti, parca: 'tornavida')

      parca_listesi(liste_tag)
      stil
      bagla
      son_durum
      sahneler
      @m.commit_operation
      @m.save(kayit_yolu) if kayit_yolu
      "Kuruldu: #{SIRA.size} parça, #{@vidalar.size} animasyonlu vida, #{@m.pages.size} sahne"
    end

    # Kutu içeriği: paneller yere yatırılmış, fabrikada takılı hırdavat üstte.
    def parca_listesi(tag)
      rx = ->(a) { Geom::Transformation.rotation(ORIGIN, X_AXIS, a.degrees) }
      ry = ->(a) { Geom::Transformation.rotation(ORIGIN, Y_AXIS, a.degrees) }
      yerlesim = {
        sol_yan: [ry.(-90), 1400, 0], sag_yan: [ry.(90), 2020, 0],
        arkalik: [rx.(90), 2640, 0], kapak: [rx.(90), 3340, 0],
        alt_tabla: [Geom::Transformation.new, 1400, -620], ust_tabla: [rx.(180), 2084, -620],
        raf: [Geom::Transformation.new, 2768, -620], baza: [rx.(90), 3450, -620]
      }
      @m.entities.grep(Sketchup::ComponentInstance).select { |i| nit(i, :parca) && nit(i, :parca) != 'tornavida' }.each do |ana|
        k = nit(ana, :parca).to_sym
        rot, x, y = yerlesim[k]
        bb = Geom::BoundingBox.new
        b = ana.definition.bounds
        8.times { |c| bb.add(b.corner(c).transform(rot)) }
        kay = Geom::Transformation.translation(P(x, y, 0) - bb.min)
        i = @m.entities.add_instance(ana.definition, kay * rot)
        i.layer = tag
        on = Geom::Point3d.new(bb.center.x, bb.min.y, 0).transform(kay) # ön kenarın ortası, zeminde
        txt = @m.entities.add_text(AD[k], on, Geom::Vector3d.new(0, -110.mm, 0))
        txt.layer = tag
      end
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
        ['0 Kutu İçeriği', [], :liste, 'Paneller ve fabrikada takılı bağlantı elemanları.'],
        ['1 Sol Yan + Arkalık', %i[sol_yan arkalik], 1, 'Arkalığı sol yan panelin kanalına geçirin.'],
        ['2 Alt Tabla', %i[alt_tabla], 2, 'Alt tablayı hem arkalığa hem sol yana geçirin; çektirmelerin ortasındaki vidaları tornavida ile sıkın.'],
        ['3 Sağ Yan', %i[sag_yan], 3, 'Sağ yanı arkalık kanalına ve alt tabladaki çektirmelere geçirin; vidaları sıkın.'],
        ['4 Üst Tabla', %i[ust_tabla], 4, 'Üst tablayı çektirmeleri iki yan panele cuk diye oturacak şekilde yerleştirin; vidaları sıkın.'],
        ['5 Raf', %i[raf], 5, 'Rafı yan panellerdeki raf pimlerinin üzerine koyun.'],
        ['6 Kapak', %i[kapak], 6, 'Kapaktaki menteşe gövdesini alt tabladaki menteşe tabanına geçirin; ortadaki vidayı sıkın.'],
        ['7 Baza', %i[baza], :"7a", 'Bazayı çektirmelerle alt tablaya takın; vidaları arkadan sıkın.'],
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
      @arac = nil
      @m.entities.grep(Sketchup::ComponentInstance).each do |i|
        k = nit(i, :parca)
        next unless k
        if k == 'tornavida' then @arac = i
        else
          @parca[k.to_sym] = i
          @taban_tr[k.to_sym] = i.transformation
        end
      end
      raise 'Model bulunamadı — önce OzcanKurulum::Ayakkabilik.kur' unless @parca.size == SIRA.size && @arac
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
              elsif nit(y, :kol) then @kollar << { inst: y, lc: Geom::Transformation.new(nit(y, :lc)) }
              elsif nit(y, :bar)
                @barlar << { inst: y, a: Geom::Point3d.new(*nit(y, :a)), b: Geom::Point3d.new(*nit(y, :b)) }
              end
            end
          end
        end
      end
      @liste_tag = @m.layers[LISTE_TAG]
      @arac_tag = @m.layers[ARAC_TAG]
      cizelge
      true
    end

    def vida_kaydi(i, parca, grup)
      { id: nit(i, :vida), inst: i, parca: parca, grup: grup,
        lt: Geom::Transformation.new(nit(i, :lt)), p: Geom::Point3d.new(*nit(i, :p)),
        d: Geom::Vector3d.new(*nit(i, :d)), strok: nit(i, :strok), bas_h: nit(i, :bas_h),
        w: Geom::Vector3d.new(*nit(i, :w)), kapi: nit(i, :kapi) }
    end

    def kapi_R(aci)
      Geom::Transformation.rotation(P(0, *PIVOT), X_AXIS, aci.degrees)
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
    end

    def hareket(k, a, b, sure)
      @cz.olay(sure) do |s, u|
        s[:p][k][:vis] = true
        s[:p][k][:off] = lerp3(a, b, u)
      end
    end

    def vida_sik(id, cek = nil, tur: 4, sure: 1.1)
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

    def cizelge
      @cz = z = Cizelge.new
      z.baslik('Kutu içeriği — bağlantı elemanları panellere takılı gelir')
      z.kamera(0, KAM[:liste])
      z.bekle(3.5)

      z.baslik('1 · Arkalığı sol yan panelin kanalına geçirin')
      z.an { |s, _| s[:liste] = false; s[:p][:sol_yan][:vis] = true }
      z.kamera(1.2, KAM[1])
      hareket(:arkalik, [450, 0, 0], [0, 0, 0], 2.0)
      z.bekle(0.5)

      z.baslik('2 · Alt tablayı arkalığa ve sol yana geçirin, vidaları sıkın')
      z.kamera(1.0, KAM[2])
      hareket(:alt_tabla, [450, 0, 0], [2, 0, 0], 2.0)
      vida_sik('alt_sol_on', [:alt_tabla, [2, 0, 0], [1, 0, 0]])
      vida_sik('alt_sol_arka', [:alt_tabla, [1, 0, 0], [0, 0, 0]])
      z.bekle(0.3)

      z.baslik('3 · Sağ yanı arkalık kanalına ve çektirmelere geçirin, vidaları sıkın')
      z.kamera(1.2, KAM[3])
      hareket(:sag_yan, [380, 0, 0], [2, 0, 0], 2.0)
      vida_sik('alt_sag_on', [:sag_yan, [2, 0, 0], [1, 0, 0]])
      vida_sik('alt_sag_arka', [:sag_yan, [1, 0, 0], [0, 0, 0]])
      z.bekle(0.3)

      z.baslik('4 · Üst tablayı çektirmelere cuk diye oturtun, vidaları sıkın')
      z.kamera(1.2, KAM[4])
      z.olay(1.4, false) do |s, u|
        s[:p][:ust_tabla][:vis] = true
        s[:p][:ust_tabla][:off] = [0, 0, 320 * (1 - u * u)]
      end
      %w[ust_sol_on ust_sol_arka ust_sag_on ust_sag_arka].each { |id| vida_sik(id, nil, tur: 3, sure: 0.8) }
      z.bekle(0.3)

      z.baslik('5 · Rafı raf pimlerinin üzerine yerleştirin')
      z.kamera(1.0, KAM[5])
      hareket(:raf, [0, -480, 40], [0, 0, 40], 1.6)
      hareket(:raf, [0, 0, 40], [0, 0, 0], 0.6)
      z.bekle(0.4)

      z.baslik('6 · Kapaktaki menteşeyi alt tabladaki tabana geçirin, ortadaki vidayı sıkın')
      z.kamera(1.0, KAM[6])
      z.an { |s, _| s[:kapi_aci] = 90.0 }
      hareket(:kapak, [0, -320, 0], [0, 0, 0], 2.0)
      vida_sik('mentese_sol', nil, tur: 3, sure: 0.9)
      vida_sik('mentese_sag', nil, tur: 3, sure: 0.9)
      z.olay(1.5) { |s, u| s[:kapi_aci] = 90.0 * (1 - u) }
      z.bekle(0.3)

      z.baslik('7 · Bazayı çektirmelerle alt tablaya takın, vidaları arkadan sıkın')
      z.kamera(1.0, KAM[:"7a"])
      hareket(:baza, [0, -320, 0], [0, 0, 0], 1.8)
      z.kamera(1.4, KAM[:"7b"])
      vida_sik('baza_sol')
      vida_sik('baza_sag')
      z.bekle(0.3)

      z.baslik('Kurulum tamamlandı')
      z.kamera(1.6, KAM[:bitti])
      z.olay(1.3) { |s, u| s[:kapi_aci] = 90.0 * u }
      z.bekle(0.8)
      z.olay(1.3) { |s, u| s[:kapi_aci] = 90.0 * (1 - u) }
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
        kapi_aci: 0.0,
        drv: nil }
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
      h = lerp3(prev[3], cur[3], u)
      kure = lambda do |e, c|
        v = [e[0] - c[0], e[1] - c[1], e[2] - c[2]]
        r = Math.sqrt(v.sum { |x| x * x })
        [r, Math.atan2(v[1], v[0]), Math.asin(v[2] / r)]
      end
      r0, a0, e0 = kure.(prev[2], prev[3])
      r1, a1, e1 = kure.(cur[2], cur[3])
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
      c = @taban_tr[:kapak]
      rinv = c.inverse * kapi_R(s[:kapi_aci]).inverse * c
      SIRA.each do |k|
        st = s[:p][k]
        off = st[:vis] ? st[:off] : UZAK
        t = tr(*off)
        t *= kapi_R(s[:kapi_aci]) if k == :kapak
        @parca[k].move!(t * @taban_tr[k])
      end
      @kollar.each { |x| x[:inst].move!(rinv * x[:lc]) }
      @barlar.each { |x| x[:inst].move!(bar_tr(x[:a], x[:b].transform(rinv))) }
      @vidalar.each do |v|
        st = s[:v][v[:id]]
        m = vida_tr(v, st[:adv], st[:ang])
        m = rinv * m if v[:kapi]
        v[:inst].move!(m)
      end
      drv = s[:drv]
      if drv
        v = @vidalar.find { |x| x[:id] == drv[:id] }
        dunya = @parca[v[:parca]].transformation
        dunya *= v[:grup].transformation if v[:grup]
        dunya *= v[:inst].transformation
        bas = Geom::Point3d.new(-v[:bas_h].mm, 0, 0).transform(dunya)
        w = v[:w]
        uc = bas.offset(w, (drv[:uz] * 130).mm)
        ax = w.axes
        @arac.move!(Geom::Transformation.axes(uc, w, ax[0], ax[1]) *
                    Geom::Transformation.rotation(ORIGIN, X_AXIS, drv[:don].degrees))
      else
        @arac.move!(tr(*UZAK))
      end
    end

    def kamera_uygula(t)
      eye, h = kamera_at(t)
      @m.active_view.camera.set(P(*eye), P(*h), Z_AXIS)
    end

    def kare(t)
      uygula(durum(t))
      kamera_uygula(t)
    end

    def hazirla(oran = 0.0)
      bagla unless @parca && @parca.values.all?(&:valid?)
      @eski_tag = [@liste_tag.visible?, @arac_tag.visible?, SIRA.map { |k| @parca[k].layer.visible? }]
      @arac_tag.visible = true
      SIRA.each { |k| @parca[k].layer.visible = true }
      c = @m.active_view.camera
      @eski_kam = [c.eye, c.target, c.up, c.fov, c.aspect_ratio]
      c.perspective = true
      c.aspect_ratio = oran
      c.fov = oran > 0 ? VIDEO_FOV : DIKEY_FOV
    end

    # Montajlı son durum: tüm parçalar yerinde, vidalar sıkılı, kapak kapalı.
    def son_durum
      s = ilk_durum
      SIRA.each { |k| s[:p][k] = { vis: true, off: [0, 0, 0] } }
      s[:v].each_key { |id| s[:v][id] = { adv: 0.0, ang: 0.0 } }
      s[:liste] = @liste_tag.visible?
      uygula(s)
      @arac.move!(Geom::Transformation.new)
    end

    def bitir
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
    end

    class Oynatici
      def initialize(mod, bas) @mod = mod; @bas = bas; @t0 = nil; @son = nil end

      def nextFrame(view)
        @t0 ||= Time.now
        t = @bas + (Time.now - @t0)
        @mod.kare(t)
        b = @mod.baslik_at(t)
        Sketchup.status_text = b if b != @son
        @son = b
        view.show_frame
        return true if t < @mod.sure
        @mod.bitir
        false
      end

      def stop
        @mod.bitir
      end
    end

    def baslik_at(t)
      b = @cz.basliklar.select { |x| x[0] <= t }.last
      b && b[1]
    end

    # Montaj animasyonunu ekranda oynatır (fareyle yörünge çevirmek durdurur).
    def oynat(bas = 0.0)
      @m = Sketchup.active_model
      hazirla
      @m.active_view.animation = Oynatici.new(self, bas)
      "Oynatılıyor: #{sure.round(1)} sn"
    end

    # Tek kare (video ayarlarıyla) — kadraj ayarlamak için.
    def onizle(t, dosya, gen: 1280, yuk: 720)
      @m = Sketchup.active_model
      hazirla(gen.to_f / yuk)
      kare(t)
      @m.active_view.write_image(filename: dosya, width: gen, height: yuk, antialias: true, transparent: false)
      baslik_at(t)
    ensure
      bitir
    end

    # Animasyonu PNG karelere yazar; basliklar.json video üstü yazılar içindir.
    def kaydet(klasor, fps: 25, gen: 1280, yuk: 720, bas: 0.0, son: nil)
      @m = Sketchup.active_model
      Dir.mkdir(klasor) unless File.directory?(klasor)
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
    end
  end
end
