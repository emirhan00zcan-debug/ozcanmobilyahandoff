# encoding: UTF-8
# Liva TV Ünitesi — modül 90 x 43 x 50 cm (13 cm ayak dahil); iki modül yan yana 180 cm set — kurulum kılavuzu modeli.
# Tarif: research_notes/Urun firsatlari 2026-11-21/tarif-F-liva-tv-unitesi.txt (21.11.2026). Gövde, 36 mm Safir Meşe
# tabla, siyah konik ayaklar ve kanallı arkalık Liva konsoldan (liva_konsol.rb). Solda bas-aç kapaklı bölme (kapak düz
# beyaz sunta, kulpsuz), sağda raflı açık niş; arkalıkta iki Ø60 kablo deliği. Kapak sağa da takılabilir: iki yanda da
# menteşe tabanı delikleri hazır, tabanlar ayrı gelir.
# Bağlantılar (21.11.2026 kuralı: çektirme yok; suntada ufik, arkalık geçmeli): yanlar ve orta dikme tablalara ufikle.
# Ufik = CNC'de panel yüzüne açılan anahtar deliği biçimli cebe bastırılan beyaz plastik bağlantı elemanı; ortadaki
# vidası sıkılınca karşı panele vidalı çelik pimin başını kavrar. Cep, pimin girdiği uçtan 36 mm içeride.
# Pimler tablaların uçlarına yatay girdiği için önce iç çerçeve (alt tabla + dikme + iç üst tabla) kurulur, yanlar
# iki uçtan geçirilir; arkalık sol yan takılınca sağdan kanallara sürülür.
#   1 ayaklar  2 orta dikme  3 iç üst tabla  4 sol yan  5 arkalık (kanala)  6 sağ yan  7 meşe tabla (alttan vida)
#   8 raf  9 menteşe tabanları  10 kapak  11 kablo kapakları
#
# SketchUp > Pencere > Ruby Konsolu:
#   load 'C:/.../scripts/product-3d/kurulum/liva_tv_unitesi.rb'
#   OzcanKurulum::LivaTv.kur                 # AÇIK MODELİ TEMİZLER, modeli sıfırdan kurar
#   OzcanKurulum::LivaTv.oynat               # montaj animasyonunu ekranda oynatır
#   OzcanKurulum::LivaTv.kumanda             # klavyeyle adım adım: → ← Enter, K serbest kamera, Esc
#   (konsoldan: sonraki, onceki, durdur, devam, adim(3), git(3), bitir)
#   OzcanKurulum::LivaTv.kaydet('C:/kareler') # animasyonu PNG karelere yazar
#
# Koordinatlar mm: X genişlik (0 = sol dış yüz), Y derinlik (0 = gövde ön yüzü, +Y arkaya; kapak Y -20..-2, arkalık
# Y 387..390 kanalda, duvar Y 420), Z yükseklik (0 = zemin).

