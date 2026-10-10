# encoding: UTF-8
# Beyaz Vera Konsol — üç kapaklı dolap (94 x 71 x 48 cm, 13 cm ayak dahil) — kurulum kılavuzu modeli.
# Tamamen beyaz: 18 mm sunta gövde, 36 mm tabla (iki kat 18 mm), oyma desenli membran kapaklar (orta
# kapağın alt kenarı kavisli), siyah konik ayaklar. Ortada geniş bölme (iç 51,5 x 50,5), iki yanda tek
# raflı dar bölmeler; yan kapaklar dış yanlara, orta kapak sağ ara dikmeye menteşeli.
# Ölçüler Drive'daki "Ürün 8 — Üç Kapaklı Dolap (Beyaz)" ve "ÜRÜN ÖLÇÜSÜ" belgelerinden; fotoğrafla
# doğrulandı (kapaklar 20 + 53 + 20 cm, orta kapağın kavisi ~5 cm, raf altında 24 cm).
#
# Her panel ayrı bileşen; fabrikada takılı gelen parçalar (şeffaf çektirme erkek/dişi, menteşe tabanı ve
# gövdesi, raf pimleri, ayak tabanları) panelin içinde ayrı bileşen. Ayaklar ve tabla vidaları demonte
# gelir. Paneller şeffaf çektirmeyle bağlanır; arkalık yanların, alt ve üst tablanın kanalına geçer.
#   1 ayaklar  2 sol yan  3 sağ yan  4 ara dikmeler  5 arkalık (kanala)  6 üst tabla
#   7 tabla (içeriden vida)  8 raflar  9 kapaklar
#
# SketchUp > Pencere > Ruby Konsolu:
#   load 'C:/.../scripts/product-3d/kurulum/vera_konsol.rb'
#   OzcanKurulum::VeraKonsol.kur               # AÇIK MODELİ TEMİZLER, modeli sıfırdan kurar
#   OzcanKurulum::VeraKonsol.oynat             # montaj animasyonunu ekranda oynatır
#   OzcanKurulum::VeraKonsol.kumanda           # klavyeyle adım adım: → ← Enter, K serbest kamera, Esc
#   (konsoldan: sonraki, onceki, durdur, devam, adim(3), git(3), bitir)
#   OzcanKurulum::VeraKonsol.kaydet('C:/kareler') # animasyonu PNG karelere yazar
#
# Koordinatlar mm: X genişlik (0 = sol dış yüz), Y derinlik (0 = gövde ön yüzü, +Y arkaya;
# kapaklar Y<0'da, arkalık Y=437..440 kanalda), Z yükseklik (0 = zemin).

