# encoding: UTF-8
# Kahve Köşesi Dolabı (80 x 175 x 40 cm) — model ve kurulum kılavuzu.
# Müşterinin gösterdiği kahve istasyonundan, Özcan Mobilya üretim tarzına uyarlandı.
# Gövde 18 mm kumtaşı sunta, gömme (yanların arasında) beyaz önler, altın rengi kısa çubuk kulplar, eğik meşe ayaklar.
#   Altta (derinlik 40): tezgahın altından alt tablaya iki tek parça gömme kapak (içinde ara tabla + pimli raf); üstünde
#   kumtaşı tezgah (yerden 89 cm).
#   Üstte (derinlik 26): yanlar tezgahın üstünde kavisle geri çekilir; ortada pimli raf, rafın ve üst tablanın
#   altında LED şerit, önde uçları kavisli kuşak, altlarında fincan kancaları.
#   Arkalık ince duralit değil, ürünün kendi malzemesi: alt ve üst bölmede 18 mm kumtaşı panel. Üst arkalık tam
#   genişlikte, yanların arka kenarına arkadan 4 vidayla (önden görünen bağlantı kalmaz); yanlar tezgahın üstünde
#   18 mm sığlaşır.
#
# Her panel ayrı bileşen; fabrikada takılı gelenler (şeffaf çektirme erkek/dişi, minifix eksantrik ve bulonları,
# menteşe tabanı ve gövdesi, raf pimleri, ayak tabanları, LED şeritler) panelin içinde. Ayaklar, kulplar ve
# vidaları, üst arkalık vidaları ve fincan kancaları ayrı gelir.
#   1 ayaklar  2 sol yan + alt tabla  3 sağ yan  4 ara tabla  5 tezgah  6 alt arkalık  7 üst arkalık  8 üst tabla
#   9 ön kuşak  10 raflar  11 kapaklar  12 kulplar  13 fincan kancaları
#
# SketchUp > Pencere > Ruby Konsolu:
#   load 'C:/.../scripts/product-3d/kurulum/kahve_kosesi.rb'
#   OzcanKurulum::KahveKosesi.kur               # AÇIK MODELİ TEMİZLER, modeli sıfırdan kurar
#   OzcanKurulum::KahveKosesi.oynat             # montaj animasyonunu ekranda oynatır
#   OzcanKurulum::KahveKosesi.kumanda           # klavyeyle adım adım: → ← Enter, K serbest kamera, Esc
#   (konsoldan: sonraki, onceki, durdur, devam, adim(3), git(3), bitir)
#   OzcanKurulum::KahveKosesi.kaydet('C:/kareler') # animasyonu PNG karelere yazar
#
# Koordinatlar mm: X genişlik (0 = sol dış yüz), Y derinlik (0 = gövde ön yüzü, +Y arkaya; önler Y=0..18'de
# yanların arasında), Z yükseklik (0 = zemin).

