# encoding: UTF-8
# İki Kapaklı Dolap (69 x 65 x 34,5 cm; iki kapak, iki raf, ayarlı ayak) — kurulum kılavuzu modeli.
#
# Her panel ayrı bileşen; fabrikada takılı gelen parçalar (açılı vidalı şeffaf çektirme
# erkek/dişi, raf pimleri, menteşe tabanı, menteşe gövdesi, ayak tabanı) panelin içinde
# ayrı bileşen. Düğme kulp ve kulp vidası demonte gelir, en son takılır.
# Kurulum sırası kullanıcının anlattığı gibidir:
#   1 sol yan + arkalık  2 ayaklar + alt tabla  3 sağ yan  4 üst tabla  5 raflar
#   6 kapaklar  7 kulplar
#
# SketchUp > Pencere > Ruby Konsolu:
#   load 'C:/.../scripts/product-3d/kurulum/iki_kapakli_dolap.rb'
#   OzcanKurulum::IkiKapakliDolap.kur               # AÇIK MODELİ TEMİZLER, modeli sıfırdan kurar
#   OzcanKurulum::IkiKapakliDolap.oynat             # montaj animasyonunu ekranda oynatır
#   OzcanKurulum::IkiKapakliDolap.kumanda           # klavyeyle adım adım: → ← Enter Esc
#   (konsoldan: sonraki, onceki, durdur, devam, adim(3), git(3), bitir)
#   OzcanKurulum::IkiKapakliDolap.kaydet('C:/kareler') # animasyonu PNG karelere yazar
#
# Koordinatlar mm: X genişlik (0 = sol dış yüz), Y derinlik (0 = gövde ön yüzü, +Y arkaya;
# kapaklar Y<0'da), Z yükseklik (0 = zemin).

