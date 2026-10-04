# encoding: UTF-8
# Fırın Mikrodalga Dolabı (60 x 180 x 62 cm) — kurulum kılavuzu modeli.
# Alttan üste: 5 cm ayak, alt bölme (25 cm klapa kapak), fırın boşluğu (59 cm),
# mikrodalga boşluğu (36,4 cm), üst bölme (51 cm yana açılan kapak, içinde pimli raf).
#
# Her panel ayrı bileşen; fabrikada takılı gelen parçalar (açılı vidalı şeffaf çektirme
# erkek/dişi, raf pimleri, rafix pimleri, gömme rafix'ler, menteşe tabanı ve gövdesi,
# ayak tabanı) panelin içinde ayrı bileşen. Kulplar, kulp vidaları ve arkalık çivileri
# demonte gelir. Kurulum sırası kullanıcının anlattığı gibidir:
#   1 ayaklar + alt tabla (sol yana)  2 üst tabla (sol yana)  3 sağ yan  4 arkalık (çivi)
#   5 raf  6 rafix'li ara tablalar  7 kapaklar  8 kulplar
#
# SketchUp > Pencere > Ruby Konsolu:
#   load 'C:/.../scripts/product-3d/kurulum/firin_mikrodalga_dolabi.rb'
#   OzcanKurulum::FirinMikrodalgaDolabi.kur               # AÇIK MODELİ TEMİZLER, modeli sıfırdan kurar
#   OzcanKurulum::FirinMikrodalgaDolabi.oynat             # montaj animasyonunu ekranda oynatır
#   OzcanKurulum::FirinMikrodalgaDolabi.kumanda           # klavyeyle adım adım: → ← Enter, K serbest kamera, Esc
#   (konsoldan: sonraki, onceki, durdur, devam, adim(3), git(3), bitir)
#   OzcanKurulum::FirinMikrodalgaDolabi.kaydet('C:/kareler') # animasyonu PNG karelere yazar
#
# Koordinatlar mm: X genişlik (0 = sol dış yüz), Y derinlik (0 = gövde ön yüzü, +Y arkaya;
# kapaklar Y<0'da, arkalık Y=597..600), Z yükseklik (0 = zemin).