module OzcanKurulum
  module KahveKosesi
    extend self

    # ------------------------------------------------------------------
    # Ölçüler (mm)
    # ------------------------------------------------------------------
    W = 800.0            # genişlik
    T = 18.0             # panel kalınlığı
    D = 400.0            # alt dolap derinliği (yan); arkalık dahil
    UST_D = 260.0        # üst bölme derinliği
    HY = D - UST_D       # üst bölmede yanların ön kenarı (140)
    KAVIS_R = 120.0      # yanda tezgah üstündeki iç kavis
    AYAK_H = 160.0
    Z0 = AYAK_H          # alt tablanın alt yüzü; yanlar buradan başlar
    ZT = 1732.0          # yanların üst kenarı; üstünde 18 mm üst tabla → 1750
    ARA_Z = 402.0        # ara tablanın alt yüzü (kapakların arkasında sabit raf)
    TEZGAH_Z = 872.0     # tezgahın alt yüzü (üstü 890)
    RAF_Z = 640.0        # alt dolaptaki pimli raf
    UST_RAF_Z = 1270.0   # üst bölmedeki pimli raf
    GERI = 20.0          # gömme önlerin arkasında kalan panellerin geri çekilmesi
    KUSAK = { h: 130.0, orta: 50.0, uc: 30.0, r: 80.0 }.freeze # ön kuşak: uçlarda 13 cm, ortada 5 cm, kavisli
    PIM_R = 2.5
    CEK_Y = [70.0, 330.0].freeze                 # alt tabla ve tezgah birleşimleri
    ARA_Y = [80.0, 320.0].freeze
    UST_Y = [200.0, 340.0].freeze                # üst tabla birleşimleri
    ALT_ARKA_Z = [500.0, 780.0].freeze           # alt arkalık çektirmeleri
    UST_ARKA_Z = [1000.0, 1600.0].freeze         # üst arkalığın yanlara arkadan vidaları
    KUSAK_X = [200.0, 600.0].freeze
    AYAK_XY = [[70, 70], [W - 70, 70], [70, D - 80], [W - 70, D - 80]].freeze
    AYAK_EGIM = 9.0      # ayaklar dışa doğru eğik (derece)
    TABAN_T = 5.0
    # Gömme önler: yanların arasında, 2 mm aralıkla; kapaklar iç yüzdeki menteşe tabanlarına (gömme menteşe)
    ON_X = [T + 2, W - T - 2].freeze
    KAPI_W = (ON_X[1] - ON_X[0] - 3) / 2
    # Tek parça kapak: tezgahın altından alt tablaya (ara tabla arkasında kalır); alt menteşe alt çektirmenin üstünde
    KAPI_BOY = { z: [Z0 + 2, TEZGAH_Z - 2], mentese: [Z0 + T + 100, TEZGAH_Z - 80] }.freeze
    KAPI = {
      kapak_sol: KAPI_BOY.merge(x0: ON_X[0], eksen: ON_X[0], yon: -1, panel: T, sx: 1),
      kapak_sag: KAPI_BOY.merge(x0: ON_X[1] - KAPI_W, eksen: ON_X[1], yon: 1, panel: W - T, sx: -1)
    }.freeze
    KAPILAR = KAPI.keys.freeze
    KAP_ZC = 24.0        # gömme menteşe: kap merkezi kapak kenarından ~22 mm
    KULP_ARA = 96.0
    KANCA_UST = [130.0, 265.0, 400.0, 535.0, 670.0].freeze # üst tablanın altında
    KANCA_RAF = [450.0, 580.0, 710.0].freeze               # üst rafın altında (solda kahve makinesine yer kalsın)
    KANCA_Y = 250.0
    PLAKA_T = 3.0

    DIKEY_FOV = 30.0
    VIDEO_FOV = 50.0

    DICT = 'ozcan_kurulum'
    SIRA = (%i[alt_tabla sol_yan sag_yan ara_tabla tezgah alt_arka ust_arka ust_tabla kusak raf ust_raf] +
            KAPILAR).freeze
    AD = {
      alt_tabla: 'Alt Tabla', sol_yan: 'Sol Yan', sag_yan: 'Sağ Yan', ara_tabla: 'Ara Tabla', tezgah: 'Tezgah',
      alt_arka: 'Alt Arkalık', ust_arka: 'Üst Arkalık', ust_tabla: 'Üst Tabla', kusak: 'Ön Kuşak', raf: 'Alt Raf',
      ust_raf: 'Üst Raf', kapak_sol: 'Sol Kapak', kapak_sag: 'Sağ Kapak'
    }.freeze
    ETIKET = {
      alt_tabla: '01 Alt Tabla', sol_yan: '02 Sol Yan', sag_yan: '03 Sağ Yan', ara_tabla: '04 Ara Tabla',
      tezgah: '05 Tezgah', alt_arka: '06 Alt Arkalık', ust_arka: '07 Üst Arkalık', ust_tabla: '08 Üst Tabla',
      kusak: '09 Ön Kuşak', raf: '10 Raflar', ust_raf: '10 Raflar'
    }.merge(KAPILAR.map { |k| [k, '11 Kapaklar'] }.to_h).freeze
    LISTE_TAG = '00 Parça Listesi'
    ARAC_TAG = '99 Tornavida'
    DEKOR_TAG = 'Dekor (fincanlar, makine)'

    # Kamera noktaları [göz, hedef] (mm)
    KAM = {
      liste:   [[3400, -3300, 5600], [3400, 800, 0]],
      1 =>     [[1500, -1300, 650], [400, 200, 220]],
      2 =>     [[2400, -2900, 2200], [400, 200, 860]],
      3 =>     [[-1700, -2900, 2200], [400, 200, 860]],
      4 =>     [[2100, -2700, 1700], [400, 150, 760]],
      5 =>     [[2200, -2800, 2000], [400, 150, 870]],
      6 =>     [[1900, 2500, 1500], [400, 300, 550]],
      7 =>     [[2400, 3300, 2400], [400, 300, 1050]],
      8 =>     [[2400, -3200, 3000], [400, 250, 1150]],
      9 =>     [[1300, -2000, 1300], [400, 200, 1550]],
      10 =>    [[2200, -3000, 2000], [400, 200, 900]],
      kapak:   [[1600, -2300, 1300], [400, 0, 640]],
      kulp:    [[1400, -2100, 1000], [400, -150, 450]],
      kanca:   [[800, -1300, 1150], [400, 250, 1450]],
      bitti:   [[2300, -3400, 2100], [400, 200, 870]]
    }.freeze
    # Tanıtım görselleri: ad, açık kapak açıları, [göz, hedef]
    TANITIM = [
      ['1_on_capraz', {}, [[1900, -3200, 1550], [400, 200, 870]]],
      ['2_kapaklar_acik', { kapak_sol: 100, kapak_sag: 100 }, [[1600, -2900, 1400], [400, 0, 780]]],
      ['3_on', {}, [[400, -4000, 1000], [400, 200, 875]]],
      ['4_yan', {}, [[3200, -1400, 1350], [400, 200, 875]]],
      ['5_ust_bolme', {}, [[1300, -2300, 1500], [400, 250, 1300]]]
    ].freeze

    # Parçaların yerleşim orijini (bileşen orijini = parçanın min köşesi)
    ORIJIN = {
      alt_tabla: [T, GERI, Z0], sol_yan: [0, 0, Z0], sag_yan: [W - T, 0, Z0], ara_tabla: [T, GERI, ARA_Z],
      tezgah: [T, 0, TEZGAH_Z], alt_arka: [T, D - T, Z0], ust_arka: [0, D - T, TEZGAH_Z], ust_tabla: [0, HY, ZT],
      kusak: [T, HY, ZT - KUSAK[:h]], raf: [T + 1.75, GERI + 2, RAF_Z], ust_raf: [T + 1.75, HY + 2, UST_RAF_Z],
    }.merge(KAPI.map { |k, h| [k, [h[:x0], 0, h[:z][0]]] }.to_h).freeze

    AYAKLAR = (1..4).map { |i| "ayak_#{i}" }.freeze
    ARKA_VIDALARI = %w[sol sag].flat_map { |t| %w[alt ust].map { |y| "arkavida_#{t}_#{y}" } }.freeze
    KULPLAR = KAPILAR.map { |k| "kulp_#{k}" }.freeze
    KULP_VIDALARI = KULPLAR.flat_map { |k| ["#{k}_vida_1", "#{k}_vida_2"] }.freeze
    KANCALAR = (KANCA_UST.each_index.map { |i| "kanca_ust_#{i + 1}" } + KANCA_RAF.each_index.map { |i| "kanca_raf_#{i + 1}" }).freeze
    DEMONTE = (AYAKLAR + ARKA_VIDALARI + KULPLAR + KULP_VIDALARI + KANCALAR).freeze

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
        govde: mk.('Kumtaşı', [216, 206, 188]),
        on: mk.('Beyaz Ön', [246, 246, 243]),
        mese: mk.('Meşe Ayak', [190, 144, 92]),
        altin: mk.('Altın Kulp', [200, 164, 92]),
        led: mk.('LED Şerit (sıcak beyaz)', [255, 236, 186]),
        dip: mk.('Çekmece Dibi', [236, 233, 226]),
        gri: mk.('Ayak Tabanı', [90, 92, 96]),
        fincan: mk.('Krem Fincan', [238, 228, 208]),
        makine: mk.('Zeytin Yeşili', [104, 124, 90]),
        metal: mk.('Paslanmaz', [196, 200, 206]),
        siyah: mk.('Siyah Plastik', [40, 40, 42]),
        seffaf: mk.('Şeffaf Plastik', [205, 225, 238], 0.35),
        cinko: mk.('Çinko Kaplama', [160, 164, 170]),
        nikel: mk.('Nikel', [192, 196, 202]),
        pirinc: mk.('Pirinç Burç', [196, 158, 72]),
        ray: mk.('Ray Çeliği', [168, 171, 176]),
        teker: mk.('Ray Tekerleği', [188, 190, 194]),
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

    # --- Ayak: alt tablanın altına vidalı taban + çevrilerek takılan, dışa eğik konik meşe ayak ---
    def ayak_taban_tanimi
      d = @m.definitions.add('Ayak Tabanı (eğik)')
      torna(d.entities, [[0, 0], [0, 25], [TABAN_T - 0.6, 25], [TABAN_T, 24], [TABAN_T, 0]], 32, @mat[:gri])
      d
    end

    # Ayak ekseni: köşeden dışa AYAK_EGIM kadar eğik (yerel +x yukarı, tabana doğru).
    def ayak_ekseni(x, y)
      ox = x < W / 2 ? -1.0 : 1.0
      oy = y < D / 2 ? -1.0 : 1.0
      s = Math.tan(AYAK_EGIM.degrees) / Math.sqrt(2)
      Geom::Vector3d.new(-ox * s, -oy * s, 1).normalize
    end

    def ayak_boyu
      (Z0 - TABAN_T) / Math.cos(AYAK_EGIM.degrees)
    end

    # Yerel +x yukarı: gövde x∈[-boy, 0] konik (Ø44 → Ø26), üstte tabana giren M8 dişli mil.
    def ayak_tanimi
      d = @m.definitions.add('Konik Meşe Ayak')
      boy = ayak_boyu
      torna(d.entities, [[-boy, 0], [-boy, 13], [-boy + 3, 13.5], [-6, 22], [0, 22], [0, 0]], 32, @mat[:mese])
      torna(d.entities, [[0, 0], [0, 4], [12, 4], [12, 0]], 16, @mat[:celik])
      d
    end

    # Eksen x boyunca, x'e dik iki eksenle konum (eğik ayak için)
    def eksen_v(o, xv)
      a = xv.cross(Z_AXIS)
      a = X_AXIS.clone unless a.valid?
      a.normalize!
      zv = a.cross(xv).normalize
      Geom::Transformation.axes(P(*o), xv, zv.cross(xv), zv)
    end

    # Altın çubuk kulp, 96 mm vida aralığı: yerel +x önden dışarı, y kulp boyu.
    def kulp_tanimi
      d = @m.definitions.add('Altın Çubuk Kulp 96')
      [-1, 1].each { |s| torna(d.entities, [[0, 0], [0, 4], [24, 4], [24, 0]], 16, @mat[:altin]).transform!(tr(0, s * KULP_ARA / 2, 0)) }
      torna(d.entities, [[-62, 0], [-62, 4], [-60, 5.5], [60, 5.5], [62, 4], [62, 0]], 20, @mat[:altin])
        .transform!(eksen([29.5, 0, 0], [0, 1, 0], [1, 0, 0]))
      d
    end

    # Fincan kancası: yerel +x yukarı (panele vidalanan kısım x∈[0, 12]), kanca aşağıda, ucu yerel +z'ye döner.
    def kanca_tanimi
      d = @m.definitions.add('Fincan Kancası')
      torna(d.entities, [[0, 0], [0, 1.6], [12, 1.6], [12, 0]], 10, @mat[:altin])
      torna(d.entities, [[-3, 0], [-3, 4], [0, 4], [0, 0]], 16, @mat[:altin])
      g = d.entities.add_group
      kutu(g.entities, -26, -1.5, -1.5, -3, 1.5, 1.5)
      kutu(g.entities, -29, -1.5, -1.5, -26, 1.5, 14)
      kutu(g.entities, -29, -1.5, 11, -16, 1.5, 14)
      boya(g.entities, @mat[:altin])
      d
    end

    # --- Tanıtım dekoru (kurulumda görünmez): fincanlar kancalarda, rafta iki kavanoz, tezgahta kahve makinesi ---
    def fincan_tanimi
      d = @m.definitions.add('Fincan (dekor)')
      torna(d.entities, [[0, 0], [0, 34], [3, 37], [86, 40], [88, 40], [88, 37], [6, 33], [6, 0]], 32, @mat[:fincan])
      g = d.entities.add_group # kulp halkası arkada
      kutu(g.entities, 70, 38, -4, 78, 60, 4)
      kutu(g.entities, 30, 38, -4, 38, 60, 4)
      kutu(g.entities, 30, 52, -4, 78, 60, 4)
      boya(g.entities, @mat[:fincan])
      d
    end

    def dekor_tanimi
      d = @m.definitions.add('Dekor')
      e = d.entities
      fincan = fincan_tanimi
      [[KANCA_UST, ZT], [KANCA_RAF, UST_RAF_Z]].each do |xs, zust|
        xs.each { |x| e.add_instance(fincan, eksen([x, KANCA_Y - 58, zust - 32 - 88], [0, 0, 1], [0, 1, 0])) }
      end
      [560, 680].each do |x| # kavanozlar
        torna(e, [[0, 0], [0, 52], [150, 52], [150, 0]], 32, @mat[:fincan]).transform!(eksen([x, 290, UST_RAF_Z + T], [0, 0, 1], [1, 0, 0]))
        torna(e, [[0, 0], [0, 54], [20, 54], [20, 0]], 32, @mat[:fincan]).transform!(eksen([x, 290, UST_RAF_Z + T + 150], [0, 0, 1], [1, 0, 0]))
      end
      zt = TEZGAH_Z + T # kahve makinesi
      m = e.add_group
      kutu(m.entities, 50, 140, zt, 270, 380, zt + 60)
      kutu(m.entities, 50, 260, zt + 60, 270, 380, zt + 330)
      kutu(m.entities, 50, 170, zt + 250, 270, 260, zt + 330)
      boya(m.entities, @mat[:makine])
      s = e.add_group
      kutu(s.entities, 120, 175, zt + 210, 200, 255, zt + 250)
      kutu(s.entities, 90, 150, zt + 60, 230, 250, zt + 66)
      boya(s.entities, @mat[:metal])
      torna(e, [[0, 0], [0, 30], [70, 34], [70, 0]], 24, @mat[:seffaf]).transform!(eksen([160, 200, zt + 66], [0, 0, 1], [1, 0, 0]))
      torna(e, [[0, 0], [0, 34], [80, 36], [80, 0]], 24, @mat[:altin]).transform!(eksen([330, 200, zt], [0, 0, 1], [1, 0, 0]))
      d
    end

    # Tüm çektirmeler dünya koordinatında: k = iç köşe noktası, ex/ey/ez bağlantı çerçevesi
    # (x erkeğin panelinden uzağa, z dişinin panelinden uzağa). Alt tabla sol yana yandan kayar, sağ yan ona
    # oturur; ara tabla ve tezgah önden girip iner (tezgahın çektirmeleri altında, görünmez); alt arkalık arkadan
    # girer (vidaları içeriden); üst arkalık çektirmesiz, arkadan vidalanır; üst tabla yukarıdan iner; ön kuşak üst
    # tablanın altına önden kayar.
    def baglantilar
      l = []
      [[:sol_yan, T, 1, 'sol'], [:sag_yan, W - T, -1, 'sag']].each do |yan, xs, sx, t|
        CEK_Y.zip(%w[on arka]).each do |y, yer|
          l << { id: "alt_#{t}_#{yer}", disi: :alt_tabla, erkek: yan, k: [xs, y, Z0 + T], ex: [sx, 0, 0], ez: [0, 0, 1] }
          l << { id: "tez_#{t}_#{yer}", disi: yan, erkek: :tezgah, k: [xs, y, TEZGAH_Z], ex: [0, 0, -1], ez: [sx, 0, 0] }
        end
        ARA_Y.zip(%w[on arka]).each do |y, yer|
          l << { id: "ara_#{t}_#{yer}", disi: :ara_tabla, erkek: yan, k: [xs, y, ARA_Z + T], ex: [sx, 0, 0], ez: [0, 0, 1] }
        end
        UST_Y.zip(%w[on arka]).each do |y, yer|
          l << { id: "ust_#{t}_#{yer}", disi: yan, erkek: :ust_tabla, k: [xs, y, ZT], ex: [0, 0, -1], ez: [sx, 0, 0] }
        end
        [[:alt_arka, ALT_ARKA_Z, 'aa']].each do |ark, zs, kod|
          zs.zip(%w[alt ust]).each do |z, yer|
            l << { id: "#{kod}_#{t}_#{yer}", disi: yan, erkek: ark, k: [xs, D - T, z], ex: [0, -1, 0], ey: [0, 0, 1], ez: [sx, 0, 0] }
          end
        end
      end
      KUSAK_X.each_with_index do |x, i|
        l << { id: "kusak_#{i + 1}", disi: :ust_tabla, erkek: :kusak, k: [x, HY + T, ZT], ex: [0, 1, 0], ey: [1, 0, 0], ez: [0, 0, -1] }
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

    # Yan profili (y, z yan-yerel): altta tam derinlik, tezgah üstünde iç kavisle üst bölme derinliğine çekilir;
    # arkada tezgahın alt yüzü hizasından yukarısı 18 mm sığlaşır (tam genişlik üst arkalık yanların arka kenarına biner).
    def yan_profili
      zt = TEZGAH_Z + T - Z0
      za = TEZGAH_Z - Z0
      h = ZT - Z0
      r = KAVIS_R
      kavis = (0..8).map { |i| a = -(90.0 * i / 8).degrees; [HY - r + r * Math.cos(a), zt + r + r * Math.sin(a)] }
      [[0, 0], [D, 0], [D, za], [D - T, za], [D - T, h], [HY, h]] + kavis + [[0, zt]]
    end

    # Yan: kapak menteşe tabanları, raf pimleri, çektirmeler.
    def dis_yan(k, sx)
      d = parca_tanimi(AD[k])
      e = d.entities
      it(e, yan_profili.map { |y, z| P(0, y, z) }, yon(1, 0, 0), T)
      boya(e, @mat[:govde])
      xi = sx > 0 ? T : 0.0 # iç yüz
      cektirmeler(e, k)
      KAPI.each_value.select { |h| h[:sx] == sx }.flat_map { |h| h[:mentese] }.each do |hz|
        e.add_instance(@taban, mentese_cerceve([xi, T, hz - Z0], sx))
      end
      [[GERI + 2, 340.0, RAF_Z], [HY + 2, UST_D - T - 4, UST_RAF_Z]].each do |y0, der, z|
        [y0 + 40, y0 + der - 40].each { |y| e.add_instance(@pim, eksen([xi, y, z - PIM_R - Z0], [sx, 0, 0], [0, 0, 1])) }
      end
      [d, ORIJIN[k]]
    end

    def sol_yan; dis_yan(:sol_yan, 1); end
    def sag_yan; dis_yan(:sag_yan, -1); end

    def tabla(k, der, mat = :govde)
      d = parca_tanimi(AD[k])
      kutu(d.entities, 0, 0, 0, W - 2 * T, der, T)
      boya(d.entities, @mat[mat])
      cektirmeler(d.entities, k)
      d
    end

    # Alt tabla: gömme önlerin arkasında; altında eğik ayakların tabanları (ayaklar demonte, çevrilerek takılır).
    def alt_tabla
      d = tabla(:alt_tabla, D - T - GERI)
      e = d.entities
      AYAK_XY.each_with_index do |(x, y), i|
        lx, ly = x - T, y - GERI
        xv = ayak_ekseni(x, y)
        e.add_instance(@ayak_taban, eksen([lx, ly, 0], [0, 0, -1], [1, 0, 0]))
        o = [lx, ly, -TABAN_T]
        vida_koy(e, @ayak, eksen_v(o, xv), P(*o), xv, 40.0, 0.0, xv.reverse, AYAKLAR[i])
      end
      [d, ORIJIN[:alt_tabla]]
    end

    def ara_tabla; [tabla(:ara_tabla, D - T - GERI), ORIJIN[:ara_tabla]]; end
    def tezgah; [tabla(:tezgah, D - T), ORIJIN[:tezgah]]; end

    # Arkalıklar: ince duralit değil, ürünün kendi malzemesi — 18 mm kumtaşı. Alt arkalık yanların arasında,
    # çektirmeli; üst arkalık tam genişlikte, yanların arka kenarına arkadan 4 vidayla (önde bağlantı görünmez).
    def alt_arka
      d = parca_tanimi(AD[:alt_arka])
      kutu(d.entities, 0, 0, 0, W - 2 * T, T, TEZGAH_Z - Z0)
      boya(d.entities, @mat[:govde])
      cektirmeler(d.entities, :alt_arka)
      [d, ORIJIN[:alt_arka]]
    end

    def ust_arka
      d = parca_tanimi(AD[:ust_arka])
      e = d.entities
      kutu(e, 0, 0, 0, W, T, ZT - TEZGAH_Z)
      boya(e, @mat[:govde])
      i = 0
      [T / 2, W - T / 2].each do |x|
        UST_ARKA_Z.each do |z|
          o = [x, T, z - TEZGAH_Z]
          vida_koy(e, @avida, eksen(o, [0, -1, 0], [0, 0, 1]), P(*o), Geom::Vector3d.new(0, -1, 0), 50.0, 2.8,
                   Geom::Vector3d.new(0, 1, 0), ARKA_VIDALARI[i])
          i += 1
        end
      end
      [d, ORIJIN[:ust_arka]]
    end

    # LED şerit: verilen yüzün altına yapışık, sıcak beyaz (fabrikada takılı)
    def led(e, x0, x1, y0, y1)
      g = e.add_group
      g.name = 'LED Şerit'
      kutu(g.entities, x0, y0, -3, x1, y1, 0)
      boya(g.entities, @mat[:led])
    end

    def kanca_koy(e, xs, y, idler)
      xs.each_with_index do |x, i|
        o = [x, y, 0]
        vida_koy(e, @kanca, eksen(o, [0, 0, 1], [0, -1, 0]), P(*o), Geom::Vector3d.new(0, 0, 1), 12.0, 0.0,
                 Geom::Vector3d.new(0, 0, -1), idler[i])
      end
    end

    # Üst tabla: altında LED şerit (ön kuşağın arkasında) ve fincan kancaları (demonte).
    def ust_tabla
      d = parca_tanimi(AD[:ust_tabla])
      e = d.entities
      kutu(e, 0, 0, 0, W, UST_D, T)
      boya(e, @mat[:govde])
      cektirmeler(e, :ust_tabla)
      led(e, 60, W - 60, 60, 68)
      kanca_koy(e, KANCA_UST, KANCA_Y - HY, KANCALAR.first(KANCA_UST.size))
      [d, ORIJIN[:ust_tabla]]
    end

    # Ön kuşak: üst tablanın altında önde; uçlarda 13 cm, ortada 5 cm, aradaki köşeler içe kavisli (CNC).
    def kusak
      d = parca_tanimi(AD[:kusak])
      gen = W - 2 * T
      k = KUSAK
      zo = k[:h] - k[:orta]
      sol = (0..8).map { |i| a = (180 - 11.25 * i).degrees; [k[:uc] + k[:r] + k[:r] * Math.cos(a), zo * Math.sin(a)] }
      sag = sol.reverse.map { |x, z| [gen - x, z] }
      hat = [[0, k[:h]], [0, 0]] + sol + sag + [[gen, 0], [gen, k[:h]]]
      it(d.entities, hat.map { |x, z| P(x, 0, z) }, yon(0, 1, 0), T)
      boya(d.entities, @mat[:govde])
      cektirmeler(d.entities, :kusak)
      [d, ORIJIN[:kusak]]
    end

    def raf
      d = parca_tanimi(AD[:raf])
      kutu(d.entities, 0, 0, 0, W - 2 * T - 3.5, 340, T)
      boya(d.entities, @mat[:govde])
      [d, ORIJIN[:raf]]
    end

    # Üst raf: altında önde LED şerit ve fincan kancaları.
    def ust_raf
      d = parca_tanimi(AD[:ust_raf])
      e = d.entities
      kutu(e, 0, 0, 0, W - 2 * T - 3.5, UST_D - T - 4, T)
      boya(e, @mat[:govde])
      led(e, 40, W - 2 * T - 40, 8, 16)
      kanca_koy(e, KANCA_RAF.map { |x| x - T - 1.75 }, KANCA_Y - HY - 2, KANCALAR.last(KANCA_RAF.size))
      [d, ORIJIN[:ust_raf]]
    end

    # Gömme kapak: yanların arasında, yan iç yüzündeki tabanlara gömme menteşeyle. Kapak-yerel orijin = sol ön alt köşe.
    def kapak(k)
      h = KAPI[k]
      d = parca_tanimi(AD[k])
      e = d.entities
      yuk = h[:z][1] - h[:z][0]
      kutu(e, 0, 0, 0, KAPI_W, T, yuk)
      sx = h[:sx]
      xi = h[:panel] - h[:x0]
      hdler = h[:mentese].map { |hz| mentese_cerceve([xi, T, hz - h[:z][0]], sx) }
      hdler.each { |hd| daire_it(e, P(0, 0, KAP_ZC).transform(hd), Y_AXIS, 17.5, yon(0, -1, 0), 12.5, 32) }
      kx = sx > 0 ? KAPI_W - 40 : 40.0
      kz = yuk - [140, yuk / 2].min
      delik = [-1, 1].map { |s| [kx, kz + s * KULP_ARA / 2] }
      delik.each { |x, z| daire_it(e, P(x, 0, z), Y_AXIS, 2.5, yon(0, 1, 0), T, 16) }
      boya(e, @mat[:on])
      no = k.to_s.sub('kapak_', '')
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
      @m.start_operation('Kahve Köşesi kurulum modeli', true)
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
      @avida = vida_tanimi('Sunta Vidası 4x50', 4.2, 2.8, 2, 50)
      @disi = disi_tanimi
      @erkek = erkek_tanimi
      @pim = pim_tanimi
      @taban = taban_tanimi
      @kol = kol_tanimi
      @kap = kap_tanimi
      @bag = bag_tanimi
      @ayak_taban = ayak_taban_tanimi
      @ayak = ayak_tanimi
      @kulp = kulp_tanimi
      @kanca = kanca_tanimi
      arac = tornavida_tanimi
      kisa = kisa_tornavida_tanimi
      cekic = cekic_tanimi

      tags = SIRA.map { |k| [k, @m.layers.add(ETIKET[k])] }.to_h
      liste_tag = @m.layers.add(LISTE_TAG)
      arac_tag = @m.layers.add(ARAC_TAG)
      dekor_tag = @m.layers.add(DEKOR_TAG)

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
      dk = @m.entities.add_instance(dekor_tanimi, Geom::Transformation.new)
      dk.layer = dekor_tag

      parca_listesi(liste_tag)
      stil
      bagla
      son_durum
      sahneler
      dekor_tag.visible = false
      @m.commit_operation
      @m.save(kayit_yolu) if kayit_yolu
      "Kuruldu: #{SIRA.size} parça, #{@vidalar.size} animasyonlu vida/kulp/ayak/kanca, #{@m.pages.size} sahne"
    end

    # Kutu içeriği: paneller yere yatırılmış, fabrikada takılı hırdavat üstte; ayaklar, kulplar, vidalar ve fincan
    # kancaları ayrı.
    def parca_listesi(tag)
      rx = ->(a) { Geom::Transformation.rotation(ORIGIN, X_AXIS, a.degrees) }
      ry = ->(a) { Geom::Transformation.rotation(ORIGIN, Y_AXIS, a.degrees) }
      rz = ->(a) { Geom::Transformation.rotation(ORIGIN, Z_AXIS, a.degrees) }
      bir = Geom::Transformation.new
      yerlesim = {
        sol_yan: [rz.(90) * ry.(-90), 1300, 0], sag_yan: [rz.(90) * ry.(90), 1800, 0],
        alt_arka: [rx.(-90), 2300, 0], ust_arka: [rx.(-90), 3200, 0], ust_tabla: [rx.(180), 4100, 0],
        tezgah: [bir, 2300, 950], alt_tabla: [bir, 3200, 950], ara_tabla: [bir, 4100, 950],
        raf: [bir, 2300, 1500], ust_raf: [bir, 3200, 1500], kusak: [rx.(90), 4100, 1500],
        kapak_sol: [rx.(90), 2750, 2000], kapak_sag: [rx.(90), 3350, 2000]
      }
      etiket = AD
      @m.entities.grep(Sketchup::ComponentInstance).select { |i| nit(i, :parca) && !%w[tornavida kisa_tornavida cekic].include?(nit(i, :parca)) }.each do |ana|
        k = nit(ana, :parca).to_sym
        rot, x, y = yerlesim[k]
        b = Geom::BoundingBox.new # demonte parçalar yerleşime katılmasın
        ana.definition.entities.each { |g| b.add(g.bounds) unless g.is_a?(Sketchup::ComponentInstance) && DEMONTE.include?(nit(g, :vida)) }
        bb = Geom::BoundingBox.new
        8.times { |c| bb.add(b.corner(c).transform(rot)) }
        kay = Geom::Transformation.translation(P(x, y, 0) - bb.min)
        i = @m.entities.add_instance(ana.definition, kay * rot)
        i.layer = tag
        on = Geom::Point3d.new(bb.center.x, bb.min.y, bb.max.z).transform(kay)
        txt = @m.entities.add_text(etiket[k], on, Geom::Vector3d.new(0, -90.mm, 0))
        txt.layer = tag
      end
      ek = lambda do |defn, adet, x, dx, ad, eks|
        adet.times { |i| @m.entities.add_instance(defn, eksen([x + i * dx, -500, eks[2]], eks[0], eks[1])).layer = tag }
        @m.entities.add_text(ad, P(x, -620, 0), Geom::Vector3d.new(0, -90.mm, 0)).layer = tag
      end
      ek.(@ayak, AYAKLAR.size, 1300, 70, "Ayak (#{AYAKLAR.size})", [[0, 1, 0], [0, 0, 1], 22])
      ek.(@kulp, KULPLAR.size, 2000, 80, "Kulp (#{KULPLAR.size})", [[0, 0, 1], [1, 0, 0], 0])
      ek.(@kvida, KULP_VIDALARI.size, 2650, 25, "Kulp Vidası (#{KULP_VIDALARI.size})", [[0, 1, 0], [0, 0, 1], 4])
      ek.(@avida, ARKA_VIDALARI.size, 3350, 30, "Arkalık Vidası 4x50 (#{ARKA_VIDALARI.size})", [[0, 1, 0], [0, 0, 1], 4])
      ek.(@kanca, KANCALAR.size, 3850, 30, "Fincan Kancası (#{KANCALAR.size})", [[0, 1, 0], [0, 0, 1], 2])
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
        ['0 Kutu İçeriği', [], :liste, 'Paneller ve fabrikada takılı bağlantı elemanları; ayaklar, kulplar, vidalar ve fincan kancaları ayrı.'],
        ['1 Ayaklar', %i[alt_tabla], 1, 'Ayakları alt tablanın altındaki eğik tabanlara çevirerek takın.'],
        ['2 Sol Yan + Alt Tabla', %i[sol_yan], 2, 'Alt tablayı sol yandaki 2 şeffaf çektirmeye geçirip vidaları sıkın.'],
        ['3 Sağ Yan', %i[sag_yan], 3, 'Sağ yanı alt tabladaki 2 çektirmeye oturtup vidaları sıkın.'],
        ['4 Ara Tabla', %i[ara_tabla], 4, 'Ara tablayı önden sürüp 4 çektirmeye oturtun, vidaları sıkın.'],
        ['5 Tezgah', %i[tezgah], 5, 'Tezgahı önden sürüp yanlardaki 4 çektirmeye oturtun, vidaları alttan sıkın.'],
        ['6 Alt Arkalık', %i[alt_arka], 6, 'Alt arkalığı arkadan yerleştirin, 4 çektirme vidasını içeriden sıkın.'],
        ['7 Üst Arkalık', %i[ust_arka], 7, 'Üst arkalığı tezgahın üstüne arkadan yerleştirin, yanların arka kenarına 4 vidayla arkadan vidalayın.'],
        ['8 Üst Tabla', %i[ust_tabla], 8, 'Üst tablayı yanların üstüne oturtun, 4 çektirme vidasını sıkın.'],
        ['9 Ön Kuşak', %i[kusak], 9, 'Ön kuşağı üst tablanın altına önden sürüp 2 çektirme vidasını sıkın.'],
        ['10 Raflar', %i[raf ust_raf], 10, 'Rafları raf pimlerinin üzerine yerleştirin.'],
        ['11 Kapaklar', KAPILAR, :kapak, 'İki kapaktaki menteşe gövdelerini yanlardaki tabanlara geçirip vidaları sıkın.'],
        ['12 Kulplar', [], :kulp, 'Kulpları önden takıp vidalarını kapağın arkasından sıkın.'],
        ['13 Fincan Kancaları', [], :kanca, 'Fincan kancalarını üst tablanın ve üst rafın altındaki deliklere çevirerek takın.'],
        ['14 Bitmiş Ürün', [], :bitti, 'Kurulum tamamlandı.']
      ]
      acik = []
      tanim.each do |ad, yeni, kam, aciklama|
        acik += yeni
        liste = kam == :liste
        @m.layers.each do |l|
          k = ETIKET.key(l.name)
          l.visible = if l.name == LISTE_TAG then liste
                      elsif l.name == ARAC_TAG || l.name == DEKOR_TAG then false
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
      raise 'Model bulunamadı — önce OzcanKurulum::KahveKosesi.kur' unless @parca.size == SIRA.size && @arac && @kisa_arac && @cekic
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

    # aci > 0 açık: gömme kapak dış ön köşesindeki dikey eksende açılır (sol kapak sola, sağ kapak sağa).
    def kapi_R(k, aci)
      h = KAPI[k]
      Geom::Transformation.rotation(P(h[:eksen], 0, 0), Z_AXIS, h[:yon] * aci.degrees)
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

    def kapak_tak(k)
      z = @cz
      z.kamera(1.2, KAM[:kapak])
      z.an { |s, _| s[:kapi][k] = 90.0 }
      hareket(k, [0, -420, 0], [0, 0, 0], 1.8)
      no = k.to_s.sub('kapak_', '')
      vida_sik("mentese_#{no}_1", nil, tur: 3, sure: 0.8)
      vida_sik("mentese_#{no}_2", nil, tur: 3, sure: 0.8, yakin: false)
      z.kamera(0.8, KAM[:kapak])
      z.olay(1.4) { |s, u| s[:kapi][k] = 90.0 * (1 - u) }
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

    def kulplari_tak
      z = @cz
      z.kamera(1.2, KAM[:kulp])
      z.olay(1.0) { |s, u| KAPILAR.each { |k| s[:kapi][k] = 95.0 * u } }
      KAPILAR.each_with_index { |k, i| kulp_tak("kulp_#{k}", i.zero?) }
      z.kamera(0.8, KAM[:kulp])
      z.olay(1.0) { |s, u| KAPILAR.each { |k| s[:kapi][k] = 95.0 * (1 - u) } }
      z.bekle(0.3)
    end

    # Fincan kancaları elle çevrilerek takılır.
    def kancalari_tak
      z = @cz
      z.kamera(1.2, KAM[:kanca])
      z.an { |s, _| KANCALAR.each { |id| s[:v][id] = { adv: 1.0, ang: 0.0 } } }
      z.bekle(0.3)
      z.olay(1.8, false) { |s, u| KANCALAR.each { |id| s[:v][id] = { adv: 1 - u, ang: 360.0 * 4 * u } } }
      z.bekle(0.5)
    end

    def cizelge
      @cz = z = Cizelge.new
      z.an { |s, _| DEMONTE.each { |id| s[:v][id] = { gizli: true } } } # takılana kadar görünmesin
      z.baslik('Kutu içeriği — bağlantı elemanları panellere takılı gelir; ayaklar, kulplar, vidalar ve kancalar ayrı')
      z.kamera(0, KAM[:liste])
      z.bekle(3.5)

      z.baslik('1 · Ayakları alt tablanın altındaki eğik tabanlara çevirerek takın')
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

      z.baslik('2 · Alt tablayı sol yandaki iki şeffaf çektirmeye geçirin, vidaları sıkın')
      z.an { |s, _| s[:p][:sol_yan] = { vis: true, off: [-400, 0, 0] } }
      z.kamera(1.2, KAM[2])
      hareket(:sol_yan, [-400, 0, 0], [-2, 0, 0], 1.8)
      sirayla_sik(%w[on arka].map { |y| "alt_sol_#{y}" }, KAM[2], cekler: cek_listesi(:sol_yan, [-2, 0, 0], 2))
      z.kamera(0.8, KAM[2])
      z.bekle(0.3)

      z.baslik('3 · Sağ yanı alt tabladaki çektirmelere oturtun, vidaları sıkın')
      z.kamera(1.2, KAM[3])
      hareket(:sag_yan, [400, 0, 0], [2, 0, 0], 1.8)
      sirayla_sik(%w[on arka].map { |y| "alt_sag_#{y}" }, KAM[3], cekler: cek_listesi(:sag_yan, [2, 0, 0], 2))
      z.kamera(0.8, KAM[3])
      z.bekle(0.3)

      z.baslik('4 · Ara tablayı önden sürüp dört çektirmeye oturtun, vidaları sıkın')
      z.kamera(1.2, KAM[4])
      hareket(:ara_tabla, [0, -500, 40], [0, 0, 40], 1.4)
      hareket(:ara_tabla, [0, 0, 40], [0, 0, 2], 0.6)
      ids = %w[sol sag].flat_map { |t| %w[on arka].map { |y| "ara_#{t}_#{y}" } }
      sirayla_sik(ids, KAM[4], cekler: cek_listesi(:ara_tabla, [0, 0, 2], ids.size))
      z.kamera(0.8, KAM[4])
      z.bekle(0.3)

      z.baslik('5 · Tezgahı önden sürüp yanlardaki dört çektirmeye oturtun, vidaları alttan sıkın')
      z.kamera(1.2, KAM[5])
      hareket(:tezgah, [0, -500, 40], [0, 0, 40], 1.4)
      hareket(:tezgah, [0, 0, 40], [0, 0, 2], 0.6)
      ids = %w[sol sag].flat_map { |t| %w[on arka].map { |y| "tez_#{t}_#{y}" } }
      sirayla_sik(ids, KAM[5], cekler: cek_listesi(:tezgah, [0, 0, 2], ids.size))
      z.kamera(0.8, KAM[5])
      z.bekle(0.3)

      z.baslik('6 · Alt arkalığı (18 mm kumtaşı) arkadan yerleştirin, dört çektirme vidasını içeriden sıkın')
      z.kamera(1.2, KAM[6])
      hareket(:alt_arka, [0, 400, 0], [0, 2, 0], 1.6)
      ids = %w[sol sag].flat_map { |t| %w[alt ust].map { |y| "aa_#{t}_#{y}" } }
      sirayla_sik(ids, KAM[6], cekler: cek_listesi(:alt_arka, [0, 2, 0], ids.size), bak: [0.3, -1, 0.4])
      z.kamera(0.8, KAM[6])
      z.bekle(0.3)

      z.baslik('7 · Üst arkalığı tezgahın üstüne arkadan oturtun, yanların arka kenarına dört vidayla arkadan vidalayın')
      z.kamera(1.2, KAM[7])
      hareket(:ust_arka, [0, 400, 0], [0, 0, 0], 1.6)
      z.an { |s, _| ARKA_VIDALARI.each { |id| s[:v][id] = { adv: 1.0, ang: 0.0 } } }
      z.bekle(0.3)
      sirayla_sik(ARKA_VIDALARI, KAM[7], tur: 5, bak: [0.5, 1, 0.35])
      z.kamera(0.8, KAM[7])
      z.bekle(0.3)

      z.baslik('8 · Üst tablayı yanların üstüne oturtun, dört çektirme vidasını sıkın')
      z.kamera(1.2, KAM[8])
      hareket(:ust_tabla, [0, 0, 300], [0, 0, 2], 1.8)
      ids = %w[sol sag].flat_map { |t| %w[on arka].map { |y| "ust_#{t}_#{y}" } }
      sirayla_sik(ids, KAM[8], cekler: cek_listesi(:ust_tabla, [0, 0, 2], ids.size))
      z.kamera(0.8, KAM[8])
      z.bekle(0.3)

      z.baslik('9 · Ön kuşağı üst tablanın altına önden sürün, iki çektirme vidasını sıkın')
      z.kamera(1.2, KAM[9])
      hareket(:kusak, [0, -350, 0], [0, -2, 0], 1.4)
      ids = %w[1 2].map { |i| "kusak_#{i}" }
      sirayla_sik(ids, KAM[9], cekler: cek_listesi(:kusak, [0, -2, 0], ids.size), bak: [0.3, -0.7, -0.6])
      z.kamera(0.8, KAM[9])
      z.bekle(0.3)

      z.baslik('10 · Rafları raf pimlerinin üzerine yerleştirin')
      z.kamera(1.2, KAM[10])
      %i[raf ust_raf].each do |k|
        hareket(k, [0, -450, 40], [0, 0, 40], 1.2)
        hareket(k, [0, 0, 40], [0, 0, 0], 0.4)
      end
      z.bekle(0.3)

      z.baslik('11 · İki kapağın menteşe gövdelerini yanlardaki tabanlara geçirin, vidaları sıkın')
      KAPILAR.each { |k| kapak_tak(k) }
      z.bekle(0.3)

      z.baslik('12 · Kulpları önden takın; vidalarını kapağın arkasından sıkın')
      kulplari_tak

      z.baslik('13 · Fincan kancalarını üst tablanın ve üst rafın altındaki deliklere çevirerek takın')
      kancalari_tak

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

    # Montajlı son durum: tüm parçalar yerinde, vidalar, ayaklar, kulplar ve kancalar takılı, kapaklar kapalı.
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
    # Adımlar başlıkların sırasıdır: 0 kutu içeriği, 1-13 montaj, 14 bitmiş ürün.
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
