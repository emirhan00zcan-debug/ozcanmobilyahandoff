# encoding: UTF-8
# Fırın Dolabı (Tablalı) — 60 x 60 x 89 cm, ayaklı, önde baza, üstte 3,6 cm tabla — model ve kurulum kılavuzu.
# Yeniden çizim: research_notes/Firin dolabi tablali 2026-10-29/tarif-firin-dolabi-tablali.txt (fotoğraflara göre;
# 10.10.2026 tarihli firin_dolabi.rb tablalı varyasyonunun yerine geçer). Alttan üste: 10 cm ayak (arkada ve bazanın
# arkasında) + önde baza, alt tabla, 12 cm tepsi bölmesi (önünde 15,5 cm klapa kapak, alt tablaya iki menteşeyle,
# aşağı açılır), orta tabla, 58,5 cm fırın boşluğu; yanların üstünde köşebentlere alttan vidalı 36 mm tabla
# (60 G x 65 D, önde ~3 cm taşar). Arkalık 3 mm, arkaya çivili. Her şey 18 mm beyaz sunta.
#
# Her panel ayrı bileşen; fabrikada takılı gelenler (şeffaf çektirmeler, köşebentler, menteşe tabanları, kapaktaki
# kulp) panelin içinde. Baza çektirmesiz: alt tablanın üstünden 3 vidayla. Ayaklar ve vidaları, baza vidaları,
# menteşeler ve vidaları, köşebent vidaları, çiviler ve arkalık ayrı gelir.
# Kurulum sırası kullanıcının verdiği gibidir:
#   1 baza + ayaklar (alt tabla grubu önde bekler)  2 yanlar orta tablaya  3 alt tabla grubu yanlara (alttan oturur)
#   4 üst tabla  5 arkalık  6 kapak menteşeleri  7 kapak alt tablaya
#
# SketchUp > Pencere > Ruby Konsolu:
#   load 'C:/.../scripts/product-3d/kurulum/firin_dolabi_tablali.rb'
#   OzcanKurulum::FirinDolabiTablali.kur        # AÇIK MODELİ TEMİZLER, modeli sıfırdan kurar
#   OzcanKurulum::FirinDolabiTablali.oynat      # montaj animasyonunu ekranda oynatır
#   OzcanKurulum::FirinDolabiTablali.kumanda    # klavyeyle adım adım: → ← Enter, K serbest kamera, Esc
#   (konsoldan: sonraki, onceki, durdur, devam, adim(3), git(3), bitir)
#   OzcanKurulum::FirinDolabiTablali.kaydet('C:/kareler') # animasyonu PNG karelere yazar
#
# Koordinatlar mm: X genişlik (0 = sol dış yüz), Y derinlik (0 = gövde ön yüzü, +Y arkaya; kapak Y=-18..0'da,
# arkalık 600..603), Z yükseklik (0 = zemin).

