# encoding: UTF-8
# Aynalı Ütü Dolabı (45 x 14,8 x 125 cm, duvara asma) — model ve kurulum kılavuzu.
# Tarif: research_notes/Urun firsatlari 2026-10-28/tarif-01-aynali-utu-dolabi.txt (kullanıcı onayı 28.10.2026).
# Kapalıyken boy aynası; kapak açılınca içeride duvara katlanmış 90 x 30 ütü masası. Mekanizma YER TUTUCU blok
# (tabla 900 x 300 x 25, braket 320 x 260 x 40); numune ölçülünce güncellenecek.
# Gövde mat beyaz 18 mm sunta, tablalar yanların arasında (minifiks + kavela), 8 mm arkalık kanalda. Tam bindirme
# aynalı kapak (3 mm akrilik ayna), solda 3 frenli menteşe, sağ kenarda siyah kenar profil kulp. Dolap duvardaki
# askı rayına iki ayarlı askıyla asılır, altta arkalıktan iki vida + Ø25 pulla sabitlenir; alt kenar yerden 600 mm.
#
# Her panel ayrı bileşen; fabrikada takılı gelenler (minifiks bulonları, menteşe tabanları ve gövdeleri, askılar,
# kapaktaki ayna) panelin içinde. Minifiks gövdeleri, kavelalar, minifiks kapakları, kancalar, kulp, askı rayı ve
# vida-dübel-pul ayrı gelir; mekanizma kendi kutusunda.
#   1 kavelalar  2 sol yan  3 sol minifiksler  4 arkalık  5 sağ yan + minifiksler  6 minifiks kapakları
#   7 kancalar  8 askı rayı  9 dolabı asma  10 alt vidalar  11 ütü masası mekanizması  12 kapak  13 kulp
# Tarifteki "sol yan + alt tabla + sağ yan → arkalık → üst tabla en son" sırası uygulanamaz: iki yandaki bulonlar
# içeri taştığı için üst tabla iki yanın arasına sonradan giremez. Bu yüzden iki tabla sol yana bağlanır, arkalık
# açık sağ taraftan kanala sürülür, sağ yan en son iki tablaya birden geçer.
#
# SketchUp > Pencere > Ruby Konsolu:
#   load 'C:/.../scripts/product-3d/kurulum/aynali_utu_dolabi.rb'
#   OzcanKurulum::UtuDolabi.kur                 # AÇIK MODELİ TEMİZLER, modeli sıfırdan kurar
#   OzcanKurulum::UtuDolabi.oynat               # montaj animasyonunu ekranda oynatır
#   OzcanKurulum::UtuDolabi.kumanda             # klavyeyle adım adım: → ← Enter, K serbest kamera, Esc
#   (konsoldan: sonraki, onceki, durdur, devam, adim(3), git(3), bitir)
#   OzcanKurulum::UtuDolabi.kaydet('C:/kareler') # animasyonu PNG karelere yazar
#
# Koordinatlar mm: X genişlik (0 = sol dış yüz), Y derinlik (0 = gövde ön yüzü, +Y duvara; kapak Y=-18..0'da),
# Z yükseklik (0 = zemin; dolabın alt kenarı 600). Tarifteki yükseklikler iç tabandan (Z = 618) ölçülür.