module OzcanKurulum
  module VeraKonsol
    extend self

    # ------------------------------------------------------------------
    # Ölçüler (mm)
    # ------------------------------------------------------------------
    W = 940.0            # gövde genişliği (kapaklar 20 + 53 + 20 ve aralıklar)
    T = 18.0             # panel kalınlığı
    D = 450.0            # yan derinliği (kapakla 470, tabla 480)
    AYAK_H = 130.0
    Z0 = AYAK_H          # alt tablanın alt yüzü
    ZT = Z0 + 541.0      # yanların üst kenarı (yan 54,1); üstünde 36 mm tabla → 707
    TABLA_T = 36.0
    TABLA_DER = 480.0    # arkası gövdeyle bir, önde kapakları 1 cm geçer
    ARKA_T = 3.0
    KANAL_Y = D - 10 - ARKA_T # arkalığın ön yüzü: kanal arka kenardan 10 mm içeride
    KANAL_DER = 8.0      # kanal derinliği (arkalık panellere 8 mm girer)
    IC_X = { dikme_sol: 194.5, dikme_sag: W - 194.5 - T }.freeze # dikmelerin sol yüzü (yan bölme içi 176,5; orta 515)
    DIKME_DER = KANAL_Y - 3 # dikmeler arkalığın önünde biter
    RAF_Z = Z0 + T + 240.0 # yan bölme raflarının alt yüzü (rafın altında 24 cm)
    RAF_W = 173.0
    RAF_DER = 430.0
    RAF_Y0 = 4.0
    PIM_R = 2.5
    PIM_Y = [RAF_Y0 + 40, RAF_Y0 + RAF_DER - 40].freeze
    CEK_Y = [70.0, 360.0].freeze # her birleşimde iki çektirme (toplam 16)
    AYAK_XY = [[60, 60], [W - 60, 60], [60, D - 70], [W - 60, D - 70]].freeze
    TABAN_T = 5.0        # ayak tabanı kalınlığı
    TABLA_VIDA = [106.0, W / 2, W - 106.0].product([90.0, 340.0]).freeze # üst tablanın altından, bölmelerin içinden
    KAPI_PAY = 2.0
    KAPI_Z0 = Z0 + 1
    KAPI_H = 538.0       # kapakların kenar yüksekliği (tablanın 2 mm altında biter)
    SARKMA = 50.0        # orta kapağın alt kavisi ortada 5 cm sarkar (orta yükseklik 58,8)
    # x0 sol kenar, gen genişlik, panel menteşe tabanının vidalandığı yüz, sx tabandan bölmeye,
    # eksen dönme ekseninin x'i (kapağın dış ön köşesi), yon -1 sola / +1 sağa açılır
    KAPI = {
      kapak_sol: { x0: 2.0, gen: 200.0, panel: T, sx: 1, eksen: 0.0, yon: -1, sarkma: 0.0 },
      kapak_orta: { x0: 205.0, gen: 530.0, panel: IC_X[:dikme_sag], sx: -1, eksen: 735.0, yon: 1, sarkma: SARKMA },
      kapak_sag: { x0: W - 202.0, gen: 200.0, panel: W - T, sx: -1, eksen: W, yon: 1, sarkma: 0.0 }
    }.freeze
    MENTESE_Z = [Z0 + 100, ZT - 100].freeze
    KAP_ZC = 4.5         # menteşe çerçevesinde kap merkezi (tam bini: kapak kenarından ~22 mm)
    KAP_ZC_YARIM = 15.0  # orta kapak dikmeyi yarım örter: kap yine kenardan ~22 mm
    PLAKA_T = 3.0

    DIKEY_FOV = 30.0
    VIDEO_FOV = 50.0

    DICT = 'ozcan_kurulum'
    SIRA = %i[alt_tabla sol_yan sag_yan dikme_sol dikme_sag arkalik ust_tabla tabla raf_sol raf_sag
              kapak_sol kapak_orta kapak_sag].freeze
    KAPILAR = %i[kapak_sol kapak_orta kapak_sag].freeze
    AD = {
      alt_tabla: 'Alt Tabla', sol_yan: 'Sol Yan', sag_yan: 'Sağ Yan', dikme_sol: 'Ara Dikme (sol)',
      dikme_sag: 'Ara Dikme (sağ)', arkalik: 'Arkalık', ust_tabla: 'Üst Tabla', tabla: 'Tabla (3,6 cm)',
      raf_sol: 'Sol Raf', raf_sag: 'Sağ Raf', kapak_sol: 'Sol Kapak', kapak_orta: 'Orta Kapak', kapak_sag: 'Sağ Kapak'
    }.freeze
    ETIKET = {
      alt_tabla: '01 Alt Tabla', sol_yan: '02 Sol Yan', sag_yan: '03 Sağ Yan', dikme_sol: '04 Ara Dikmeler',
      dikme_sag: '04 Ara Dikmeler', arkalik: '05 Arkalık', ust_tabla: '06 Üst Tabla', tabla: '07 Tabla',
      raf_sol: '08 Raflar', raf_sag: '08 Raflar', kapak_sol: '09 Kapaklar', kapak_orta: '09 Kapaklar',
      kapak_sag: '09 Kapaklar'
    }.freeze
    LISTE_TAG = '00 Parça Listesi'
    ARAC_TAG = '99 Tornavida'

    # Kamera noktaları [göz, hedef] (mm)
    KAM = {
      liste:   [[3000, -2900, 4700], [3000, 380, 0]],
      1 =>     [[1400, -1250, 420], [470, 225, 150]],
      2 =>     [[-600, -1500, 1100], [380, 225, 330]],
      3 =>     [[1550, -1500, 1100], [560, 225, 330]],
      4 =>     [[1350, -1650, 1250], [470, 225, 380]],
      5 =>     [[1700, 2300, 1500], [470, 300, 400]],
      6 =>     [[1500, -1800, 1600], [470, 225, 450]],
      7 =>     [[1500, -1800, 1750], [470, 225, 520]],
      :ic =>   [[760, -1250, 260], [470, 225, 560]],
      8 =>     [[1250, -1700, 1100], [470, 200, 400]],
      9 =>     [[1500, -1900, 1150], [470, 0, 400]],
      bitti:   [[1650, -2000, 1250], [470, 200, 380]]
    }.freeze

    # Parçaların yerleşim orijini (bileşen orijini = parçanın min köşesi)
    ORIJIN = {
      alt_tabla: [T, 0, Z0], sol_yan: [0, 0, Z0], sag_yan: [W - T, 0, Z0],
      dikme_sol: [IC_X[:dikme_sol], 0, Z0 + T], dikme_sag: [IC_X[:dikme_sag], 0, Z0 + T],
      arkalik: [T - KANAL_DER, KANAL_Y, Z0 + T - KANAL_DER], ust_tabla: [T, 0, ZT - T],
      tabla: [0, D - TABLA_DER, ZT],
      raf_sol: [T + 1.75, RAF_Y0, RAF_Z], raf_sag: [IC_X[:dikme_sag] + T + 1.75, RAF_Y0, RAF_Z]
    }.merge(KAPI.map { |k, h| [k, [h[:x0], -(KAPI_PAY + T), KAPI_Z0 - h[:sarkma]]] }.to_h).freeze

    AYAKLAR = %w[ayak_1 ayak_2 ayak_3 ayak_4].freeze
    TABLA_VIDALARI = (1..TABLA_VIDA.size).map { |i| "tabla_#{i}" }.freeze
    DEMONTE = (AYAKLAR + TABLA_VIDALARI).freeze

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
        govde: mk.('Mat Beyaz', [242, 242, 240]),
        on: mk.('Membran Beyaz', [248, 248, 246]),
        ayak: mk.('Siyah Ayak', [34, 34, 36]),
        gri: mk.('Ayak Tabanı', [90, 92, 96]),
        seffaf: mk.('Şeffaf Plastik', [205, 225, 238], 0.35),
        cinko: mk.('Çinko Kaplama', [160, 164, 170]),
        nikel: mk.('Nikel', [192, 196, 202]),
        pirinc: mk.('Pirinç Burç', [196, 158, 72]),
        celik: mk.('Çelik', [110, 113, 120]),
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
    def kap_tanimi(zc = KAP_ZC, ad = 'Menteşe Kabı Ø35')
      d = @m.definitions.add(ad)
      e = d.entities
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

    # --- Ayak: alt tablanın altına vidalı taban + çevrilerek takılan siyah konik ayak ---
    def ayak_taban_tanimi
      d = @m.definitions.add('Ayak Tabanı')
      torna(d.entities, [[0, 0], [0, 25], [TABAN_T - 0.6, 25], [TABAN_T, 24], [TABAN_T, 0]], 32, @mat[:gri])
      d
    end

    # Yerel +x yukarı: gövde x∈[-(AYAK_H - TABAN_T), 0] pahlı kare kesitli, aşağı doğru incelir;
    # üstte tabana giren M8 dişli mil.
    def ayak_tanimi
      d = @m.definitions.add('Siyah Konik Ayak')
      kesit = lambda do |x, a|
        c = a * 0.2
        [[a - c, a], [-(a - c), a], [-a, a - c], [-a, -(a - c)], [-(a - c), -a], [a - c, -a], [a, -(a - c)], [a, a - c]]
          .map { |y, z| Geom::Point3d.new(x.mm, y.mm, z.mm) }
      end
      ust = kesit.(0, 24)
      alt = kesit.(-(AYAK_H - TABAN_T), 16)
      mesh = Geom::PolygonMesh.new
      ust.size.times { |i| j = (i + 1) % ust.size; mesh.add_polygon(ust[i], alt[i], alt[j], ust[j]) }
      mesh.add_polygon(ust.reverse)
      mesh.add_polygon(alt)
      g = d.entities.add_group
      g.entities.add_faces_from_mesh(mesh, 0, @mat[:ayak], @mat[:ayak])
      torna(d.entities, [[0, 0], [0, 4], [12, 4], [12, 0]], 16, @mat[:celik])
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

    # Tüm çektirmeler dünya koordinatında: k = iç köşe noktası, ex/ey/ez bağlantı çerçevesi
    # (x erkeğin panelinden uzağa, z dişinin panelinden uzağa). Yanlar alt tablaya yandan kayar;
    # dikmeler alt tablaya yukarıdan iner (çektirmeleri yan bölmelerde); üst tabla yanlara ve
    # dikmelere yukarıdan iner (yanlarda erkek tablada, dikmelerde erkek dikmede).
    def baglantilar
      l = []
      [[:sol_yan, T, 1, 'sol'], [:sag_yan, W - T, -1, 'sag']].each do |yan, xs, sx, taraf|
        CEK_Y.zip(%w[on arka]).each do |y, yer|
          l << { id: "alt_#{taraf}_#{yer}", disi: :alt_tabla, erkek: yan, k: [xs, y, Z0 + T], ex: [sx, 0, 0], ez: [0, 0, 1] }
          l << { id: "ust_#{taraf}_#{yer}", disi: yan, erkek: :ust_tabla, k: [xs, y, ZT - T], ex: [0, 0, -1], ez: [sx, 0, 0] }
        end
      end
      [[:dikme_sol, IC_X[:dikme_sol], -1, 'sol'], [:dikme_sag, IC_X[:dikme_sag] + T, 1, 'sag']].each do |dk, xf, sx, taraf|
        CEK_Y.zip(%w[on arka]).each do |y, yer|
          l << { id: "icalt_#{taraf}_#{yer}", disi: :alt_tabla, erkek: dk, k: [xf, y, Z0 + T], ex: [sx, 0, 0], ez: [0, 0, 1] }
          l << { id: "icust_#{taraf}_#{yer}", disi: :ust_tabla, erkek: dk, k: [xf, y, ZT - T], ex: [sx, 0, 0], ez: [0, 0, -1] }
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

    # Menteşe çerçevesi: orijin kapak arka yüzü / yanın iç yüzü / menteşe yüksekliği;
    # x' menteşe ekseni (dikey), y' = +Y derinlik, z' yandan içeri.
    def mentese_cerceve(o, sx)
      Geom::Transformation.axes(P(*o), Geom::Vector3d.new(0, 0, -sx), Y_AXIS, Geom::Vector3d.new(sx, 0, 0))
    end

    # Arkalık kanalı: verilen yüzde boydan boya, arkalıktan 1 mm geniş, KANAL_DER derin.
    def kanal(e, nokta, v)
      it(e, [[KANAL_Y - 0.5, 0], [KANAL_Y + ARKA_T + 0.5, 0], [KANAL_Y + ARKA_T + 0.5, 1], [KANAL_Y - 0.5, 1]]
                .map { |y, s| nokta.(y, s) }, v, KANAL_DER)
    end

    # Dış yan: arkalık kanalı, çektirmeler, menteşe tabanları, raf pimleri.
    def dis_yan(k, sx)
      d = parca_tanimi(AD[k])
      e = d.entities
      h = ZT - Z0
      kutu(e, 0, 0, 0, T, D, h)
      xi = sx > 0 ? T : 0.0 # iç yüz
      kanal(e, ->(y, s) { P(xi, y, s * h) }, yon(-sx, 0, 0))
      boya(e, @mat[:govde])
      cektirmeler(e, k)
      MENTESE_Z.each { |hz| e.add_instance(@taban, mentese_cerceve([xi, -KAPI_PAY, hz - Z0], sx)) }
      PIM_Y.each { |y| e.add_instance(@pim, eksen([xi, y, RAF_Z - PIM_R - Z0], [sx, 0, 0], [0, 0, 1])) }
      [d, ORIJIN[k]]
    end

    def sol_yan; dis_yan(:sol_yan, 1); end
    def sag_yan; dis_yan(:sag_yan, -1); end

    # Alt tabla: üstte arkalık kanalı, altta ayak tabanları takılı; ayaklar demonte (çevrilerek takılır).
    def alt_tabla
      d = parca_tanimi(AD[:alt_tabla])
      e = d.entities
      gen = W - 2 * T
      kutu(e, 0, 0, 0, gen, D, T)
      kanal(e, ->(y, s) { P(s * gen, y, T) }, yon(0, 0, -1))
      boya(e, @mat[:govde])
      cektirmeler(e, :alt_tabla)
      AYAK_XY.each_with_index do |(x, y), i|
        e.add_instance(@ayak_taban, eksen([x - T, y, 0], [0, 0, -1], [1, 0, 0]))
        vida_koy(e, @ayak, eksen([x - T, y, -TABAN_T], [0, 0, 1], [1, 0, 0]), P(x - T, y, -TABAN_T),
                 Geom::Vector3d.new(0, 0, 1), 40.0, 0.0, Geom::Vector3d.new(0, 0, -1), AYAKLAR[i])
      end
      [d, ORIJIN[:alt_tabla]]
    end

    # Üst tabla: altta arkalık kanalı; tabla vidaları (demonte) içeriden, alttan girer.
    def ust_tabla
      d = parca_tanimi(AD[:ust_tabla])
      e = d.entities
      gen = W - 2 * T
      kutu(e, 0, 0, 0, gen, D, T)
      kanal(e, ->(y, s) { P(s * gen, y, 0) }, yon(0, 0, 1))
      boya(e, @mat[:govde])
      cektirmeler(e, :ust_tabla)
      TABLA_VIDA.each_with_index do |(x, y), i|
        o = [x - T, y, 0]
        vida_koy(e, @vida30, eksen(o, [0, 0, 1], [1, 0, 0]), P(*o), Geom::Vector3d.new(0, 0, 1), 30.0, 2.5,
                 Geom::Vector3d.new(0, 0, -1), TABLA_VIDALARI[i])
      end
      [d, ORIJIN[:ust_tabla]]
    end

    def tabla
      d = parca_tanimi(AD[:tabla])
      kutu(d.entities, 0, 0, 0, W, TABLA_DER, TABLA_T)
      boya(d.entities, @mat[:govde])
      [d, ORIJIN[:tabla]]
    end

    # 3 mm arkalık: yanların, alt ve üst tablanın kanalına 8 mm girer.
    def arkalik
      d = parca_tanimi(AD[:arkalik])
      kutu(d.entities, 0, 0, 0, W - 2 * T + 2 * KANAL_DER, ARKA_T, ZT - Z0 - 2 * T + 2 * KANAL_DER)
      boya(d.entities, @mat[:govde])
      [d, ORIJIN[:arkalik]]
    end

    # Ara dikme: yan bölme tarafında raf pimleri ve çektirme erkekleri; sağ dikmenin orta bölme
    # yüzünde orta kapağın menteşe tabanları.
    def dikme(k)
      d = parca_tanimi(AD[k])
      e = d.entities
      kutu(e, 0, 0, 0, T, DIKME_DER, ZT - Z0 - 2 * T)
      boya(e, @mat[:govde])
      sol = k == :dikme_sol
      xb = sol ? 0.0 : T # yan bölme tarafı
      PIM_Y.each { |y| e.add_instance(@pim, eksen([xb, y, RAF_Z - PIM_R - Z0 - T], [sol ? -1 : 1, 0, 0], [0, 0, 1])) }
      MENTESE_Z.each { |hz| e.add_instance(@taban, mentese_cerceve([0.0, -KAPI_PAY, hz - Z0 - T], -1)) } unless sol
      cektirmeler(e, k)
      [d, ORIJIN[k]]
    end

    def dikme_sol; dikme(:dikme_sol); end
    def dikme_sag; dikme(:dikme_sag); end

    def raf(k)
      d = parca_tanimi(AD[k])
      kutu(d.entities, 0, 0, 0, RAF_W, RAF_DER, T)
      boya(d.entities, @mat[:govde])
      [d, ORIJIN[k]]
    end

    def raf_sol; raf(:raf_sol); end
    def raf_sag; raf(:raf_sag); end

    # Kapak dış hattı (x, z): orta kapağın alt kenarı gen genişliğinde, ortada sar kadar sarkan yay.
    def kavis_r(gen, sar) (gen**2 / 4.0 + sar**2) / (2 * sar) end

    def kapak_hatti(gen, sar)
      ust = sar + KAPI_H
      return [[0, 0], [gen, 0], [gen, ust], [0, ust]] if sar <= 0
      r = kavis_r(gen, sar)
      (0..24).map { |i| x = gen * i / 24.0; [x, r - Math.sqrt(r * r - (x - gen / 2)**2)] } + [[gen, ust], [0, ust]]
    end

    # Oyma desen hattı: kenarlardan i içeride, üst köşeleri yuvarlak; kavisli kapakta alt kenar kavise paralel.
    def desen_hatti(gen, sar, i, r = 12.0)
      ust = sar + KAPI_H
      return yuvarlak_dik(i, i, gen - i, ust - i, r) if sar <= 0
      rr = kavis_r(gen, sar)
      alt = (0..20).map { |j| x = i + (gen - 2 * i) * j / 20.0; [x, rr - Math.sqrt((rr - i)**2 - (x - gen / 2)**2)] }
      kose = ->(cx, a0) { (0..6).map { |j| a = (a0 + 15 * j).degrees; [cx + r * Math.cos(a), ust - i - r + r * Math.sin(a)] } }
      alt + kose.(gen - i - r, 0) + kose.(i + r, 90)
    end

    # Ön yüzde iki hat arasında 2 mm derin yiv (membran kapağın oyma deseni).
    def yiv(e, dis, ic)
      e.add_face(dis.map { |x, z| P(x, 0, z) })
      e.add_face(ic.map { |x, z| P(x, 0, z) })
      halka = e.grep(Sketchup::Face).select { |f| f.loops.size == 2 && f.normal.parallel?(Y_AXIS) }.min_by(&:area)
      itme(halka, yon(0, 1, 0), 2)
    end

    # Membran kapak, kapak-yerel orijin = sol ön en alt köşe. Yan kapaklar dış yanlara tam bindirme;
    # orta kapak sağ dikmeye yarım bindirme menteşeli.
    def kapak(k)
      h = KAPI[k]
      d = parca_tanimi(AD[k])
      e = d.entities
      gen = h[:gen]
      sar = h[:sarkma]
      it(e, kapak_hatti(gen, sar).map { |x, z| P(x, 0, z) }, yon(0, 1, 0), T)
      ic = sar > 0 ? 60.0 : 45.0
      yiv(e, desen_hatti(gen, sar, ic), desen_hatti(gen, sar, ic + 12))
      sx = h[:sx]
      yarim = k == :kapak_orta
      zc = yarim ? KAP_ZC_YARIM : KAP_ZC
      xi = h[:panel] - h[:x0] # tabanın vidalandığı yüz, kapak-yerel
      z0 = KAPI_Z0 - sar
      hdler = MENTESE_Z.map { |hz| mentese_cerceve([xi, T, hz - z0], sx) }
      hdler.each { |hd| daire_it(e, P(0, 0, zc).transform(hd), Y_AXIS, 17.5, yon(0, -1, 0), 12.5, 32) }
      boya(e, @mat[:on])
      no = k.to_s.sub('kapak_', '')
      hdler.each_with_index do |hd, i|
        g = e.add_group
        g.name = 'Menteşe Gövdesi (büyük parça)'
        ge = g.entities
        ge.add_instance(yarim ? @kap_yarim : @kap, hd)
        kol = ge.add_instance(@kol, hd)
        nitelik(kol, kol: true, lc: hd.to_a)
        a = P(0, -4, zc - 7.5).transform(hd)
        b = P(0, 12, 14).transform(hd)
        bag = ge.add_instance(@bag, bar_tr(a, b))
        nitelik(bag, bar: true, a: a.to_a, b: b.to_a)
        lt = hd * eksen([0, 34, 8], [0, 0, -1], [1, 0, 0])
        zx = hd.zaxis # sabitleme vidası panelden dışarı bakar; tornavida önden 35° eğik gelir
        w = Geom::Vector3d.new(zx.x * Math.cos(35.degrees), -Math.sin(35.degrees), zx.z * Math.cos(35.degrees))
        vida_koy(ge, @mvida, lt, P(0, 34, 8).transform(hd), Geom::Vector3d.new(0, 0, -1).transform(hd), 4.0, 2.3, w,
                 "mentese_#{no}_#{i + 1}", true)
      end
      [d, ORIJIN[k]]
    end

    def kapak_sol; kapak(:kapak_sol); end
    def kapak_orta; kapak(:kapak_orta); end
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
      @m.start_operation('Vera Konsol kurulum modeli', true)
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
      @cvida = vida_tanimi('Çektirme Vidası (açılı)', 4, 2.5, 2.5, 14)
      @vida30 = vida_tanimi('Tabla Vidası 3.5x30', 3.8, 2.5, 1.75, 30)
      @disi = disi_tanimi
      @erkek = erkek_tanimi
      @pim = pim_tanimi
      @taban = taban_tanimi
      @kol = kol_tanimi
      @kap = kap_tanimi
      @kap_yarim = kap_tanimi(KAP_ZC_YARIM, 'Menteşe Kabı Ø35 (yarım bindirme)')
      @bag = bag_tanimi
      @ayak_taban = ayak_taban_tanimi
      @ayak = ayak_tanimi
      arac = tornavida_tanimi
      kisa = kisa_tornavida_tanimi

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
      [[arac, 'tornavida'], [kisa, 'kisa_tornavida']].each do |d, ad|
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
      "Kuruldu: #{SIRA.size} parça, #{@vidalar.size} animasyonlu vida/ayak, #{@m.pages.size} sahne"
    end

    # Kutu içeriği: paneller yere yatırılmış, fabrikada takılı hırdavat üstte; ayaklar ve tabla vidaları ayrı.
    def parca_listesi(tag)
      rx = ->(a) { Geom::Transformation.rotation(ORIGIN, X_AXIS, a.degrees) }
      ry = ->(a) { Geom::Transformation.rotation(ORIGIN, Y_AXIS, a.degrees) }
      rz = ->(a) { Geom::Transformation.rotation(ORIGIN, Z_AXIS, a.degrees) }
      bir = Geom::Transformation.new
      yerlesim = {
        sol_yan: [rz.(90) * ry.(-90), 1300, 0], sag_yan: [rz.(90) * ry.(90), 1950, 0],
        dikme_sol: [rz.(90) * ry.(90), 2600, 0], dikme_sag: [rz.(90) * ry.(-90), 3250, 0],
        arkalik: [rx.(-90), 3900, 0],
        alt_tabla: [bir, 1300, 750], ust_tabla: [rx.(180), 2400, 750], tabla: [bir, 3500, 750],
        raf_sol: [bir, 1300, 1450], raf_sag: [bir, 1700, 1450],
        kapak_sol: [rx.(90), 2150, 1450], kapak_orta: [rx.(90), 2600, 1450], kapak_sag: [rx.(90), 3400, 1450]
      }
      @m.entities.grep(Sketchup::ComponentInstance).select { |i| nit(i, :parca) && !%w[tornavida kisa_tornavida].include?(nit(i, :parca)) }.each do |ana|
        k = nit(ana, :parca).to_sym
        rot, x, y = yerlesim[k]
        b = Geom::BoundingBox.new # demonte parçalar (ayaklar, tabla vidaları) yerleşime katılmasın
        ana.definition.entities.each { |g| b.add(g.bounds) unless g.is_a?(Sketchup::ComponentInstance) && DEMONTE.include?(nit(g, :vida)) }
        bb = Geom::BoundingBox.new
        8.times { |c| bb.add(b.corner(c).transform(rot)) }
        kay = Geom::Transformation.translation(P(x, y, 0) - bb.min)
        i = @m.entities.add_instance(ana.definition, kay * rot)
        i.layer = tag
        on = Geom::Point3d.new(bb.center.x, bb.min.y, bb.max.z).transform(kay) # üst yüzün ön kenarı (görünür)
        txt = @m.entities.add_text(AD[k], on, Geom::Vector3d.new(0, -90.mm, 0))
        txt.layer = tag
      end
      AYAKLAR.each_index { |i| @m.entities.add_instance(@ayak, eksen([1300, -400 - i * 70, 24], [1, 0, 0], [0, 0, 1])).layer = tag }
      @m.entities.add_text("Ayak (#{AYAKLAR.size})", P(1300, -640, 0), Geom::Vector3d.new(0, -90.mm, 0)).layer = tag
      TABLA_VIDALARI.each_index { |i| @m.entities.add_instance(@vida30, eksen([2000, -400 - i * 35, 4], [1, 0, 0], [0, 0, 1])).layer = tag }
      @m.entities.add_text("Tabla Vidası 3.5x30 (#{TABLA_VIDALARI.size})", P(2010, -630, 0), Geom::Vector3d.new(0, -90.mm, 0)).layer = tag
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
        ['0 Kutu İçeriği', [], :liste, 'Paneller ve fabrikada takılı bağlantı elemanları; ayaklar ve tabla vidaları ayrı.'],
        ['1 Ayaklar', %i[alt_tabla], 1, 'Ayakları alt tablanın altındaki tabanlara çevirerek takın.'],
        ['2 Sol Yan', %i[sol_yan], 2, 'Sol yanı alt tabladaki 2 şeffaf çektirmeye geçirip vidaları sıkın.'],
        ['3 Sağ Yan', %i[sag_yan], 3, 'Sağ yanı aynı şekilde 2 çektirmeyle bağlayın.'],
        ['4 Ara Dikmeler', %i[dikme_sol dikme_sag], 4, 'Ara dikmeleri alt tabladaki çektirmelere oturtup alt vidaları sıkın.'],
        ['5 Arkalık', %i[arkalik], 5, 'Arkalığı yukarıdan yanların ve alt tablanın kanalına geçirerek indirin.'],
        ['6 Üst Tabla', %i[ust_tabla], 6, 'Üst tablayı yanların ve dikmelerin üstüne indirin; 8 çektirme vidasını sıkın.'],
        ['7 Tabla', %i[tabla], 7, 'Tablayı üste oturtun; içeriden, üst tablanın altından 6 vidayla bağlayın.'],
        ['8 Raflar', %i[raf_sol raf_sag], 8, 'Rafları raf pimlerinin üzerine yerleştirin.'],
        ['9 Kapaklar', KAPILAR, 9, 'Menteşe gövdelerini tabanlara geçirip vidaları sıkın; orta kapak sağ dikmeye takılır.'],
        ['10 Bitmiş Ürün', [], :bitti, 'Kurulum tamamlandı.']
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
      @arac = @kisa_arac = nil
      @m.entities.grep(Sketchup::ComponentInstance).each do |i|
        k = nit(i, :parca)
        next unless k
        if k == 'tornavida' then @arac = i
        elsif k == 'kisa_tornavida' then @kisa_arac = i
        else
          @parca[k.to_sym] = i
          @taban_tr[k.to_sym] = i.transformation
        end
      end
      raise 'Model bulunamadı — önce OzcanKurulum::VeraKonsol.kur' unless @parca.size == SIRA.size && @arac && @kisa_arac
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
      cizelge
      true
    end

    def vida_kaydi(i, parca, grup)
      { id: nit(i, :vida), inst: i, parca: parca, grup: grup,
        lt: Geom::Transformation.new(nit(i, :lt)), p: Geom::Point3d.new(*nit(i, :p)),
        d: Geom::Vector3d.new(*nit(i, :d)), strok: nit(i, :strok), bas_h: nit(i, :bas_h),
        w: Geom::Vector3d.new(*nit(i, :w)), kapi: nit(i, :kapi), kisa: nit(i, :kisa) }
    end

    # aci > 0 açık: kapak dış ön köşesindeki dikey eksende açılır (sol kapak sola, orta ve sağ kapak sağa).
    def kapi_R(k, aci)
      h = KAPI[k]
      Geom::Transformation.rotation(P(h[:eksen], -(KAPI_PAY + T), 0), Z_AXIS, h[:yon] * aci.degrees)
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

    def kapak_tak(k)
      z = @cz
      z.kamera(1.2, KAM[9])
      z.an { |s, _| s[:kapi][k] = 90.0 }
      hareket(k, [0, -420, 0], [0, 0, 0], 1.8)
      no = k.to_s.sub('kapak_', '')
      vida_sik("mentese_#{no}_1", nil, tur: 3, sure: 0.8)
      vida_sik("mentese_#{no}_2", nil, tur: 3, sure: 0.8, yakin: false)
      z.kamera(0.8, KAM[9])
      z.olay(1.4) { |s, u| s[:kapi][k] = 90.0 * (1 - u) }
    end

    def cizelge
      @cz = z = Cizelge.new
      z.an { |s, _| DEMONTE.each { |id| s[:v][id] = { gizli: true } } } # takılana kadar görünmesin
      z.baslik('Kutu içeriği — bağlantı elemanları panellere takılı gelir; ayaklar ve tabla vidaları ayrı')
      z.kamera(0, KAM[:liste])
      z.bekle(3.5)

      z.baslik('1 · Ayakları alt tablanın altındaki tabanlara çevirerek takın')
      z.an do |s, _|
        s[:liste] = false
        s[:p][:alt_tabla] = { vis: true, off: [0, 0, 150] }
        AYAKLAR.each { |id| s[:v][id] = { adv: 1.0, ang: 0.0 } }
      end
      z.kamera(1.2, KAM[1])
      z.olay(2.0, false) { |s, u| AYAKLAR.each { |id| s[:v][id] = { adv: 1 - u, ang: 360.0 * 6 * u } } }
      z.bekle(0.3)
      hareket(:alt_tabla, [0, 0, 150], [0, 0, 0], 0.7)
      z.bekle(0.3)

      z.baslik('2 · Sol yanı alt tabladaki iki şeffaf çektirmeye geçirin, vidaları sıkın')
      z.kamera(1.2, KAM[2])
      hareket(:sol_yan, [-500, 0, 0], [-2, 0, 0], 2.0)
      sirayla_sik(%w[on arka].map { |y| "alt_sol_#{y}" }, KAM[2], cekler: cek_listesi(:sol_yan, [-2, 0, 0], 2))
      z.kamera(0.8, KAM[2])
      z.bekle(0.3)

      z.baslik('3 · Sağ yanı aynı şekilde iki çektirmeyle bağlayın')
      z.kamera(1.2, KAM[3])
      hareket(:sag_yan, [500, 0, 0], [2, 0, 0], 2.0)
      sirayla_sik(%w[on arka].map { |y| "alt_sag_#{y}" }, KAM[3], cekler: cek_listesi(:sag_yan, [2, 0, 0], 2))
      z.kamera(0.8, KAM[3])
      z.bekle(0.3)

      z.baslik('4 · Ara dikmeleri alt tabladaki çektirmelere oturtun, alt vidaları sıkın')
      { dikme_sol: 'sol', dikme_sag: 'sag' }.each do |k, taraf|
        z.kamera(1.0, KAM[4])
        hareket(k, [0, 0, 450], [0, 0, 2], 1.6)
        ids = %w[on arka].map { |y| "icalt_#{taraf}_#{y}" }
        sirayla_sik(ids, KAM[4], cekler: cek_listesi(k, [0, 0, 2], ids.size))
      end
      z.kamera(0.8, KAM[4])
      z.bekle(0.3)

      z.baslik('5 · Arkalığı yukarıdan yanların ve alt tablanın kanalına geçirerek indirin')
      z.kamera(1.2, KAM[5])
      hareket(:arkalik, [0, 0, 650], [0, 0, 0], 2.4)
      z.bekle(0.4)

      z.baslik('6 · Üst tablayı yanların ve dikmelerin üstüne indirin, sekiz çektirme vidasını sıkın')
      z.kamera(1.2, KAM[6])
      hareket(:ust_tabla, [0, 0, 300], [0, 0, 2], 2.0)
      ids = %w[ust icust].flat_map { |a| %w[sol sag].flat_map { |t| %w[on arka].map { |y| "#{a}_#{t}_#{y}" } } }
      sirayla_sik(ids, KAM[6], cekler: cek_listesi(:ust_tabla, [0, 0, 2], ids.size))
      z.kamera(0.8, KAM[6])
      z.bekle(0.3)

      z.baslik('7 · Tablayı üste oturtun; içeriden, üst tablanın altından altı vidayla bağlayın')
      z.kamera(1.2, KAM[7])
      hareket(:tabla, [0, 0, 350], [0, 0, 0], 1.6)
      z.an { |s, _| TABLA_VIDALARI.each { |id| s[:v][id] = { adv: 1.0, ang: 0.0 } } }
      TABLA_VIDALARI.each_with_index do |id, i| # ilk vidaya önden-alttan bak, kalanları içeriden
        z.kamera(0.8, KAM[:ic]) if i == 1
        vida_sik(id, nil, tur: 5, sure: i.zero? ? 1.0 : 0.7, yakin: i.zero?, bak: [0.35, -0.9, -0.5])
      end
      z.kamera(0.8, KAM[7])
      z.bekle(0.3)

      z.baslik('8 · Rafları raf pimlerinin üzerine yerleştirin')
      z.kamera(1.2, KAM[8])
      %i[raf_sol raf_sag].each do |k|
        hareket(k, [0, -450, 40], [0, 0, 40], 1.2)
        hareket(k, [0, 0, 40], [0, 0, 0], 0.4)
      end
      z.bekle(0.3)

      z.baslik('9 · Kapakları takın: menteşe gövdelerini tabanlara geçirip vidaları sıkın (orta kapak sağ dikmeye)')
      KAPILAR.each { |k| kapak_tak(k) }
      z.bekle(0.3)

      z.baslik('Kurulum tamamlandı')
      z.kamera(1.6, KAM[:bitti])
      z.olay(1.3) { |s, u| KAPILAR.each { |k| s[:kapi][k] = 95.0 * u } }
      z.bekle(0.8)
      z.olay(1.3) { |s, u| KAPILAR.each { |k| s[:kapi][k] = 95.0 * (1 - u) } }
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

    # Montajlı son durum: tüm parçalar yerinde, vidalar ve ayaklar sıkılı, kapaklar kapalı.
    def son_durum
      s = ilk_durum
      SIRA.each { |k| s[:p][k] = { vis: true, off: [0, 0, 0] } }
      s[:v].each_key { |id| s[:v][id] = { adv: 0.0, ang: 0.0 } }
      s[:liste] = @liste_tag.visible?
      uygula(s)
      @arac.move!(Geom::Transformation.new)
      @kisa_arac.move!(Geom::Transformation.new)
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
    # Adımlar başlıkların sırasıdır: 0 kutu içeriği, 1-9 montaj, 10 bitmiş ürün.
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