module OzcanKurulum
  module FirinDolabiTablali
    extend self

    # ------------------------------------------------------------------
    # Ölçüler (mm)
    # ------------------------------------------------------------------
    W = 600.0            # genişlik
    T = 18.0             # panel kalınlığı
    IW = W - 2 * T       # iç genişlik 564
    D = 600.0            # gövde derinliği (arkalık +3, kapak +18)
    Z0 = 100.0           # ayak/baza yüksekliği: alt tablanın alt yüzü, yanların alt kenarı
    ORTA_Z = 238.0       # orta tablanın alt yüzü (üstü 256; altında 120 iç bölme)
    ZT = 854.0           # yanların üst kenarı (yan 754)
    TABLA_T = 36.0       # iki kat 18 mm
    TABLA_DER = 650.0
    ARKA_T = 3.0
    TABLA_Y0 = D + ARKA_T - TABLA_DER # tablanın ön kenarı (-47): arkada arkalıkla hizalı
    CEKTIRME_Y = [60.0, D - 60].freeze
    BAZA_VIDA_X = [120.0, W / 2, W - 120].freeze # baza alt tablaya üstten 3 vidayla (4x40), bazanın üst kenarına
    KOSEBENT_Y = [100.0, D - 80].freeze
    AYAK_XY = [[70.0, 70.0], [W - 70, 70.0], [70.0, D - 50], [W - 70, D - 50]].freeze # bazanın arkasında ve arkada
    AYAK_VIDA = [[-17, -17], [17, -17], [17, 17], [-17, 17]].freeze
    # Klapa kapak: 600 x 155, tam bindirme, 101–256; alt ön kenarında döner, aşağı açılır
    KAPAK = { x0: 0.0, z: [Z0 + 1, ORTA_Z + T], gen: W, py: -T, klapa: true }.freeze
    KAPI = { kapak: KAPAK, mentese_1: KAPAK, mentese_2: KAPAK }.freeze # menteşe gövdeleri kapakla birlikte döner
    KAPILAR = KAPI.keys.freeze
    KAPAK_GRUBU = KAPILAR
    MENTESE_X = [80.0, W - 80].freeze # kapak kenarlarından ~80 mm içeride; tabanlar alt tablanın üstünde
    KAP_ZC = KAPAK[:z][0] + 22.5 - (Z0 + T) # kap merkezi alt tablanın üst yüzünden 5,5 mm (kapak kenarından 22,5)
    KULP_ARA = 160.0
    KULP = [W / 2, (KAPAK[:z][1] - KAPAK[:z][0]) / 2].freeze # kapak ortası
    CIVI_XZ = ([9.0, W - 9].product([150.0, 300.0, 450.0, 600.0, 750.0]) +
               [150.0, 300.0, 450.0].product([Z0 + T / 2, ORTA_Z + T / 2])).freeze
    KAPAK_DIS = [0.0, -450.0, 300.0].freeze # menteşeler takılırken kapak (90° açık) önde bekler
    ALT_DIS = [0.0, -850.0, 0.0].freeze     # baza ve ayaklar takılırken alt tabla grubu önde; 3. adımda yerine
    ALT_GRUBU = %i[alt_tabla baza].freeze
    FIRIN = { x: [2.5, W - 2.5], z: [ORTA_Z + T + 2, ZT - 2], y: -22.0 }.freeze # son karede örnek ankastre fırın
    PLAKA_T = 3.0

    DIKEY_FOV = 30.0
    VIDEO_FOV = 50.0

    DICT = 'ozcan_kurulum'
    SIRA = (%i[alt_tabla baza sol_yan sag_yan orta_tabla tabla arkalik firin] + KAPILAR).freeze
    AD = {
      alt_tabla: 'Alt Tabla', baza: 'Baza', sol_yan: 'Sol Yan', sag_yan: 'Sağ Yan', orta_tabla: 'Orta Tabla',
      tabla: 'Üst Tabla', arkalik: 'Arkalık', kapak: 'Klapa Kapak', mentese_1: 'Menteşe', mentese_2: 'Menteşe',
      firin: 'Ankastre Fırın (örnek)'
    }.freeze
    ETIKET = {
      alt_tabla: '01 Alt Tabla', baza: '01 Alt Tabla', sol_yan: '02 Yanlar', sag_yan: '02 Yanlar',
      orta_tabla: '03 Orta Tabla', tabla: '04 Üst Tabla', arkalik: '05 Arkalık', kapak: '06 Kapak',
      mentese_1: '06 Kapak', mentese_2: '06 Kapak', firin: '08 Fırın (örnek)'
    }.freeze
    LISTE_TAG = '00 Parça Listesi'
    ARAC_TAG = '99 Tornavida'

    # Kamera noktaları [göz, hedef] (mm)
    KAM = {
      liste:   [[2600, -2300, 5900], [2600, 330, 0]],
      1 =>     [[1500, -2650, 950], [300, -580, 90]],
      2 =>     [[2000, -3000, 1500], [300, -150, 360]],
      3 =>     [[1800, -2600, 1250], [300, -150, 320]],
      4 =>     [[1800, -2300, 1750], [300, 250, 600]],
      5 =>     [[1800, 2700, 1400], [300, 400, 450]],
      6 =>     [[750, -2350, 1350], [300, -380, 380]],
      7 =>     [[1600, -2100, 1050], [300, -120, 230]],
      bitti:   [[1800, -2500, 1500], [300, 200, 440]]
    }.freeze

    # Parçaların yerleşim orijini (bileşen orijini = parçanın min köşesi)
    ORIJIN = {
      alt_tabla: [T, 0, Z0], baza: [0, 0, 0], sol_yan: [0, 0, Z0], sag_yan: [W - T, 0, Z0],
      orta_tabla: [T, 0, ORTA_Z], tabla: [0, TABLA_Y0, ZT], arkalik: [0, D, Z0],
      firin: [FIRIN[:x][0], FIRIN[:y], FIRIN[:z][0]]
    }.merge(KAPILAR.map { |k| [k, [0, -T, KAPAK[:z][0]]] }.to_h).freeze

    AYAKLAR = (1..4).map { |i| "ayak_#{i}" }.freeze
    AYAK_VIDALARI = AYAKLAR.flat_map { |a| (1..4).map { |j| "#{a}_vida_#{j}" } }.freeze
    KOSEBENT_VIDALARI = %w[sol sag].flat_map { |t| %w[on arka].map { |y| "kosebent_#{t}_#{y}" } }.freeze
    CIVILER = (1..CIVI_XZ.size).map { |i| "civi_#{i}" }.freeze
    MENTESE_KAP_VIDALARI = (1..2).flat_map { |i| (1..2).map { |j| "mentese_#{i}_kap_#{j}" } }.freeze
    BAZA_VIDALARI = (1..BAZA_VIDA_X.size).map { |i| "baza_vida_#{i}" }.freeze
    DEMONTE = (AYAKLAR + AYAK_VIDALARI + BAZA_VIDALARI + KOSEBENT_VIDALARI + CIVILER + MENTESE_KAP_VIDALARI).freeze

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
        govde: mk.('Beyaz Sunta', [245, 245, 243]),
        arka: mk.('Beyaz Arkalık 3 mm', [238, 238, 235]),
        kulp: mk.('Siyah Kulp', [30, 30, 32]),
        ayak: mk.('Gri Plastik Ayak', [150, 154, 160]),
        firin: mk.('Fırın Gövdesi (siyah)', [34, 34, 36]),
        cam: mk.('Fırın Camı', [58, 62, 68]),
        inoks: mk.('Paslanmaz', [196, 200, 206]),
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

    # Köşebent (L, 2 mm sac): yerel +x panelden içeri yatay kanat, z yukarı; z=0 yanın üst kenarı.
    def kosebent_tanimi
      d = @m.definitions.add('Köşebent 20x20')
      e = d.entities
      kutu(e, 0, -8, -20, 2, 8, 0)
      kutu(e, 2, -8, -2, 20, 8, 0)
      boya(e, @mat[:nikel])
      d
    end

    # Siyah klasik kulp, 160 mm vida aralığı: yerel +x kapaktan dışarı, y kulp boyu (fabrikada takılı).
    def kulp_tanimi
      d = @m.definitions.add('Siyah Klasik Kulp 160')
      [-1, 1].each do |sy|
        g = d.entities.add_group
        kutu(g.entities, 0, sy * KULP_ARA / 2 - 4.5, -4.5, 22, sy * KULP_ARA / 2 + 4.5, 4.5)
        boya(g.entities, @mat[:kulp])
      end
      yarim = [[0, 7.5], [5, 7], [8, 5.5], [11, 4], [14, 5], [17, 6.5], [20, 5], [24, 3.5], [40, 4.5], [60, 5.5],
               [72, 4.5], [76, 3.8], [84, 3.8], [87, 4.5], [91, 5], [94, 4.5], [97, 2.5]]
      prof = [[-97, 0]] + yarim.reverse.map { |x, r| [-x, r] } + yarim.drop(1) + [[97, 0]]
      torna(d.entities, prof, 24, @mat[:kulp]).transform!(eksen([25, 0, 0], [0, 1, 0], [1, 0, 0]))
      d
    end

    # Ayarlı plastik ayak 100 mm: yerel +x yukarı (alt tablaya doğru), x=0 tablanın alt yüzü; Ø64 plaka 4 vidalı.
    def ayak_tanimi
      d = @m.definitions.add('Ayarlı Ayak 100')
      torna(d.entities, [[-4, 0], [-4, 32], [0, 32], [0, 0]], 32, @mat[:ayak])
      torna(d.entities, [[-86, 0], [-86, 17], [-80, 19], [-10, 22], [-4, 24], [-4, 0]], 32, @mat[:ayak])
      torna(d.entities, [[-100, 0], [-100, 24], [-96, 26], [-88, 26], [-86, 17], [-86, 0]], 32, @mat[:ayak])
      AYAK_VIDA.each { |a, b| daire_it(d.entities, P(-4, a, b), X_AXIS, 2.2, yon(1, 0, 0), 4, 12) }
      d
    end

    # Menteşe kabı (vidasız; kap vidaları animasyonlu, 6. adımda takılır).
    def kap_vidasiz_tanimi
      d = @m.definitions.add('Menteşe Kabı Ø35 (tam bindirme)')
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
      end
      torna(e, [[-6, 0], [-6, 4], [6, 4], [6, 0]], 20, @mat[:nikel]).transform!(tr(0, -4, zc - 7.5))
      d
    end

    # Kutu içeriği için tek menteşe (kap + kol + bağlantı kolu bir arada).
    def mentese_liste_tanimi
      d = @m.definitions.add('Menteşe (kutu içeriği)')
      e = d.entities
      hd = Geom::Transformation.new
      e.add_instance(@kap, hd)
      e.add_instance(@kol, hd)
      e.add_instance(@bag, bar_tr(P(0, -4, KAP_ZC - 7.5), P(0, 12, 14)))
      d
    end

    # Klapa menteşesinin çerçevesi: alt tablanın üst yüzünde, yerel z yukarı.
    def klapa_cerceve(o)
      Geom::Transformation.axes(P(*o), X_AXIS, Y_AXIS, Z_AXIS)
    end

    # Tüm çektirmeler dünya koordinatında: k = iç köşe noktası, ex/ey/ez bağlantı çerçevesi
    # (x erkeğin panelinden uzağa, z dişinin panelinden uzağa). Yanlar orta tablaya yandan geçer; alt tabla grubu
    # yanların arasına alttan oturur (vida alt tablanın üstünde, orta tablanın altında — kısa tornavida). Orta tabla
    # vidaları yanın iç yüzünde, tablanın altında (kısa tornavida). Baza çektirmesiz: alt tablanın üstünden
    # vidalanır (alt_tabla bileşeninde).
    def baglantilar
      l = []
      [[:sol_yan, T, 1, 'sol'], [:sag_yan, W - T, -1, 'sag']].each do |yan, xs, sx, taraf|
        CEKTIRME_Y.zip(%w[on arka]).each do |y, yer|
          l << { id: "alt_#{taraf}_#{yer}", disi: :alt_tabla, erkek: yan, k: [xs, y, Z0 + T], ex: [sx, 0, 0], ez: [0, 0, 1],
                 kisa: true } # orta tabla üstte: 120 mm bölmede kısa tornavida
          l << { id: "orta_#{taraf}_#{yer}", disi: yan, erkek: :orta_tabla, k: [xs, y, ORTA_Z], ex: [0, 0, -1],
                 ez: [sx, 0, 0], kisa: true }
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

    # ------------------------------------------------------------------
    # Panel bileşenleri
    # ------------------------------------------------------------------
    # Yan (754): çektirmeler (alt tabla erkeği, orta tabla dişisi) ve üstte iç yüzde iki köşebent; köşebent vidaları
    # alttan tablaya (demonte).
    def yan(k, sx)
      d = parca_tanimi(AD[k])
      e = d.entities
      kutu(e, 0, 0, 0, T, D, ZT - Z0)
      boya(e, @mat[:govde])
      cektirmeler(e, k)
      xi = sx > 0 ? T : 0.0 # iç yüz
      taraf = sx > 0 ? 'sol' : 'sag'
      KOSEBENT_Y.zip(%w[on arka]).each do |y, yer|
        e.add_instance(@kosebent, eksen([xi, y, ZT - Z0], [sx, 0, 0], [0, 0, 1]))
        o = [xi + sx * 12, y, ZT - Z0 - 2]
        vida_koy(e, @vida16, eksen(o, [0, 0, 1], [1, 0, 0]), P(*o), Geom::Vector3d.new(0, 0, 1), 16.0, 2.5,
                 Geom::Vector3d.new(0.25 * sx, -0.35, -1).normalize, "kosebent_#{taraf}_#{yer}")
      end
      [d, ORIJIN[k]]
    end

    def sol_yan; yan(:sol_yan, 1); end
    def sag_yan; yan(:sag_yan, -1); end

    # Alt tabla: yanların arasında; ön kenarından bazaya üstten 3 vida (demonte), altında 4 ayak (demonte, 4'er vida),
    # üstünde önde kapak menteşe tabanları (fabrikada takılı).
    def alt_tabla
      d = parca_tanimi(AD[:alt_tabla])
      e = d.entities
      kutu(e, 0, 0, 0, IW, D, T)
      boya(e, @mat[:govde])
      cektirmeler(e, :alt_tabla)
      MENTESE_X.each { |hx| e.add_instance(@taban, klapa_cerceve([hx - T, 0, T])) }
      wb = Geom::Vector3d.new(0.2, -0.45, 1).normalize # tornavida üstten
      BAZA_VIDA_X.each_with_index do |x, i|
        o = [x - T, T / 2, T]
        vida_koy(e, @bvida, eksen(o, [0, 0, -1], [1, 0, 0]), P(*o), Geom::Vector3d.new(0, 0, -1), 40.0, 2.8, wb,
                 BAZA_VIDALARI[i])
      end
      wv = Geom::Vector3d.new(0.2, -0.35, -1).normalize # tornavida alttan
      AYAK_XY.each_with_index do |(x, y), i|
        lx = x - T
        o = [lx, y, 0]
        vida_koy(e, @ayak, eksen(o, [0, 0, 1], [1, 0, 0]), P(*o), Geom::Vector3d.new(0, 0, 1), 60.0, 0.0,
                 Geom::Vector3d.new(0, 0, -1), AYAKLAR[i])
        AYAK_VIDA.each_with_index do |(a, b), j|
          v = [lx + a, y + b, -4]
          vida_koy(e, @vida16, eksen(v, [0, 0, 1], [1, 0, 0]), P(*v), Geom::Vector3d.new(0, 0, 1), 16.0, 2.5, wv,
                   "#{AYAKLAR[i]}_vida_#{j + 1}")
        end
      end
      [d, ORIJIN[:alt_tabla]]
    end

    def orta_tabla
      d = parca_tanimi(AD[:orta_tabla])
      kutu(d.entities, 0, 0, 0, IW, D, T)
      boya(d.entities, @mat[:govde])
      cektirmeler(d.entities, :orta_tabla)
      [d, ORIJIN[:orta_tabla]]
    end

    # Baza 600 x 100: önde, ön yüzü yanların ön kenarıyla bir; alt tablanın üstünden üst kenarına 3 vidayla.
    def baza
      d = parca_tanimi(AD[:baza])
      kutu(d.entities, 0, 0, 0, W, T, Z0)
      boya(d.entities, @mat[:govde])
      cektirmeler(d.entities, :baza)
      [d, ORIJIN[:baza]]
    end

    # Üst tabla: iki kat 18 mm (çizimde ayrı katmanlar), yanların üstünde; arkada arkalıkla hizalı, önde ~3 cm taşar.
    def tabla
      d = parca_tanimi(AD[:tabla])
      [0, T].each do |z|
        g = d.entities.add_group
        kutu(g.entities, 0, 0, z, W, TABLA_DER, z + T)
        boya(g.entities, @mat[:govde])
      end
      [d, ORIJIN[:tabla]]
    end

    # Arkalık 3 mm, 600 x 754: yanların ve tablaların arka kenarına çivilenir (16 çivi, demonte).
    def arkalik
      d = parca_tanimi(AD[:arkalik])
      e = d.entities
      kutu(e, 0, 0, 0, W, ARKA_T, ZT - Z0)
      boya(e, @mat[:arka])
      CIVI_XZ.each_with_index do |(x, z), i|
        o = [x, ARKA_T, z - Z0]
        vida_koy(e, @civi, eksen(o, [0, -1, 0], [0, 0, 1]), P(*o), Geom::Vector3d.new(0, -1, 0), 20.0, 1.2,
                 Geom::Vector3d.new(0, 1, 0), CIVILER[i])
      end
      [d, ORIJIN[:arkalik]]
    end

    # Klapa kapak 600 x 155: arkasında alt kenara yakın iki Ø35 kap yuvası; siyah klasik kulp fabrikada takılı.
    def kapak
      h = KAPAK
      d = parca_tanimi(AD[:kapak])
      e = d.entities
      kutu(e, 0, 0, 0, h[:gen], T, h[:z][1] - h[:z][0])
      MENTESE_X.each { |hx| daire_it(e, P(0, 0, KAP_ZC).transform(mentese_hd(hx)), Y_AXIS, 17.5, yon(0, -1, 0), 12.5, 32) }
      kx, kz = KULP
      [-1, 1].each { |s| daire_it(e, P(kx + s * KULP_ARA / 2, 0, kz), Y_AXIS, 2.5, yon(0, 1, 0), T, 16) }
      boya(e, @mat[:govde])
      e.add_instance(@kulp, eksen([kx, 0, kz], [0, -1, 0], [0, 0, 1]))
      [d, ORIJIN[:kapak]]
    end

    # Kapak-yerel menteşe çerçevesi (alt tablanın üst yüzü, kapağın arka yüzü hizası)
    def mentese_hd(hx)
      klapa_cerceve([hx - KAPAK[:x0], T, Z0 + T - KAPAK[:z][0]])
    end

    # Menteşe gövdesi (kap + kol), demonte: 6. adımda kapaktaki yuvaya iki vidayla, 7. adımda koluyla alt tabladaki
    # tabana geçip sabitleme vidasıyla bağlanır. Kapakla aynı eksende döner.
    def mentese(i)
      k = :"mentese_#{i}"
      hd = mentese_hd(MENTESE_X[i - 1])
      d = parca_tanimi("#{AD[k]} #{i}")
      g = d.entities.add_group
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
      w = Geom::Vector3d.new(0, -Math.sin(35.degrees), Math.cos(35.degrees))
      vida_koy(ge, @mvida, lt, P(0, 34, 8).transform(hd), Geom::Vector3d.new(0, 0, -1).transform(hd), 4.0, 2.3, w,
               "mentese_#{i}", true)
      [-1, 1].each_with_index do |s, j|
        o = [24 * s, -1.0, KAP_ZC + 6]
        vida_koy(ge, @vida16h, hd * eksen(o, [0, -1, 0], [0, 0, 1]), P(*o).transform(hd),
                 Geom::Vector3d.new(0, -1, 0).transform(hd), 14.0, 2.2, Geom::Vector3d.new(0.2, 1, 0.35).normalize,
                 "mentese_#{i}_kap_#{j + 1}")
      end
      [d, ORIJIN[k]]
    end

    def mentese_1; mentese(1); end
    def mentese_2; mentese(2); end

    # Örnek ankastre fırın (yalnız son karede, kutuda yok): 595 x 594 ön panel, siyah cam, kapak kolu, düğmeler.
    def firin
      d = parca_tanimi(AD[:firin])
      e = d.entities
      gen = FIRIN[:x][1] - FIRIN[:x][0]
      yuk = FIRIN[:z][1] - FIRIN[:z][0]
      g = e.add_group
      kutu(g.entities, 0, 0, 0, gen, 21, yuk)
      kutu(g.entities, 20, 21, 2, gen - 20, 560, yuk - 14)
      boya(g.entities, @mat[:firin])
      c = e.add_group
      kutu(c.entities, 40, -1, 40, gen - 40, 0, yuk - 120)
      boya(c.entities, @mat[:cam])
      torna(e, [[0, 0], [0, 7], [gen - 120, 7], [gen - 120, 0]], 20, @mat[:inoks])
        .transform!(eksen([60, -32, yuk - 150], [1, 0, 0], [0, 0, 1]))
      [80, gen - 80].each do |x|
        torna(e, [[0, 0], [0, 4], [32, 4], [32, 0]], 12, @mat[:inoks]).transform!(eksen([x, 0, yuk - 150], [0, -1, 0], [0, 0, 1]))
      end
      [110, gen / 2, gen - 110].each do |x|
        torna(e, [[0, 0], [0, 15], [18, 15], [20, 12], [20, 0]], 24, @mat[:inoks]).transform!(eksen([x, 0, yuk - 55], [0, -1, 0], [0, 0, 1]))
      end
      [d, ORIJIN[:firin]]
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
      @m.start_operation('Fırın dolabı (tablalı) kurulum modeli', true)
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
      @bvida = vida_tanimi('Sunta Vidası 4x40', 4.2, 2.8, 2, 40)
      @civi = civi_tanimi
      @disi = disi_tanimi
      @erkek = erkek_tanimi
      @taban = taban_tanimi
      @kol = kol_tanimi
      @kap = kap_vidasiz_tanimi
      @bag = bag_tanimi
      @kosebent = kosebent_tanimi
      @kulp = kulp_tanimi
      @ayak = ayak_tanimi
      arac = tornavida_tanimi
      kisa = kisa_tornavida_tanimi
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
      "Kuruldu: #{SIRA.size} parça, #{@vidalar.size} animasyonlu vida/çivi/ayak, #{@m.pages.size} sahne"
    end

    # Kutu içeriği: paneller yere yatırılmış, fabrikada takılı hırdavat (çektirmeler, köşebentler, menteşe tabanları,
    # kulp) üstünde; ayaklar, menteşeler, vidalar ve çiviler ayrı. Örnek fırın kutuda yok.
    PARCA_HARF = { sol_yan: 'A', sag_yan: 'B', alt_tabla: 'C', orta_tabla: 'D', tabla: 'E', baza: 'F', kapak: 'G',
                   arkalik: 'H' }.freeze

    def parca_listesi(tag)
      rx = ->(a) { Geom::Transformation.rotation(ORIGIN, X_AXIS, a.degrees) }
      ry = ->(a) { Geom::Transformation.rotation(ORIGIN, Y_AXIS, a.degrees) }
      rz = ->(a) { Geom::Transformation.rotation(ORIGIN, Z_AXIS, a.degrees) }
      bir = Geom::Transformation.new
      yerlesim = {
        sol_yan: [rz.(90) * ry.(-90), 1300, 900], sag_yan: [rz.(90) * ry.(90), 2050, 900],
        arkalik: [rx.(-90), 2800, 900], tabla: [bir, 3550, 900],
        alt_tabla: [bir, 1300, 0], orta_tabla: [bir, 2050, 0], baza: [rx.(-90), 2800, 0], kapak: [rx.(-90), 2800, 300]
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
        @m.entities.add_text("#{PARCA_HARF[k]} · #{AD[k]}", on, Geom::Vector3d.new(0, -110.mm, 0)).layer = tag
      end
      ek = lambda do |defn, adet, x, y, dx, ad, eks, anahtar|
        adet.times do |i|
          ins = @m.entities.add_instance(defn, eksen([x + i * dx, y, eks[2]], eks[0], eks[1]))
          ins.layer = tag
          nitelik(ins, liste: anahtar)
        end
        @m.entities.add_text(ad, P(x, y - 150, 0), Geom::Vector3d.new(0, -110.mm, 0)).layer = tag
      end
      ek.(@ayak, 4, 1250, -500, 110, 'Ayarlı Ayak (4)', [[0, 1, 0], [0, 0, 1], 32], 'ayak')
      ek.(@vida16, 16, 2050, -500, 22, 'Ayak Vidası (16)', [[0, 1, 0], [0, 0, 1], 4], 'ayak_vidasi')
      ek.(@bvida, 3, 2850, -500, 40, 'Baza Vidası 4x40 (3)', [[0, 1, 0], [0, 0, 1], 5], 'baza_vidasi')
      ek.(@vida16, 4, 3550, -500, 30, 'Köşebent Vidası (4)', [[0, 1, 0], [0, 0, 1], 4], 'kosebent_vidasi')
      ek.(mentese_liste_tanimi, 2, 1250, -950, 110, 'Menteşe (2)', [[1, 0, 0], [0, 0, 1], 0], 'mentese')
      ek.(@vida16h, 4, 2050, -950, 30, 'Menteşe Vidası (4)', [[0, 1, 0], [0, 0, 1], 4], 'mentese_vidasi')
      ek.(@civi, 16, 2850, -950, 16, 'Arkalık Çivisi (16)', [[0, 1, 0], [0, 0, 1], 3], 'civi')
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
        ['0 Kutu İçeriği', [], :liste, 'Paneller ve fabrikada takılı çektirmeler, köşebentler, menteşe tabanları ve kulp; ayaklar, menteşeler, vidalar ve çiviler ayrı.'],
        ['1 Baza ve Ayaklar', %i[alt_tabla baza], 1, 'Bazayı alt tablanın ön kenarının altına hizalayıp üstten 3 vidayla vidalayın; 4 ayağı 4\'er vidayla takın.'],
        ['2 Yanlar ve Orta Tabla', %i[sol_yan sag_yan orta_tabla], 2, 'Yanları orta tablanın iki ucuna geçirin; yanlardaki 4 çektirme vidasını sıkın.'],
        ['3 Alt Tabla', [], 3, 'Bazası ve ayakları takılı alt tablayı yanların arasına alttan oturtun, 4 çektirme vidasını sıkın.'],
        ['4 Üst Tabla', %i[tabla], 4, 'Üst tablayı yanların üstüne oturtun; 4 köşebent vidasını alttan sıkın.'],
        ['5 Arkalık', %i[arkalik], 5, 'Arkalığı arkaya yerleştirip yanlara, alt ve orta tablaya 16 çiviyle çakın.'],
        ['6 Kapak Menteşeleri', %i[kapak], 6, 'İki menteşeyi kapaktaki 35 mm yuvalara oturtup 2\'şer vidayla sabitleyin.'],
        ['7 Kapağı Bağlama', [], 7, 'Menteşe kollarını alt tabladaki tabanlara geçirin, sabitleme vidalarını sıkın.'],
        ['8 Bitmiş Ürün', %i[firin], :bitti, 'Kurulum tamamlandı; ankastre fırın orta bölmeye yerleştirilir.']
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
      raise 'Model bulunamadı — önce OzcanKurulum::FirinDolabiTablali.kur' unless @parca.size == SIRA.size && @arac && @kisa_arac && @cekic
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

    # aci > 0 açık: klapa kapak (ve ona takılı menteşe gövdeleri) alt ön kenarındaki yatay eksende öne-aşağı yatar.
    def kapi_R(k, aci)
      h = KAPI[k]
      Geom::Transformation.rotation(P(0, h[:py], h[:z][0]), X_AXIS, aci.degrees)
    end

    def acik_aci(_k)
      90.0
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

    # Birkaç parçayı birlikte taşır (kapak ve menteşe gövdeleri).
    def toplu(ks, a, b, sure)
      @cz.olay(sure) { |s, u| ks.each { |k| s[:p][k] = { vis: true, off: lerp3(a, b, u) } } }
    end

    # Demonte parçayı tornavida gelmeden önce gevşek konumda gösterir.
    def goster(ids)
      @cz.an { |s, _| ids.each { |id| s[:v][id] = { adv: 1.0, ang: 0.0 } } }
    end

    # Elle takılan parçalar (ayaklar): görünür olur, yerine itilir.
    def elle_tak(ids, sure = 1.0)
      goster(ids)
      @cz.bekle(0.3)
      @cz.olay(sure) { |s, u| ids.each { |id| s[:v][id] = { adv: 1 - u, ang: 0.0 } } }
    end

    # Çektirme sıkılırken parça son milimetreleri kapatır; parça bir taban ofsetinde (ör. önde beklerken) çalışır.
    def cek_dis(k, taban, bas, n)
      (0...n).map { |i| [k, taban.zip(bas).map { |t, b| t + b * (n - i) / n.to_f }, taban.zip(bas).map { |t, b| t + b * (n - i - 1) / n.to_f }] }
    end

    # Kapak ve menteşe gövdeleri aynı açıda döner.
    def kapak_aci(s, aci)
      KAPAK_GRUBU.each { |k| s[:kapi][k] = aci }
    end

    def cizelge
      @cz = z = Cizelge.new
      z.an { |s, _| DEMONTE.each { |id| s[:v][id] = { gizli: true } } } # takılana kadar görünmesin
      z.baslik('Kutu içeriği — çektirmeler, köşebentler, menteşe tabanları ve kulp takılı; ayak, menteşe, vida, çivi ayrı')
      z.kamera(0, KAM[:liste])
      z.bekle(3.5)

      z.baslik('1 · Bazayı alt tablaya üstten üç vidayla vidalayın, ayakları takın')
      z.an do |s, _|
        s[:liste] = false
        s[:p][:alt_tabla] = { vis: true, off: ALT_DIS }
      end
      z.kamera(1.2, KAM[1])
      hareket(:baza, ALT_DIS.zip([0, -320, -60]).map(&:sum), ALT_DIS, 1.6)
      goster(BAZA_VIDALARI)
      z.bekle(0.3)
      sirayla_sik(BAZA_VIDALARI, KAM[1], tur: 5, bak: [0.35, -1, 0.9])
      z.kamera(1.0, KAM[1])
      elle_tak(AYAKLAR)
      goster(AYAK_VIDALARI)
      z.bekle(0.3)
      sirayla_sik(AYAK_VIDALARI, KAM[1], tur: 4, bak: [0.4, -1, -0.7])
      z.kamera(0.8, KAM[1])
      z.bekle(0.3)

      z.baslik('2 · Yanları orta tablanın iki ucuna geçirin, yanlardaki dört çektirme vidasını sıkın')
      z.an { |s, _| s[:p][:orta_tabla] = { vis: true, off: [0, 0, 0] } }
      z.kamera(1.2, KAM[2])
      hareket(:sol_yan, [-400, 0, 0], [-2, 0, 0], 1.6)
      ids = %w[orta_sol_on orta_sol_arka]
      sirayla_sik(ids, KAM[2], cekler: cek_listesi(:sol_yan, [-2, 0, 0], ids.size))
      z.kamera(0.8, KAM[2])
      hareket(:sag_yan, [400, 0, 0], [2, 0, 0], 1.6)
      ids = %w[orta_sag_on orta_sag_arka]
      sirayla_sik(ids, KAM[2], cekler: cek_listesi(:sag_yan, [2, 0, 0], ids.size))
      z.kamera(0.8, KAM[2])
      z.bekle(0.3)

      z.baslik('3 · Alt tablayı (bazası ve ayakları takılı) yanların arasına alttan oturtun, dört vidayı sıkın')
      z.kamera(1.2, KAM[3])
      toplu(ALT_GRUBU, ALT_DIS, [0, 0, -70], 1.8)
      toplu(ALT_GRUBU, [0, 0, -70], [0, 0, 0], 0.9)
      ids = %w[sol sag].flat_map { |t| %w[on arka].map { |y| "alt_#{t}_#{y}" } }
      sirayla_sik(ids, KAM[3])
      z.kamera(0.8, KAM[3])
      z.bekle(0.3)

      z.baslik('4 · Üst tablayı yanların üstüne oturtun, dört köşebent vidasını alttan sıkın')
      z.kamera(1.2, KAM[4])
      hareket(:tabla, [0, 0, 300], [0, 0, 0], 1.8)
      goster(KOSEBENT_VIDALARI)
      z.bekle(0.3)
      sirayla_sik(KOSEBENT_VIDALARI, KAM[4], bak: [0.4, -0.8, -0.6])
      z.kamera(0.8, KAM[4])
      z.bekle(0.3)

      z.baslik('5 · Arkalığı arkaya yerleştirip yanlara, alt ve orta tablaya çivileyin')
      z.kamera(1.2, KAM[5])
      hareket(:arkalik, [0, 450, 0], [0, 0, 0], 1.8)
      goster(CIVILER)
      z.bekle(0.3)
      yakin_kamera(CIVILER.first, yon: [0.4, 1, 0.5])
      civi_cak(CIVILER.first)
      z.kamera(0.8, KAM[5])
      CIVILER.drop(1).each { |id| civi_cak(id) }
      z.bekle(0.4)

      z.baslik('6 · Kapak menteşelerini takın: kapaktaki yuvalara oturtup ikişer vidayla sabitleyin')
      z.an do |s, _|
        kapak_aci(s, 90.0)
        s[:p][:kapak] = { vis: true, off: KAPAK_DIS }
      end
      z.kamera(1.2, KAM[6])
      ust = [KAPAK_DIS[0], KAPAK_DIS[1], KAPAK_DIS[2] + 140]
      toplu(%i[mentese_1 mentese_2], ust, KAPAK_DIS, 1.4)
      goster(MENTESE_KAP_VIDALARI)
      z.bekle(0.3)
      sirayla_sik(MENTESE_KAP_VIDALARI, KAM[6], tur: 4, bak: [0.3, -0.6, 1])
      z.kamera(0.8, KAM[6])
      z.bekle(0.3)

      z.baslik('7 · Menteşeleri alt tabladaki tabanlara geçirin, sabitleme vidalarını sıkın; kapağı kapatın')
      z.kamera(1.2, KAM[7])
      toplu(KAPAK_GRUBU, KAPAK_DIS, [0, 0, 0], 1.8)
      sirayla_sik(%w[mentese_1 mentese_2], KAM[7], tur: 3)
      z.kamera(0.8, KAM[7])
      z.olay(1.4) { |s, u| kapak_aci(s, 90.0 * (1 - u)) }
      z.bekle(0.3)

      z.baslik('Kurulum tamamlandı')
      z.kamera(1.6, KAM[:bitti])
      z.olay(1.2) { |s, u| kapak_aci(s, 90.0 * u) }
      z.bekle(0.6)
      z.olay(1.2) { |s, u| kapak_aci(s, 90.0 * (1 - u)) }
      hareket(:firin, [0, -700, 0], [0, 0, 0], 2.0)
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

    # Montajlı son durum: tüm parçalar yerinde, vidalar, çiviler, ayaklar ve menteşeler takılı, kapak kapalı.
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
