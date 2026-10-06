# encoding: UTF-8
# Konsol (145 x 72,5 x 44,5 cm) — kurulum kılavuzu modeli.
# Beyaz gövde, membran (latte) kapak ve çekmece önleri, 36 mm meşe üst tabla, kemerli baza.
# Solda ve sağda tek raflı kapaklı bölme; ortada alt çekmece, açık niş, üst çekmece.
# Ölçüler kullanıcının verdiği ölçülerden; fotoğrafla doğrulandı (ön cepheler 43 + 58 + 43 = 145
# gövde genişliği, üst tabla yanlardan ~1 cm taşar; raf üstünde 27,5 cm boşluk).
#
# Her panel ayrı bileşen; fabrikada takılı gelen parçalar (şeffaf çektirme erkek/dişi, menteşe
# tabanı ve gövdesi, raf pimleri, çekmece rayları, minifix eksantrik ve bulonları) panelin içinde
# ayrı bileşen. Çiviler demonte gelir. Kurulum sırası kullanıcının anlattığı gibidir:
#   1 sol yan + alt tabla  2 sağ yan  3 üst tabla  4 arkalık (çivi)  5 orta yanlar
#   6-7 çekmeceler (minifix + dip çivisi, raylara itilir)  8 niş tablaları  9 raflar
#   10 kapaklar  11 baza
#
# SketchUp > Pencere > Ruby Konsolu:
#   load 'C:/.../scripts/product-3d/kurulum/konsol.rb'
#   OzcanKurulum::Konsol.kur               # AÇIK MODELİ TEMİZLER, modeli sıfırdan kurar
#   OzcanKurulum::Konsol.oynat             # montaj animasyonunu ekranda oynatır
#   OzcanKurulum::Konsol.kumanda           # klavyeyle adım adım: → ← Enter, K serbest kamera, Esc
#   (konsoldan: sonraki, onceki, durdur, devam, adim(3), git(3), bitir)
#   OzcanKurulum::Konsol.kaydet('C:/kareler') # animasyonu PNG karelere yazar
#
# Koordinatlar mm: X genişlik (0 = sol dış yüz), Y derinlik (0 = gövde ön yüzü, +Y arkaya;
# kapaklar Y<0'da, arkalık Y=422..425), Z yükseklik (0 = zemin).