module OzcanKurulum
  module LivaTv
    extend self

    # ------------------------------------------------------------------
    # Ölçüler (mm)
    # ------------------------------------------------------------------
    W = 900.0            # modül genişliği (set: iki modül 1800)
    T = 18.0             # panel kalınlığı
    D = 400.0            # yan derinliği (kapakla 420, tabla 430)
    AYAK_H = 130.0
    Z0 = AYAK_H          # alt tablanın alt yüzü
    ZT = Z0 + 334.0      # yanların üst kenarı (yan 33,4); üstünde 36 mm meşe tabla → 500
    TABLA_T = 36.0
    TABLA_DER = 430.0    # arkası gövdeyle bir, önde kapağı 1 cm geçer
    ARKA_T = 3.0
    KANAL_Y = D - 10 - ARKA_T # arkalığın ön yüzü: kanal arka kenardan 10 mm içeride
    KANAL_DER = 8.0      # kanal derinliği (arkalık panellere 8 mm girer)
    DIKME_X = 441.0      # orta dikme X 441-459: solda kapaklı bölme, sağda açık niş
    DIKME_DER = KANAL_Y - 3 # dikme arkalığın önünde biter
    IC_H = ZT - Z0 - 2 * T # iç yükseklik 298
    RAF_Z = 289.0        # açık nişteki rafın alt yüzü (altında ~141, üstünde ~139 mm)
    RAF_W = 421.0
    RAF_DER = 370.0
    RAF_Y0 = 4.0
    PIM_R = 2.5
    PIM_Y = [RAF_Y0 + 33, RAF_Y0 + RAF_DER - 37].freeze # 37 ve 337
    PIM_DELIK_Z = [-32.0, 0.0, 32.0].map { |d| RAF_Z - PIM_R + d }.freeze
    AYAK_XY = [[60, 60], [W - 60, 60], [60, D - 70], [W - 60, D - 70]].freeze
    TABAN_T = 5.0        # ayak tabanı kalınlığı
    # Meşe tablayı iç üst tablaya bağlayan vidalar (alttan, bölmelerin içinden; dikmenin hizası boş)
    TABLA_VIDA = [[150.0, 90.0], [150.0, 310.0], [330.0, 200.0], [570.0, 200.0], [750.0, 90.0], [750.0, 310.0]].freeze
    # Ufik (kullanıcı kuralı: uzun kenardan 32, kısa kenardan 36)
    UF_ARA = 36.0
    UF_Y = [32.0, D - 32].freeze             # yan ↔ alt ve iç üst tabla (cep tablanın üst yüzünde)
    UF_Y_DIKME = [32.0, DIKME_DER - 32].freeze # dikme ↔ tablalar (cep dikmenin sol yüzünde)
    KABLO = { x: [225.0, 675.0], z: 400.0, r: 30.0 }.freeze # arkalıkta Ø60 kablo delikleri (tablanın 64 mm altı)
    BIRLESTIRME = { y: 200.0, z: [250.0, 380.0] }.freeze  # set: komşu yanlarda Ø5 birleştirme cıvatası deliği
    KAPI_PAY = 2.0
    KAPI_Z0 = Z0 + 1
    KAPI_H = 332.0
    # x0 sol kenar, gen genişlik, panel menteşe tabanının vidalandığı yüz, sx tabandan bölmeye,
    # eksen dönme ekseninin x'i (kapağın dış ön köşesi), yon -1 sola açılır
    KAPI = { kapak: { x0: 1.5, gen: 447.0, panel: T, sx: 1, eksen: 1.5, yon: -1 } }.freeze
    MENTESE_Z = [KAPI_Z0 + 100, KAPI_Z0 + KAPI_H - 100].freeze
    KAP_ZC = 1.5 + 22.5 - T # kap merkezi yan iç yüzünden 6 mm (kapak kenarından 22,5)
    BASAC_X = 1.5 + 447.0 - 40 # bas-aç itici: iç üst tablanın altında, kapağın serbest kenarından 40 mm içeride
    PLAKA_T = 3.0

    DIKEY_FOV = 30.0
    VIDEO_FOV = 50.0

    DICT = 'ozcan_kurulum'
    SIRA = %i[alt_tabla dikme ust_tabla sol_yan arkalik sag_yan tabla raf kapak].freeze
    KAPILAR = %i[kapak].freeze
    AD = {
      alt_tabla: 'Alt Tabla', dikme: 'Orta Dikme', ust_tabla: 'İç Üst Tabla', sol_yan: 'Sol Yan', arkalik: 'Arkalık',
      sag_yan: 'Sağ Yan', tabla: 'Tabla (Safir Meşe 3,6 cm)', raf: 'Raf', kapak: 'Kapak (bas-aç)'
    }.freeze
    ETIKET = {
      alt_tabla: '01 Alt Tabla', dikme: '02 Orta Dikme', ust_tabla: '03 İç Üst Tabla', sol_yan: '04 Sol Yan',
      arkalik: '05 Arkalık', sag_yan: '06 Sağ Yan', tabla: '07 Tabla', raf: '08 Raf', kapak: '09 Kapak'
    }.freeze
    LISTE_TAG = '00 Parça Listesi'
    ARAC_TAG = '99 Tornavida'
    DUVAR_TAG = 'Duvar ve Zemin'
    DEKOR_TAG = 'Dekor (tanıtım)'
    OLCU_TAG = 'Ölçüler'
    SET_TAG = 'Set (ikinci modül)'

    # Kamera noktaları [göz, hedef] (mm)
    KAM = {
      liste:   [[2750, -2500, 3700], [2750, 380, 0]],
      1 =>     [[1250, -1100, 380], [450, 200, 160]],
      2 =>     [[1300, -1250, 950], [450, 200, 250]],
      3 =>     [[1350, -1300, 1050], [450, 200, 330]],
      4 =>     [[-750, -1250, 900], [330, 200, 300]],
      5 =>     [[2000, 1800, 1100], [500, 300, 300]],
      6 =>     [[1700, -1250, 900], [570, 200, 300]],
      7 =>     [[1450, -1650, 1350], [450, 200, 400]],
      ic:      [[650, -1050, 180], [400, 200, 440]],
      8 =>     [[1300, -1250, 750], [660, 200, 300]],
      9 =>     [[850, -850, 650], [60, 120, 300]],
      kapak:   [[1350, -1700, 900], [450, 0, 300]],
      10 =>    [[1450, 1850, 950], [450, 400, 380]],
      bitti:   [[1500, -1900, 1000], [450, 150, 280]]
    }.freeze
    # Tanıtım görselleri (4:5): ad, açık katmanlar, kapak açısı, [göz, hedef]
    TANITIM = [
      ['1_salonda_set', %i[duvar dekor sus set tv55], 0, [[2050, -3500, 1150], [900, 150, 620]]],
      ['2_tek_modul_32_tv', %i[duvar dekor tv32], 0, [[1300, -2300, 1150], [450, 100, 600]]],
      ['3_acik_nis_kablolar', %i[duvar dekor sus], 0, [[1180, -720, 470], [680, 280, 360]]],
      ['4_kapak_acik', %i[duvar dekor sus], 100, [[820, -1550, 720], [240, 200, 300]]],
      ['5_olculer', %i[duvar olcu], 0, [[1500, -1800, 1000], [450, 150, 280]]]
    ].freeze

    # Parçaların yerleşim orijini (bileşen orijini = parçanın min köşesi)
    ORIJIN = {
      alt_tabla: [T, 0, Z0], dikme: [DIKME_X, 0, Z0 + T], ust_tabla: [T, 0, ZT - T], sol_yan: [0, 0, Z0],
      arkalik: [T - KANAL_DER, KANAL_Y, Z0 + T - KANAL_DER], sag_yan: [W - T, 0, Z0], tabla: [0, D - TABLA_DER, ZT],
      raf: [DIKME_X + T + 1, RAF_Y0, RAF_Z], kapak: [KAPI[:kapak][:x0], -(KAPI_PAY + T), KAPI_Z0]
    }.freeze

    AYAKLAR = %w[ayak_1 ayak_2 ayak_3 ayak_4].freeze
    TABLA_VIDALARI = (1..TABLA_VIDA.size).map { |i| "tabla_#{i}" }.freeze
    UF = {
      dikme_alt: %w[uf_dik_alt_1 uf_dik_alt_2], dikme_ust: %w[uf_dik_ust_1 uf_dik_ust_2],
      sol: %w[uf_alt_sol_1 uf_alt_sol_2 uf_ust_sol_1 uf_ust_sol_2], sag: %w[uf_alt_sag_1 uf_alt_sag_2 uf_ust_sag_1 uf_ust_sag_2]
    }.freeze
    UFIKLER = UF.values.flatten.freeze
    PIMLER = %w[pim_1 pim_2 pim_3 pim_4].freeze
    TABANLAR = %w[taban_1 taban_2].freeze
    TABAN_VIDALARI = TABANLAR.flat_map { |t| ["#{t}_v1", "#{t}_v2"] }.freeze
    KABLO_KAPAKLARI = %w[kablo_1 kablo_2].freeze
    DEMONTE = (AYAKLAR + TABLA_VIDALARI + UFIKLER + UFIKLER.map { |u| "#{u}_v" } + PIMLER + TABANLAR + TABAN_VIDALARI +
               KABLO_KAPAKLARI).freeze

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
        govde: mk.('Beyaz Mat Sunta (D101)', [242, 242, 240]),
        mese: mk.('Safir Meşe', [198, 152, 102]),
        arka: mk.('Arkalık (beyaz HDF)', [236, 236, 233]),
        ayak: mk.('Siyah Ayak', [34, 34, 36]),
        gri: mk.('Ayak Tabanı', [90, 92, 96]),
        ufik: mk.('Ufik (beyaz plastik)', [250, 250, 248]),
        kablo_kapak: mk.('Kablo Kapağı (siyah plastik)', [40, 40, 42]),
        basac: mk.('Bas-Aç Gövdesi', [70, 72, 76]),
        cinko: mk.('Çinko Kaplama', [160, 164, 170]),
        nikel: mk.('Nikel', [192, 196, 202]),
        celik: mk.('Çelik', [110, 113, 120]),
        yuva: mk.('Vida Yuvası', [40, 40, 44]),
        sap: mk.('Tornavida Sapı', [226, 96, 24]),
        uc: mk.('Tornavida Ucu', [70, 72, 78]),
        duvar: mk.('Duvar (açık gri)', [226, 224, 220]),
        supurge: mk.('Süpürgelik', [250, 250, 248]),
        zemin: mk.('Parke (açık meşe)', [214, 190, 156]),
        tv: mk.('TV Kasası', [28, 28, 30]),
        ekran: mk.('TV Ekranı', [52, 66, 92]),
        cihaz: mk.('Cihaz (siyah)', [36, 36, 38]),
        modem: mk.('Modem (beyaz)', [238, 238, 236]),
        led: mk.('LED', [90, 200, 120]),
        kablo: mk.('Kablo (siyah)', [30, 30, 32]),
        kutu1: mk.('Oyun Kutusu', [40, 90, 160]),
        kutu2: mk.('Oyun Kutusu 2', [180, 50, 50]),
        kitap: mk.('Kitap Kapağı', [70, 96, 120]),
        kitap2: mk.('Kitap Kapağı 2', [168, 82, 60]),
        sayfa: mk.('Kitap Sayfası', [244, 238, 222]),
        saksi: mk.('Saksı', [236, 232, 224]),
        yesil: mk.('Bitki', [86, 128, 76]),
        yatak: mk.('Yatak Örtüsü', [222, 214, 200]),
        yastik: mk.('Yastık', [246, 244, 240]),
        baslik: mk.('Yatak Başlığı', [150, 140, 128]),
        hali: mk.('Halı', [196, 188, 176]),
        olcu: mk.('Ölçü', [40, 40, 44])
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

    # Menteşe parçaları "menteşe çerçevesinde" çizilir: orijin kapak arka yüzünde, yan
    # panelin iç yüzü hizasında; x' menteşe ekseni, y' derinlik, z' panelden içeri.
    # Taban haç biçimli: oval delikli kanatlar, orta sırt; arka uçtaki vidanın
    # altına kolun çatalı kayar, ortadaki dişli deliğe kolun sabitleme vidası girer.
    def taban_tanimi(vidali = true)
      d = @m.definitions.add(vidali ? 'Menteşe Tabanı (küçük parça)' : 'Menteşe Tabanı (vidasız)')
      e = d.entities
      kutu(e, -7, 22, 0, 7, 62, 6)
      [-1, 1].each { |s| it(e, [[30, 0], [30, 2.5], [46, 2.5], [46, 0]].map { |y, z| P(7 * s, y, z) }, yon(s, 0, 0), 12) }
      it(e, [P(-4.5, 24, 6), P(4.5, 24, 6), P(4.5, 62, 6), P(-4.5, 62, 6)], yon(0, 0, 1), 2)
      [-1, 1].each { |s| it(e, plaka_hatti([[12 * s, 38, 2.2], [16 * s, 38, 2.2]]).map { |x, y| P(x, y, 2.5) }, yon(0, 0, -1), 2.5) }
      [34, 59].each { |y| daire_it(e, P(0, y, 8), Z_AXIS, 2, yon(0, 0, -1), 7, 16) }
      boya(e, @mat[:nikel])
      [-1, 1].each { |s| e.add_instance(@vida16, eksen([14 * s, 38, 2.5], [0, 0, -1], [1, 0, 0])) } if vidali
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

    # --- Ufik (modüler bağlantı elemanı) ---
    # Cep hattı (u, v): u cepten pimin girdiği uca doğru; Ø20 göbek uçtan 36 mm içeride, Ø10 boyun uca doğru.
    def ufik_hatti(pay = 0.0)
      plaka_hatti([[0, 0, 10 - pay], [22, 0, 5 - pay]])
    end

    # Beyaz plastik gövde: yerel +x uca doğru, +z panelden dışarı; üst yüzü panel yüzüyle bir, 11,5 mm gömülü.
    def ufik_tanimi
      d = @m.definitions.add('Ufik Bağlantı Elemanı')
      e = d.entities
      it(e, ufik_hatti(0.3).map { |x, y| P(x, y, 0) }, yon(0, 0, -1), 11.5)
      daire_it(e, P(0, 0, 0), Z_AXIS, 4.5, yon(0, 0, -1), 1.5, 20) # vida başı yuvası
      boya(e, @mat[:ufik])
      d
    end

    # Çelik pim: dişli kısmı panelde (x<0), başlı şaftı yerel +x yönünde karşı panelin ucuna girer; başı cebe gelir.
    def ufik_pim_tanimi
      d = @m.definitions.add('Ufik Pimi (çelik)')
      torna(d.entities, [[-8, 0], [-8, 2.5], [0, 2.5], [0, 3.5], [2, 3.5], [2, 2.5], [30, 2.5], [31, 4], [35, 4],
                         [36, 2], [36, 0]], 16, @mat[:cinko])
      d
    end

    # Cep (CNC) + gövde (demonte, elle bastırılır) + sıkma vidası (demonte). o: göbek merkezi panel yüzünde
    # (parça-yerel), n: yüz normali (dışa), t: pimin girdiği uca doğru. Uçtan cebe Ø8 pim deliği (kalınlığın ortası).
    def ufik_cep(e, o, n, t, id, kisa: false, w: nil)
      nv = Geom::Vector3d.new(*n)
      bv = (nv * Geom::Vector3d.new(*t)).to_a
      nokta = ->(u, v, h = 0) { P(*o.each_index.map { |i| o[i] + u * t[i] + v * bv[i] - h * n[i] }) }
      it(e, ufik_hatti.map { |u, v| nokta.(u, v) }, nv.reverse, 12)
      daire_it(e, nokta.(UF_ARA, 0, T / 2), Geom::Vector3d.new(*t), 4, Geom::Vector3d.new(*t).reverse, 12, 16)
      vida_koy(e, @ufik, eksen(o, t, n), P(*o), nv.reverse, 14.0, 0.0, nv, id)
      w ||= Geom::Vector3d.new(*n.each_index.map { |i| n[i] - 0.35 * t[i] }).normalize
      vida_koy(e, @ufvida, eksen(o, n.map(&:-@), t), P(*o), nv.reverse, 5.0, 1.5, w, "#{id}_v", false, kisa)
    end

    # Pim karşı panelin yüzüne vidalı (fabrikada takılı): p yüzdeki nokta, d yüzden dışarı (cebe doğru).
    def ufik_pim(e, p, d)
      z = d[2].abs > 0.9 ? [1, 0, 0] : [0, 0, 1]
      e.add_instance(@ufpim, eksen(p, d, z))
    end

    # Plastik kablo kapağı Ø60: yerel +x deliğe giriş yönü (arkadan öne); flanş x∈[-2, 0], halka x∈[0, 3], iç Ø48.
    def kablo_kapak_tanimi
      d = @m.definitions.add('Kablo Kapağı Ø60')
      torna(d.entities, [[-2, 24], [-2, 36], [0, 36], [0, 30], [3, 30], [3, 24]], 32, @mat[:kablo_kapak])
      d
    end

    # Bas-aç itici (fabrikada takılı): iç üst tablanın altına vidalı gövde, öne doğru yaylı itme ucu.
    # Yerel: +y arkaya, z=0 tablanın alt yüzü; lastik uç y=-1,5'te kapağın arka yüzündeki pula değer.
    def basac_tanimi
      d = @m.definitions.add('Bas-Aç İtici')
      e = d.entities
      g = e.add_group
      kutu(g.entities, -10, 4, -15, 10, 52, 0)
      kutu(g.entities, -16, 14, -3, 16, 42, 0)
      boya(g.entities, @mat[:basac])
      torna(e, [[0, 0], [0, 4], [3.5, 4], [3.5, 0]], 16, @mat[:nikel]).transform!(eksen([0, 0.5, -7.5], [0, 1, 0], [0, 0, 1]))
      torna(e, [[0, 0], [0, 4], [1.5, 4.5], [2, 4.5], [2, 0]], 16, @mat[:kablo_kapak]).transform!(eksen([0, -1.5, -7.5], [0, 1, 0], [0, 0, 1]))
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

    # Yan: iç yüzde arkalık kanalı; iki yanda da menteşe tabanı vida delikleri ve raf pimi delikleri (kapak ve raf
    # iki yöne de takılır), set için birleştirme delikleri; tablaların ufik pimleri (takılı). Sol yanda menteşe
    # tabanları ve vidaları, sağ yanda (açık niş) raf pimleri demonte.
    def dis_yan(k, sx)
      d = parca_tanimi(AD[k])
      e = d.entities
      h = ZT - Z0
      kutu(e, 0, 0, 0, T, D, h)
      xi = sx > 0 ? T : 0.0 # iç yüz
      kanal(e, ->(y, s) { P(xi, y, s * h) }, yon(-sx, 0, 0))
      MENTESE_Z.each { |hz| [-14, 14].each { |dz| daire_it(e, P(xi, 36, hz - Z0 + dz), X_AXIS, 1.5, yon(-sx, 0, 0), 10, 12) } }
      PIM_Y.each { |y| PIM_DELIK_Z.each { |z| daire_it(e, P(xi, y, z - Z0), X_AXIS, PIM_R, yon(-sx, 0, 0), 10, 12) } }
      BIRLESTIRME[:z].each { |z| daire_it(e, P(0, BIRLESTIRME[:y], z - Z0), X_AXIS, 2.5, yon(1, 0, 0), T, 12) }
      boya(e, @mat[:govde])
      UF_Y.each { |y| [T / 2, h - T / 2].each { |z| ufik_pim(e, [xi, y, z], [sx, 0, 0]) } }
      if sx > 0
        MENTESE_Z.each_with_index do |hz, i|
          hd = mentese_cerceve([xi, -KAPI_PAY, hz - Z0], sx)
          id = TABANLAR[i]
          vida_koy(e, @taban0, hd, P(xi, -KAPI_PAY, hz - Z0), Geom::Vector3d.new(-sx, 0, 0), 30.0, 0.0,
                   Geom::Vector3d.new(sx, 0, 0), id)
          [-14, 14].each_with_index do |s, j|
            vida_koy(e, @vida16, hd * eksen([s, 38, 2.5], [0, 0, -1], [1, 0, 0]), P(s, 38, 2.5).transform(hd),
                     Geom::Vector3d.new(-sx, 0, 0), 12.0, 2.5, Geom::Vector3d.new(sx, -0.45, 0.25).normalize, "#{id}_v#{j + 1}")
          end
        end
      else
        PIM_Y.each_with_index do |y, i|
          o = [xi, y, RAF_Z - PIM_R - Z0]
          vida_koy(e, @pim, eksen(o, [sx, 0, 0], [0, 0, 1]), P(*o), Geom::Vector3d.new(-sx, 0, 0), 20.0, 0.0,
                   Geom::Vector3d.new(sx, 0, 0), PIMLER[2 + i])
        end
      end
      [d, ORIJIN[k]]
    end

    def sol_yan; dis_yan(:sol_yan, 1); end
    def sag_yan; dis_yan(:sag_yan, -1); end

    # Alt tabla: üstte arkalık kanalı, iki ucunda yanların ufik cepleri, ortada dikmenin ufik pimleri (takılı);
    # altta ayak tabanları takılı, ayaklar demonte (çevrilerek takılır).
    def alt_tabla
      d = parca_tanimi(AD[:alt_tabla])
      e = d.entities
      gen = W - 2 * T
      kutu(e, 0, 0, 0, gen, D, T)
      kanal(e, ->(y, s) { P(s * gen, y, T) }, yon(0, 0, -1))
      UF_Y.each_with_index do |y, i|
        ufik_cep(e, [UF_ARA, y, T], [0, 0, 1], [-1, 0, 0], "uf_alt_sol_#{i + 1}")
        ufik_cep(e, [gen - UF_ARA, y, T], [0, 0, 1], [1, 0, 0], "uf_alt_sag_#{i + 1}")
      end
      boya(e, @mat[:govde])
      UF_Y_DIKME.each { |y| ufik_pim(e, [DIKME_X + T / 2 - T, y, T], [0, 0, 1]) }
      AYAK_XY.each_with_index do |(x, y), i|
        e.add_instance(@ayak_taban, eksen([x - T, y, 0], [0, 0, -1], [1, 0, 0]))
        vida_koy(e, @ayak, eksen([x - T, y, -TABAN_T], [0, 0, 1], [1, 0, 0]), P(x - T, y, -TABAN_T),
                 Geom::Vector3d.new(0, 0, 1), 40.0, 0.0, Geom::Vector3d.new(0, 0, -1), AYAKLAR[i])
      end
      [d, ORIJIN[:alt_tabla]]
    end

    # İç üst tabla: altta arkalık kanalı ve dikmenin ufik pimleri, üstte yanların ufik cepleri (meşe tablanın altında
    # kalır); tabla vidaları (demonte) içeriden alttan girer; bas-aç itici altta takılı.
    def ust_tabla
      d = parca_tanimi(AD[:ust_tabla])
      e = d.entities
      gen = W - 2 * T
      kutu(e, 0, 0, 0, gen, D, T)
      kanal(e, ->(y, s) { P(s * gen, y, 0) }, yon(0, 0, 1))
      UF_Y.each_with_index do |y, i|
        ufik_cep(e, [UF_ARA, y, T], [0, 0, 1], [-1, 0, 0], "uf_ust_sol_#{i + 1}")
        ufik_cep(e, [gen - UF_ARA, y, T], [0, 0, 1], [1, 0, 0], "uf_ust_sag_#{i + 1}")
      end
      boya(e, @mat[:govde])
      UF_Y_DIKME.each { |y| ufik_pim(e, [DIKME_X + T / 2 - T, y, 0], [0, 0, -1]) }
      TABLA_VIDA.each_with_index do |(x, y), i|
        o = [x - T, y, 0]
        vida_koy(e, @vida30, eksen(o, [0, 0, 1], [1, 0, 0]), P(*o), Geom::Vector3d.new(0, 0, 1), 30.0, 2.5,
                 Geom::Vector3d.new(0, 0, -1), TABLA_VIDALARI[i])
      end
      e.add_instance(@basac, tr(BASAC_X - T, 0, 0))
      [d, ORIJIN[:ust_tabla]]
    end

    def tabla
      d = parca_tanimi(AD[:tabla])
      kutu(d.entities, 0, 0, 0, W, TABLA_DER, TABLA_T)
      boya(d.entities, @mat[:mese])
      [d, ORIJIN[:tabla]]
    end

    # 3 mm arkalık: yanların, alt ve iç üst tablanın kanalına 8 mm girer; her bölmede Ø60 kablo deliği,
    # kablo kapakları (demonte) arkadan takılır.
    def arkalik
      d = parca_tanimi(AD[:arkalik])
      e = d.entities
      kutu(e, 0, 0, 0, W - 2 * T + 2 * KANAL_DER, ARKA_T, IC_H + 2 * KANAL_DER)
      ox, oz = ORIJIN[:arkalik].values_at(0, 2)
      KABLO[:x].each { |x| daire_it(e, P(x - ox, 0, KABLO[:z] - oz), Y_AXIS, KABLO[:r], yon(0, 1, 0), ARKA_T, 32) }
      boya(e, @mat[:arka])
      KABLO[:x].each_with_index do |x, i|
        o = [x - ox, ARKA_T, KABLO[:z] - oz]
        vida_koy(e, @kkapak, eksen(o, [0, -1, 0], [0, 0, 1]), P(*o), Geom::Vector3d.new(0, -1, 0), 40.0, 0.0,
                 Geom::Vector3d.new(0, 1, 0), KABLO_KAPAKLARI[i])
      end
      [d, ORIJIN[:arkalik]]
    end

    # Orta dikme: iki yüzünde raf pimi delikleri; sol yüzünde (kapaklı bölme) iki ucunda ufik cepleri; sağ yüzünde
    # (açık niş) raf pimleri (demonte).
    def dikme
      d = parca_tanimi(AD[:dikme])
      e = d.entities
      kutu(e, 0, 0, 0, T, DIKME_DER, IC_H)
      [[0.0, 1], [T, -1]].each { |xf, s| PIM_Y.each { |y| PIM_DELIK_Z.each { |z| daire_it(e, P(xf, y, z - Z0 - T), X_AXIS, PIM_R, yon(s, 0, 0), 8, 12) } } }
      UF_Y_DIKME.each_with_index do |y, i|
        ufik_cep(e, [0, y, UF_ARA], [-1, 0, 0], [0, 0, -1], "uf_dik_alt_#{i + 1}")
        ufik_cep(e, [0, y, IC_H - UF_ARA], [-1, 0, 0], [0, 0, 1], "uf_dik_ust_#{i + 1}")
      end
      boya(e, @mat[:govde])
      PIM_Y.each_with_index do |y, i|
        o = [T, y, RAF_Z - PIM_R - Z0 - T]
        vida_koy(e, @pim, eksen(o, [1, 0, 0], [0, 0, 1]), P(*o), Geom::Vector3d.new(-1, 0, 0), 20.0, 0.0,
                 Geom::Vector3d.new(1, 0, 0), PIMLER[i])
      end
      [d, ORIJIN[:dikme]]
    end

    def raf
      d = parca_tanimi(AD[:raf])
      kutu(d.entities, 0, 0, 0, RAF_W, RAF_DER, T)
      boya(d.entities, @mat[:govde])
      [d, ORIJIN[:raf]]
    end

    # Düz beyaz sunta kapak, kulpsuz (bas-aç): arkada 2 menteşe kabı + gövde (takılı), bas-aç ucunun karşısında
    # metal pul. Kapak-yerel orijin = sol ön en alt köşe.
    def kapak(k = :kapak)
      h = KAPI[k]
      d = parca_tanimi(AD[k])
      e = d.entities
      gen = h[:gen]
      kutu(e, 0, 0, 0, gen, T, KAPI_H)
      sx = h[:sx]
      xi = h[:panel] - h[:x0] # tabanın vidalandığı yüz, kapak-yerel
      hdler = MENTESE_Z.map { |hz| mentese_cerceve([xi, T, hz - KAPI_Z0], sx) }
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
                 "mentese_#{k}_#{i + 1}", true)
      end
      torna(e, [[0, 0], [0, 7], [1, 7], [1, 0]], 20, @mat[:nikel])
        .transform!(eksen([BASAC_X - h[:x0], T, ZT - T - 7.5 - KAPI_Z0], [0, 1, 0], [0, 0, 1]))
      [d, ORIJIN[k]]
    end

    def bar_tr(a, b)
      v = b - a
      x = v.normalize
      y = Geom::Vector3d.new(1, 0, 0)
      Geom::Transformation.axes(a, x, y, x * y) * Geom::Transformation.scaling(ORIGIN, v.length / 10.mm, 1, 1)
    end

    # ------------------------------------------------------------------
    # Tanıtım dekoru (ayrı katmanlarda; kurulum sahnelerinde kapalı)
    # ------------------------------------------------------------------
    DUVAR_Y = 420.0
    SUS_TAG = 'Süs (bitki, kitap)'
    TV55_TAG = 'TV 55" (yer tutucu)'
    TV32_TAG = 'TV 32" (yer tutucu)'

    def duvar_tanimi
      d = @m.definitions.add('Duvar ve Zemin')
      e = d.entities
      g = e.add_group
      kutu(g.entities, -1800, DUVAR_Y, 0, 3600, DUVAR_Y + 20, 2700)
      boya(g.entities, @mat[:duvar])
      s = e.add_group
      kutu(s.entities, -1800, DUVAR_Y - 14, 0, 3600, DUVAR_Y, 70)
      boya(s.entities, @mat[:supurge])
      z = e.add_group
      kutu(z.entities, -1800, -4500, -12, 3600, DUVAR_Y, 0)
      boya(z.entities, @mat[:zemin])
      (-1800..3600).step(180).drop(1).each { |x| z.entities.add_line(P(x, -4500, 0), P(x, DUVAR_Y - 14, 0)) }
      d
    end

    # Kablo: köşeleri kavisli tek parça boru (yol noktaları mm).
    def kablo_ciz(e, pts, r, mat)
      yol = [pts.first]
      pts.each_cons(3) do |a, b, c|
        u = b.zip(a).map { |p, q| p - q }
        v = c.zip(b).map { |p, q| p - q }
        la = Math.sqrt(u.sum { |x| x * x })
        lb = Math.sqrt(v.sum { |x| x * x })
        f = [22.0, la / 2, lb / 2].min
        next yol << b if f < 0.5
        p0 = b.zip(u).map { |q, dd| q - dd * f / la }
        p2 = b.zip(v).map { |q, dd| q + dd * f / lb }
        (0..6).each { |i| s = i / 6.0; yol << [0, 1, 2].map { |k| (1 - s)**2 * p0[k] + 2 * (1 - s) * s * b[k] + s * s * p2[k] } }
      end
      yol << pts.last
      yol = yol.each_with_object([]) { |q, l| l << q if l.empty? || Math.sqrt(q.zip(l.last).sum { |x, y| (x - y)**2 }) > 0.05 }
      n = yol.size
      tan = (0...n).map { |i| Geom::Vector3d.new(*yol[[i + 1, n - 1].min].zip(yol[[i - 1, 0].max]).map { |x, y| x - y }).normalize }
      nv = tan[0].cross(tan[0].z.abs > 0.9 ? X_AXIS : Z_AXIS).normalize
      seg = 10
      halka = (0...n).map do |i|
        ti = tan[i]
        k = nv % ti
        nv = (nv - Geom::Vector3d.new(ti.x * k, ti.y * k, ti.z * k)).normalize
        bv = ti.cross(nv)
        (0...seg).map do |j|
          a = 2 * Math::PI * j / seg
          Geom::Point3d.new(*[0, 1, 2].map { |c| (yol[i][c] + r * (Math.cos(a) * nv.to_a[c] + Math.sin(a) * bv.to_a[c])).mm })
        end
      end
      mesh = Geom::PolygonMesh.new
      (0...n - 1).each { |i| seg.times { |j| mesh.add_polygon(halka[i][j], halka[i][(j + 1) % seg], halka[i + 1][(j + 1) % seg], halka[i + 1][j]) } }
      mesh.add_polygon(halka[0].reverse)
      mesh.add_polygon(halka[-1])
      g = e.add_group
      g.entities.add_faces_from_mesh(mesh, Geom::PolygonMesh::AUTO_SOFTEN | Geom::PolygonMesh::SMOOTH_SOFT_EDGES, mat, mat)
      g
    end

    def kutu_boya(e, a, mat)
      g = e.add_group
      kutu(g.entities, *a)
      boya(g.entities, @mat[mat])
      g
    end

    # Açık nişte modem (altta) ve uydu alıcısı (rafta), kabloları arkalıktaki delikten; kapaklı bölmede oyun konsolu
    # ve oyun kutuları.
    def dekor_tanimi
      d = @m.definitions.add('Dekor (cihazlar)')
      e = d.entities
      za = Z0 + T
      zr = RAF_Z + T
      kutu_boya(e, [500, 140, za, 690, 270, za + 34], :modem)
      [520, 670].each { |x| torna(e, [[0, 0], [0, 4], [105, 3], [105, 0]], 12, @mat[:modem]).transform!(eksen([x, 262, za + 34], [0, 0, 1], [1, 0, 0])) }
      [530, 550, 570, 590].each { |x| kutu_boya(e, [x, 139.6, za + 15, x + 6, 140, za + 19], :led) }
      kutu_boya(e, [500, 50, zr, 740, 235, zr + 40], :cihaz)
      kutu_boya(e, [525, 49.6, zr + 13, 600, 50, zr + 26], :led)
      kablo_ciz(e, [[595, 270, za + 17], [600, 330, za + 17], [655, 372, za + 60], [668, 380, KABLO[:z] - 12], [668, 410, KABLO[:z] - 12], [668, 412, 90]], 2.5, @mat[:kablo])
      kablo_ciz(e, [[640, 235, zr + 20], [650, 330, zr + 3], [680, 378, KABLO[:z] + 4], [680, 410, KABLO[:z] + 4], [690, 412, 90]], 2.5, @mat[:kablo])
      kutu_boya(e, [40, 60, za, 315, 370, za + 82], :modem)
      kutu_boya(e, [40, 59.6, za + 34, 315, 60, za + 48], :cihaz)
      (0..4).each { |i| kutu_boya(e, [335 + i * 15, 110, za, 349 + i * 15, 280, za + 135], i.even? ? :kutu1 : :kutu2) }
      d
    end

    # Tabla üstünde bitki ve kitaplar (set ve yakın çekim görsellerinde).
    def sus_tanimi
      d = @m.definitions.add('Süs (bitki, kitap)')
      e = d.entities
      zu = ZT + TABLA_T
      torna(e, [[0, 0], [0, 58], [150, 70], [158, 70], [158, 0]], 28, @mat[:saksi]).transform!(eksen([110, 220, zu], [0, 0, 1], [1, 0, 0]))
      [[110, 220, 250, 85], [70, 190, 300, 65], [150, 250, 330, 60], [100, 260, 380, 50]].each do |x, y, z, r|
        torna(e, (0..8).map { |i| a = Math::PI * i / 8; [r * -Math.cos(a), r * Math.sin(a)] }, 16, @mat[:yesil])
          .transform!(eksen([x, y, zu + z], [0, 0, 1], [1, 0, 0]))
      end
      kutu_boya(e, [260, 40, zu, 470, 190, zu + 30], :kitap)
      kutu_boya(e, [275, 55, zu + 30, 455, 175, zu + 54], :kitap2)
      kutu_boya(e, [262, 39.6, zu + 3, 468, 40, zu + 27], :sayfa)
      d
    end

    # Yer tutucu TV (marka yok, ekranda düz renk): ayaklı, cx ortası, cy arka panelin önü.
    def tv_tanimi(ad, gen, yuk, cx, cy)
      d = @m.definitions.add(ad)
      e = d.entities
      zu = ZT + TABLA_T
      kutu_boya(e, [cx - 150, cy - 90, zu, cx + 150, cy + 110, zu + 8], :tv)
      kutu_boya(e, [cx - 25, cy + 10, zu + 8, cx + 25, cy + 30, zu + 90], :tv)
      kutu_boya(e, [cx - gen / 2, cy + 18, zu + 70, cx + gen / 2, cy + 44, zu + 70 + yuk], :tv)
      kutu_boya(e, [cx - gen / 2 + 8, cy + 17.6, zu + 78, cx + gen / 2 - 8, cy + 18, zu + 62 + yuk], :ekran)
      d
    end

    # --- Ölçü görseli: çizgiler ve 3B yazı ---
    def cubuk(e, a, b, k = 2.4)
      fark = b.zip(a).map { |p, q| p - q }
      g = e.add_group
      kutu(g.entities, 0, -k / 2, -k / 2, Math.sqrt(fark.sum { |c| c * c }), k / 2, k / 2)
      x = Geom::Vector3d.new(*fark).normalize
      z = x.parallel?(Z_AXIS) ? X_AXIS.clone : Z_AXIS.clone
      yv = z.cross(x).normalize
      g.transform!(Geom::Transformation.axes(P(*a), x, yv, x.cross(yv)))
      boya(g.entities, @mat[:olcu])
    end

    # :on önden okunur (XZ düzlemi), :dik önden okunur ve dik, :yan sağdan okunur (YZ düzlemi)
    def yazi(e, metin, merkez, yon_ad, boy = 42.0)
      g = e.add_group
      g.entities.add_3d_text(metin, TextAlignLeft, 'Segoe UI', true, false, boy.mm, 0.0, 0.0, true, 0.0)
      c = g.bounds.center
      g.transform!(Geom::Transformation.translation(Geom::Vector3d.new(-c.x, -c.y, 0)))
      r = Geom::Transformation.rotation(ORIGIN, X_AXIS, 90.degrees)
      r = Geom::Transformation.rotation(ORIGIN, Y_AXIS, -90.degrees) * r if yon_ad == :dik
      r = Geom::Transformation.rotation(ORIGIN, Z_AXIS, 90.degrees) * r if yon_ad == :yan
      g.transform!(Geom::Transformation.translation(P(*merkez) - ORIGIN) * r)
      boya(g.entities, @mat[:olcu])
    end

    def olcu_tanimi
      d = @m.definitions.add('Ölçüler')
      e = d.entities
      h = ZT + TABLA_T
      y0 = D - TABLA_DER
      yo = y0 - 1
      zu = h + 70
      cubuk(e, [0, yo, zu], [W, yo, zu])
      [0, W].each { |x| cubuk(e, [x, yo, h + 15], [x, yo, zu + 22], 1.4) }
      yazi(e, '900', [W / 2, yo, zu + 42], :on, 46.0)
      xr = W + 90
      cubuk(e, [xr, yo, 0], [xr, yo, h])
      [0, h].each { |z| cubuk(e, [W + 4, yo, z], [xr + 22, yo, z], 1.4) }
      yazi(e, '500', [xr + 42, yo, h / 2], :dik, 46.0)
      xd = W + 1
      cubuk(e, [xd, y0, h + 45], [xd, D, h + 45])
      [y0, D].each { |y| cubuk(e, [xd, y, h + 12], [xd, y, h + 65], 1.4) }
      yazi(e, '430', [xd + 1, (y0 + D) / 2, h + 100], :yan, 46.0)
      yazi(e, 'Set: iki modül yan yana 1800 mm', [W / 2, yo, h + 230], :on, 30.0)
      yazi(e, 'Ayak 130 mm · açık niş rafı ayarlı', [W / 2, yo, h + 180], :on, 26.0)
      d
    end

    # ------------------------------------------------------------------
    # Model kurulumu
    # ------------------------------------------------------------------
    def kur(kayit_yolu = nil)
      @m = Sketchup.active_model
      @m.start_operation('Liva TV ünitesi kurulum modeli', true)
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
      @vida30 = vida_tanimi('Tabla Vidası 3.5x30', 3.8, 2.5, 1.75, 30)
      @ufvida = vida_tanimi('Ufik Sıkma Vidası', 3.6, 1.5, 1.8, 8)
      @ufik = ufik_tanimi
      @ufpim = ufik_pim_tanimi
      @pim = pim_tanimi
      @taban0 = taban_tanimi(false)
      @kol = kol_tanimi
      @kap = kap_tanimi
      @bag = bag_tanimi
      @ayak_taban = ayak_taban_tanimi
      @ayak = ayak_tanimi
      @kkapak = kablo_kapak_tanimi
      @basac = basac_tanimi
      arac = tornavida_tanimi
      kisa = kisa_tornavida_tanimi

      tags = SIRA.map { |k| [k, @m.layers.add(ETIKET[k])] }.to_h
      liste_tag = @m.layers.add(LISTE_TAG)
      arac_tag = @m.layers.add(ARAC_TAG)
      ek = [[DUVAR_TAG, duvar_tanimi], [DEKOR_TAG, dekor_tanimi], [SUS_TAG, sus_tanimi],
            [TV55_TAG, tv_tanimi('TV 55 (yer tutucu)', 1230.0, 715.0, W, 220.0)],
            [TV32_TAG, tv_tanimi('TV 32 (yer tutucu)', 725.0, 430.0, W / 2, 220.0)], [OLCU_TAG, olcu_tanimi]]

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
      ek.each { |t, d| @m.entities.add_instance(d, Geom::Transformation.new).layer = @m.layers.add(t) }

      parca_listesi(liste_tag)
      stil
      bagla
      son_durum
      sahneler
      ek.each { |t, _| @m.layers[t].visible = false }
      @m.commit_operation
      @m.save(kayit_yolu) if kayit_yolu
      "Kuruldu: #{SIRA.size} parça, #{@vidalar.size} animasyonlu vida/ufik/ayak/pim, #{@m.pages.size} sahne"
    end

    # Kutu içeriği: paneller yere yatırılmış, fabrikada takılı hırdavat görünür; ayrı gelen küçük parçalar önde.
    def parca_listesi(tag)
      rx = ->(a) { Geom::Transformation.rotation(ORIGIN, X_AXIS, a.degrees) }
      ry = ->(a) { Geom::Transformation.rotation(ORIGIN, Y_AXIS, a.degrees) }
      rz = ->(a) { Geom::Transformation.rotation(ORIGIN, Z_AXIS, a.degrees) }
      bir = Geom::Transformation.new
      yerlesim = {
        sol_yan: [rz.(90) * ry.(-90), 1300, 0], sag_yan: [rz.(90) * ry.(90), 1800, 0],
        dikme: [rz.(90) * ry.(90), 2300, 0], arkalik: [rx.(-90), 2800, 0],
        alt_tabla: [bir, 1300, 550], ust_tabla: [rx.(180), 2300, 550], tabla: [bir, 3300, 550],
        raf: [bir, 1300, 1100], kapak: [rx.(90), 2000, 1100]
      }
      @m.entities.grep(Sketchup::ComponentInstance).select { |i| nit(i, :parca) && !%w[tornavida kisa_tornavida].include?(nit(i, :parca)) }.each do |ana|
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
        @m.entities.add_text(AD[k], on, Geom::Vector3d.new(0, -90.mm, 0)).layer = tag
      end
      ek = lambda do |defn, adet, x, dx, ad, lt|
        adet.times { |i| @m.entities.add_instance(defn, tr(x + i * dx, -420, 0) * lt).layer = tag }
        @m.entities.add_text(ad, P(x, -560, 0), Geom::Vector3d.new(0, -90.mm, 0)).layer = tag unless ad.empty?
      end
      yatik = ->(z) { eksen([0, 0, z], [1, 0, 0], [0, 0, 1]) }
      ek.(@ayak, 4, 1300, 70, 'Ayak (4)', eksen([0, 0, 24], [1, 0, 0], [0, 0, 1]))
      ek.(@vida30, 6, 1750, 30, 'Tabla Vidası (6)', yatik.(4))
      ek.(@ufik, 12, 2200, 32, 'Ufik + Vidası (12)', tr(0, 0, 11.5))
      ek.(@pim, 4, 2800, 30, 'Raf Pimi (4)', yatik.(3.5))
      ek.(@taban0, 2, 3150, 80, 'Menteşe Tabanı (2) + Vida (4)', bir)
      ek.(@vida16, 4, 3320, 25, '', yatik.(4))
      ek.(@kkapak, 2, 3750, 90, 'Kablo Kapağı (2)', eksen([0, 0, 2], [0, 0, 1], [1, 0, 0]))
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
        ['0 Kutu İçeriği', [], :liste, 'Paneller ve fabrikada takılı parçalar (ufik pimleri, menteşe kapları, ayak tabanları, bas-aç); ufikler, ayaklar, vidalar, raf pimleri, menteşe tabanları ve kablo kapakları ayrı.'],
        ['1 Ayaklar', %i[alt_tabla], 1, 'Ayakları alt tablanın altındaki tabanlara çevirerek takın.'],
        ['2 Orta Dikme', %i[dikme], 2, 'Orta dikmeyi alt tablanın pimlerine oturtun; 2 ufiği bastırıp vidalarını sıkın.'],
        ['3 İç Üst Tabla', %i[ust_tabla], 3, 'İç üst tablayı dikmenin üstüne indirin; 2 ufiği bastırıp vidalarını sıkın.'],
        ['4 Sol Yan', %i[sol_yan], 4, 'Sol yanı tablaların uçlarına geçirin; 4 ufiği bastırıp vidalarını sıkın.'],
        ['5 Arkalık', %i[arkalik], 5, 'Arkalığı sağdan tablaların kanalına sürüp sol yanın kanalına oturtun.'],
        ['6 Sağ Yan', %i[sag_yan], 6, 'Sağ yanı tablaların uçlarına ve arkalığın kenarına geçirin; 4 ufiği sıkın.'],
        ['7 Tabla', %i[tabla], 7, 'Meşe tablayı üste oturtun; içeriden 6 vidayla bağlayın.'],
        ['8 Raf', %i[raf], 8, 'Raf pimlerini açık nişe takın, rafı yerleştirin.'],
        ['9 Menteşe Tabanları', [], 9, 'Menteşe tabanlarını kapağın takılacağı yana (burada sol) vidalayın.'],
        ['10 Kapak', KAPILAR, :kapak, 'Kapağı tabanlara geçirip menteşe vidalarını sıkın; kapak bas-aç ile açılır.'],
        ['11 Kablo Kapakları', [], 10, 'Kablo kapaklarını arkalıktaki deliklere arkadan takın.'],
        ['12 Bitmiş Ürün', [], :bitti, 'Kurulum tamamlandı.']
      ]
      ek = [ARAC_TAG, DUVAR_TAG, DEKOR_TAG, SUS_TAG, TV55_TAG, TV32_TAG, OLCU_TAG, SET_TAG]
      acik = []
      tanim.each do |ad, yeni, kam, aciklama|
        acik += yeni
        liste = kam == :liste
        @m.layers.each do |l|
          k = ETIKET.key(l.name)
          l.visible = if l.name == LISTE_TAG then liste
                      elsif ek.include?(l.name) then false
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
      raise 'Model bulunamadı — önce OzcanKurulum::LivaTv.kur' unless @parca.size == SIRA.size && @arac && @kisa_arac
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

    # Demonte parçayı gevşek konumda gösterir (tornavida gelmeden önce).
    def goster(ids)
      @cz.an { |s, _| ids.each { |id| s[:v][id] = { adv: 1.0, ang: 0.0 } } }
    end

    # Elle takılan parçalar (ufik gövdesi, raf pimi, menteşe tabanı, kablo kapağı): görünür olur, yerine itilir.
    def elle_tak(ids, sure = 0.9)
      goster(ids)
      @cz.bekle(0.3)
      @cz.olay(sure) { |s, u| ids.each { |id| s[:v][id] = { adv: 1 - u, ang: 0.0 } } }
    end

    # Ufik: gövdeler cebe bastırılır, vidaları sıkılınca pimin başını kavrayıp son milimetreyi çeker.
    def ufik_tak(ids, kam, cekler: [], bak: nil)
      elle_tak(ids)
      vidalar = ids.map { |i| "#{i}_v" }
      goster(vidalar)
      @cz.bekle(0.2)
      sirayla_sik(vidalar, kam, cekler: cekler, tur: 2, bak: bak)
    end

    def kapak_tak(k)
      z = @cz
      z.kamera(1.2, KAM[:kapak])
      z.an { |s, _| s[:kapi][k] = 90.0 }
      hareket(k, [0, -420, 0], [0, 0, 0], 1.8)
      vida_sik("mentese_#{k}_1", nil, tur: 3, sure: 0.8)
      vida_sik("mentese_#{k}_2", nil, tur: 3, sure: 0.8, yakin: false)
      z.kamera(0.8, KAM[:kapak])
      z.olay(1.4) { |s, u| s[:kapi][k] = 90.0 * (1 - u) }
    end

    def cizelge
      @cz = z = Cizelge.new
      z.an { |s, _| DEMONTE.each { |id| s[:v][id] = { gizli: true } } } # takılana kadar görünmesin
      z.baslik('Kutu içeriği — pimler, menteşe kapları, ayak tabanları ve bas-aç takılı; ufikler, ayaklar, vidalar ve küçük parçalar ayrı')
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

      z.baslik('2 · Orta dikmeyi alt tablanın pimlerine oturtun; iki ufiği cebine bastırıp vidalarını sıkın')
      z.kamera(1.2, KAM[2])
      hareket(:dikme, [0, 0, 300], [0, 0, 2], 1.6)
      ufik_tak(UF[:dikme_alt], KAM[2], cekler: cek_listesi(:dikme, [0, 0, 2], 2), bak: [-1, -0.7, 0.5])
      z.kamera(0.8, KAM[2])
      z.bekle(0.3)

      z.baslik('3 · İç üst tablayı dikmenin üstüne indirin; iki ufiği bastırıp vidalarını sıkın')
      z.kamera(1.2, KAM[3])
      hareket(:ust_tabla, [0, 0, 300], [0, 0, 2], 1.6)
      ufik_tak(UF[:dikme_ust], KAM[3], cekler: cek_listesi(:ust_tabla, [0, 0, 2], 2), bak: [-1, -0.7, -0.2])
      z.kamera(0.8, KAM[3])
      z.bekle(0.3)

      z.baslik('4 · Sol yanı tablaların uçlarına geçirin; dört ufiği bastırıp vidalarını sıkın')
      z.kamera(1.2, KAM[4])
      hareket(:sol_yan, [-400, 0, 0], [-2, 0, 0], 1.8)
      ufik_tak(UF[:sol], KAM[4], cekler: cek_listesi(:sol_yan, [-2, 0, 0], 4), bak: [0.35, -0.8, 1])
      z.kamera(0.8, KAM[4])
      z.bekle(0.3)

      z.baslik('5 · Arkalığı sağdan alt ve iç üst tablanın kanalına sürün, sol yanın kanalına oturtun')
      z.kamera(1.2, KAM[5])
      hareket(:arkalik, [950, 0, 0], [0, 0, 0], 2.4)
      z.bekle(0.4)

      z.baslik('6 · Sağ yanı tablaların uçlarına ve arkalığın kenarına geçirin; dört ufiği bastırıp vidalarını sıkın')
      z.kamera(1.2, KAM[6])
      hareket(:sag_yan, [400, 0, 0], [2, 0, 0], 1.8)
      ufik_tak(UF[:sag], KAM[6], cekler: cek_listesi(:sag_yan, [2, 0, 0], 4), bak: [-0.35, -0.8, 1])
      z.kamera(0.8, KAM[6])
      z.bekle(0.3)

      z.baslik('7 · Meşe tablayı üste oturtun; içeriden, iç üst tablanın altından altı vidayla bağlayın')
      z.kamera(1.2, KAM[7])
      hareket(:tabla, [0, 0, 350], [0, 0, 0], 1.6)
      z.an { |s, _| TABLA_VIDALARI.each { |id| s[:v][id] = { adv: 1.0, ang: 0.0 } } }
      TABLA_VIDALARI.each_with_index do |id, i| # ilk vidaya önden-alttan bak, kalanları içeriden
        z.kamera(0.8, KAM[:ic]) if i == 1
        vida_sik(id, nil, tur: 5, sure: i.zero? ? 1.0 : 0.7, yakin: i.zero?, bak: [0.35, -0.9, -0.5])
      end
      z.kamera(0.8, KAM[7])
      z.bekle(0.3)

      z.baslik('8 · Raf pimlerini açık nişe takın, rafı pimlerin üzerine yerleştirin')
      z.kamera(1.2, KAM[8])
      elle_tak(PIMLER)
      hareket(:raf, [0, -450, 40], [0, 0, 40], 1.2)
      hareket(:raf, [0, 0, 40], [0, 0, 0], 0.4)
      z.bekle(0.3)

      z.baslik('9 · Menteşe tabanlarını kapağın takılacağı yana vidalayın (burada sol yan; sağa da takılabilir)')
      z.kamera(1.2, KAM[9])
      elle_tak(TABANLAR)
      goster(TABAN_VIDALARI)
      z.bekle(0.2)
      sirayla_sik(TABAN_VIDALARI, KAM[9], tur: 4, bak: [0.8, -0.6, 0.25])
      z.kamera(0.8, KAM[9])
      z.bekle(0.3)

      z.baslik('10 · Kapağı tabanlara geçirip iki menteşe vidasını sıkın; kapak kulpsuz, bas-aç ile açılır')
      kapak_tak(:kapak)
      z.bekle(0.3)

      z.baslik('11 · Kablo kapaklarını arkalıktaki iki deliğe arkadan takın')
      z.kamera(1.2, KAM[10])
      elle_tak(KABLO_KAPAKLARI, 1.0)
      z.bekle(0.4)

      z.baslik('Kurulum tamamlandı')
      z.kamera(1.6, KAM[:bitti])
      z.olay(1.3) { |s, u| s[:kapi][:kapak] = 95.0 * u }
      z.bekle(0.8)
      z.olay(1.3) { |s, u| s[:kapi][:kapak] = 95.0 * (1 - u) }
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