module OzcanKurulum
  module FirinMikrodalgaDolabi
    extend self

    # ------------------------------------------------------------------
    # Ölçüler (mm)
    # ------------------------------------------------------------------
    W = 600.0            # dış genişlik
    T = 18.0             # panel kalınlığı
    IW = W - 2 * T       # iç genişlik 564
    D = 597.0            # yan derinliği; + 3 mm çakma arkalık = 600 (kapakla 620)
    ARKA_T = 3.0
    AYAK_H = 50.0
    Z0 = AYAK_H          # gövdenin alt yüzü
    ZT = 1800.0          # gövdenin üst yüzü (ayak dahil 180)
    # Rafix'li ara tablaların alt yüzleri: üst bölme / mikrodalga / fırın / alt bölme sınırları
    BOLME = { bolme_1: 1276.0, bolme_2: 894.0, bolme_3: 286.0 }.freeze
    BOLME_AD = { bolme_1: 'Ara Tabla (mikrodalga üstü)', bolme_2: 'Ara Tabla (fırın üstü)',
                 bolme_3: 'Ara Tabla (alt bölme üstü)' }.freeze
    RAF_Z = 1529.0       # üst bölmedeki pimli rafın alt yüzü (altı ve üstü 23,5 cm)
    RAF_Y0 = 20.0
    RAF_DER = 350.0
    PIM_R = 2.5
    PIM_Y = [RAF_Y0 + 37, RAF_Y0 + RAF_DER - 37].freeze
    RAFIX_Y = [40.0, 555.0].freeze
    CEKTIRME_Y = [60.0, 300.0, 540.0].freeze # büyük ürün: her köşede 3 çektirme
    KAPI_PAY = 2.0
    KAPI_W = W - 3       # tam bindirme kapak
    KAPI_X0 = 1.5
    KAPAK = { kapak_ust: [1290.0, ZT], kapak_alt: [Z0, 300.0] }.freeze # [alt, üst] kenar Z
    MENTESE_Z = [1710.0, 1380.0].freeze # üst kapak menteşeleri (sol yanda)
    MENTESE_X = [110.0, 490.0].freeze   # alt klapa kapağın menteşeleri (alt tablanın üstünde)
    KAP_ZC = 4.5         # menteşe çerçevesinde kap merkezi (kapak kenarından ~22 mm)
    PIVOT = [0.0, -(KAPI_PAY + T)] # üst kapak sol ön köşede dikey eksende, klapa alt ön kenarda döner
    KULP_ARA = 192.0     # krom çubuk kulp vida aralığı
    # çubuk kulp merkezi (kapak-yerel x, z) ve yönü: üst kapakta sağda dikey, alt klapada üstte yatay
    KULP = { kapak_ust: [KAPI_W - 45, 150.0, :dikey], kapak_alt: [KAPI_W / 2, 203.0, :yatay] }.freeze
    AYAK_XY = [[50, 50], [550, 50], [50, 547], [550, 547]].freeze
    PLAKA_T = 3.0

    DIKEY_FOV = 30.0
    VIDEO_FOV = 50.0

    DICT = 'ozcan_kurulum'
    SIRA = %i[sol_yan alt_tabla ust_tabla sag_yan arkalik raf bolme_1 bolme_2 bolme_3
              kapak_ust kapak_alt].freeze
    KAPILAR = %i[kapak_ust kapak_alt].freeze
    ETIKET = {
      sol_yan: '01 Sol Yan', alt_tabla: '02 Alt Tabla', ust_tabla: '03 Üst Tabla',
      sag_yan: '04 Sağ Yan', arkalik: '05 Arkalık', raf: '06 Raf',
      bolme_1: '07 Ara Tablalar', bolme_2: '07 Ara Tablalar', bolme_3: '07 Ara Tablalar',
      kapak_ust: '08 Üst Kapak', kapak_alt: '09 Alt Kapak'
    }.freeze
    AD = {
      sol_yan: 'Sol Yan', alt_tabla: 'Alt Tabla', ust_tabla: 'Üst Tabla', sag_yan: 'Sağ Yan',
      arkalik: 'Arkalık', raf: 'Raf', kapak_ust: 'Üst Kapak', kapak_alt: 'Alt Kapak'
    }.merge(BOLME_AD).freeze
    LISTE_TAG = '00 Parça Listesi'
    ARAC_TAG = '99 Tornavida'

    # Kamera noktaları [göz, hedef] (mm)
    KAM = {
      liste:  [[4000, -4300, 5500], [4000, 800, 0]],
      1 =>    [[1290, -996, 1056], [300, 300, 300]],
      2 =>    [[1290, -996, 2356], [300, 300, 1600]],
      3 =>    [[-1900, -2580, 2580], [300, 300, 900]],
      4 =>    [[2500, 3180, 2580], [300, 300, 900]],
      5 =>    [[1400, -1240, 2340], [300, 200, 1500]],
      6 =>    [[2500, -2580, 2580], [300, 300, 900]],
      :"7a" => [[1570, -1828, 2508], [250, -100, 1500]],
      :"7b" => [[1350, -1540, 1040], [250, -100, 200]],
      :"8a" => [[-1000, -1500, 1700], [60, -400, 1340]],
      :"8b" => [[1000, -1250, 40], [300, -150, 120]],
      bitti:  [[2300, -2800, 2300], [300, 200, 900]]
    }.freeze

    # Parçaların yerleşim orijini (bileşen orijini = parçanın min köşesi)
    ORIJIN = {
      sol_yan: [0, 0, Z0], sag_yan: [W - T, 0, Z0], alt_tabla: [T, 0, Z0], ust_tabla: [T, 0, ZT - T],
      arkalik: [0, D, Z0], raf: [T + 1, RAF_Y0, RAF_Z],
      bolme_1: [T + 0.5, 0, BOLME[:bolme_1]], bolme_2: [T + 0.5, 0, BOLME[:bolme_2]],
      bolme_3: [T + 0.5, 0, BOLME[:bolme_3]],
      kapak_ust: [KAPI_X0, -(KAPI_PAY + T), KAPAK[:kapak_ust][0]],
      kapak_alt: [KAPI_X0, -(KAPI_PAY + T), KAPAK[:kapak_alt][0]]
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
        govde: mk.('Beyaz Melamin', [242, 242, 240]),
        arka: mk.('Arkalık Beyaz', [240, 239, 234]),
        seffaf: mk.('Şeffaf Plastik', [205, 225, 238], 0.35),
        cinko: mk.('Çinko Kaplama', [160, 164, 170]),
        nikel: mk.('Nikel', [192, 196, 202]),
        pirinc: mk.('Pirinç Burç', [196, 158, 72]),
        krom: mk.('Krom', [214, 217, 222]),
        kaucuk: mk.('Kauçuk', [45, 45, 48]),
        gri: mk.('Gri Plastik', [150, 152, 156]),
        rafix: mk.('Rafix Plastik', [228, 228, 224]),
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

    # --- Rafix: yan panelde pim, ara tablanın altında gömme yuva (alttan tornavidayla çevrilir) ---
    def rafix_pim_tanimi
      d = @m.definitions.add('Rafix Pimi')
      torna(d.entities, [[0, 0], [0, 3], [5, 3], [5, 4.5], [8, 4.5], [8.8, 3.5], [8.8, 0]], 20, @mat[:nikel])
      d
    end

    # Yerel +x tablanın alt yüzünden dışarı (aşağı); x=0 alt yüz.
    def rafix_tanimi
      d = @m.definitions.add('Gömme Rafix')
      torna(d.entities, [[0, 0], [0, 10], [0.6, 10], [0.6, 0]], 28, @mat[:rafix])
      yildiz(d.entities, 0.65, 8)
      d
    end

    # Arkalık çivisi: baş x∈[-1.2, 0], gövde +x (çakılma yönü)
    def civi_tanimi
      d = @m.definitions.add('Arkalık Çivisi')
      torna(d.entities, [[-1.2, 0], [-1.2, 2.6], [0, 2.6], [0, 0.9], [18, 0.9], [20, 0], ], 12, @mat[:cinko])
      d
    end

    # Krom çubuk kulp: yerel +x kapaktan dışarı, y kulp boyu; iki ayak KULP_ARA aralıklı.
    def cubuk_kulp_tanimi
      d = @m.definitions.add('Çubuk Kulp 192')
      [-1, 1].each do |sy|
        torna(d.entities, [[0, 0], [0, 4.5], [22, 4.5], [22, 0]], 20, @mat[:krom]).transform!(tr(0, sy * KULP_ARA / 2, 0))
      end
      torna(d.entities, [[-112, 0], [-112, 4], [-110, 5], [110, 5], [112, 4], [112, 0]], 24, @mat[:krom])
        .transform!(eksen([27, 0, 0], [0, 1, 0], [1, 0, 0]))
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

    # Tüm çektirmeler dünya koordinatında: k = iç köşe noktası, ex/ez bağlantı çerçevesi.
    # Alt ve üst tabla sol yana yandan kayarak gelir, sağ yan ikisine birden oturur:
    # bu yüzden hepsinde dişi tablada (yuva yana açık), erkek yanda.
    def baglantilar
      l = []
      [[:sol_yan, T, 1, 'sol'], [:sag_yan, W - T, -1, 'sag']].each do |yan, xs, sx, taraf|
        CEKTIRME_Y.each_with_index do |y, i|
          yer = %w[on orta arka][i]
          l << { id: "alt_#{taraf}_#{yer}", disi: :alt_tabla, erkek: yan, k: [xs, y, Z0 + T], ex: [sx, 0, 0], ez: [0, 0, 1] }
          l << { id: "ust_#{taraf}_#{yer}", disi: :ust_tabla, erkek: yan, k: [xs, y, ZT - T], ex: [sx, 0, 0], ez: [0, 0, -1] }
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
    # x' menteşe ekseni (dikey), y' = +Y derinlik, z' yandan içeri.
    def mentese_cerceve(o, sx)
      Geom::Transformation.axes(P(*o), Geom::Vector3d.new(0, 0, -sx), Y_AXIS, Geom::Vector3d.new(sx, 0, 0))
    end

    def yan(ad, x_ic, sx)
      d = parca_tanimi(ad)
      e = d.entities
      kutu(e, 0, 0, 0, T, D, ZT - Z0)
      boya(e, @mat[:govde])
      xp = x_ic # pimler yanın iç yüzünde, iç yüze dik
      PIM_Y.each { |y| e.add_instance(@pim, eksen([xp, y, RAF_Z - PIM_R - Z0], [sx, 0, 0], [0, 0, 1])) }
      BOLME.each_value do |bz|
        RAFIX_Y.each { |y| e.add_instance(@rafix_pim, eksen([xp, y, bz + 6 - Z0], [sx, 0, 0], [0, 0, 1])) }
      end
      e
    end

    def sol_yan
      e = yan('Sol Yan', T, 1)
      cektirmeler(e, :sol_yan)
      MENTESE_Z.each { |hz| e.add_instance(@taban, mentese_cerceve([T, -KAPI_PAY, hz - Z0], 1)) }
      [e.parent, ORIJIN[:sol_yan]]
    end

    def sag_yan
      e = yan('Sağ Yan', 0, -1)
      cektirmeler(e, :sag_yan)
      [e.parent, ORIJIN[:sag_yan]]
    end

    def alt_tabla
      d = parca_tanimi('Alt Tabla')
      e = d.entities
      kutu(e, 0, 0, 0, IW, D, T)
      boya(e, @mat[:govde])
      cektirmeler(e, :alt_tabla)
      MENTESE_X.each { |hx| e.add_instance(@taban, tr(hx - T, -KAPI_PAY, T)) } # klapa menteşe tabanları
      AYAK_XY.each_with_index do |(x, y), i|
        e.add_instance(@ayak_taban, eksen([x - T, y, 0], [0, 0, -1], [1, 0, 0]))
        lt = eksen([x - T, y, -11], [0, 0, 1], [1, 0, 0])
        vida_koy(e, @ayak, lt, P(x - T, y, -11), Geom::Vector3d.new(0, 0, 1), 40.0, 0.0,
                 Geom::Vector3d.new(0, 0, -1), "ayak_#{i + 1}")
      end
      [d, ORIJIN[:alt_tabla]]
    end

    def ust_tabla
      d = parca_tanimi('Üst Tabla')
      e = d.entities
      kutu(e, 0, 0, 0, IW, D, T)
      boya(e, @mat[:govde])
      cektirmeler(e, :ust_tabla)
      [d, ORIJIN[:ust_tabla]]
    end

    # Arkalık gövdenin arkasına çakılır; çiviler önceden açılmış deliklerden yanlara,
    # alt ve üst tablaya girer (demonte gelir, animasyonda çekiçle çakılır).
    CIVI = (0...8).flat_map { |i| z = 70 + i * 237.1; [[T / 2, z], [W - T / 2, z]] } +
           [90, 230, 370, 510].flat_map { |x| [[x, T / 2], [x, ZT - Z0 - T / 2]] }

    def arkalik
      d = parca_tanimi('Arkalık')
      e = d.entities
      kutu(e, 0, 0, 0, W, ARKA_T, ZT - Z0)
      boya(e, @mat[:govde])
      CIVI.each_with_index do |(x, z), i|
        vida_koy(e, @civi, eksen([x, ARKA_T, z], [0, -1, 0], [0, 0, 1]), P(x, ARKA_T, z), Geom::Vector3d.new(0, -1, 0),
                 16.0, 1.2, Geom::Vector3d.new(0, 1, 0), format('civi_%02d', i + 1))
      end
      [d, ORIJIN[:arkalik]]
    end

    def raf
      d = parca_tanimi('Raf')
      kutu(d.entities, 0, 0, 0, IW - 2, RAF_DER, T)
      boya(d.entities, @mat[:govde])
      [d, ORIJIN[:raf]]
    end

    # Rafix'li ara tabla: dört köşede gömme rafix; her biri ayrı bileşen tanımı (rafix'ler
    # animasyonda ayrı ayrı döner).
    def bolme(k)
      d = parca_tanimi(BOLME_AD[k])
      e = d.entities
      bw = IW - 1
      kutu(e, 0, 0, 0, bw, D - 2, T)
      boya(e, @mat[:govde])
      w = Geom::Vector3d.new(0, -0.9, -0.45).normalize # tornavida alttan-önden
      [[10.5, 'sol'], [bw - 10.5, 'sag']].each do |x, taraf|
        RAFIX_Y.each_with_index do |y, i|
          vida_koy(e, @rafix, eksen([x, y, 0], [0, 0, -1], [1, 0, 0]), P(x, y, 0), Geom::Vector3d.new(0, 0, 1),
                   0.01, 0.0, w, "rafix_#{k}_#{taraf}_#{i.zero? ? 'on' : 'arka'}")
        end
      end
      [d, ORIJIN[k]]
    end

    def bolme_1; bolme(:bolme_1); end
    def bolme_2; bolme(:bolme_2); end
    def bolme_3; bolme(:bolme_3); end

    def bar_tr(a, b)
      v = b - a
      x = v.normalize
      y = Geom::Vector3d.new(1, 0, 0)
      Geom::Transformation.axes(a, x, y, x * y) * Geom::Transformation.scaling(ORIGIN, v.length / 10.mm, 1, 1)
    end

    # Kapaklar tam bindirme. Üst kapak sol yandaki iki menteşeyle yana açılır; alt kapak
    # alt tablanın üstündeki iki menteşeyle öne yatan klapadır. Krom çubuk kulplar ve
    # vidaları demonte gelir (son adımda takılır). Kapak-yerel orijin = sol ön alt köşe.
    def kapak(k, ad)
      z0, z1 = KAPAK[k]
      h = z1 - z0
      x0 = ORIJIN[k][0]
      klapa = k == :kapak_alt
      no = klapa ? 'alt' : 'ust'
      d = parca_tanimi(ad)
      e = d.entities
      kutu(e, 0, 0, 0, KAPI_W, T, h)
      kx, kz, kyon = KULP[k]
      dikey = kyon == :dikey
      delik = [-1, 1].map { |sy| dikey ? [kx, kz + sy * KULP_ARA / 2] : [kx + sy * KULP_ARA / 2, kz] }
      delik.each { |x, z| daire_it(e, P(x, 0, z), Y_AXIS, 2.5, yon(0, 1, 0), T, 16) } # kulp vida delikleri (Ø5)
      hdler = if klapa
                MENTESE_X.map { |hx| tr(hx - x0, T, Z0 + T - z0) }
              else
                MENTESE_Z.map { |hz| mentese_cerceve([T - x0, T, hz - z0], 1) }
              end
      hdler.each { |hd| daire_it(e, P(0, 0, KAP_ZC).transform(hd), Y_AXIS, 17.5, yon(0, -1, 0), 12.5, 32) }
      boya(e, @mat[:govde])
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
        zx = hd.zaxis # sabitleme vidası panelden dışarı bakar; tornavida önden 35° eğik gelir
        w = Geom::Vector3d.new(zx.x * Math.cos(35.degrees), -Math.sin(35.degrees), zx.z * Math.cos(35.degrees))
        vida_koy(ge, @mvida, lt, P(0, 34, 8).transform(hd), Geom::Vector3d.new(0, 0, -1).transform(hd), 4.0, 2.3, w,
                 "mentese_#{no}_#{i + 1}", true)
      end
      # çubuk kulp önden oturur (kulp-yerel x kapaktan dışarı, y kulp boyu), vidaları arkadan
      vida_koy(e, @kulp, eksen([kx, 0, kz], [0, -1, 0], dikey ? [-1, 0, 0] : [0, 0, 1]), P(kx, 0, kz),
               Geom::Vector3d.new(0, 1, 0), 60.0, 0.0, Geom::Vector3d.new(0, -1, 0), "kulp_#{no}")
      wk = klapa ? Geom::Vector3d.new(0, 0.77, 0.64) : Geom::Vector3d.new(0.64, 0.77, 0) # serbest kenara eğik
      delik.each_with_index do |(x, z), j|
        vida_koy(e, @kvida, eksen([x, T, z], [0, -1, 0], [0, 0, 1]), P(x, T, z), Geom::Vector3d.new(0, -1, 0),
                 25.0, 2.3, wk, "kulpvida_#{no}_#{j + 1}")
      end
      [d, ORIJIN[k]]
    end

    def kapak_ust
      kapak(:kapak_ust, 'Üst Kapak')
    end

    def kapak_alt
      kapak(:kapak_alt, 'Alt Kapak')
    end

    # ------------------------------------------------------------------
    # Model kurulumu
    # ------------------------------------------------------------------
    def kur(kayit_yolu = nil)
      @m = Sketchup.active_model
      @m.start_operation('Fırın mikrodalga dolabı kurulum modeli', true)
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
      @kvida = vida_tanimi('Kulp Vidası M4x25', 3.8, 2.3, 2, 25)
      @disi = disi_tanimi
      @erkek = erkek_tanimi
      @ayak_taban = ayak_taban_tanimi
      @ayak = ayak_tanimi
      @pim = pim_tanimi
      @rafix_pim = rafix_pim_tanimi
      @rafix = rafix_tanimi
      @civi = civi_tanimi
      @taban = taban_tanimi
      @kol = kol_tanimi
      @kap = kap_tanimi
      @bag = bag_tanimi
      @kulp = cubuk_kulp_tanimi
      arac = tornavida_tanimi
      cekic = cekic_tanimi

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
      [[arac, 'tornavida'], [cekic, 'cekic']].each do |d, ad|
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
      "Kuruldu: #{SIRA.size} parça, #{@vidalar.size} animasyonlu vida/ayak/rafix/çivi/kulp, #{@m.pages.size} sahne"
    end

    # Kutu içeriği: paneller yere yatırılmış, fabrikada takılı hırdavat üstte.
    def parca_listesi(tag)
      rx = ->(a) { Geom::Transformation.rotation(ORIGIN, X_AXIS, a.degrees) }
      ry = ->(a) { Geom::Transformation.rotation(ORIGIN, Y_AXIS, a.degrees) }
      rz = ->(a) { Geom::Transformation.rotation(ORIGIN, Z_AXIS, a.degrees) }
      bir = Geom::Transformation.new
      yerlesim = {
        sol_yan: [rz.(90) * ry.(-90), 1400, 0], sag_yan: [rz.(90) * ry.(90), 2150, 0],
        arkalik: [rx.(-90), 2900, 0],
        kapak_ust: [rx.(90), 3700, 0], kapak_alt: [rx.(90), 3700, 750], raf: [bir, 3700, 1200],
        alt_tabla: [bir, 4500, 0], ust_tabla: [rx.(180), 4500, 800],
        bolme_1: [rx.(180), 5250, 0], bolme_2: [rx.(180), 5250, 800], bolme_3: [rx.(180), 5250, 1600]
      }
      @m.entities.grep(Sketchup::ComponentInstance).select { |i| nit(i, :parca) && !%w[tornavida cekic].include?(nit(i, :parca)) }.each do |ana|
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
      # demonte gelenler: 2 çubuk kulp, 4 kulp vidası, arkalık çivileri
      ekler = [[@kulp, [3100, -520, 0], [0, 0, 1], [1, 0, 0], 'Çubuk Kulp (2)'], [@kulp, [3180, -520, 0], [0, 0, 1], [1, 0, 0], nil]]
      4.times { |i| ekler << [@kvida, [4000, -420 - i * 35, 4], [1, 0, 0], [0, 0, 1], i.zero? ? 'Kulp Vidası (4)' : nil] }
      6.times { |i| ekler << [@civi, [2200 + i * 12, -450, 3], [1, 0, 0], [0, 0, 1], i.zero? ? "Arkalık Çivisi (#{CIVI.size})" : nil] }
      ekler.each do |defn, o, x, z, ad|
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
        ['0 Kutu İçeriği', [], :liste, 'Paneller ve fabrikada takılı bağlantı elemanları; kulplar ve çiviler demonte.'],
        ['1 Ayaklar + Alt Tabla', %i[sol_yan alt_tabla], 1, 'Ayakları alt tablaya çevirerek takın; alt tablayı sol yandaki çektirmelere geçirip 3 açılı vidayı sıkın.'],
        ['2 Üst Tabla', %i[ust_tabla], 2, 'Üst tablayı sol yandaki çektirmelere geçirin; 3 açılı vidayı sıkın.'],
        ['3 Sağ Yan', %i[sag_yan], 3, 'Sağ yanı alt ve üst tabladaki çektirmelere oturtun; 6 vidayı sıkın.'],
        ['4 Arkalık', %i[arkalik], 4, 'Arkalığı arkaya yerleştirip hazır deliklerden çivileri çekiçle çakın.'],
        ['5 Raf', %i[raf], 5, 'Rafı üst bölmedeki raf pimlerinin üzerine koyun.'],
        ['6 Rafix Ara Tablalar', %i[bolme_1 bolme_2 bolme_3], 6, 'Ara tablaları rafix pimlerine oturtun; rafix\'leri alttan tornavidayla çevirin.'],
        ['7 Kapaklar', KAPILAR, :"7a", 'Kapaktaki menteşe gövdelerini yandaki tabanlara geçirin; ortadaki vidaları sıkın.'],
        ['8 Kulplar', [], :"8a", 'Çubuk kulpları kapağın önüne koyup arkadan kulp vidalarıyla sıkın.'],
        ['9 Bitmiş Ürün', [], :bitti, 'Kurulum tamamlandı.']
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
        elsif k == 'cekic' then @cekic = i
        else
          @parca[k.to_sym] = i
          @taban_tr[k.to_sym] = i.transformation
        end
      end
      raise 'Model bulunamadı — önce OzcanKurulum::FirinMikrodalgaDolabi.kur' unless @parca.size == SIRA.size && @arac
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

    # aci > 0 açık: üst kapak sol ön köşedeki dikey eksende yana, alt klapa alt ön kenarında
    # öne doğru yatar.
    def kapi_R(k, aci)
      if k == :kapak_alt
        Geom::Transformation.rotation(P(0, PIVOT[1], Z0), X_AXIS, aci.degrees)
      else
        Geom::Transformation.rotation(P(PIVOT[0], PIVOT[1], 0), Z_AXIS, -aci.degrees)
      end
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

    AYAKLAR = %w[ayak_1 ayak_2 ayak_3 ayak_4].freeze
    CIVILER = (1..CIVI.size).map { |i| format('civi_%02d', i) }.freeze
    DEMONTE = (%w[kulp_ust kulp_alt kulpvida_ust_1 kulpvida_ust_2 kulpvida_alt_1 kulpvida_alt_2] + CIVILER).freeze

    # Çekiç çiviye gelir, iki kez vurur (çivi her vuruşta yarı yarıya girer), geri çekilir.
    def civi_cak(id)
      @cz.olay(0.25) { |s, u| s[:cekic] = { id: id, uz: 1 - u } }
      @cz.olay(0.45, false) do |s, u|
        s[:cekic] = { id: id, uz: 0.15 * Math.sin(Math::PI * 2 * u).abs }
        s[:v][id] = { adv: u < 0.5 ? 1.0 : (u < 1.0 ? 0.5 : 0.0), ang: 0.0 }
      end
      @cz.olay(0.2) { |s, u| s[:cekic] = u >= 1 ? nil : { id: id, uz: u } }
    end

    def kapak_tak(k, kam)
      z = @cz
      z.kamera(1.2, KAM[kam])
      z.an { |s, _| s[:kapi][k] = 90.0 }
      hareket(k, [0, -420, 0], [0, 0, 0], 1.8)
      no = k == :kapak_ust ? 'ust' : 'alt'
      vida_sik("mentese_#{no}_1", nil, tur: 3, sure: 0.8)
      vida_sik("mentese_#{no}_2", nil, tur: 3, sure: 0.8)
      z.kamera(0.8, KAM[kam])
      z.olay(1.4) { |s, u| s[:kapi][k] = 90.0 * (1 - u) }
    end

    # Kapak açılır, çubuk kulp önden oturur, iki kulp vidası arkadan gelip sıkılır, kapak kapanır.
    def kulp_tak(k, kam)
      z = @cz
      no = k == :kapak_ust ? 'ust' : 'alt'
      z.kamera(1.2, KAM[kam])
      z.olay(1.0) { |s, u| s[:kapi][k] = 90.0 * u }
      z.olay(0.8) { |s, u| s[:v]["kulp_#{no}"] = { adv: 3.0 * (1 - u), ang: 0.0 } }
      [1, 2].each do |j|
        id = "kulpvida_#{no}_#{j}"
        z.olay(0.5) { |s, u| s[:v][id] = { adv: 4.0 - 3.0 * u, ang: 0.0 } }
        vida_sik(id, nil, tur: 4, sure: 0.9)
      end
      z.kamera(0.7, KAM[kam])
      z.olay(1.0) { |s, u| s[:kapi][k] = 90.0 * (1 - u) }
    end

    def cizelge
      @cz = z = Cizelge.new
      z.an { |s, _| DEMONTE.each { |id| s[:v][id] = { gizli: true } } } # takılana kadar görünmesin
      z.baslik('Kutu içeriği — bağlantı elemanları panellere takılı gelir, kulplar ve çiviler ayrı')
      z.kamera(0, KAM[:liste])
      z.bekle(3.5)

      z.baslik('1 · Ayakları alt tablaya çevirerek takın, alt tablayı sol yandaki çektirmelere geçirip vidaları sıkın')
      z.an do |s, _|
        s[:liste] = false
        s[:p][:sol_yan][:vis] = true
        s[:p][:alt_tabla] = { vis: true, off: [420, 0, 0] }
      end
      z.kamera(1.2, KAM[1])
      z.olay(1.8, false) { |s, u| AYAKLAR.each { |id| s[:v][id] = { adv: 1 - u, ang: 360.0 * 6 * u } } }
      hareket(:alt_tabla, [420, 0, 0], [2, 0, 0], 2.0)
      vida_sik('alt_sol_on', [:alt_tabla, [2, 0, 0], [1.3, 0, 0]])
      vida_sik('alt_sol_orta', [:alt_tabla, [1.3, 0, 0], [0.6, 0, 0]])
      vida_sik('alt_sol_arka', [:alt_tabla, [0.6, 0, 0], [0, 0, 0]])
      z.bekle(0.3)

      z.baslik('2 · Üst tablayı sol yandaki çektirmelere geçirin, vidaları sıkın')
      z.kamera(1.2, KAM[2])
      hareket(:ust_tabla, [420, 0, 0], [2, 0, 0], 2.0)
      vida_sik('ust_sol_on', [:ust_tabla, [2, 0, 0], [1.3, 0, 0]])
      vida_sik('ust_sol_orta', [:ust_tabla, [1.3, 0, 0], [0.6, 0, 0]])
      vida_sik('ust_sol_arka', [:ust_tabla, [0.6, 0, 0], [0, 0, 0]])
      z.bekle(0.3)

      z.baslik('3 · Sağ yanı alt ve üst tabladaki çektirmelere oturtun, vidaları sıkın')
      z.kamera(1.2, KAM[3])
      hareket(:sag_yan, [420, 0, 0], [2, 0, 0], 2.0)
      vida_sik('alt_sag_on', [:sag_yan, [2, 0, 0], [1, 0, 0]], tur: 3, sure: 0.8)
      vida_sik('ust_sag_on', [:sag_yan, [1, 0, 0], [0, 0, 0]], tur: 3, sure: 0.8)
      %w[alt_sag_orta alt_sag_arka ust_sag_orta ust_sag_arka].each { |id| vida_sik(id, nil, tur: 3, sure: 0.8) }
      z.bekle(0.3)

      z.baslik('4 · Arkalığı arkaya yerleştirip çivileri çekiçle çakın')
      z.kamera(1.2, KAM[4])
      hareket(:arkalik, [0, 450, 0], [0, 0, 0], 2.0)
      z.an { |s, _| CIVILER.each { |id| s[:v][id] = { adv: 1.0, ang: 0.0 } } }
      z.bekle(0.3)
      yakin_kamera(CIVILER.first, yon: [0.45, 1, 0.35])
      civi_cak(CIVILER.first)
      z.kamera(0.8, KAM[4])
      CIVILER.drop(1).each { |id| civi_cak(id) }
      z.bekle(0.3)

      z.baslik('5 · Rafı üst bölmedeki raf pimlerinin üzerine yerleştirin')
      z.kamera(1.0, KAM[5])
      hareket(:raf, [0, -450, 40], [0, 0, 40], 1.2)
      hareket(:raf, [0, 0, 40], [0, 0, 0], 0.4)
      z.bekle(0.3)

      z.baslik("6 · Ara tablaları rafix pimlerine oturtun, rafix'leri alttan tornavidayla çevirin")
      BOLME.each_key do |k|
        z.kamera(1.0, KAM[6])
        hareket(k, [0, -650, 40], [0, 0, 40], 1.6)
        hareket(k, [0, 0, 40], [0, 0, 0], 0.5)
        %w[sol_on sol_arka sag_on sag_arka].each do |y|
          sx = y.start_with?('sol') ? 1 : -1 # tornavidaya karşıdan değil, bölmenin içinden yandan bak
          vida_sik("rafix_#{k}_#{y}", nil, tur: 0.25, sure: 0.6, bak: [0.75 * sx, -0.6, -0.35])
        end
      end
      z.kamera(1.0, KAM[6])
      z.bekle(0.3)

      z.baslik('7 · Kapakları menteşe tabanlarına geçirin, ortadaki vidaları sıkın')
      kapak_tak(:kapak_ust, :"7a")
      kapak_tak(:kapak_alt, :"7b")
      z.kamera(1.2, KAM[:bitti])
      z.bekle(0.3)

      z.baslik('8 · Çubuk kulpları önden koyup arkadan kulp vidalarıyla sıkın')
      kulp_tak(:kapak_ust, :"8a")
      kulp_tak(:kapak_alt, :"8b")
      z.kamera(1.2, KAM[:bitti])
      z.bekle(0.3)

      z.baslik('Kurulum tamamlandı')
      z.kamera(1.6, KAM[:bitti])
      z.olay(1.3) { |s, u| s[:kapi][:kapak_ust] = 95.0 * u; s[:kapi][:kapak_alt] = 90.0 * u }
      z.bekle(0.8)
      z.olay(1.3) { |s, u| s[:kapi][:kapak_ust] = 95.0 * (1 - u); s[:kapi][:kapak_alt] = 90.0 * (1 - u) }
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
      ck = s[:cekic]
      if ck
        v = @vidalar.find { |x| x[:id] == ck[:id] }
        ana = @parca[v[:parca]].transformation
        bas = Geom::Point3d.new(-v[:bas_h].mm, 0, 0).transform(ana * v[:inst].transformation)
        w = v[:w].transform(ana).normalize
        yuz = bas.offset(w, (ck[:uz] * 150).mm)
        yy = Z_AXIS.cross(w)
        yy = X_AXIS.clone if yy.length < 1e-6
        yy.normalize!
        @cekic.move!(Geom::Transformation.axes(yuz, w, yy, w.cross(yy)))
      else
        @cekic.move!(tr(*UZAK))
      end
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

    # Montajlı son durum: tüm parçalar yerinde, vidalar sıkılı, kapak kapalı.
    def son_durum
      s = ilk_durum
      SIRA.each { |k| s[:p][k] = { vis: true, off: [0, 0, 0] } }
      s[:v].each_key { |id| s[:v][id] = { adv: 0.0, ang: 0.0 } }
      s[:liste] = @liste_tag.visible?
      uygula(s)
      @arac.move!(Geom::Transformation.new)
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