module OzcanKurulum
  module IkiKapakliDolap
    extend self

    # ------------------------------------------------------------------
    # Ölçüler (mm)
    # ------------------------------------------------------------------
    W = 690.0            # dış genişlik (üst tabla)
    T = 18.0             # panel kalınlığı
    IW = W - 2 * T       # iç genişlik (654)
    D = 325.0            # yan derinliği (+ 2 mm menteşe payı + 18 mm kapak = 345)
    AYAK_H = 50.0
    Z0 = AYAK_H          # gövdenin alt yüzü
    YAN_UST = 632.0      # yanların üst kotu = üst tablanın alt yüzü (gövde 60 cm)
    ZT = YAN_UST + T     # toplam yükseklik 650
    KANAL_Y0 = D - 14.0  # arkalık kanalı: 4 mm geniş, 8 mm derin, arka kenardan 10 mm içeride
    KANAL_Y1 = D - 10.0
    KANAL_DER = 8.0
    ARKA_T = 3.0
    PIM_R = 2.5
    RAF_PIM_Z = [241.5, 435.5] # iç yükseklik eşit üç bölme (~17,6 cm raflar arası)
    PIM_Y = [52.0, 272.0]
    RAF_Y0 = 15.0
    CEKTIRME_Y = [55.0, 265.0]
    KAPI_PAY = 2.0       # kapak arka yüzü ile gövde ön yüzü arası
    KAPI_W = (W - 3) / 2 # iki tam bindirme kapak, ortada 3 mm boşluk
    KAPI_Z = [Z0, YAN_UST - 3] # kapak alt / üst kenarı (üst tablanın 3 mm altı)
    MENTESE_Z = [Z0 + 90, YAN_UST - 3 - 90].freeze
    KAP_ZC = 4.5         # menteşe çerçevesinde kap merkezi (kapak kenarından 22,5 mm)
    KULP = [40.0, 43.0]  # düğme kulp: kapağın iç kenarından ve üst kenarından
    AYAK_XY = [[55, 45], [635, 45], [55, 280], [635, 280]]
    PLAKA_T = 3.0

    DIKEY_FOV = 30.0
    VIDEO_FOV = 50.0

    DICT = 'ozcan_kurulum'
    SIRA = %i[sol_yan arkalik alt_tabla sag_yan ust_tabla raf_1 raf_2 kapak_sol kapak_sag].freeze
    KAPILAR = %i[kapak_sol kapak_sag].freeze
    ETIKET = {
      sol_yan: '01 Sol Yan', arkalik: '02 Arkalık', alt_tabla: '03 Alt Tabla',
      sag_yan: '04 Sağ Yan', ust_tabla: '05 Üst Tabla', raf_1: '06 Raflar', raf_2: '06 Raflar',
      kapak_sol: '07 Sol Kapak', kapak_sag: '08 Sağ Kapak'
    }.freeze
    AD = {
      sol_yan: 'Sol Yan', arkalik: 'Arkalık', alt_tabla: 'Alt Tabla', sag_yan: 'Sağ Yan',
      ust_tabla: 'Üst Tabla', raf_1: 'Raf', raf_2: 'Raf', kapak_sol: 'Sol Kapak', kapak_sag: 'Sağ Kapak'
    }.freeze
    LISTE_TAG = '00 Parça Listesi'
    ARAC_TAG = '99 Tornavida'

    # Kamera noktaları [göz, hedef] (mm)
    KAM = {
      liste:  [[3060, -3900, 3600], [3060, -150, 0]],
      1 =>    [[1665, -1568, 1348], [345, 160, 340]],
      2 =>    [[1350, -1150, 900], [420, 160, 120]],
      3 =>    [[-975, -1568, 1348], [345, 160, 340]],
      4 =>    [[1445, -1280, 1360], [345, 160, 520]],
      5 =>    [[1445, -1280, 1180], [345, 160, 340]],
      :"6a" => [[1460, -1684, 1264], [250, -100, 340]],
      :"6b" => [[-770, -1684, 1264], [440, -100, 340]],
      :"7a" => [[-900, -1500, 1100], [60, -330, 560]],
      :"7b" => [[1590, -1500, 1100], [630, -330, 560]],
      bitti:  [[1600, -1900, 1300], [345, 120, 320]]
    }.freeze

    # Parçaların yerleşim orijini (bileşen orijini = parçanın min köşesi)
    ORIJIN = {
      sol_yan: [0, 0, Z0], sag_yan: [W - T, 0, Z0], alt_tabla: [T, 0, Z0],
      ust_tabla: [0, -(KAPI_PAY + T), YAN_UST],
      arkalik: [T - KANAL_DER + 0.5, KANAL_Y0 + 0.5, Z0 + T - KANAL_DER + 0.5],
      raf_1: [T + 1, RAF_Y0, RAF_PIM_Z[0] + PIM_R], raf_2: [T + 1, RAF_Y0, RAF_PIM_Z[1] + PIM_R],
      kapak_sol: [0, -(KAPI_PAY + T), Z0], kapak_sag: [W - KAPI_W, -(KAPI_PAY + T), Z0]
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
        govde: mk.('Meşe Melamin', [198, 162, 112]),
        ic_beyaz: mk.('Arkalık İç Yüz', [238, 236, 230]),
        hdf: mk.('Arkalık HDF (kahve)', [172, 128, 84]),
        seffaf: mk.('Şeffaf Plastik', [205, 225, 238], 0.35),
        cinko: mk.('Çinko Kaplama', [160, 164, 170]),
        nikel: mk.('Nikel', [192, 196, 202]),
        pirinc: mk.('Pirinç Burç', [196, 158, 72]),
        krom: mk.('Krom', [214, 217, 222]),
        kaucuk: mk.('Kauçuk', [45, 45, 48]),
        gri: mk.('Gri Plastik', [150, 152, 156]),
        yuva: mk.('Vida Yuvası', [40, 40, 44]),
        kulp: mk.('Siyah Kulp', [28, 28, 30]),
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

    # --- Şeffaf çektirme (açılı vidalı, iki parça) ---
    # İki yarım da "bağlantı çerçevesinde" çizilir: orijin iki panelin iç köşe
    # çizgisinde; y = köşe çizgisi boyunca, x = erkeğin panelinden uzağa (dişinin
    # paneli üzerinde), z = dişinin panelinden uzağa (erkeğin paneli üzerinde).
    # Erkek x=0 panelinde pahlı bir blok taşır. Dişi z=0 panelinde C kesitli bir kanal
    # taşır; kanal erkeğin paneline ve iki ucuna açıktır, yani erkek bloğu yandan,
    # yukarıdan ya da önden kayarak girer: dişi erkeğe geçer. Metal vida kanalın pahlı
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
      kesit = [[15.5, 3], [23, 3], [23, 17], [15, 25], [3.5, 25], [3.5, 17.5], [15.5, 17.5]]
      it(g.entities, kesit.map { |x, z| P(x, -11, z) }, yon(0, 1, 0), 22)
      daire_it(g.entities, P(19, 0, 21), Geom::Vector3d.new(1, 0, 1), 4.5, yon(-1, 0, -1), 1.5, 20)
      boya(g.entities, @mat[:seffaf])
      delik.each { |x, y, _| e.add_instance(@vida16h, eksen([x, y, -0.7], [0, 0, -1], [1, 0, 0])) }
      d
    end

    # --- Ayak: tabla altına vidalı taban + çevrilerek takılan krom ayak ---
    def ayak_taban_tanimi
      d = @m.definitions.add('Ayak Tabanı')
      torna(d.entities, [[0, 0], [0, 22], [4, 22], [5, 20], [5, 10], [11, 9], [11, 0]], 32, @mat[:gri])
      d
    end

    # Yerel +x yukarı; gövde x∈[-39, 0], üstte tabana giren M8 dişli mil.
    def ayak_tanimi
      d = @m.definitions.add('Ayarlı Ayak')
      torna(d.entities, [[-37, 0], [-37, 13], [-35, 14.5], [-3, 15], [0, 14], [0, 4], [18, 4], [18, 0]], 32, @mat[:krom])
      torna(d.entities, [[-39, 0], [-39, 12.5], [-37, 13], [-37, 0]], 32, @mat[:kaucuk])
      yildiz(d.entities, -39.05, 6) # dönüşü göstermek için alt yüzde iz
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

    # Siyah düğme kulp; yerel +x kapaktan dışarı. Arkadan kulp vidasıyla tutturulur.
    def kulp_tanimi
      d = @m.definitions.add('Düğme Kulp')
      torna(d.entities, [[0, 0], [0, 8], [5, 7.5], [9, 12], [13, 15], [19, 15], [22, 13], [24, 9], [24, 0]],
            32, @mat[:kulp])
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

    def parca_tanimi(ad)
      @m.definitions.add(ad)
    end

    # Tüm çektirmeler dünya koordinatında: k = iç köşe noktası, ex/ez bağlantı
    # çerçevesinin eksenleri (yukarıdaki tanıma göre). Alt tablada dişi tablada, erkek
    # yanda; üst tabla yukarıdan indiği için orada dişi yanda (kanal üst tablaya açık).
    def baglantilar
      l = []
      [[:sol_yan, T, 1, 'sol'], [:sag_yan, W - T, -1, 'sag']].each do |yan, xs, sx, taraf|
        CEKTIRME_Y.each_with_index do |y, i|
          yer = i.zero? ? 'on' : 'arka'
          l << { id: "alt_#{taraf}_#{yer}", disi: :alt_tabla, erkek: yan, k: [xs, y, Z0 + T], ex: [sx, 0, 0], ez: [0, 0, 1] }
          l << { id: "ust_#{taraf}_#{yer}", disi: yan, erkek: :ust_tabla, k: [xs, y, YAN_UST], ex: [0, 0, -1], ez: [sx, 0, 0] }
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
        j = ters * cerceve(b[:k], b[:ex], [0, 1, 0], b[:ez])
        e.add_instance(@erkek, j) if b[:erkek] == parca
        next unless b[:disi] == parca
        e.add_instance(@disi, j)
        lt = j * eksen(VIDA_OTURMA, VIDA_YON, [0, 1, 0])
        d = Geom::Vector3d.new(*VIDA_YON).transform(j).normalize
        w = Geom::Vector3d.new(-d.x, -d.y, -d.z)
        vida_koy(e, @cvida, lt, P(*VIDA_OTURMA).transform(j), d, 9.0, 2.5, w, b[:id])
      end
    end

    # Menteşe çerçevesi: orijin kapak arka yüzü / yanın iç yüzü / menteşe yüksekliği;
    # x' menteşe ekseni (dikey), y' = +Y derinlik, z' yandan içeri (sol yanda +X, sağda -X).
    def mentese_cerceve(o, sx)
      Geom::Transformation.axes(P(*o), Geom::Vector3d.new(0, 0, -sx), Y_AXIS, Geom::Vector3d.new(sx, 0, 0))
    end

    def yan(ad, x_ic, sx)
      d = parca_tanimi(ad)
      e = d.entities
      h = YAN_UST - Z0
      kutu(e, 0, 0, 0, T, D, h)
      it(e, [P(x_ic, KANAL_Y0, 0), P(x_ic, KANAL_Y1, 0), P(x_ic, KANAL_Y1, h), P(x_ic, KANAL_Y0, h)],
         yon(-sx, 0, 0), KANAL_DER)
      boya(e, @mat[:govde])
      e
    end

    def sol_yan
      e = yan('Sol Yan', T, 1)
      cektirmeler(e, :sol_yan)
      RAF_PIM_Z.product(PIM_Y).each { |z, y| e.add_instance(@pim, eksen([T, y, z - Z0], [1, 0, 0], [0, 0, 1])) }
      MENTESE_Z.each { |hz| e.add_instance(@taban, mentese_cerceve([T, -KAPI_PAY, hz - Z0], 1)) }
      [e.parent, ORIJIN[:sol_yan]]
    end

    def sag_yan
      e = yan('Sağ Yan', 0, -1)
      cektirmeler(e, :sag_yan)
      RAF_PIM_Z.product(PIM_Y).each { |z, y| e.add_instance(@pim, eksen([0, y, z - Z0], [-1, 0, 0], [0, 0, 1])) }
      MENTESE_Z.each { |hz| e.add_instance(@taban, mentese_cerceve([0, -KAPI_PAY, hz - Z0], -1)) }
      [e.parent, ORIJIN[:sag_yan]]
    end

    def arkalik
      d = parca_tanimi('Arkalık')
      bh = (YAN_UST + KANAL_DER - 0.5) - ORIJIN[:arkalik][2]
      kutu(d.entities, 0, 0, 0, IW + 2 * KANAL_DER - 1, ARKA_T, bh)
      boya(d.entities, @mat[:ic_beyaz])
      d.entities.grep(Sketchup::Face).each { |f| f.material = f.back_material = @mat[:hdf] if f.normal.y > 0.5 }
      [d, ORIJIN[:arkalik]]
    end

    def alt_tabla
      d = parca_tanimi('Alt Tabla')
      e = d.entities
      kutu(e, 0, 0, 0, IW, D, T)
      it(e, [P(0, KANAL_Y0, T), P(IW, KANAL_Y0, T), P(IW, KANAL_Y1, T), P(0, KANAL_Y1, T)], yon(0, 0, -1), KANAL_DER)
      boya(e, @mat[:govde])
      cektirmeler(e, :alt_tabla)
      AYAK_XY.each_with_index do |(x, y), i|
        e.add_instance(@ayak_taban, eksen([x - T, y, 0], [0, 0, -1], [1, 0, 0]))
        lt = eksen([x - T, y, -11], [0, 0, 1], [1, 0, 0])
        vida_koy(e, @ayak, lt, P(x - T, y, -11), Geom::Vector3d.new(0, 0, 1), 40.0, 0.0,
                 Geom::Vector3d.new(0, 0, -1), "ayak_#{i + 1}")
      end
      [d, ORIJIN[:alt_tabla]]
    end

    # Üst tabla yanların üstüne oturur, tam genişlikte ve kapakları da örter.
    def ust_tabla
      d = parca_tanimi('Üst Tabla')
      e = d.entities
      oy = KAPI_PAY + T
      kutu(e, 0, 0, 0, W, D + oy, T)
      it(e, [P(0, KANAL_Y0 + oy, 0), P(W, KANAL_Y0 + oy, 0), P(W, KANAL_Y1 + oy, 0), P(0, KANAL_Y1 + oy, 0)],
         yon(0, 0, 1), KANAL_DER)
      boya(e, @mat[:govde])
      cektirmeler(e, :ust_tabla)
      [d, ORIJIN[:ust_tabla]]
    end

    # İki raf aynı bileşen
    def raf(k)
      unless @raf_tanim
        @raf_tanim = parca_tanimi('Raf')
        kutu(@raf_tanim.entities, 0, 0, 0, IW - 2, KANAL_Y0 - 2 - RAF_Y0, T)
        boya(@raf_tanim.entities, @mat[:govde])
      end
      [@raf_tanim, ORIJIN[k]]
    end

    def raf_1; raf(:raf_1); end
    def raf_2; raf(:raf_2); end

    def bar_tr(a, b)
      v = b - a
      x = v.normalize
      y = Geom::Vector3d.new(1, 0, 0)
      Geom::Transformation.axes(a, x, y, x * y) * Geom::Transformation.scaling(ORIGIN, v.length / 10.mm, 1, 1)
    end

    # Kapaklar: sol kapağın menteşeleri sol yanda, sağınki sağ yanda. Düğme kulp iç
    # üst köşede; demonte gelir (kulp önde, kulp vidası arkada bekler, 7. adımda takılır).
    # Kapak-yerel orijin = kapağın sol ön alt köşesi.
    def kapak(k, ad)
      sol = k == :kapak_sol
      x0 = ORIJIN[k][0]
      h = KAPI_Z[1] - KAPI_Z[0]
      d = parca_tanimi(ad)
      e = d.entities
      kutu(e, 0, 0, 0, KAPI_W, T, h)
      xs = sol ? T : W - T # menteşenin bağlandığı yanın iç yüzü (dünya X)
      sx = sol ? 1 : -1
      MENTESE_Z.each { |hz| daire_it(e, P(xs + sx * KAP_ZC - x0, T, hz - Z0), Y_AXIS, 17.5, yon(0, -1, 0), 12.5, 32) }
      boya(e, @mat[:govde])
      taraf = sol ? 'sol' : 'sag'
      MENTESE_Z.each_with_index do |hz, i|
        g = e.add_group
        g.name = 'Menteşe Gövdesi (büyük parça)'
        ge = g.entities
        hd = mentese_cerceve([xs - x0, T, hz - Z0], sx)
        ge.add_instance(@kap, hd)
        kol = ge.add_instance(@kol, hd)
        nitelik(kol, kol: true, lc: hd.to_a)
        a = P(0, -4, KAP_ZC - 7.5).transform(hd)
        b = P(0, 12, 14).transform(hd)
        bag = ge.add_instance(@bag, bar_tr(a, b))
        nitelik(bag, bar: true, a: a.to_a, b: b.to_a)
        lt = hd * eksen([0, 34, 8], [0, 0, -1], [1, 0, 0])
        w = Geom::Vector3d.new(sx * Math.cos(35.degrees), -Math.sin(35.degrees), 0)
        vida_koy(ge, @mvida, lt, P(0, 34, 8).transform(hd), Geom::Vector3d.new(-sx, 0, 0), 4.0, 2.3, w,
                 "mentese_#{taraf}_#{i + 1}", true)
      end
      kx = sol ? KAPI_W - KULP[0] : KULP[0]
      kz = h - KULP[1]
      vida_koy(e, @kulp, eksen([kx, 0, kz], [0, -1, 0], [0, 0, 1]), P(kx, 0, kz), Geom::Vector3d.new(0, 1, 0),
               60.0, 0.0, Geom::Vector3d.new(0, -1, 0), "kulp_#{taraf}")
      # kulp vidası arkadan; tornavida kapağın serbest kenarına doğru eğik gelir (w kapak-yerel)
      vida_koy(e, @kvida, eksen([kx, T, kz], [0, -1, 0], [0, 0, 1]), P(kx, T, kz), Geom::Vector3d.new(0, -1, 0),
               25.0, 2.3, Geom::Vector3d.new(sol ? 0.64 : -0.64, 0.77, 0), "kulpvida_#{taraf}")
      [d, ORIJIN[k]]
    end

    def kapak_sol
      kapak(:kapak_sol, 'Sol Kapak')
    end

    def kapak_sag
      kapak(:kapak_sag, 'Sağ Kapak')
    end

    # ------------------------------------------------------------------
    # Model kurulumu
    # ------------------------------------------------------------------
    def kur(kayit_yolu = nil)
      @m = Sketchup.active_model
      @m.start_operation('İki kapaklı dolap kurulum modeli', true)
      @m.entities.clear!
      @m.pages.to_a.each { |p| @m.pages.erase(p) }
      @m.definitions.purge_unused
      @m.materials.purge_unused
      @m.layers.purge_unused
      malzemeler
      @raf_tanim = nil

      @vida16 = vida_tanimi('Sunta Vidası 3.5x16', 3.8, 2.5, 1.75, 16)
      @vida16h = havsa_vida_tanimi
      @tvida = vida_tanimi('Taban Vidası M4', 3.5, 2.2, 2, 9)
      @mvida = vida_tanimi('Menteşe Sabitleme Vidası', 3.8, 2.3, 2, 4)
      @cvida = vida_tanimi('Çektirme Vidası (açılı)', 4, 2.5, 2.5, 14)
      @kvida = vida_tanimi('Kulp Vidası M4x25', 3.8, 2.3, 2, 25)
      @disi = disi_tanimi
      @erkek = erkek_tanimi
      @ayak_taban = ayak_taban_tanimi
      @ayak = ayak_tanimi
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
      "Kuruldu: #{SIRA.size} parça, #{@vidalar.size} animasyonlu vida/ayak/kulp, #{@m.pages.size} sahne"
    end

    # Kutu içeriği: paneller yere yatırılmış, fabrikada takılı hırdavat üstte.
    def parca_listesi(tag)
      rx = ->(a) { Geom::Transformation.rotation(ORIGIN, X_AXIS, a.degrees) }
      ry = ->(a) { Geom::Transformation.rotation(ORIGIN, Y_AXIS, a.degrees) }
      bir = Geom::Transformation.new
      yerlesim = {
        sol_yan: [ry.(-90), 1400, 0], sag_yan: [ry.(90), 2100, 0], arkalik: [rx.(90), 2800, 0],
        kapak_sol: [rx.(90), 3600, 0], kapak_sag: [rx.(90), 4050, 0],
        alt_tabla: [bir, 1400, -800], ust_tabla: [rx.(180), 2200, -800],
        raf_1: [bir, 3050, -800], raf_2: [bir, 3800, -800]
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
        txt = @m.entities.add_text(AD[k], on, Geom::Vector3d.new(0, -90.mm, 0))
        txt.layer = tag
      end
      # demonte gelenler: 2 düğme kulp, 2 kulp vidası
      [[@kulp, [4600, 150, 0], [0, 0, 1], [1, 0, 0], 'Düğme Kulp (2)'], [@kulp, [4680, 150, 0], [0, 0, 1], [1, 0, 0], nil],
       [@kvida, [4600, -80, 4], [1, 0, 0], [0, 0, 1], 'Kulp Vidası (2)'], [@kvida, [4600, -120, 4], [1, 0, 0], [0, 0, 1], nil]]
        .each do |defn, o, x, z, ad|
          @m.entities.add_instance(defn, eksen(o, x, z)).layer = tag
          next unless ad
          @m.entities.add_text(ad, P(o[0], o[1] - 30, 0), Geom::Vector3d.new(0, -90.mm, 0)).layer = tag
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
        ['0 Kutu İçeriği', [], :liste, 'Paneller ve fabrikada takılı bağlantı elemanları; kulplar demonte.'],
        ['1 Sol Yan + Arkalık', %i[sol_yan arkalik], 1, 'Arkalığı sol yan panelin kanalına geçirin.'],
        ['2 Ayaklar + Alt Tabla', %i[alt_tabla], 2, 'Ayakları alt tablaya çevirerek takın; alt tablayı arkalığa ve sol yandaki çektirmelere geçirip açılı vidaları sıkın.'],
        ['3 Sağ Yan', %i[sag_yan], 3, 'Sağ yanı arkalık kanalına ve alt tabladaki çektirmelere geçirin; vidaları sıkın.'],
        ['4 Üst Tabla', %i[ust_tabla], 4, 'Üst tablayı arkalığa ve iki yandaki çektirmelere oturtun; vidaları sıkın.'],
        ['5 Raflar', %i[raf_1 raf_2], 5, 'Rafları raf pimlerinin üzerine yerleştirin.'],
        ['6 Kapaklar', KAPILAR, :"6a", 'Kapaktaki menteşe gövdelerini yandaki tabanlara geçirin; ortadaki vidaları sıkın.'],
        ['7 Kulplar', [], :"7a", 'Düğme kulpları kapağın önüne koyup arkadan kulp vidasıyla sıkın.'],
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
      raise 'Model bulunamadı — önce OzcanKurulum::IkiKapakliDolap.kur' unless @parca.size == SIRA.size && @arac
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
      # Aynı tanımı paylaşan rafların içinde vida yok; alt tablanın vidaları tek kez sayılsın
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
        w: Geom::Vector3d.new(*nit(i, :w)), kapi: nit(i, :kapi) }
    end

    # Kapaklar dış ön köşedeki dikey eksen etrafında açılır (aci > 0 açık): sol kapak
    # sol ön köşede, sağ kapak sağ ön köşede döner.
    def kapi_R(k, aci)
      sol = k == :kapak_sol
      Geom::Transformation.rotation(P(sol ? 0 : W, -(KAPI_PAY + T), 0), Z_AXIS, (sol ? -aci : aci).degrees)
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

    AYAKLAR = %w[ayak_1 ayak_2 ayak_3 ayak_4].freeze

    def kapak_tak(k, kam)
      z = @cz
      z.kamera(1.2, KAM[kam])
      z.an { |s, _| s[:kapi][k] = 90.0 }
      hareket(k, [0, -420, 0], [0, 0, 0], 1.8)
      no = k == :kapak_sol ? 'sol' : 'sag'
      vida_sik("mentese_#{no}_1", nil, tur: 3, sure: 0.8)
      vida_sik("mentese_#{no}_2", nil, tur: 3, sure: 0.8)
      z.olay(1.4) { |s, u| s[:kapi][k] = 90.0 * (1 - u) }
    end

    # Kapak açılır, kulp önden oturur, kulp vidası arkadan gelip sıkılır, kapak kapanır.
    def kulp_tak(k, kam)
      z = @cz
      no = k == :kapak_sol ? 'sol' : 'sag'
      z.kamera(1.2, KAM[kam])
      z.olay(1.0) { |s, u| s[:kapi][k] = 90.0 * u }
      z.olay(0.8) { |s, u| s[:v]["kulp_#{no}"] = { adv: 3.0 * (1 - u), ang: 0.0 } }
      z.olay(0.6) { |s, u| s[:v]["kulpvida_#{no}"] = { adv: 4.0 - 3.0 * u, ang: 0.0 } }
      vida_sik("kulpvida_#{no}", nil, tur: 4, sure: 1.0)
      z.olay(1.0) { |s, u| s[:kapi][k] = 90.0 * (1 - u) }
    end

    def cizelge
      @cz = z = Cizelge.new
      # demonte kulp ve vidaları takılana kadar görünmesin
      z.an do |s, _|
        %w[sol sag].each { |n| s[:v]["kulp_#{n}"] = { gizli: true }; s[:v]["kulpvida_#{n}"] = { gizli: true } }
      end
      z.baslik('Kutu içeriği — bağlantı elemanları panellere takılı gelir, kulplar ayrı')
      z.kamera(0, KAM[:liste])
      z.bekle(3.5)

      z.baslik('1 · Arkalığı sol yan panelin kanalına geçirin')
      z.an { |s, _| s[:liste] = false; s[:p][:sol_yan][:vis] = true }
      z.kamera(1.2, KAM[1])
      hareket(:arkalik, [500, 0, 0], [0, 0, 0], 2.2)
      z.bekle(0.4)

      z.baslik('2 · Ayakları alt tablaya çevirerek takın, alt tablayı arkalığa ve sol yana geçirip vidaları sıkın')
      z.kamera(1.2, KAM[2])
      z.an { |s, _| s[:p][:alt_tabla] = { vis: true, off: [400, 0, 0] } }
      z.olay(1.8, false) { |s, u| AYAKLAR.each { |id| s[:v][id] = { adv: 1 - u, ang: 360.0 * 6 * u } } }
      hareket(:alt_tabla, [400, 0, 0], [2, 0, 0], 2.0)
      vida_sik('alt_sol_on', [:alt_tabla, [2, 0, 0], [1, 0, 0]])
      vida_sik('alt_sol_arka', [:alt_tabla, [1, 0, 0], [0, 0, 0]])
      z.bekle(0.3)

      z.baslik('3 · Sağ yanı arkalık kanalına ve alt tabladaki çektirmelere geçirin, vidaları sıkın')
      z.kamera(1.2, KAM[3])
      hareket(:sag_yan, [450, 0, 0], [2, 0, 0], 2.0)
      vida_sik('alt_sag_on', [:sag_yan, [2, 0, 0], [1, 0, 0]])
      vida_sik('alt_sag_arka', [:sag_yan, [1, 0, 0], [0, 0, 0]])
      z.bekle(0.3)

      z.baslik('4 · Üst tablayı arkalığa ve çektirmelere oturtun, vidaları sıkın')
      z.kamera(1.2, KAM[4])
      z.olay(1.4, false) do |s, u|
        s[:p][:ust_tabla][:vis] = true
        s[:p][:ust_tabla][:off] = [0, 0, 350 * (1 - u * u)]
      end
      %w[ust_sol_on ust_sol_arka ust_sag_on ust_sag_arka].each { |id| vida_sik(id, nil, tur: 3, sure: 0.8) }
      z.bekle(0.3)

      z.baslik('5 · Rafları raf pimlerinin üzerine yerleştirin')
      z.kamera(1.0, KAM[5])
      %i[raf_1 raf_2].each do |k|
        hareket(k, [0, -450, 40], [0, 0, 40], 1.1)
        hareket(k, [0, 0, 40], [0, 0, 0], 0.4)
      end
      z.bekle(0.3)

      z.baslik('6 · Kapakları menteşe tabanlarına geçirin, ortadaki vidaları sıkın')
      kapak_tak(:kapak_sol, :"6a")
      kapak_tak(:kapak_sag, :"6b")
      z.bekle(0.3)

      z.baslik('7 · Düğme kulpları önden koyup arkadan kulp vidasıyla sıkın')
      kulp_tak(:kapak_sol, :"7a")
      kulp_tak(:kapak_sag, :"7b")
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
      rinv = KAPILAR.map do |k|
        c = @taban_tr[k]
        [k, c.inverse * kapi_R(k, s[:kapi][k]).inverse * c]
      end.to_h
      SIRA.each do |k|
        st = s[:p][k]
        off = st[:vis] ? st[:off] : UZAK
        t = tr(*off)
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
      drv = s[:drv]
      if drv
        v = @vidalar.find { |x| x[:id] == drv[:id] }
        dunya = @parca[v[:parca]].transformation
        dunya *= v[:grup].transformation if v[:grup]
        dunya *= v[:inst].transformation
        bas = Geom::Point3d.new(-v[:bas_h].mm, 0, 0).transform(dunya)
        # menteşe vidalarının ekseni dünyada sabit; diğerleri parçayla birlikte döner
        w = v[:kapi] ? v[:w] : v[:w].transform(@parca[v[:parca]].transformation).normalize
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
      @simdi = t
      uygula(durum(t))
      kamera_uygula(t)
      durum_yazisi
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
      ek = oynuyor? ? '' : '   (durdu — → sonraki adım, ← önceki, Enter devam, Esc bitir)'
      Sketchup.status_text = "#{baslik_at(@simdi)}#{ek}"
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
        Sketchup.status_text = 'Kurulum: → sonraki adım · ← önceki adım · Enter durdur/devam · Esc bitir'
      end

      def onKeyDown(key, _repeat, _flags, _view)
        case key
        when VK_RIGHT then @mod.sonraki
        when VK_LEFT then @mod.onceki
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