module OzcanKurulum
  module Konsol
    extend self

    # ------------------------------------------------------------------
    # Ölçüler (mm)
    # ------------------------------------------------------------------
    W = 1450.0           # gövde genişliği (ön cepheler 431 + 580 + 431 ve aralıklar)
    T = 18.0             # panel kalınlığı
    D = 422.0            # yan derinliği; + 3 mm çakma arkalık = 425 (kapakla 445)
    ARKA_T = 3.0
    Z0 = 80.0            # baza yüksekliği = gövdenin alt yüzü
    ZT = 689.0           # yanların üst kenarı; üstünde 36 mm tabla → 725
    TABLA_T = 36.0
    TABLA_TASMA = 10.0   # meşe tablanın yanlardan taşması
    IC_X = { ic_sol: 425.0, ic_sag: W - 425.0 - T }.freeze # orta yanların sol yüzü (yan bölme içi 407)
    ORTA_X0 = IC_X[:ic_sol] + T # orta bölümün iç yüzleri (iç genişlik 564)
    ORTA_X1 = IC_X[:ic_sag]
    NIS = { nis_alt: 245.0, nis_ust: 498.0 }.freeze # niş tablalarının alt yüzü (niş iç yüksekliği 235)
    RAF_Z = 398.0        # yan bölme raflarının alt yüzü (rafın üstünde 27,3 cm)
    RAF_W = 405.0
    RAF_DER = 400.0
    RAF_Y0 = 10.0
    PIM_R = 2.5
    PIM_Y = [RAF_Y0 + 40, RAF_Y0 + RAF_DER - 40].freeze
    DIS_Y = [60.0, 211.0, 362.0].freeze # dış yanlarda altta ve üstte üçer çektirme
    IC_Y = [80.0, 342.0].freeze         # orta yanlarda altta ve üstte ikişer
    NIS_Y = [80.0, 342.0].freeze        # niş tablalarında her yanda iki
    BAZA_ON_X = [200.0, 725.0, 1250.0].freeze
    BAZA_YAN_Y = [100.0, 322.0].freeze
    KAPI_PAY = 2.0
    KAPI_W = 431.0       # yan kapaklar 43 x 60
    KAPI_H = 600.0
    KAPI_Z0 = Z0 + 1
    KAPI_X0 = { kapak_sol: 1.5, kapak_sag: W - 1.5 - KAPI_W }.freeze
    MENTESE_Z = [180.0, 580.0].freeze
    KAP_ZC = 4.5         # menteşe çerçevesinde kap merkezi (kapak kenarından ~22 mm)
    ON_W = 580.0         # orta bölüm çekmece önü 58 x 18
    ON_H = 180.0
    ON_X0 = (W - ON_W) / 2
    KUTU_W = 535.0       # çekmece kutusu 53,5 x 11,5 x 40
    KUTU_H = 115.0
    KUTU_D = 400.0
    KUTU_T = 16.0
    KUTU_X0 = (W - KUTU_W) / 2
    RAY_T = 7.25         # ray kalınlığı (dolap ve çekmece parçası, toplam 14,5)
    KAM_ARA = 34.0       # minifix eksantriğinin panel ucuna uzaklığı
    CEKMECE = {
      c1: { ad: 'Alt Çekmece', on_z: KAPI_Z0, kutu_z: 105.0 },
      c2: { ad: 'Üst Çekmece', on_z: KAPI_Z0 + KAPI_H - ON_H, kutu_z: 545.0 }
    }.freeze
    CEKMECE_PAR = %w[on sol sag arka dip].freeze
    BAZA_H = Z0
    PLAKA_T = 3.0

    DIKEY_FOV = 30.0
    VIDEO_FOV = 50.0

    DICT = 'ozcan_kurulum'
    CEKMECE_SIRA = CEKMECE.keys.flat_map { |c| CEKMECE_PAR.map { |p| :"#{c}_#{p}" } }.freeze
    SIRA = (%i[sol_yan alt_tabla sag_yan ust_tabla arkalik ic_sol ic_sag] + CEKMECE_SIRA +
            %i[nis_alt nis_ust raf_sol raf_sag kapak_sol kapak_sag baza_on baza_sol baza_sag]).freeze
    KAPILAR = %i[kapak_sol kapak_sag].freeze
    AD = {
      sol_yan: 'Sol Yan', alt_tabla: 'Alt Tabla', sag_yan: 'Sağ Yan', ust_tabla: 'Üst Tabla (meşe)',
      arkalik: 'Arkalık', ic_sol: 'Orta Yan (sol)', ic_sag: 'Orta Yan (sağ)', nis_alt: 'Niş Alt Tablası',
      nis_ust: 'Niş Üst Tablası', raf_sol: 'Sol Raf', raf_sag: 'Sağ Raf', kapak_sol: 'Sol Kapak',
      kapak_sag: 'Sağ Kapak', baza_on: 'Ön Baza', baza_sol: 'Sol Baza', baza_sag: 'Sağ Baza'
    }.merge(CEKMECE.flat_map { |c, h|
      { on: 'Önü', sol: 'Yanı (sol)', sag: 'Yanı (sağ)', arka: 'Arkası', dip: 'Dibi' }.map { |p, a| [:"#{c}_#{p}", "#{h[:ad]} #{a}"] }
    }.to_h).freeze
    ETIKET = {
      sol_yan: '01 Sol Yan', alt_tabla: '02 Alt Tabla', sag_yan: '03 Sağ Yan', ust_tabla: '04 Üst Tabla',
      arkalik: '05 Arkalık', ic_sol: '06 Orta Yanlar', ic_sag: '06 Orta Yanlar', nis_alt: '09 Niş Tablaları',
      nis_ust: '09 Niş Tablaları', raf_sol: '10 Raflar', raf_sag: '10 Raflar', kapak_sol: '11 Kapaklar',
      kapak_sag: '11 Kapaklar', baza_on: '12 Baza', baza_sol: '12 Baza', baza_sag: '12 Baza'
    }.merge(CEKMECE_SIRA.map { |k| [k, k.to_s.start_with?('c1') ? '07 Alt Çekmece' : '08 Üst Çekmece'] }.to_h).freeze
    LISTE_TAG = '00 Parça Listesi'
    ARAC_TAG = '99 Tornavida'

    # Kamera noktaları [göz, hedef] (mm)
    KAM = {
      liste:   [[3800, -4300, 6300], [3800, 1250, 0]],
      1 =>     [[1700, -1500, 1200], [500, 200, 250]],
      2 =>     [[-500, -1900, 1300], [950, 200, 250]],
      3 =>     [[2300, -2500, 2100], [725, 210, 400]],
      4 =>     [[2600, 2700, 1500], [725, 210, 380]],
      5 =>     [[1900, -2100, 1400], [725, 210, 400]],
      :cek =>  [[2000, -2200, 1200], [725, -300, 380]],
      8 =>     [[1600, -1900, 1000], [725, 50, 380]],
      9 =>     [[2000, -2200, 1300], [725, 210, 400]],
      10 =>    [[2300, -2600, 1500], [725, 0, 400]],
      11 =>    [[2100, -1900, 600], [725, 200, 60]],
      bitti:   [[2600, -3000, 1700], [725, 210, 380]]
    }.freeze

    # Parçaların yerleşim orijini (bileşen orijini = parçanın min köşesi)
    ORIJIN = {
      sol_yan: [0, 0, Z0], sag_yan: [W - T, 0, Z0], alt_tabla: [T, 0, Z0],
      ust_tabla: [-TABLA_TASMA, -(KAPI_PAY + T), ZT], arkalik: [0, D, Z0],
      ic_sol: [IC_X[:ic_sol], 0, Z0 + T], ic_sag: [IC_X[:ic_sag], 0, Z0 + T],
      nis_alt: [ORTA_X0, 0, NIS[:nis_alt]], nis_ust: [ORTA_X0, 0, NIS[:nis_ust]],
      raf_sol: [T + 1, RAF_Y0, RAF_Z], raf_sag: [IC_X[:ic_sag] + T + 1, RAF_Y0, RAF_Z],
      kapak_sol: [KAPI_X0[:kapak_sol], -(KAPI_PAY + T), KAPI_Z0], kapak_sag: [KAPI_X0[:kapak_sag], -(KAPI_PAY + T), KAPI_Z0],
      baza_on: [T, 0, 0], baza_sol: [0, 0, 0], baza_sag: [W - T, 0, 0]
    }.merge(CEKMECE.flat_map { |c, h|
      kz = h[:kutu_z]
      [[:"#{c}_on", [ON_X0, -(KAPI_PAY + T), h[:on_z]]], [:"#{c}_sol", [KUTU_X0, -KAPI_PAY, kz]],
       [:"#{c}_sag", [KUTU_X0 + KUTU_W - KUTU_T, -KAPI_PAY, kz]],
       [:"#{c}_arka", [KUTU_X0 + KUTU_T, KUTU_D - KAPI_PAY - KUTU_T, kz]], [:"#{c}_dip", [KUTU_X0, -KAPI_PAY, kz - ARKA_T]]]
    }.to_h).freeze

    # Arkalık çivileri: dış yanların ve alt tablanın arka kenarına
    CIVI = [120, 260, 400, 540, 660].flat_map { |z| [[T / 2, z - Z0], [W - T / 2, z - Z0]] } +
           [150, 500, 950, 1300].map { |x| [x, T / 2] }
    CIVILER = (1..CIVI.size).map { |i| format('civi_%02d', i) }.freeze
    # Çekmece dibi çivileri (dip-yerel x, y): yanlara ikişer, öne ve arkaya birer
    DIP_CIVI = [[KUTU_T / 2, 60], [KUTU_T / 2, 340], [KUTU_W - KUTU_T / 2, 60], [KUTU_W - KUTU_T / 2, 340],
                [KUTU_W / 2, KUTU_T / 2], [KUTU_W / 2, KUTU_D - KUTU_T / 2]].freeze
    DIP_CIVILER = CEKMECE.keys.flat_map { |c| (1..DIP_CIVI.size).map { |i| "#{c}_civi_#{i}" } }.freeze
    DEMONTE = (CIVILER + DIP_CIVILER).freeze

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
        on: mk.('Membran Latte', [178, 147, 127]),
        mese: mk.('Meşe Tabla', [192, 148, 94]),
        seffaf: mk.('Şeffaf Plastik', [205, 225, 238], 0.35),
        cinko: mk.('Çinko Kaplama', [160, 164, 170]),
        nikel: mk.('Nikel', [192, 196, 202]),
        pirinc: mk.('Pirinç Burç', [196, 158, 72]),
        ray: mk.('Ray Çeliği', [168, 171, 176]),
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

    # Dar yerler için (orta bölmenin altı, bazanın arkası) kısa tornavida
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
    # (x erkeğin panelinden uzağa, z dişinin panelinden uzağa). Alt tabla sol yana yandan kayar,
    # sağ yan ona oturur; üst tabla yukarıdan iner (erkek tablada); orta yanlar önden girip yana
    # kayar (erkek orta yanda); niş tablaları önden girip iner/kalkar (erkek tablada, dişi orta
    # yanda); bazalar alt tablanın altına kayar. Dar yerlerdeki vidalar kısa tornavidayla.
    def baglantilar
      l = []
      [[:sol_yan, T, 1, 'sol'], [:sag_yan, W - T, -1, 'sag']].each do |yan, xs, sx, taraf|
        DIS_Y.zip(%w[on orta arka]).each do |y, yer|
          l << { id: "alt_#{taraf}_#{yer}", disi: :alt_tabla, erkek: yan, k: [xs, y, Z0 + T], ex: [sx, 0, 0], ez: [0, 0, 1] }
          l << { id: "ust_#{taraf}_#{yer}", disi: yan, erkek: :ust_tabla, k: [xs, y, ZT], ex: [0, 0, -1], ez: [sx, 0, 0] }
        end
      end
      [[:ic_sol, IC_X[:ic_sol], -1, 'sol'], [:ic_sag, IC_X[:ic_sag] + T, 1, 'sag']].each do |ic, xf, sx, taraf|
        IC_Y.zip(%w[on arka]).each do |y, yer|
          l << { id: "icalt_#{taraf}_#{yer}", disi: :alt_tabla, erkek: ic, k: [xf, y, Z0 + T], ex: [sx, 0, 0], ez: [0, 0, 1] }
          l << { id: "icust_#{taraf}_#{yer}", disi: :ust_tabla, erkek: ic, k: [xf, y, ZT], ex: [sx, 0, 0], ez: [0, 0, -1] }
        end
      end
      [[:ic_sol, ORTA_X0, 1, 'sol'], [:ic_sag, ORTA_X1, -1, 'sag']].each do |ic, xs, sx, taraf|
        NIS_Y.zip(%w[on arka]).each do |y, yer|
          l << { id: "nisalt_#{taraf}_#{yer}", disi: ic, erkek: :nis_alt, k: [xs, y, NIS[:nis_alt]], ex: [0, 0, -1],
                 ez: [sx, 0, 0], kisa: true }
          l << { id: "nisust_#{taraf}_#{yer}", disi: ic, erkek: :nis_ust, k: [xs, y, NIS[:nis_ust] + T], ex: [0, 0, 1],
                 ez: [sx, 0, 0], kisa: true }
        end
      end
      BAZA_ON_X.each_with_index do |x, i|
        l << { id: "bazaon_#{i + 1}", disi: :alt_tabla, erkek: :baza_on, k: [x, T, Z0], ex: [0, 1, 0], ey: [1, 0, 0],
               ez: [0, 0, -1], kisa: true }
      end
      [[:baza_sol, T, 1, [0, -1, 0], 'sol'], [:baza_sag, W - T, -1, [0, 1, 0], 'sag']].each do |bz, xs, sx, ey, taraf|
        BAZA_YAN_Y.each_with_index do |y, i|
          l << { id: "baza#{taraf}_#{i + 1}", disi: :alt_tabla, erkek: bz, k: [xs, y, Z0], ex: [sx, 0, 0], ey: ey,
                 ez: [0, 0, -1], kisa: true }
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

    def ray(e, x0, x1, y0, y1, zc)
      g = e.add_group
      kutu(g.entities, x0, y0, zc - 17.5, x1, y1, zc + 17.5)
      boya(g.entities, @mat[:ray])
    end

    # Dış yan: çektirmeler, menteşe tabanları, raf pimleri.
    def dis_yan(k, sx)
      d = parca_tanimi(AD[k])
      e = d.entities
      kutu(e, 0, 0, 0, T, D, ZT - Z0)
      boya(e, @mat[:govde])
      xi = sx > 0 ? T : 0.0 # iç yüz
      cektirmeler(e, k)
      MENTESE_Z.each { |hz| e.add_instance(@taban, mentese_cerceve([xi, -KAPI_PAY, hz - Z0], sx)) }
      PIM_Y.each { |y| e.add_instance(@pim, eksen([xi, y, RAF_Z - PIM_R - Z0], [sx, 0, 0], [0, 0, 1])) }
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
      kutu(d.entities, 0, 0, 0, W + 2 * TABLA_TASMA, D + ARKA_T + KAPI_PAY + T, TABLA_T)
      boya(d.entities, @mat[:mese])
      cektirmeler(d.entities, :ust_tabla)
      [d, ORIJIN[:ust_tabla]]
    end

    def arkalik
      d = parca_tanimi(AD[:arkalik])
      e = d.entities
      kutu(e, 0, 0, 0, W, ARKA_T, ZT - Z0)
      boya(e, @mat[:govde])
      CIVI.each_with_index do |(x, z), i|
        vida_koy(e, @civi, eksen([x, ARKA_T, z], [0, -1, 0], [0, 0, 1]), P(x, ARKA_T, z), Geom::Vector3d.new(0, -1, 0),
                 16.0, 1.2, Geom::Vector3d.new(0, 1, 0), CIVILER[i])
      end
      [d, ORIJIN[:arkalik]]
    end

    # Orta yan: bölme tarafında raf pimleri ve çektirme erkekleri, orta tarafta niş tablası
    # dişileri ve çekmece rayları (dolap parçası).
    def ic_yan(k)
      d = parca_tanimi(AD[k])
      e = d.entities
      kutu(e, 0, 0, 0, T, D, ZT - Z0 - T)
      boya(e, @mat[:govde])
      sol = k == :ic_sol
      xb = sol ? 0.0 : T # bölme tarafı
      PIM_Y.each { |y| e.add_instance(@pim, eksen([xb, y, RAF_Z - PIM_R - Z0 - T], [sol ? -1 : 1, 0, 0], [0, 0, 1])) }
      xr = sol ? [T, T + RAY_T] : [-RAY_T, 0.0]
      CEKMECE.each_value { |h| ray(e, *xr, RAF_Y0, RAF_Y0 + KUTU_D, h[:kutu_z] + KUTU_H / 2 - Z0 - T) }
      cektirmeler(e, k)
      [d, ORIJIN[k]]
    end

    def ic_sol; ic_yan(:ic_sol); end
    def ic_sag; ic_yan(:ic_sag); end

    def nis(k)
      d = parca_tanimi(AD[k])
      kutu(d.entities, 0, 0, 0, ORTA_X1 - ORTA_X0, D, T)
      boya(d.entities, @mat[:govde])
      cektirmeler(d.entities, k)
      [d, ORIJIN[k]]
    end

    def nis_alt; nis(:nis_alt); end
    def nis_ust; nis(:nis_ust); end

    def raf(k)
      d = parca_tanimi(AD[k])
      kutu(d.entities, 0, 0, 0, RAF_W, RAF_DER, T)
      boya(d.entities, @mat[:govde])
      [d, ORIJIN[k]]
    end

    def raf_sol; raf(:raf_sol); end
    def raf_sag; raf(:raf_sag); end

    # Membran ön: üst kenara yakın gömme (frezeli) kulp oyuğu.
    def on_panel(e, gen, yuk, kulp_gen)
      kutu(e, 0, 0, 0, gen, T, yuk)
      it(e, yuvarlak_dik(gen / 2 - kulp_gen / 2, yuk - 27, gen / 2 + kulp_gen / 2, yuk - 5, 10).map { |x, z| P(x, 0, z) },
         yon(0, 1, 0), 8)
    end

    # Yan kapaklar tam bindirme, menteşeler dış yanlarda. Kapak-yerel orijin = sol ön alt köşe.
    def kapak(k)
      d = parca_tanimi(AD[k])
      e = d.entities
      on_panel(e, KAPI_W, KAPI_H, 290)
      sol = k == :kapak_sol
      sx = sol ? 1 : -1
      xi = (sol ? T : W - T) - KAPI_X0[k] # dış yanın iç yüzü, kapak-yerel
      hdler = MENTESE_Z.map { |hz| mentese_cerceve([xi, T, hz - KAPI_Z0], sx) }
      hdler.each { |hd| daire_it(e, P(0, 0, KAP_ZC).transform(hd), Y_AXIS, 17.5, yon(0, -1, 0), 12.5, 32) }
      boya(e, @mat[:on])
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
                 "mentese_#{sol ? 'sol' : 'sag'}_#{i + 1}", true)
      end
      [d, ORIJIN[k]]
    end

    def kapak_sol; kapak(:kapak_sol); end
    def kapak_sag; kapak(:kapak_sag); end

    # --- Çekmece: membran ön + kutu önü (minifix eksantrikleri), iki yan (bulonlar ve ray), arka
    # (eksantrikler), 3 mm dip (alttan çivilenir). Yanlar ön ile arkanın uçlarını kavrar. ---
    def cekmece_on(c)
      h = CEKMECE[c]
      d = parca_tanimi(AD[:"#{c}_on"])
      e = d.entities
      on_panel(e, ON_W, ON_H, 430)
      boya(e, @mat[:on])
      g = e.add_group # kutu önü (beyaz), membran önün arkasında
      x0 = KUTU_X0 + KUTU_T - ON_X0
      zk = h[:kutu_z] - h[:on_z]
      kutu(g.entities, x0, T, zk, x0 + KUTU_W - 2 * KUTU_T, T + KUTU_T, zk + KUTU_H)
      boya(g.entities, @mat[:govde])
      [[x0 + KAM_ARA, 'sol'], [x0 + KUTU_W - 2 * KUTU_T - KAM_ARA, 'sag']].each do |x, taraf|
        o = [x, T + KUTU_T, zk + KUTU_H / 2]
        vida_koy(e, @kam, eksen(o, [0, -1, 0], [0, 0, 1]), P(*o), Geom::Vector3d.new(0, -1, 0), 0.01, 0.0,
                 Geom::Vector3d.new(0, 1, 0), "#{c}_kam_on_#{taraf}", false, true)
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
      ray(e, *(sol ? [-RAY_T, 0.0] : [KUTU_T, KUTU_T + RAY_T]), 0, KUTU_D, KUTU_H / 2)
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
      boya(e, @mat[:govde])
      DIP_CIVI.each_with_index do |(x, y), i|
        vida_koy(e, @civi, eksen([x, y, 0], [0, 0, 1], [1, 0, 0]), P(x, y, 0), Geom::Vector3d.new(0, 0, 1), 16.0, 1.2,
                 Geom::Vector3d.new(0, 0, -1), "#{c}_civi_#{i + 1}")
      end
      [d, ORIJIN[k]]
    end

    # Kemerli baza kesiti (boy boyunca s, yükseklik z): a0..a1 arası alttan h kadar oyuk.
    def kemer(boy, a0, a1, h, r = 45.0)
      sol = (0..6).map { |i| t = Math::PI / 12 * i; [a0 + r * Math.sin(t), h - h * Math.cos(t)] }
      sag = (0..6).map { |i| t = Math::PI / 2 - Math::PI / 12 * i; [a1 - r * Math.sin(t), h - h * Math.cos(t)] }
      [[0, 0]] + sol + sag + [[boy, 0], [boy, BAZA_H], [0, BAZA_H]]
    end

    def baza_on
      d = parca_tanimi(AD[:baza_on])
      boy = W - 2 * T
      it(d.entities, kemer(boy, 374 - T, W - 374 - T, 32).map { |s, z| P(s, 0, z) }, yon(0, 1, 0), T)
      boya(d.entities, @mat[:govde])
      cektirmeler(d.entities, :baza_on)
      [d, ORIJIN[:baza_on]]
    end

    def baza_yan(k)
      d = parca_tanimi(AD[k])
      it(d.entities, kemer(D, 110, D - 110, 27).map { |s, z| P(0, s, z) }, yon(1, 0, 0), T)
      boya(d.entities, @mat[:govde])
      cektirmeler(d.entities, k)
      [d, ORIJIN[k]]
    end

    def baza_sol; baza_yan(:baza_sol); end
    def baza_sag; baza_yan(:baza_sag); end

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
      @m.start_operation('Konsol kurulum modeli', true)
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
      @disi = disi_tanimi
      @erkek = erkek_tanimi
      @pim = pim_tanimi
      @civi = civi_tanimi
      @kam = kam_tanimi
      @bulon = bulon_tanimi
      @taban = taban_tanimi
      @kol = kol_tanimi
      @kap = kap_tanimi
      @bag = bag_tanimi
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
      "Kuruldu: #{SIRA.size} parça, #{@vidalar.size} animasyonlu vida/eksantrik/çivi, #{@m.pages.size} sahne"
    end

    # Kutu içeriği: paneller yere yatırılmış, fabrikada takılı hırdavat üstte; çiviler ayrı.
    def parca_listesi(tag)
      rx = ->(a) { Geom::Transformation.rotation(ORIGIN, X_AXIS, a.degrees) }
      ry = ->(a) { Geom::Transformation.rotation(ORIGIN, Y_AXIS, a.degrees) }
      rz = ->(a) { Geom::Transformation.rotation(ORIGIN, Z_AXIS, a.degrees) }
      bir = Geom::Transformation.new
      yerlesim = {
        sol_yan: [rz.(90) * ry.(-90), 1700, 0], sag_yan: [rz.(90) * ry.(90), 2400, 0],
        ic_sol: [rz.(90) * ry.(90), 3100, 0], ic_sag: [rz.(90) * ry.(-90), 3800, 0], arkalik: [rx.(-90), 4500, 0],
        alt_tabla: [bir, 1700, 950], ust_tabla: [rx.(180), 3500, 950],
        nis_alt: [rx.(180), 1700, 1750], nis_ust: [bir, 2500, 1750], raf_sol: [bir, 3300, 1750],
        raf_sag: [bir, 3950, 1750], kapak_sol: [rx.(90), 4600, 1750], kapak_sag: [rx.(90), 5300, 1750],
        baza_on: [rx.(90), 1700, -650], baza_sol: [ry.(-90), 3500, -650], baza_sag: [ry.(90), 4300, -650]
      }
      CEKMECE.keys.each_with_index do |c, i|
        y = 2650 + i * 750
        yerlesim.merge!(:"#{c}_on" => [rx.(90), 1700, y], :"#{c}_sol" => [ry.(90), 2550, y], :"#{c}_sag" => [ry.(-90), 2900, y],
                        :"#{c}_arka" => [rx.(-90), 3250, y], :"#{c}_dip" => [bir, 4000, y])
      end
      etiket = AD.merge(CEKMECE.map { |c, h| [:"#{c}_on", "#{h[:ad]} (5 parça)"] }.to_h)
      @m.entities.grep(Sketchup::ComponentInstance).select { |i| nit(i, :parca) && !%w[tornavida kisa_tornavida cekic].include?(nit(i, :parca)) }.each do |ana|
        k = nit(ana, :parca).to_sym
        rot, x, y = yerlesim[k]
        bb = Geom::BoundingBox.new
        b = ana.definition.bounds
        8.times { |c| bb.add(b.corner(c).transform(rot)) }
        kay = Geom::Transformation.translation(P(x, y, 0) - bb.min)
        i = @m.entities.add_instance(ana.definition, kay * rot)
        i.layer = tag
        next if CEKMECE_SIRA.include?(k) && !k.to_s.end_with?('_on') # çekmece parçalarına tek etiket
        on = Geom::Point3d.new(bb.center.x, bb.min.y, bb.max.z).transform(kay)
        txt = @m.entities.add_text(etiket[k], on, Geom::Vector3d.new(0, -90.mm, 0))
        txt.layer = tag
      end
      6.times do |i|
        @m.entities.add_instance(@civi, eksen([5100 + i * 12, -600, 3], [1, 0, 0], [0, 0, 1])).layer = tag
      end
      @m.entities.add_text("Çivi (#{DEMONTE.size})", P(5100, -630, 0), Geom::Vector3d.new(0, -90.mm, 0)).layer = tag
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
        ['0 Kutu İçeriği', [], :liste, 'Paneller ve fabrikada takılı bağlantı elemanları; çiviler ayrı.'],
        ['1 Sol Yan + Alt Tabla', %i[sol_yan alt_tabla], 1, 'Alt tablayı sol yandaki 3 şeffaf çektirmeye geçirip vidaları sıkın.'],
        ['2 Sağ Yan', %i[sag_yan], 2, 'Sağ yanı alt tabladaki 3 çektirmeye oturtup vidaları sıkın.'],
        ['3 Üst Tabla', %i[ust_tabla], 3, 'Üst tablayı yanların üstüne oturtun; 6 çektirme vidasını sıkın.'],
        ['4 Arkalık', %i[arkalik], 4, 'Arkalığı arkaya yerleştirip çivileri çakın.'],
        ['5 Orta Yanlar', %i[ic_sol ic_sag], 5, 'Orta yanları alt ve üst tabladaki çektirmelere geçirip vidaları sıkın.'],
        ['6 Alt Çekmece', CEKMECE_SIRA.select { |k| k.to_s.start_with?('c1') }, :cek, 'Yanları minifixle öne ve arkaya bağlayın, dibi çakın, raylara hizalayıp itin.'],
        ['7 Üst Çekmece', CEKMECE_SIRA.select { |k| k.to_s.start_with?('c2') }, :cek, 'Alt çekmece gibi kurup raylara itin.'],
        ['8 Niş Tablaları', %i[nis_alt nis_ust], 8, 'Niş tablalarını çektirmelere geçirin; çekmeceleri çekip vidaları içeriden sıkın.'],
        ['9 Raflar', %i[raf_sol raf_sag], 9, 'Rafları raf pimlerinin üzerine yerleştirin.'],
        ['10 Kapaklar', KAPILAR, 10, 'Kapaktaki menteşe gövdelerini yandaki tabanlara geçirin; vidaları sıkın.'],
        ['11 Baza', %i[baza_on baza_sol baza_sag], 11, 'Ön ve yan bazaları alt tablanın altındaki çektirmelere geçirip vidaları arkadan sıkın.'],
        ['12 Bitmiş Ürün', [], :bitti, 'Kurulum tamamlandı.']
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
      raise 'Model bulunamadı — önce OzcanKurulum::Konsol.kur' unless @parca.size == SIRA.size && @arac && @kisa_arac && @cekic
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

    # aci > 0 açık: sol kapak sol ön köşedeki, sağ kapak sağ ön köşedeki dikey eksende açılır.
    def kapi_R(k, aci)
      if k == :kapak_sol
        Geom::Transformation.rotation(P(0, -(KAPI_PAY + T), 0), Z_AXIS, -aci.degrees)
      else
        Geom::Transformation.rotation(P(W, -(KAPI_PAY + T), 0), Z_AXIS, aci.degrees)
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

    def kapak_tak(k)
      z = @cz
      z.kamera(1.2, KAM[10])
      z.an { |s, _| s[:kapi][k] = 90.0 }
      hareket(k, [0, -420, 0], [0, 0, 0], 1.8)
      no = k == :kapak_sol ? 'sol' : 'sag'
      vida_sik("mentese_#{no}_1", nil, tur: 3, sure: 0.8)
      vida_sik("mentese_#{no}_2", nil, tur: 3, sure: 0.8, yakin: false)
      z.kamera(0.8, KAM[10])
      z.olay(1.4) { |s, u| s[:kapi][k] = 90.0 * (1 - u) }
    end

    # Çekmece önde kurulur: yanlar minifix bulonlarıyla ön ve arkanın uçlarına geçer, eksantrikler
    # yarım tur çevrilir, dip alttan çakılır; sonra raylara hizalanıp içeri itilir.
    def cekmece_kur(c)
      z = @cz
      s0 = [0, -650, 0]
      z.kamera(1.2, KAM[:cek])
      z.an do |s, _|
        s[:p][:"#{c}_on"] = { vis: true, off: s0 }
        s[:p][:"#{c}_arka"] = { vis: true, off: s0 }
      end
      z.bekle(0.4)
      hareket(:"#{c}_sol", [-160, -650, 0], s0, 1.0)
      hareket(:"#{c}_sag", [160, -650, 0], s0, 1.0)
      # ilk eksantriğe kutunun içinden, arkadan-yukarıdan bak (membran ön görüşü kapatmasın)
      sirayla_sik(%w[on_sol on_sag arka_sol arka_sag].map { |p| "#{c}_kam_#{p}" }, KAM[:cek], tur: 0.5, bak: [0.3, 1, 0.8])
      hareket(:"#{c}_dip", [0, -650, -160], s0, 1.0)
      ids = (1..DIP_CIVI.size).map { |i| "#{c}_civi_#{i}" }
      z.an { |s, _| ids.each { |id| s[:v][id] = { adv: 1.0, ang: 0.0 } } }
      yakin_kamera(ids.first, yon: [0.35, -1, -0.75])
      civi_cak(ids.first)
      z.kamera(0.8, KAM[:cek])
      ids.drop(1).each { |id| civi_cak(id) }
      cekmece_hareket(c, s0, [0, 0, 0], 1.8)
      z.bekle(0.3)
    end

    def cizelge
      @cz = z = Cizelge.new
      z.an { |s, _| DEMONTE.each { |id| s[:v][id] = { gizli: true } } } # takılana kadar görünmesin
      z.baslik('Kutu içeriği — bağlantı elemanları panellere takılı gelir, çiviler ayrı')
      z.kamera(0, KAM[:liste])
      z.bekle(3.5)

      z.baslik('1 · Alt tablayı sol yandaki üç şeffaf çektirmeye geçirin, vidaları sıkın')
      z.an do |s, _|
        s[:liste] = false
        s[:p][:sol_yan][:vis] = true
        s[:p][:alt_tabla] = { vis: true, off: [500, 0, 0] }
      end
      z.kamera(1.2, KAM[1])
      hareket(:alt_tabla, [500, 0, 0], [2, 0, 0], 2.0)
      sirayla_sik(%w[on orta arka].map { |y| "alt_sol_#{y}" }, KAM[1], cekler: cek_listesi(:alt_tabla, [2, 0, 0], 3))
      z.kamera(0.8, KAM[1])
      z.bekle(0.3)

      z.baslik('2 · Sağ yanı alt tabladaki çektirmelere oturtun, vidaları sıkın')
      z.kamera(1.2, KAM[2])
      hareket(:sag_yan, [500, 0, 0], [2, 0, 0], 2.0)
      sirayla_sik(%w[on orta arka].map { |y| "alt_sag_#{y}" }, KAM[2], cekler: cek_listesi(:sag_yan, [2, 0, 0], 3))
      z.kamera(0.8, KAM[2])
      z.bekle(0.3)

      z.baslik('3 · Üst tablayı yanların üstüne oturtun, altı çektirme vidasını sıkın')
      z.kamera(1.2, KAM[3])
      hareket(:ust_tabla, [0, 0, 300], [0, 0, 2], 2.0)
      ids = %w[sol sag].flat_map { |t| %w[on orta arka].map { |y| "ust_#{t}_#{y}" } }
      sirayla_sik(ids, KAM[3], cekler: cek_listesi(:ust_tabla, [0, 0, 2], ids.size))
      z.kamera(0.8, KAM[3])
      z.bekle(0.3)

      z.baslik('4 · Arkalığı arkaya yerleştirip çivileri çekiçle çakın')
      z.kamera(1.2, KAM[4])
      hareket(:arkalik, [0, 450, 0], [0, 0, 0], 2.0)
      z.an { |s, _| CIVILER.each { |id| s[:v][id] = { adv: 1.0, ang: 0.0 } } }
      z.bekle(0.3)
      yakin_kamera(CIVILER.first, yon: [1.0, 0.75, 0.45])
      civi_cak(CIVILER.first)
      z.kamera(0.8, KAM[4])
      CIVILER.drop(1).each { |id| civi_cak(id) }
      z.bekle(0.3)

      z.baslik('5 · Orta yanları alt ve üst tabladaki çektirmelere geçirin, vidaları sıkın')
      { ic_sol: [40, 'sol'], ic_sag: [-40, 'sag'] }.each do |ic, (dx, taraf)|
        z.kamera(1.0, KAM[5])
        hareket(ic, [dx, -550, 0], [dx, 0, 0], 1.6)
        hareket(ic, [dx, 0, 0], [dx * 0.05, 0, 0], 0.6)
        ids = %w[icalt icust].flat_map { |a| %w[on arka].map { |y| "#{a}_#{taraf}_#{y}" } }
        sirayla_sik(ids, KAM[5], cekler: cek_listesi(ic, [dx * 0.05, 0, 0], ids.size))
      end
      z.kamera(0.8, KAM[5])
      z.bekle(0.3)

      z.baslik('6 · Alt çekmeceyi minifixle kurun, dibini çakın, raylara hizalayıp itin')
      cekmece_kur(:c1)
      z.baslik('7 · Üst çekmeceyi aynı şekilde kurup raylara itin')
      cekmece_kur(:c2)

      z.baslik('8 · Niş tablalarını çektirmelere geçirin; çekmeceleri çekip vidaları içeriden sıkın')
      z.kamera(1.2, KAM[8])
      hareket(:nis_alt, [0, -500, 40], [0, 0, 40], 1.4)
      hareket(:nis_alt, [0, 0, 40], [0, 0, 0], 0.5)
      hareket(:nis_ust, [0, -500, -40], [0, 0, -40], 1.4)
      hareket(:nis_ust, [0, 0, -40], [0, 0, 0], 0.5)
      cekmece_hareket(CEKMECE.keys, [0, 0, 0], [0, -700, 0], 1.2)
      { 'nisalt' => -0.15, 'nisust' => 0.15 }.each do |a, bz|
        %w[sol sag].each do |t|
          sx = t == 'sol' ? 1 : -1 # karşı yandan, çekmece boşluğunun içinden bak
          sirayla_sik(%w[on arka].map { |y| "#{a}_#{t}_#{y}" }, KAM[8], tur: 3, bak: [0.9 * sx, -0.4, bz])
        end
      end
      z.kamera(0.8, KAM[8])
      cekmece_hareket(CEKMECE.keys, [0, -700, 0], [0, 0, 0], 1.2)
      z.bekle(0.3)

      z.baslik('9 · Rafları raf pimlerinin üzerine yerleştirin')
      z.kamera(1.2, KAM[9])
      %i[raf_sol raf_sag].each do |k|
        hareket(k, [0, -450, 40], [0, 0, 40], 1.2)
        hareket(k, [0, 0, 40], [0, 0, 0], 0.4)
      end
      z.bekle(0.3)

      z.baslik('10 · Kapakların menteşe gövdelerini yandaki tabanlara geçirin, vidaları sıkın')
      kapak_tak(:kapak_sol)
      kapak_tak(:kapak_sag)
      z.bekle(0.3)

      z.baslik('11 · Bazaları alt tablanın altındaki çektirmelere geçirin, vidaları arkadaki boşluktan sıkın')
      z.kamera(1.2, KAM[11])
      hareket(:baza_on, [0, -400, 0], [0, -2, 0], 1.6)
      ids = BAZA_ON_X.each_index.map { |i| "bazaon_#{i + 1}" }
      sirayla_sik(ids, KAM[11], cekler: cek_listesi(:baza_on, [0, -2, 0], ids.size), bak: [0.3, 1, -0.05])
      [[:baza_sol, -1, 'sol'], [:baza_sag, 1, 'sag']].each do |bz, sx, t|
        z.kamera(0.8, KAM[11])
        hareket(bz, [300 * sx, 0, 0], [2 * sx, 0, 0], 1.4)
        ids = BAZA_YAN_Y.each_index.map { |i| "baza#{t}_#{i + 1}" }
        sirayla_sik(ids, KAM[11], cekler: cek_listesi(bz, [2 * sx, 0, 0], ids.size), bak: [-0.35 * sx, 1, -0.05])
      end
      z.kamera(0.8, KAM[11])
      z.bekle(0.3)

      z.baslik('Kurulum tamamlandı')
      z.kamera(1.6, KAM[:bitti])
      z.olay(1.3) do |s, u|
        KAPILAR.each { |k| s[:kapi][k] = 95.0 * u }
        CEKMECE.each_key { |c| cekmece_parcalari(c).each { |k| s[:p][k][:off] = [0, -300 * u, 0] } }
      end
      z.bekle(0.8)
      z.olay(1.3) do |s, u|
        KAPILAR.each { |k| s[:kapi][k] = 95.0 * (1 - u) }
        CEKMECE.each_key { |c| cekmece_parcalari(c).each { |k| s[:p][k][:off] = [0, -300 * (1 - u), 0] } }
      end
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

    # Montajlı son durum: tüm parçalar yerinde, vidalar sıkılı, kapaklar ve çekmeceler kapalı.
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
    # Adımlar başlıkların sırasıdır: 0 kutu içeriği, 1-11 montaj, 12 bitmiş ürün.
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