module OzcanKurulum
  module UtuDolabi
    extend self

    # ------------------------------------------------------------------
    # Ölçüler (mm)
    # ------------------------------------------------------------------
    W = 450.0            # genişlik
    T = 18.0             # panel kalınlığı
    D = 130.0            # gövde derinliği (yan); kapakla 148
    H = 1250.0           # gövde yüksekliği
    Z0 = 600.0           # dolabın alt kenarı (yerden)
    ZT = Z0 + H          # üst kenar 1850
    IZ = Z0 + T          # iç taban (tarifte 0)
    IW = W - 2 * T       # iç genişlik 414
    KANAL_Y = [D - 10 - 8.5, D - 10].freeze # arkalık kanalı 8,5 geniş, 8 derin, arka kenardan 10 mm içeride
    KANAL_DER = 8.0
    ARKA_T = 8.0
    ARKA_Y = KANAL_Y[0] + 0.25 # arkalığın ön yüzü (iç derinlik 111,75)
    # Minifiks: uzun kenardan (ön/arka) 32, kısa kenardan (tabla ucu) 36 mm; kavela 72 mm içeride, ikisinin arasında
    MF_Y = [32.0, D - 32.0].freeze
    KAM_ARA = 36.0
    KAVELA_Y = 72.0
    KAVELA = { r: 4.0, tabla: 18.0, yan: 12.0 }.freeze # Ø8 x 30: 18 mm tablada, 12 mm yanda
    # Askı: yanların iç yüzünde üst-arka köşede; arkalıkta 20 x 40 kesikten geçen kanca duvardaki raya oturur
    ASKI = { x: 20.0, y0: 62.0, h: 60.0 }.freeze
    RAY = { z0: ZT - T - 72, z1: ZT - T - 17, dudak: 15.0 }.freeze # 414 mm askı rayı (duvarda, arkalığın arkasında)
    ALT_VIDA = { z: IZ + 50, x: [T + 60, W - T - 60] }.freeze      # arkalıktan duvara, Ø25 pullu
    KANCA_Z = [IZ + 900, IZ + 1050].freeze # sol iç yan, arka yarı
    KANCA_Y = 88.0
    # Mekanizma (yer tutucu): ortalı; tabla katlıyken pivot 262'den 1162'ye, braket 100–360 arası
    MASA = { gen: 300.0, boy: 900.0, kal: 25.0, pivot: IZ + 262 }.freeze
    BRAKET = { gen: 320.0, h: 260.0, der: 40.0, z0: IZ + 100 }.freeze
    BRAKET_Y = ARKA_Y - 0.25 - BRAKET[:der] # braketin ön yüzü 71,5
    MASA_Y = BRAKET_Y - MASA[:kal]          # katlı tablanın ön yüzü 46,5 (pivot ekseni)
    MASA_X = (W - MASA[:gen]) / 2
    BRAKET_X = (W - BRAKET[:gen]) / 2
    # Kapak: tam bindirme, her kenarda 2 mm pay, arka yüzü gövde ön yüzünde; sol yanda 3 frenli menteşe
    KAPI_X = 2.0
    KAPI_W = W - 4
    KAPI_Z = [Z0 + 2, ZT - 2].freeze
    KAPI = {
      kapak: { x0: KAPI_X, z: KAPI_Z, gen: KAPI_W, eksen: KAPI_X, py: -T, yon: -1, panel: T, sx: 1,
               mentese: [KAPI_Z[0] + 100, KAPI_Z[0] + 623, KAPI_Z[1] - 100] },
      masa: { x0: MASA_X, z: [MASA[:pivot], MASA[:pivot] + MASA[:boy]], gen: MASA[:gen], py: MASA_Y, klapa: true }
    }.freeze
    KAPILAR = KAPI.keys.freeze
    KAP_ZC = KAPI_X + 22.5 - T # kap merkezi yan iç yüzünden 6,5 mm (kapak kenarından 22,5)
    AYNA = { pay: 25.0, t: 3.0 }.freeze
    KULP_L = 200.0 # kenar profil kulp boyu; kapağın sağ kenarında, dikeyde ortalı
    DIS = [650.0, -350.0, -Z0].freeze     # askı rayı takılırken gövde yerde, sağda bekler
    KAPAK_DIS = [0.0, -400.0, 0.0].freeze # kapak 90° açık, önden gelir
    PLAKA_T = 3.0

    DIKEY_FOV = 30.0
    VIDEO_FOV = 50.0

    DICT = 'ozcan_kurulum'
    GOVDE = %i[alt_tabla ust_tabla sol_yan arkalik sag_yan].freeze
    SIRA = (GOVDE + %i[ray braket] + KAPILAR).freeze
    AD = {
      alt_tabla: 'Alt Tabla', ust_tabla: 'Üst Tabla', sol_yan: 'Sol Yan', sag_yan: 'Sağ Yan', arkalik: 'Arkalık',
      ray: 'Askı Rayı', braket: 'Ütü Masası Braketi', masa: 'Ütü Masası', kapak: 'Aynalı Kapak'
    }.freeze
    ETIKET = {
      alt_tabla: '01 Tablalar', ust_tabla: '01 Tablalar', sol_yan: '02 Sol Yan', arkalik: '03 Arkalık',
      sag_yan: '04 Sağ Yan', ray: '05 Askı Rayı', braket: '06 Ütü Masası', masa: '06 Ütü Masası', kapak: '07 Kapak'
    }.freeze
    LISTE_TAG = '00 Parça Listesi'
    ARAC_TAG = '99 Tornavida'
    DUVAR_TAG = 'Duvar ve Zemin'
    DEKOR_TAG = 'Dekor (ayna yansıması)'
    MASA_DEKOR_TAG = 'Dekor (ütü, gömlek, sprey)'
    OLCU_TAG = 'Ölçüler'

    # Kamera noktaları [göz, hedef] (mm)
    KAM = {
      liste:   [[2550, -1800, 5000], [2550, 60, 0]],
      1 =>     [[900, -1000, 1150], [225, 65, 640]],
      '1b' =>  [[900, -1000, 2380], [225, 65, 1830]],
      2 =>     [[-1500, -2500, 2300], [225, 60, 1225]],
      3 =>     [[1400, -2600, 2500], [225, 60, 1225]],
      4 =>     [[2000, -1500, 2300], [225, 80, 1225]],
      5 =>     [[1900, -2500, 2200], [225, 60, 1225]],
      6 =>     [[650, -700, 2600], [225, 65, 1850]],
      7 =>     [[800, -800, 1900], [60, 88, 1590]],
      8 =>     [[1500, -3200, 1350], [560, 0, 930]],
      9 =>     [[1100, -2500, 1850], [250, 60, 1220]],
      10 =>    [[800, -1000, 1150], [225, 100, 700]],
      11 =>    [[1300, -2100, 1600], [225, -100, 1050]],
      13 =>    [[950, -1550, 1500], [70, -330, 1225]],
      kapak:   [[1500, -2600, 1900], [225, -150, 1225]],
      bitti:   [[1500, -2700, 1800], [225, -220, 1150]]
    }.freeze
    # Tanıtım görselleri (4:5): ad, kapak/masa açıları, açık katmanlar, [göz, hedef]
    TANITIM = [
      ['1_kapali_ayna', {}, %i[duvar dekor], [[950, -2700, 1350], [225, 60, 1170]]],
      ['2_kapak_acik_masa_katli', { kapak: 105 }, %i[duvar], [[1150, -2800, 1600], [200, 0, 1200]]],
      ['3_utu_masasi_acik', { kapak: 105, masa: 90 }, %i[duvar masa_dekor], [[1500, -2700, 1800], [180, -280, 1050]]],
      ['4_kulp_mentese_yakin', { kapak: 70 }, %i[duvar], [[950, -1350, 1600], [110, -220, 1300]]],
      ['5_olculer', {}, %i[duvar olcu], [[2000, -3300, 1300], [280, 60, 960]]]
    ].freeze

    # Parçaların yerleşim orijini (bileşen orijini = parçanın min köşesi)
    ORIJIN = {
      alt_tabla: [T, 0, Z0], ust_tabla: [T, 0, ZT - T], sol_yan: [0, 0, Z0], sag_yan: [W - T, 0, Z0],
      arkalik: [T - KANAL_DER + 1, ARKA_Y, Z0 + T - KANAL_DER + 1], ray: [T, D - 10, 0],
      braket: [BRAKET_X, BRAKET_Y, BRAKET[:z0]], kapak: [KAPI_X, -T, KAPI_Z[0]], masa: [MASA_X, MASA_Y, MASA[:pivot]]
    }.freeze

    KAVELALAR = %w[alt ust].flat_map { |t| %w[sol sag].map { |y| "kavela_#{t}_#{y}" } }.freeze
    KAMLAR = %w[sol sag].to_h { |y| [y, %w[alt ust].flat_map { |t| %w[on arka].map { |o| "mf_#{t}_#{y}_#{o}" } }] }.freeze
    KAPAKCIKLAR = %w[sol sag].flat_map { |y| %w[on arka].map { |o| "mfkapak_#{y}_#{o}" } }.freeze
    KANCALAR = %w[1 2].map { |i| "kanca_#{i}" }.freeze
    KANCA_VIDALARI = KANCALAR.map { |k| "#{k}_vida" }.freeze
    ASKI_VIDALARI = %w[sol sag].map { |y| "aski_#{y}" }.freeze
    RAY_VIDALARI = (1..3).map { |i| "ray_vida_#{i}" }.freeze
    ALT_VIDALAR = %w[sol sag].map { |y| "alt_vida_#{y}" }.freeze
    BRAKET_VIDALARI = (1..4).map { |i| "braket_vida_#{i}" }.freeze
    KULP_VIDALARI = %w[1 2].map { |i| "kulp_vida_#{i}" }.freeze
    DEMONTE = (KAVELALAR + KAMLAR.values.flatten + KAPAKCIKLAR + KANCALAR + KANCA_VIDALARI + RAY_VIDALARI +
               ALT_VIDALAR + BRAKET_VIDALARI + ['kulp'] + KULP_VIDALARI).freeze


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
        govde: mk.('Mat Beyaz Sunta', [244, 243, 240]),
        arka: mk.('Beyaz Arkalık (MDF lam)', [238, 237, 233]),
        ayna: mk.('Akrilik Ayna', [200, 210, 218]),
        yansima: mk.('Ayna Yansıması', [255, 255, 255]),
        kulp: mk.('Siyah Mat Alüminyum', [36, 36, 38]),
        krom: mk.('Krom', [205, 208, 214]),
        kavela: mk.('Kavela (kayın)', [214, 182, 140]),
        mfkapak: mk.('Beyaz Minifiks Kapağı', [250, 250, 248]),
        aski: mk.('Askı Gövdesi (beyaz plastik)', [232, 232, 230]),
        braket: mk.('Mekanizma Braketi (beyaz boya)', [228, 228, 226]),
        kilif: mk.('Ütü Masası Kılıfı', [206, 216, 224]),
        duvar: mk.('Duvar (açık bej)', [218, 209, 196]),
        zemin: mk.('Ahşap Zemin', [214, 180, 140]),
        gomlek: mk.('Beyaz Gömlek', [248, 248, 250]),
        utu: mk.('Ütü Gövdesi', [92, 136, 170]),
        sprey: mk.('Sprey Şişesi', [214, 230, 238], 0.85),
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
      doku = File.join(File.dirname(__FILE__), 'aynali_utu_dolabi_yansima.png')
      if File.exist?(doku)
        @mat[:yansima].texture = doku
        @mat[:yansima].texture.size = [396.mm, 1196.mm]
      end
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

    # Duvar vidası + Ø25 geniş pul: pul x∈[0, 1.5] (arkalığa basar), vida başı pulun önünde.
    def pul_vida_tanimi
      d = @m.definitions.add('Vida 5x60 + Ø25 Pul + Dübel')
      prof = [[-3, 0], [-3, 3.8], [-1, 4.6], [0, 4.6], [0, 12.5], [1.5, 12.5], [1.5, 2.5], [58, 2.5], [60, 0.8], [60, 0]]
      torna(d.entities, prof, 24, @mat[:cinko])
      yildiz(d.entities, -3.05, 3.8)
      d
    end

    # Krom kanca: yerel +x panelden dışarı, +z yukarı. Plaka x∈[0, 3]; kol aşağıdan dışa ve yukarı kıvrılır.
    def kanca_tanimi
      d = @m.definitions.add('Krom Kanca')
      e = d.entities
      g = e.add_group
      kutu(g.entities, 0, -8, -22, 3, 8, 22)
      boya(g.entities, @mat[:krom])
      daire_it(g.entities, P(3, 0, 12), X_AXIS, 2.2, yon(-1, 0, 0), 3, 12)
      kol = [0.94, 0, 0.34]
      torna(e, [[0, 0], [0, 3.5], [42, 3.5], [42, 0]], 16, @mat[:krom]).transform!(eksen([2, 0, -12], kol, [-0.34, 0, 0.94]))
      uc = [2 + 42 * 0.94, 0, -12 + 42 * 0.34]
      torna(e, [[0, 0], [0, 3.5], [16, 3.5], [19, 2], [19, 0]], 16, @mat[:krom]).transform!(eksen(uc, [0.2, 0, 1], [-1, 0, 0.2]))
      torna(e, [[-4, 0], [-4, 2], [-2, 4], [2, 4], [4, 2], [4, 0]], 16, @mat[:krom]).transform!(eksen(uc, [1, 0, 0], [0, 0, 1]))
      d
    end

    # Kenar profil kulp (200 mm, siyah mat alüminyum): yerel orijin kapağın sağ kenarı + arka yüzü, kulp ortası.
    # Arka kanat kapak arkasında 2 mm cepte, uç dudak kapak kenarından 10 mm dışarıda öne döner.
    def kulp_tanimi
      d = @m.definitions.add('Kenar Profil Kulp 200')
      kesit = [[-26, -1.8], [8, -1.8], [8, -14], [10, -14], [10, -0.1], [-26, -0.1]]
      it(d.entities, kesit.map { |x, y| P(x, y, -KULP_L / 2) }, yon(0, 0, 1), KULP_L)
      boya(d.entities, @mat[:kulp])
      d
    end

    # Ütü masası destek kolu: yerel +x boyunca 10 mm (bar_tr ile braket ile tabla arasına gerilir).
    def destek_tanimi
      d = @m.definitions.add('Ütü Masası Destek Kolu')
      kutu(d.entities, 0, -2, -7, 10, 2, 7)
      boya(d.entities, @mat[:celik])
      d
    end

    # --- Duvar ve zemin (asma adımlarında ve tanıtımda) ---
    def duvar_tanimi
      d = @m.definitions.add('Duvar ve Zemin')
      e = d.entities
      g = e.add_group
      kutu(g.entities, -2600, D, 0, 3200, D + 20, 3200)
      boya(g.entities, @mat[:duvar])
      z = e.add_group
      kutu(z.entities, -2600, -4000, -12, 3200, D, 0)
      boya(z.entities, @mat[:zemin])
      (-2600..3200).step(180).drop(1).each { |x| z.entities.add_line(P(x, -4000, 0), P(x, D, 0)) } # parke derzleri
      d
    end

    # --- Masa açıkken dekor: tablada beyaz gömlek ve ütü, yanında sprey şişesi ---
    def masa_dekor_tanimi
      d = @m.definitions.add('Dekor (ütü, gömlek, sprey)')
      e = d.entities
      zu = MASA[:pivot] + MASA[:kal] # açık tablanın üst yüzü
      gomlek = [[118, -575], [332, -575], [332, -285], [366, -262], [356, -205], [285, -172], [252, -192],
                [198, -192], [165, -172], [94, -205], [84, -262], [118, -285]]
      g = e.add_group
      it(g.entities, gomlek.map { |x, y| P(x, y, zu) }, yon(0, 0, 1), 5)
      boya(g.entities, @mat[:gomlek])
      y = e.add_group # yaka ve düğme patı
      it(y.entities, [[190, -205], [225, -232], [260, -205], [252, -190], [225, -210], [198, -190]].map { |x, yy| P(x, yy, zu + 5) }, yon(0, 0, 1), 3)
      kutu(y.entities, 221, -560, zu + 5, 229, -232, zu + 6)
      boya(y.entities, @mat[:gomlek])
      taban = [[150, -640], [270, -640], [270, -720], [210, -840], [150, -720]] # ütü tabanı, ucu masanın ucuna bakar
      t = e.add_group
      it(t.entities, taban.map { |x, yy| P(x, yy, zu) }, yon(0, 0, 1), 6)
      boya(t.entities, @mat[:nikel])
      u = e.add_group
      it(u.entities, [[156, -646], [264, -646], [264, -718], [210, -826], [156, -718]].map { |x, yy| P(x, yy, zu + 6) }, yon(0, 0, 1), 38)
      kutu(u.entities, 201, -780, zu + 44, 219, -668, zu + 58)
      kutu(u.entities, 201, -680, zu + 44, 219, -664, zu + 92)
      kutu(u.entities, 201, -784, zu + 44, 219, -768, zu + 92)
      kutu(u.entities, 199, -790, zu + 88, 221, -658, zu + 102)
      boya(u.entities, @mat[:utu])
      torna(e, [[0, 0], [0, 30], [150, 30], [162, 14], [182, 14], [182, 0]], 28, @mat[:sprey])
        .transform!(eksen([335, -70, zu], [0, 0, 1], [1, 0, 0]))
      s = e.add_group
      kutu(s.entities, 327, -112, zu + 182, 343, -60, zu + 206)
      kutu(s.entities, 329, -100, zu + 150, 341, -92, zu + 184)
      boya(s.entities, @mat[:kulp])
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

    # Yazı: dik düzlemde; yon :on (önden okunur), :yan (+x'ten okunur), :dik (önden, aşağıdan yukarı)
    def yazi(e, metin, merkez, yon_ad, boy = 62.0)
      g = e.add_group
      g.entities.add_3d_text(metin, TextAlignLeft, 'Segoe UI', true, false, boy.mm, 0.0, 0.0, true, 0.0)
      c = g.bounds.center
      g.transform!(Geom::Transformation.translation(Geom::Vector3d.new(-c.x, -c.y, 0)))
      r = Geom::Transformation.rotation(ORIGIN, X_AXIS, 90.degrees)
      r = Geom::Transformation.rotation(ORIGIN, Z_AXIS, 90.degrees) * r if yon_ad == :yan
      r = Geom::Transformation.rotation(ORIGIN, Y_AXIS, -90.degrees) * r if yon_ad == :dik
      g.transform!(Geom::Transformation.translation(P(*merkez) - ORIGIN) * r)
      boya(g.entities, @mat[:olcu])
    end

    def olcu_tanimi
      d = @m.definitions.add('Ölçüler')
      e = d.entities
      yo = -T - 1
      zu = ZT + 110 # genişlik çizgisi
      cubuk(e, [0, yo, zu], [W, yo, zu])
      [0, W].each { |x| cubuk(e, [x, yo, ZT + 20], [x, yo, zu + 30], 1.6) }
      yazi(e, '450', [W / 2, yo, zu + 55], :on)
      xr = W + 130 # yükseklik ve montaj yüksekliği çizgileri (sağda)
      cubuk(e, [xr, yo, Z0], [xr, yo, ZT])
      cubuk(e, [xr, yo, 0], [xr, yo, Z0])
      [[ZT, W + 4], [Z0, W + 4], [0, W - 40]].each { |z, x0| cubuk(e, [x0, yo, z], [xr + 30, yo, z], 1.6) }
      yazi(e, '1250', [xr + 55, yo, (Z0 + ZT) / 2], :dik)
      yazi(e, '600', [xr + 55, yo, Z0 / 2], :dik)
      za = Z0 - 80 # derinlik çizgisi (sağ yanın altında, kapak dahil)
      cubuk(e, [W + 1, -T, za], [W + 1, D, za])
      [-T, D].each { |y| cubuk(e, [W + 1, y, za - 30], [W + 1, y, Z0 - 6], 1.6) }
      yazi(e, '148', [W + 75, -T - 1, za - 30], :on)
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
    # Yan: iç yüzde boydan boya arkalık kanalı, alt ve üst tabla hizasında 2 minifiks bulonu + kavela deliği;
    # askı üst-arka köşede (fabrikada takılı). Sol yanda menteşe tabanları ve kancalar.
    def yan(k, sx)
      d = parca_tanimi(AD[k])
      e = d.entities
      kutu(e, 0, 0, 0, T, D, H)
      xi = sx > 0 ? T : 0.0 # iç yüz
      it(e, [[KANAL_Y[0], 0], [KANAL_Y[1], 0], [KANAL_Y[1], H], [KANAL_Y[0], H]].map { |y, z| P(xi, y, z) },
         yon(-sx, 0, 0), KANAL_DER)
      [T / 2, H - T / 2].each { |z| daire_it(e, P(xi, KAVELA_Y, z), X_AXIS, KAVELA[:r], yon(-sx, 0, 0), KAVELA[:yan] + 1, 16) }
      boya(e, @mat[:govde])
      [T / 2, H - T / 2].each { |z| MF_Y.each { |y| e.add_instance(@bulon, eksen([xi, y, z], [sx, 0, 0], [0, 0, 1])) } }
      if sx > 0
        KAPI[:kapak][:mentese].each { |hz| e.add_instance(@taban, mentese_cerceve([xi, 0, hz - Z0], 1)) }
        KANCA_Z.each_with_index { |z, i| kanca_koy(e, xi, z - Z0, i) }
      end
      aski(e, xi, sx)
      [d, ORIJIN[k]]
    end

    def sol_yan; yan(:sol_yan, 1); end
    def sag_yan; yan(:sag_yan, -1); end

    # Ayarlı asma dolap askısı (fabrikada takılı): gövdesi yanın iç yüzünde üst-arka köşede; kancası arkalıktaki
    # kesikten geçip duvardaki rayın kanalına oturur. Önündeki ayar vidası yüksekliği ayarlar.
    def aski(e, xi, sx)
      g = e.add_group
      g.name = 'Asma Dolap Askısı'
      x0, x1 = [xi, xi + sx * ASKI[:x]].minmax
      zt = H - T
      kutu(g.entities, x0, ASKI[:y0], zt - ASKI[:h], x1, ARKA_Y - 0.5, zt)
      boya(g.entities, @mat[:aski])
      k = e.add_group
      k.name = 'Askı Kancası'
      kx0, kx1 = [xi + sx * 5, xi + sx * 12].minmax
      zr = RAY[:z1] - Z0 # rayın dudağının üstü (yan-yerel)
      kutu(k.entities, kx0, ARKA_Y - 6, zr + 1, kx1, D - 3.5, zr + 6)
      kutu(k.entities, kx0, D - 6, zr - 14, kx1, D - 3.5, zr + 1)
      boya(k.entities, @mat[:celik])
      o = [xi + sx * ASKI[:x] / 2, ASKI[:y0], zt - ASKI[:h] + 16]
      vida_koy(e, @ayvida, eksen(o, [0, 1, 0], [0, 0, 1]), P(*o), Geom::Vector3d.new(0, 1, 0), 3.0, 2.0,
               Geom::Vector3d.new(0.25 * sx, -1, 0.35).normalize, "aski_#{sx > 0 ? 'sol' : 'sag'}")
    end

    # Krom kanca (demonte): plakası sol yanın iç yüzüne bir vidayla.
    def kanca_koy(e, xi, z, i)
      o = [xi, KANCA_Y, z]
      vida_koy(e, @kanca, eksen(o, [1, 0, 0], [0, 0, 1]), P(*o), Geom::Vector3d.new(-1, 0, 0), 30.0, 0.0,
               Geom::Vector3d.new(1, 0, 0), KANCALAR[i])
      v = [xi + 3, KANCA_Y, z + 12]
      vida_koy(e, @vida16, eksen(v, [-1, 0, 0], [0, 0, 1]), P(*v), Geom::Vector3d.new(-1, 0, 0), 16.0, 2.5,
               Geom::Vector3d.new(1, -0.35, 0.3).normalize, KANCA_VIDALARI[i])
    end

    # Tabla: yanların arasında; uçlarda bulon ve kavela delikleri, eksantrik yuvaları üst yüzde (alt tablada iç,
    # üst tablada dış yüz — iç arka köşelerde askılar var); arkalık kanalı iç yüzde. Eksantrikler, kavelalar ve
    # üst tablanın minifiks kapakları demonte.
    def tabla(k)
      ust = k == :ust_tabla
      t = ust ? 'ust' : 'alt'
      d = parca_tanimi(AD[k])
      e = d.entities
      kutu(e, 0, 0, 0, IW, D, T)
      zk = ust ? 0.0 : T
      it(e, [[0, KANAL_Y[0]], [IW, KANAL_Y[0]], [IW, KANAL_Y[1]], [0, KANAL_Y[1]]].map { |x, y| P(x, y, zk) },
         yon(0, 0, ust ? 1 : -1), KANAL_DER)
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

    # Arkalık 8 mm: dört kenarı kanalda; üst köşelerde askı kancaları için 20 x 40 kesik. Altta iki duvar vidası
    # (Ø25 pullu) iç tabandan 50 mm yukarıda, yanlardan 60 mm içeride.
    def arkalik
      d = parca_tanimi(AD[:arkalik])
      e = d.entities
      gw = IW + 2 * (KANAL_DER - 1)
      gh = H - 2 * T + 2 * (KANAL_DER - 1)
      kx = 20.0
      kz = 40.0
      hat = [[0, 0], [gw, 0], [gw, gh - kz], [gw - kx, gh - kz], [gw - kx, gh], [kx, gh], [kx, gh - kz], [0, gh - kz]]
      it(e, hat.map { |x, z| P(x, 0, z) }, yon(0, 1, 0), ARKA_T)
      boya(e, @mat[:arka])
      ox, _, oz = ORIJIN[:arkalik]
      ALT_VIDA[:x].each_with_index do |x, i|
        o = [x - ox, -1.5, ALT_VIDA[:z] - oz]
        vida_koy(e, @pvida, eksen(o, [0, 1, 0], [0, 0, 1]), P(*o), Geom::Vector3d.new(0, 1, 0), 60.0, 3.0,
                 Geom::Vector3d.new(0.2, -1, 0.35).normalize, ALT_VIDALAR[i])
      end
      [d, ORIJIN[:arkalik]]
    end

    # Askı rayı 414 mm (duvarda, arkalığın arkasındaki 10 mm boşlukta): sırt plakası + üstte U kanal; askı
    # kancaları kanala oturur. Üç vida + dübelle duvara.
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
      [40.0, IW / 2, IW - 40].each_with_index do |x, i|
        o = [x, 8, zv]
        vida_koy(e, @avida, eksen(o, [0, 1, 0], [0, 0, 1]), P(*o), Geom::Vector3d.new(0, 1, 0), 40.0, 3.0,
                 Geom::Vector3d.new(0.15, -1, 0.2).normalize, RAY_VIDALARI[i])
      end
      [d, ORIJIN[:ray]]
    end

    # Ütü masası braketi (YER TUTUCU 320 x 260 x 40): arkalığın önünde; dört vidası arkalıktan geçip duvara
    # bağlanır (yük duvara biner). Önünde tablanın döndüğü iki kulak ve pim.
    def braket
      d = parca_tanimi(AD[:braket])
      e = d.entities
      b = BRAKET
      kutu(e, 0, 0, 0, b[:gen], b[:der], b[:h])
      boya(e, @mat[:braket])
      zp = MASA[:pivot] - b[:z0]
      mx = MASA_X - BRAKET_X
      yp = MASA_Y - BRAKET_Y # pivot ekseni (braket-yerel y)
      [[mx - 6, mx - 1], [mx + MASA[:gen] + 1, mx + MASA[:gen] + 6]].each do |x0, x1|
        g = e.add_group
        kutu(g.entities, x0, yp - 4, zp - 26, x1, 0, zp + 14)
        boya(g.entities, @mat[:celik])
      end
      torna(e, [[0, 0], [0, 3], [MASA[:gen] + 14, 3], [MASA[:gen] + 14, 0]], 12, @mat[:celik])
        .transform!(eksen([mx - 7, yp, zp], [1, 0, 0], [0, 0, 1]))
      [[5.0, 30.0], [b[:gen] - 5, 30.0], [5.0, b[:h] - 30], [b[:gen] - 5, b[:h] - 30]].each_with_index do |(x, z), i|
        o = [x, 0, z]
        vida_koy(e, @avida, eksen(o, [0, 1, 0], [0, 0, 1]), P(*o), Geom::Vector3d.new(0, 1, 0), 60.0, 3.0,
                 Geom::Vector3d.new(0.15, -1, 0.25).normalize, BRAKET_VIDALARI[i])
      end
      [d, ORIJIN[:braket]]
    end

    # Ütü masası tablası (YER TUTUCU 900 x 300 x 25, ucu daralır): katlıyken duvara dik, pivot alt ön kenarda;
    # açılınca öne yatar. Altında braketten gelen iki destek kolu.
    def masa
      d = parca_tanimi(AD[:masa])
      e = d.entities
      m = MASA
      hat = [[0, 0], [m[:gen], 0], [m[:gen], 760], [250, 860], [150, m[:boy]], [50, 860], [0, 760]]
      it(e, hat.map { |x, z| P(x, 0, z) }, yon(0, 1, 0), m[:kal])
      boya(e, @mat[:kilif])
      g = e.add_group
      g.name = 'Destek Kolu'
      zb = BRAKET[:z0] + 14 - m[:pivot]
      [40.0, m[:gen] - 40].each do |x|
        a = P(x, 6, 300)
        b = P(x, m[:kal] - 2, zb)
        kol = g.entities.add_instance(@destek, bar_tr(a, b))
        nitelik(kol, bar: true, a: a.to_a, b: b.to_a)
      end
      [d, ORIJIN[:masa]]
    end

    # Aynalı kapak: tam bindirme, arka yüzünde 3 menteşe kabı (sol kenardan 22,5 mm), önünde 3 mm akrilik ayna
    # (kenarlardan 25 mm içeride). Kenar profil kulp ve vidaları demonte.
    def kapak
      h = KAPI[:kapak]
      d = parca_tanimi(AD[:kapak])
      e = d.entities
      yuk = h[:z][1] - h[:z][0]
      kutu(e, 0, 0, 0, KAPI_W, T, yuk)
      hdler = h[:mentese].map { |hz| mentese_cerceve([h[:panel] - h[:x0], T, hz - h[:z][0]], 1) }
      hdler.each { |hd| daire_it(e, P(0, 0, KAP_ZC).transform(hd), Y_AXIS, 17.5, yon(0, -1, 0), 12.5, 32) }
      boya(e, @mat[:govde])
      x0 = AYNA[:pay]
      x1 = KAPI_W - AYNA[:pay]
      z0 = AYNA[:pay]
      z1 = yuk - AYNA[:pay]
      g = e.add_group
      g.name = 'Akrilik Ayna 396x1196'
      kutu(g.entities, x0, -AYNA[:t], z0, x1, 0, z1)
      boya(g.entities, @mat[:ayna])
      y = e.add_group # tanıtım: aynada oda yansıması (dekor katmanı)
      y.name = 'Ayna Yansıması'
      y.layer = @m.layers[DEKOR_TAG]
      yy = -AYNA[:t] - 0.4
      f = y.entities.add_face(P(x0, yy, z0), P(x1, yy, z0), P(x1, yy, z1), P(x0, yy, z1))
      f.reverse! if f.normal.y > 0
      f.position_material(@mat[:yansima], [P(x0, yy, z0), Geom::Point3d.new(0, 0, 0), P(x1, yy, z0),
                                           Geom::Point3d.new(1, 0, 0), P(x1, yy, z1), Geom::Point3d.new(1, 1, 0)], true)
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
                 "mentese_#{i + 1}", true)
      end
      zk = yuk / 2
      vida_koy(e, @kulp, eksen([KAPI_W, T, zk], [1, 0, 0], [0, 0, 1]), P(KAPI_W, T, zk), Geom::Vector3d.new(-1, 0, 0),
               40.0, 0.0, Geom::Vector3d.new(1, 0, 0), 'kulp')
      [-70, 70].each_with_index do |dz, j|
        o = [KAPI_W - 13, T, zk + dz]
        vida_koy(e, @vida16, eksen(o, [0, -1, 0], [0, 0, 1]), P(*o), Geom::Vector3d.new(0, -1, 0), 18.0, 2.5,
                 Geom::Vector3d.new(0.35, 1, 0.2).normalize, KULP_VIDALARI[j])
      end
      [d, ORIJIN[:kapak]]
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
      @m.start_operation('Aynalı ütü dolabı kurulum modeli', true)
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
      @avida = vida_tanimi('Vida 5x60 + Dübel', 4.6, 3.0, 2.5, 60)
      @ayvida = vida_tanimi('Askı Ayar Vidası', 3.2, 2.0, 2.0, 10)
      @pvida = pul_vida_tanimi
      @kam = kam_tanimi
      @bulon = bulon36_tanimi
      @kavela = kavela_tanimi
      @mfkapak = mfkapak_tanimi
      @taban = taban_tanimi
      @kol = kol_tanimi
      @kap = kap_tanimi
      @bag = bag_tanimi
      @destek = destek_tanimi
      @kanca = kanca_tanimi
      @kulp = kulp_tanimi
      arac = tornavida_tanimi
      kisa = kisa_tornavida_tanimi
      cekic = cekic_tanimi

      tags = SIRA.map { |k| [k, @m.layers.add(ETIKET[k])] }.to_h
      liste_tag = @m.layers.add(LISTE_TAG)
      arac_tag = @m.layers.add(ARAC_TAG)
      ek_tag = [DUVAR_TAG, DEKOR_TAG, MASA_DEKOR_TAG, OLCU_TAG].to_h { |t| [t, @m.layers.add(t)] }

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
      [[duvar_tanimi, DUVAR_TAG], [masa_dekor_tanimi, MASA_DEKOR_TAG], [olcu_tanimi, OLCU_TAG]].each do |d, t|
        @m.entities.add_instance(d, Geom::Transformation.new).layer = ek_tag[t]
      end

      parca_listesi(liste_tag)
      stil
      bagla
      son_durum
      sahneler
      [DEKOR_TAG, MASA_DEKOR_TAG, OLCU_TAG].each { |t| ek_tag[t].visible = false }
      @m.commit_operation
      @m.save(kayit_yolu) if kayit_yolu
      "Kuruldu: #{SIRA.size} parça, #{@vidalar.size} animasyonlu vida/eksantrik/kavela/kanca, #{@m.pages.size} sahne"
    end

    # Kutu içeriği: paneller yere yatırılmış, fabrikada takılı hırdavat görünür; ayrı gelen küçük parçalar altta.
    # Ütü masası mekanizması kendi kutusunda gelir, listede yok.
    def parca_listesi(tag)
      rx = ->(a) { Geom::Transformation.rotation(ORIGIN, X_AXIS, a.degrees) }
      ry = ->(a) { Geom::Transformation.rotation(ORIGIN, Y_AXIS, a.degrees) }
      rz = ->(a) { Geom::Transformation.rotation(ORIGIN, Z_AXIS, a.degrees) }
      bir = Geom::Transformation.new
      yerlesim = {
        sol_yan: [rz.(90) * ry.(-90), 1300, 0], sag_yan: [rz.(90) * ry.(90), 1650, 0],
        arkalik: [rx.(-90), 2000, 0], kapak: [rx.(-90), 2600, 0],
        alt_tabla: [bir, 3250, 0], ust_tabla: [bir, 3250, 420], ray: [rx.(-90), 3250, 840]
      }
      @m.entities.grep(Sketchup::ComponentInstance).each do |ana|
        k = nit(ana, :parca)&.to_sym
        next unless yerlesim.key?(k)
        rot, x, y = yerlesim[k]
        b = Geom::BoundingBox.new # demonte parçalar ve dekor yerleşime katılmasın
        ana.definition.entities.each do |g|
          next if g.is_a?(Sketchup::ComponentInstance) && DEMONTE.include?(nit(g, :vida))
          next if g.layer.name == DEKOR_TAG
          b.add(g.bounds)
        end
        bb = Geom::BoundingBox.new
        8.times { |c| bb.add(b.corner(c).transform(rot)) }
        kay = Geom::Transformation.translation(P(x, y, 0) - bb.min)
        i = @m.entities.add_instance(ana.definition, kay * rot)
        i.layer = tag
        on = Geom::Point3d.new(bb.center.x, bb.min.y, bb.max.z).transform(kay)
        @m.entities.add_text(AD[k], on, Geom::Vector3d.new(0, -110.mm, 0)).layer = tag
      end
      ek = lambda do |defn, adet, x, y, dx, ad, eks|
        adet.times { |i| @m.entities.add_instance(defn, eksen([x + i * dx, y, eks[2]], eks[0], eks[1])).layer = tag }
        @m.entities.add_text(ad, P(x, y - 140, 0), Geom::Vector3d.new(0, -110.mm, 0)).layer = tag
      end
      ek.(@kam, 8, 1300, -450, 30, 'Minifiks Gövdesi (8)', [[0, 0, -1], [1, 0, 0], 12])
      ek.(@kavela, 4, 2000, -450, 40, 'Kavela Ø8x30 (4)', [[0, 1, 0], [0, 0, 1], 4])
      ek.(@mfkapak, 4, 2700, -450, 35, 'Minifiks Kapağı (4)', [[0, 0, -1], [1, 0, 0], 1.5])
      ek.(@kanca, 2, 3400, -450, 90, 'Krom Kanca (2)', [[0, 0, 1], [0, -1, 0], 3])
      ek.(@vida16, 4, 1300, -900, 35, 'Sunta Vidası 3.5x16 (4)', [[0, 1, 0], [0, 0, 1], 4])
      ek.(@kulp, 1, 2000, -900, 0, 'Kenar Profil Kulp (1)', [[0, 0, 1], [1, 0, 0], 14])
      ek.(@avida, 3, 2700, -900, 45, 'Ray Vidası + Dübel (3)', [[0, 1, 0], [0, 0, 1], 5])
      ek.(@pvida, 2, 3400, -900, 60, 'Vida + Ø25 Pul + Dübel (2)', [[0, 1, 0], [0, 0, 1], 13])
      @m.entities.add_text('Ütü masası mekanizması ayrı kutuda', P(3250, 1250, 0), Geom::Vector3d.new(0, 0, 0)).layer = tag
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
        ['0 Kutu İçeriği', [], :liste, 'Paneller ve fabrikada takılı bağlantı elemanları; minifiks gövdeleri, kavelalar, kapaklar, kancalar, kulp, ray ve vidalar ayrı. Mekanizma kendi kutusunda.'],
        ['1 Kavelalar', %i[alt_tabla ust_tabla], 1, 'Kavelaları alt ve üst tablanın uçlarındaki deliklere takın.'],
        ['2 Sol Yan', %i[sol_yan], 2, 'Sol yanı iki tablanın uçlarına geçirin: bulonlar ve kavelalar deliklere girer.'],
        ['3 Sol Minifiksler', [], 3, 'Sol taraftaki 4 minifiks gövdesini yerleştirip yarım tur çevirin (alt tablada içten, üst tablada üstten).'],
        ['4 Arkalık', %i[arkalik], 4, 'Arkalığı açık sağ taraftan tablaların ve sol yanın kanalına sürün.'],
        ['5 Sağ Yan', %i[sag_yan], 5, 'Sağ yanı iki tablanın uçlarına ve arkalığa geçirin; sağdaki 4 minifiks gövdesini çevirin.'],
        ['6 Minifiks Kapakları', [], 6, 'Üst tabladaki 4 minifiks gövdesinin üstüne beyaz kapaklarını bastırın.'],
        ['7 Kancalar', [], 7, 'İki krom kancayı sol iç yanın arka yarısına birer vidayla takın.'],
        ['8 Askı Rayı', %i[ray], 8, 'Delme şablonuyla işaretleyin; askı rayını 3 vida ve dübelle duvara vidalayın.'],
        ['9 Dolabı Asma', [], 9, 'Dolabı askılarıyla raya asın; askı vidalarıyla yüksekliği ayarlayın.'],
        ['10 Alt Vidalar', [], 10, 'Alttaki 2 vidayı Ø25 pulla arkalıktan duvara sıkın.'],
        ['11 Ütü Masası', %i[braket masa], 11, 'Mekanizmanın braketini 4 vidayla arkalıktan duvara vidalayın, tablayı katlayın.'],
        ['12 Kapak', %i[kapak], :kapak, 'Kapağı sol yandaki menteşe tabanlarına geçirin, 3 menteşe vidasını sıkın.'],
        ['13 Kulp', [], 13, 'Kenar profil kulpu kapağın sağ kenarına geçirip 2 vidayı arkadan sıkın; kapağı kapatın.'],
        ['14 Bitmiş Ürün', [], :bitti, 'Kurulum tamamlandı.']
      ]
      acik = []
      tanim.each_with_index do |(ad, yeni, kam, aciklama), n|
        acik += yeni
        liste = kam == :liste
        @m.layers.each do |l|
          k = ETIKET.key(l.name)
          l.visible = if l.name == LISTE_TAG then liste
                      elsif l.name == DUVAR_TAG then n >= 8
                      elsif [ARAC_TAG, DEKOR_TAG, MASA_DEKOR_TAG, OLCU_TAG].include?(l.name) then false
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
      raise 'Model bulunamadı — önce OzcanKurulum::UtuDolabi.kur' unless @parca.size == SIRA.size && @arac && @kisa_arac && @cekic
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
      cizelge
      true
    end

    def vida_kaydi(i, parca, grup)
      { id: nit(i, :vida), inst: i, parca: parca, grup: grup,
        lt: Geom::Transformation.new(nit(i, :lt)), p: Geom::Point3d.new(*nit(i, :p)),
        d: Geom::Vector3d.new(*nit(i, :d)), strok: nit(i, :strok), bas_h: nit(i, :bas_h),
        w: Geom::Vector3d.new(*nit(i, :w)), kapi: nit(i, :kapi), kisa: nit(i, :kisa) }
    end

    # aci > 0 açık: kapak sol ön dış köşesindeki dikey eksende sola açılır; ütü masası tablası katlıyken alt ön
    # kenarındaki yatay eksende öne yatar (90° = yatay).
    def kapi_R(k, aci)
      h = KAPI[k]
      return Geom::Transformation.rotation(P(0, h[:py], h[:z][0]), X_AXIS, aci.degrees) if h[:klapa]
      Geom::Transformation.rotation(P(h[:eksen], h[:py], 0), Z_AXIS, h[:yon] * aci.degrees)
    end

    # Tam açık açı: frenli menteşe 110°'ye kadar; masa yatay.
    def acik_aci(k)
      k == :masa ? 90.0 : 105.0
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

    # Birkaç parçayı birlikte taşır (asma adımında gövdenin tamamı, mekanizmanın braketi ve tablası).
    def toplu(ks, a, b, sure)
      @cz.olay(sure) { |s, u| ks.each { |k| s[:p][k] = { vis: true, off: lerp3(a, b, u) } } }
    end

    # Demonte parçayı tornavida gelmeden önce gevşek konumda gösterir.
    def goster(ids)
      @cz.an { |s, _| ids.each { |id| s[:v][id] = { adv: 1.0, ang: 0.0 } } }
    end

    # Elle takılan parçalar (kavela, minifiks kapağı, kanca): görünür olur, yerine itilir; alet yok.
    def elle_tak(ids, sure = 0.9)
      goster(ids)
      @cz.bekle(0.3)
      @cz.olay(sure) { |s, u| ids.each { |id| s[:v][id] = { adv: 1 - u, ang: 0.0 } } }
    end

    def kancalari_tak
      elle_tak(KANCALAR)
      goster(KANCA_VIDALARI)
      sirayla_sik(KANCA_VIDALARI, KAM[7], tur: 4, bak: [0.6, -1, 0.3])
    end

    # Kulp kapağın sağ kenarına kayarak oturur; iki vidası kapağın arkasından sıkılır.
    def kulp_tak
      z = @cz
      goster(['kulp'])
      z.bekle(0.3)
      z.olay(1.0) { |s, u| s[:v]['kulp'] = { adv: 1 - u, ang: 0.0 } }
      goster(KULP_VIDALARI)
      sirayla_sik(KULP_VIDALARI, KAM[13], tur: 4, bak: [1, -0.25, 0.35])
    end

    # Kapak açık (90°) gelir, menteşe gövdeleri sol yandaki tabanlara geçer, üç vida sıkılır; kapak açık kalır.
    def kapak_tak(bas)
      z = @cz
      z.an { |s, _| s[:kapi][:kapak] = 90.0 }
      z.kamera(1.2, KAM[:kapak])
      hareket(:kapak, bas, [0, 0, 0], 1.8)
      sirayla_sik(%w[mentese_1 mentese_2 mentese_3], KAM[:kapak], tur: 3)
      z.kamera(0.8, KAM[:kapak])
    end

    def cizelge
      @cz = z = Cizelge.new
      z.an { |s, _| DEMONTE.each { |id| s[:v][id] = { gizli: true } } } # takılana kadar görünmesin
      z.baslik('Kutu içeriği — bulon, askı, menteşe ve ayna takılı; minifiks gövdesi, kavela, kanca, kulp, ray ve vidalar ayrı')
      z.kamera(0, KAM[:liste])
      z.bekle(3.5)

      z.baslik('1 · Kavelaları alt ve üst tablanın uçlarındaki deliklere takın')
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

      z.baslik('3 · Sol taraftaki dört minifiks gövdesini yuvasına koyup yarım tur çevirin (üst tablada dış yüzden)')
      z.kamera(1.0, KAM[3])
      ids = KAMLAR['sol']
      goster(ids)
      z.bekle(0.3)
      sirayla_sik(ids, KAM[3], cekler: cek_listesi(:sol_yan, [-2, 0, 0], ids.size), tur: 0.5, bak: [0.35, -1, 0.9])
      z.kamera(0.8, KAM[3])
      z.bekle(0.3)

      z.baslik('4 · Arkalığı açık sağ taraftan tablaların ve sol yanın kanalına sonuna kadar sürün')
      z.kamera(1.2, KAM[4])
      hareket(:arkalik, [480, 0, 0], [0, 0, 0], 2.2)
      z.bekle(0.4)

      z.baslik('5 · Sağ yanı tablalara ve arkalığa geçirin; sağdaki dört minifiks gövdesini yarım tur çevirin')
      z.kamera(1.2, KAM[5])
      hareket(:sag_yan, [350, 0, 0], [2, 0, 0], 2.0)
      ids = KAMLAR['sag']
      goster(ids)
      z.bekle(0.3)
      sirayla_sik(ids, KAM[5], cekler: cek_listesi(:sag_yan, [2, 0, 0], ids.size), tur: 0.5, bak: [-0.35, -1, 0.9])
      z.kamera(0.8, KAM[5])
      z.bekle(0.3)

      z.baslik('6 · Üst tabladaki dört minifiks gövdesinin üstüne beyaz kapaklarını bastırın')
      z.kamera(1.2, KAM[6])
      elle_tak(KAPAKCIKLAR, 1.0)
      z.bekle(0.4)

      z.baslik('7 · İki krom kancayı sol iç yanın arka yarısına birer vidayla takın')
      z.kamera(1.2, KAM[7])
      kancalari_tak
      z.kamera(0.8, KAM[7])
      z.bekle(0.3)

      z.baslik('8 · Delme şablonuyla işaretleyin; askı rayını üç vida ve dübelle duvara vidalayın')
      z.an { |s, _| s[:duvar] = true }
      z.kamera(1.2, KAM[8])
      toplu(GOVDE, [0, 0, 0], DIS, 1.4)
      hareket(:ray, [0, -300, 0], [0, 0, 0], 1.4)
      goster(RAY_VIDALARI)
      z.bekle(0.3)
      sirayla_sik(RAY_VIDALARI, KAM[8], tur: 4, bak: [0.3, -1, 0.3])
      z.kamera(0.8, KAM[8])
      z.bekle(0.3)

      z.baslik('9 · Dolabı askılarıyla raya asın; askı vidalarıyla yüksekliği ve duvara yaslanmayı ayarlayın')
      z.kamera(1.2, KAM[9])
      toplu(GOVDE, DIS, [0, -260, 45], 1.8)
      toplu(GOVDE, [0, -260, 45], [0, 0, 45], 1.2)
      toplu(GOVDE, [0, 0, 45], [0, 0, 0], 0.8)
      z.bekle(0.3)
      sirayla_sik(ASKI_VIDALARI, KAM[9], tur: 2, bak: [0.3, -1, 0.4])
      z.kamera(0.8, KAM[9])
      z.bekle(0.3)

      z.baslik('10 · Alttaki iki vidayı Ø25 pulla arkalıktan duvara sıkın')
      z.kamera(1.2, KAM[10])
      goster(ALT_VIDALAR)
      z.bekle(0.3)
      sirayla_sik(ALT_VIDALAR, KAM[10], tur: 5, bak: [0.25, -1, 0.5])
      z.kamera(0.8, KAM[10])
      z.bekle(0.3)

      z.baslik('11 · Ütü masası braketini dört vidayla arkalıktan duvara vidalayın, sonra tablayı katlayın')
      z.kamera(1.2, KAM[11])
      z.an { |s, _| s[:kapi][:masa] = 90.0 }
      toplu(%i[braket masa], [0, -650, 0], [0, 0, 0], 2.0)
      goster(BRAKET_VIDALARI)
      z.bekle(0.3)
      sirayla_sik(BRAKET_VIDALARI, KAM[11], tur: 5, bak: [0.35, -1, -0.2])
      z.kamera(0.8, KAM[11])
      z.olay(1.6) { |s, u| s[:kapi][:masa] = 90.0 * (1 - u) }
      z.bekle(0.3)

      z.baslik('12 · Kapağı sol yandaki menteşe tabanlarına geçirin; üç menteşe vidasını sıkın')
      kapak_tak(KAPAK_DIS)
      z.bekle(0.3)

      z.baslik('13 · Kenar profil kulpu kapağın sağ kenarına geçirin; iki vidasını arkadan sıkın, kapağı kapatın')
      z.kamera(1.2, KAM[13])
      kulp_tak
      z.kamera(0.8, KAM[13])
      z.olay(1.4) { |s, u| s[:kapi][:kapak] = 90.0 * (1 - u) }
      z.kamera(1.0, KAM[:kapak])
      z.bekle(0.3)

      z.baslik('Kurulum tamamlandı')
      z.kamera(1.6, KAM[:bitti])
      z.olay(1.3) { |s, u| s[:kapi][:kapak] = 105.0 * u }
      z.olay(1.3) { |s, u| s[:kapi][:masa] = 90.0 * u }
      z.bekle(1.0)
      z.olay(1.3) { |s, u| s[:kapi][:masa] = 90.0 * (1 - u) }
      z.olay(1.3) { |s, u| s[:kapi][:kapak] = 105.0 * (1 - u) }
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

    # Montajlı son durum: tüm parçalar yerinde, vidalar, eksantrikler, kavelalar, kancalar ve kulp takılı, kapak kapalı.
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
