# encoding: UTF-8
# Çapraz Kitaplık (60 x 140 x 30 cm) — kurulum kılavuzu modeli.
# Yere basan dikey arka tablanın önünde, ayaklı alt tablanın üstünde yedi çapraz (45°) raf:
# '\' raflar sol yandan, '/' raflar sağ yandan iner ve her biri alttaki rafın üst yüzüne
# oturarak zikzak (ağaç) biçimi verir. Alt tabla ve tüm raflar arka tablaya arkadan alyan
# (konfirmat) vidayla bağlanır. Ölçüler fotoğraflardan (18 mm panel kalınlığı referans).
#
# Her panel ayrı bileşen; arka tablada vida yuvaları açık, ayak tabanları alt tablada takılı
# gelir; ayaklar, alyan vidalar ve alyan anahtarı ayrı. Kurulum sırası kullanıcının anlattığı gibidir:
#   1 ayaklar  2 arka tabla + alt tabla  3-9 raflar alttan yukarı (1. raftan 7. rafa)
#
# SketchUp > Pencere > Ruby Konsolu:
#   load 'C:/.../scripts/product-3d/kurulum/capraz_kitaplik.rb'
#   OzcanKurulum::CaprazKitaplik.kur               # AÇIK MODELİ TEMİZLER, modeli sıfırdan kurar
#   OzcanKurulum::CaprazKitaplik.oynat             # montaj animasyonunu ekranda oynatır
#   OzcanKurulum::CaprazKitaplik.kumanda           # klavyeyle adım adım: → ← Enter, K serbest kamera, Esc
#   (konsoldan: sonraki, onceki, durdur, devam, adim(3), git(3), bitir)
#   OzcanKurulum::CaprazKitaplik.kaydet('C:/kareler') # animasyonu PNG karelere yazar
#
# Koordinatlar mm: X genişlik (0 = sol yan kenar), Y derinlik (0 = rafların ön kenarı, +Y
# arkaya; arka tabla Y=280..298), Z yükseklik (0 = zemin).

module OzcanKurulum
  module CaprazKitaplik
    extend self

    # ------------------------------------------------------------------
    # Ölçüler (mm)
    # ------------------------------------------------------------------
    W = 600.0            # genişlik
    T = 18.0             # panel kalınlığı
    D = 280.0            # raf ve alt tabla derinliği (arka tablanın önünde)
    H = 1400.0           # arka tabla yüksekliği (yere basar)
    AYAK_H = 50.0
    Z0 = AYAK_H          # alt tablanın alt yüzü
    ZB = Z0 + T          # alt tablanın üst yüzü
    K2 = T * Math.sqrt(2) # 45° rafın düşey kesitte kalınlığı
    # Çapraz raflar alttan yukarı (montaj sırası): [yön, raf üst yüzünün yan kenardaki yüksekliği].
    # Her raf alttakinin üst yüzüne oturur; 1. raf alt tablaya.
    RAFLAR = {
      raf_1: [:sol, 485.0], raf_2: [:sag, 590.0], raf_3: [:sol, 780.0], raf_4: [:sag, 985.0],
      raf_5: [:sol, 1080.0], raf_6: [:sag, H], raf_7: [:sol, H]
    }.freeze
    ALT_VIDA_X = [100.0, W - 100].freeze
    AYAK_XY = [[50, 50], [W - 50, 50], [50, D - 50], [W - 50, D - 50]].freeze
    VIDA_BAS = 2.5       # vida başı yüksekliği = arka tabladaki havşa yuvası derinliği

    DIKEY_FOV = 30.0
    VIDEO_FOV = 50.0

    DICT = 'ozcan_kurulum'
    SIRA = (%i[alt_tabla arka_tabla] + RAFLAR.keys).freeze
    AD = { alt_tabla: 'Alt Tabla', arka_tabla: 'Arka Tabla' }
         .merge(RAFLAR.keys.map.with_index { |k, i| [k, "#{i + 1}. Raf"] }.to_h).freeze
    ETIKET = SIRA.map.with_index { |k, i| [k, format('%02d %s', i + 1, AD[k])] }.to_h.freeze
    LISTE_TAG = '00 Parça Listesi'
    ARAC_TAG = '99 Alyan Anahtarı'

    # Kamera noktaları [göz, hedef] (mm)
    KAM = {
      liste:  [[2700, -2400, 3400], [2700, 650, 0]],
      1 =>    [[1100, -1100, 450], [300, 140, 60]],
      2 =>    [[1700, 2300, 1300], [300, 140, 450]],
      raf:    [[1800, -2400, 1700], [300, 140, 700]],
      bitti:  [[1700, -2500, 1600], [300, 140, 700]]
    }.freeze

    # Parçaların yerleşim orijini (raflar dünya koordinatında çizilir)
    ORIJIN = { alt_tabla: [0, 0, Z0], arka_tabla: [0, D, 0] }.merge(RAFLAR.keys.map { |k| [k, [0, 0, 0]] }.to_h).freeze

    AYAKLAR = %w[ayak_1 ayak_2 ayak_3 ayak_4].freeze
    ALT_VIDALARI = %w[alt_1 alt_2].freeze
    VIDALAR = (ALT_VIDALARI + RAFLAR.keys.flat_map { |k| ["#{k}_1", "#{k}_2"] }).freeze

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
      mk = lambda do |ad, rgb|
        m = @m.materials[ad] || @m.materials.add(ad)
        m.color = Sketchup::Color.new(*rgb)
        m
      end
      @mat = {
        govde: mk.('Beyaz Melamin', [242, 242, 240]),
        cinko: mk.('Çinko Kaplama', [160, 164, 170]),
        krom: mk.('Krom', [214, 217, 222]),
        gri: mk.('Gri Plastik', [150, 152, 156]),
        kaucuk: mk.('Kauçuk', [45, 45, 48]),
        yuva: mk.('Vida Yuvası', [40, 40, 44]),
        anahtar: mk.('Alyan Anahtarı', [52, 54, 58])
      }
    end

    # ------------------------------------------------------------------
    # Hırdavat bileşenleri
    # ------------------------------------------------------------------
    # Altıgen (alyan) vida yuvası: x düzleminde koyu altıgen
    def altigen(e, x, r)
      g = e.add_group
      f = g.entities.add_face((0...6).map { |i| a = Math::PI / 3 * i; P(x, r * Math.cos(a), r * Math.sin(a)) })
      f.material = @mat[:yuva]
      f.back_material = @mat[:yuva]
      g
    end

    # Alyan (konfirmat) vida 7x50: düz baş x∈[-2.5, 0] üstünde altıgen yuva, gövde +x yönünde
    def alyan_vida_tanimi
      d = @m.definitions.add('Alyan Vida 7x50')
      torna(d.entities, [[-VIDA_BAS, 0], [-VIDA_BAS, 5], [-0.6, 5], [0, 3.6], [0, 2.5], [8, 2.5], [8, 3.5], [46, 3.5],
                         [50, 1.2], [50, 0]], 24, @mat[:cinko])
      altigen(d.entities, -VIDA_BAS - 0.05, 2.3)
      d
    end

    # --- Ayak: alt tabla altına vidalı taban + çevrilerek takılan krom ayak ---
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

    # Alyan anahtarı (L, 4 mm): kısa kol yerel +x boyunca (uç x=-3'te yuvada), uzun kol +y yönünde
    def alyan_anahtari_tanimi
      d = @m.definitions.add('Alyan Anahtarı 4 mm')
      torna(d.entities, [[-3, 0], [-3, 2.3], [28, 2.3], [28, 0]], 6, @mat[:anahtar])
      torna(d.entities, [[-2.3, 0], [-2.3, 2.3], [92, 2.3], [92, 0]], 6, @mat[:anahtar])
        .transform!(eksen([28, 0, 0], [0, 1, 0], [1, 0, 0]))
      d
    end

    # ------------------------------------------------------------------
    # Panel bileşenleri
    # ------------------------------------------------------------------
    # Animasyonda dönen vida/tıpa: parçanın içine ayrı örnek olarak eklenir.
    def vida_koy(e, defn, lt, p, d, strok, bas_h, w, id)
      i = e.add_instance(defn, lt)
      nitelik(i, vida: id, lt: lt.to_a, p: p.to_a, d: d.to_a, strok: strok, bas_h: bas_h, w: w.to_a)
      i
    end

    def parca_tanimi(ad)
      @m.definitions.add(ad)
    end

    # Alyan vida: o = parça-yerel yüzey noktası, n = vidalanma yönü (yüzeyden içeri).
    # Yüzde Ø10 havşa yuvası açılır; vida başı yüzle bir oturur.
    def alyan_vida(e, o, n, id)
      nv = Geom::Vector3d.new(*n)
      daire_it(e, P(*o), nv, 5, nv, VIDA_BAS, 20)
      dik = n[2].abs > 0.5 ? [1, 0, 0] : [0, 0, 1]
      ic = o.zip(n).map { |a, b| a + b * VIDA_BAS }
      vida_koy(e, @vida, eksen(ic, n, dik), P(*ic), nv, 50.0, VIDA_BAS, Geom::Vector3d.new(*n.map(&:-@)), id)
    end

    # Rafın ön yüz kesiti (XZ, mm): üst yüz ve alt yüz çizgileri yan kenardan başlar; iç uç
    # alttaki rafın (1. rafta alt tablanın) üst yüzüne oturur. [poligon, vida orta çizgisi].
    def raf_kesit(k)
      yon, z = RAFLAR[k]
      i = RAFLAR.keys.index(k)
      alt = i.zero? ? nil : RAFLAR.values[i - 1]
      if yon == :sol # '\': üst yüz z = z - x
        bit = ->(t) { alt ? (z - t - alt[1] + W) / 2 : z - t - ZB } # t: üst yüzden düşey iniş
        poli = [[0, z], [bit.(0), z - bit.(0)], [bit.(K2), z - K2 - bit.(K2)], [0, z - K2]]
        orta = ->(u) { x = u * bit.(K2 / 2); [x, z - K2 / 2 - x] }
      else # '/': üst yüz z = z - W + x
        bit = ->(t) { (alt[1] - z + W + t) / 2 }
        poli = [[W, z], [bit.(0), alt[1] - bit.(0)], [bit.(K2), alt[1] - bit.(K2)], [W, z - K2]]
        orta = ->(u) { x = W - u * (W - bit.(K2 / 2)); [x, z - W - K2 / 2 + x] }
      end
      [poli, orta]
    end

    def raf(k)
      d = parca_tanimi(AD[k])
      poli, = raf_kesit(k)
      it(d.entities, poli.map { |x, z| P(x, 0, z) }, yon(0, 1, 0), D)
      boya(d.entities, @mat[:govde])
      [d, ORIJIN[k]]
    end

    # Arka tabla: yere basar; arkadan alt tablaya ve her rafa ikişer alyan vida (yuvalar açık).
    def arka_tabla
      d = parca_tanimi(AD[:arka_tabla])
      e = d.entities
      kutu(e, 0, 0, 0, W, T, H)
      ALT_VIDA_X.zip(ALT_VIDALARI).each { |x, id| alyan_vida(e, [x, T, Z0 + T / 2], [0, -1, 0], id) }
      RAFLAR.each_key do |k|
        _, orta = raf_kesit(k)
        [0.25, 0.75].each_with_index { |u, j| x, z = orta.(u); alyan_vida(e, [x, T, z], [0, -1, 0], "#{k}_#{j + 1}") }
      end
      boya(e, @mat[:govde])
      [d, ORIJIN[:arka_tabla]]
    end

    # Alt tabla: altında ayak tabanları takılı; ayaklar demonte (çevrilerek takılır).
    def alt_tabla
      d = parca_tanimi(AD[:alt_tabla])
      e = d.entities
      kutu(e, 0, 0, 0, W, D, T)
      boya(e, @mat[:govde])
      AYAK_XY.each_with_index do |(x, y), i|
        e.add_instance(@ayak_taban, eksen([x, y, 0], [0, 0, -1], [1, 0, 0]))
        vida_koy(e, @ayak, eksen([x, y, -11], [0, 0, 1], [1, 0, 0]), P(x, y, -11), Geom::Vector3d.new(0, 0, 1), 40.0, 0.0,
                 Geom::Vector3d.new(0, 0, -1), "ayak_#{i + 1}")
      end
      [d, ORIJIN[:alt_tabla]]
    end

    def parca_yap(k)
      case k
      when :alt_tabla then alt_tabla
      when :arka_tabla then arka_tabla
      else raf(k)
      end
    end

    # ------------------------------------------------------------------
    # Model kurulumu
    # ------------------------------------------------------------------
    def kur(kayit_yolu = nil)
      @m = Sketchup.active_model
      @m.start_operation('Çapraz kitaplık kurulum modeli', true)
      @m.entities.clear!
      @m.pages.to_a.each { |p| @m.pages.erase(p) }
      @m.definitions.purge_unused
      @m.materials.purge_unused
      @m.layers.purge_unused
      malzemeler

      @vida = alyan_vida_tanimi
      @ayak_taban = ayak_taban_tanimi
      @ayak = ayak_tanimi
      @anahtar = alyan_anahtari_tanimi

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
      ai = @m.entities.add_instance(@anahtar, tr(0, 0, 0))
      ai.layer = arac_tag
      nitelik(ai, parca: 'anahtar')

      parca_listesi(liste_tag)
      stil
      bagla
      son_durum
      sahneler
      @m.commit_operation
      @m.save(kayit_yolu) if kayit_yolu
      "Kuruldu: #{SIRA.size} parça, #{VIDALAR.size} alyan vida, #{AYAKLAR.size} ayak, #{@m.pages.size} sahne"
    end

    # Kutu içeriği: paneller yere yatırılmış (arka tablanın vida yuvaları üstte), vidalar ayrı.
    def parca_listesi(tag)
      rx = ->(a) { Geom::Transformation.rotation(ORIGIN, X_AXIS, a.degrees) }
      ry = ->(a) { Geom::Transformation.rotation(ORIGIN, Y_AXIS, a.degrees) }
      bir = Geom::Transformation.new
      yerlesim = {
        arka_tabla: [rx.(90), 1300, 0], alt_tabla: [bir, 2100, 0],
        raf_1: [ry.(-45), 2900, 0], raf_2: [ry.(45), 3700, 0], raf_3: [ry.(-45), 2100, 650],
        raf_4: [ry.(45), 2900, 650], raf_5: [ry.(-45), 3700, 650], raf_6: [ry.(45), 2100, 1300],
        raf_7: [ry.(-45), 2900, 1300]
      }
      @m.entities.grep(Sketchup::ComponentInstance).select { |i| nit(i, :parca) && nit(i, :parca) != 'anahtar' }.each do |ana|
        k = nit(ana, :parca).to_sym
        rot, x, y = yerlesim[k]
        bb = Geom::BoundingBox.new
        b = ana.definition.bounds
        8.times { |c| bb.add(b.corner(c).transform(rot)) }
        kay = Geom::Transformation.translation(P(x, y, 0) - bb.min)
        i = @m.entities.add_instance(ana.definition, kay * rot)
        i.layer = tag
        on = Geom::Point3d.new(bb.center.x, bb.min.y, bb.max.z).transform(kay) # üst yüzün ön kenarı (görünür)
        txt = @m.entities.add_text(AD[k], on, Geom::Vector3d.new(0, -90.mm, 0))
        txt.layer = tag
      end
      # demonte gelenler: ayaklar, alyan vidalar, alyan anahtarı
      ekler = []
      4.times { |i| ekler << [@ayak, [1400 + i * 45, -450, 0], [0, 0, 1], [1, 0, 0], i.zero? ? 'Ayak (4)' : nil] }
      6.times { |i| ekler << [@vida, [2300, -420 - i * 30, 5], [1, 0, 0], [0, 0, 1], i.zero? ? "Alyan Vida 7x50 (#{VIDALAR.size})" : nil] }
      ekler << [@anahtar, [3200, -500, 2.3], [1, 0, 0], [0, 0, 1], 'Alyan Anahtarı']
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
        ['0 Kutu İçeriği', [], :liste, 'Paneller; ayaklar, alyan vidalar ve alyan anahtarı ayrı.'],
        ['1 Ayaklar', %i[alt_tabla], 1, 'Ayakları alt tablaya çevirerek takın.'],
        ['2 Arka Tabla', %i[arka_tabla], 2, 'Arka tablayı alt tablaya arkadan 2 alyan vidasıyla bağlayın; arka tabla yere basar.']
      ] + RAFLAR.keys.map.with_index { |k, i|
        ["#{i + 3} #{AD[k]}", [k], :raf, "#{AD[k]}ı #{i.zero? ? 'alt tablaya' : 'alttaki rafa'} oturtup arkadan 2 alyan vidasıyla bağlayın."]
      } + [['10 Bitmiş Ürün', [], :bitti, 'Kurulum tamamlandı.']]
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
        if k == 'anahtar' then @arac = i
        else
          @parca[k.to_sym] = i
          @taban_tr[k.to_sym] = i.transformation
        end
      end
      raise 'Model bulunamadı — önce OzcanKurulum::CaprazKitaplik.kur' unless @parca.size == SIRA.size && @arac
      @vidalar = @parca.flat_map do |k, ana|
        ana.definition.entities.grep(Sketchup::ComponentInstance).select { |x| nit(x, :vida) }.map { |x| vida_kaydi(x, k) }
      end
      @liste_tag = @m.layers[LISTE_TAG]
      @arac_tag = @m.layers[ARAC_TAG]
      cizelge
      true
    end

    def vida_kaydi(i, parca)
      { id: nit(i, :vida), inst: i, parca: parca,
        lt: Geom::Transformation.new(nit(i, :lt)), p: Geom::Point3d.new(*nit(i, :p)),
        d: Geom::Vector3d.new(*nit(i, :d)), strok: nit(i, :strok), bas_h: nit(i, :bas_h),
        w: Geom::Vector3d.new(*nit(i, :w)) }
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

    # Sıkılan vidaya yakın çekim: anahtarın geldiği yandan, önden-yukarıdan bakar (arkadan
    # sıkılan vidalara arkadan); anahtar ve vida başı birlikte görünür.
    def yakin_kamera(id, sure = 0.7, yon: nil)
      @cz.kamera_dinamik(sure) do
        v = @vidalar.find { |x| x[:id] == id }
        ana = @parca[v[:parca]].transformation
        bas = Geom::Point3d.new(-v[:bas_h].mm, 0, 0).transform(ana * v[:inst].transformation)
        w = v[:w].transform(ana).normalize
        bak = if yon then Geom::Vector3d.new(*yon)
              elsif w.y > 0.5 then Geom::Vector3d.new(1.0, 0.75, 0.45)
              else Geom::Vector3d.new(0.55 * w.x, 0.55 * w.y - 0.75, 0.55 * w.z + 0.45)
              end.normalize
        h = bas.to_a.map(&:to_mm)
        [h.zip(bak.to_a).map { |c, d| c + 450 * d }, h]
      end
    end

    def vida_sik(id, tur: 3, sure: 0.8)
      yakin_kamera(id)
      @cz.olay(0.45) { |s, u| s[:drv] = { id: id, uz: 1 - u, don: 0.0 } }
      @cz.olay(sure, false) do |s, u|
        s[:drv] = { id: id, uz: 0.0, don: 360.0 * tur * u }
        s[:v][id] = { adv: 1 - u, ang: 360.0 * tur * u }
      end
      @cz.olay(0.35) { |s, u| s[:drv] = u >= 1 ? nil : { id: id, uz: u, don: 360.0 * tur } }
    end

    # Demonte vidalar deliklerin önünde belirir, sonra tek tek alyan anahtarıyla sıkılır.
    def vidala(ids)
      @cz.an { |s, _| ids.each { |id| s[:v][id] = { adv: 1.0, ang: 0.0 } } }
      ids.each { |id| vida_sik(id) }
    end

    def cizelge
      @cz = z = Cizelge.new
      z.an { |s, _| VIDALAR.each { |id| s[:v][id] = { gizli: true } } } # takılana kadar görünmesin
      z.baslik('Kutu içeriği — paneller, ayaklar, alyan vidalar ve alyan anahtarı')
      z.kamera(0, KAM[:liste])
      z.bekle(3.5)

      z.baslik('1 · Ayakları alt tablaya çevirerek takın')
      z.an do |s, _|
        s[:liste] = false
        s[:p][:alt_tabla][:vis] = true
      end
      z.kamera(1.2, KAM[1])
      z.olay(1.8, false) { |s, u| AYAKLAR.each { |id| s[:v][id] = { adv: 1 - u, ang: 360.0 * 6 * u } } }
      z.bekle(0.5)

      z.baslik('2 · Arka tablayı alt tablaya arkadan iki alyan vidasıyla bağlayın; arka tabla yere basar')
      z.kamera(1.2, KAM[2])
      hareket(:arka_tabla, [0, 400, 0], [0, 0, 0], 1.8)
      vidala(ALT_VIDALARI)
      z.kamera(0.8, KAM[2])
      z.bekle(0.3)

      RAFLAR.each_key.with_index do |k, i|
        z.baslik("#{i + 3} · #{AD[k]}ı #{i.zero? ? 'alt tablaya' : 'alttaki rafa'} oturtup arkadan iki alyan vidasıyla bağlayın")
        z.kamera(1.0, KAM[:raf])
        hareket(k, [0, -450, 0], [0, 0, 0], 1.4)
        vidala(%w[1 2].map { |j| "#{k}_#{j}" })
        z.kamera(0.8, KAM[:raf])
        z.bekle(0.3)
      end

      z.baslik('Kurulum tamamlandı')
      z.kamera(1.6, KAM[:bitti])
      z.bekle(2.0)
      @cz
    end

    def sure
      @cz.t
    end

    def ilk_durum
      { liste: true,
        p: SIRA.map { |k| [k, { vis: false, off: [0, 0, 0] }] }.to_h,
        v: @vidalar.map { |v| [v[:id], { adv: 1.0, ang: 0.0 }] }.to_h,
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
      SIRA.each do |k|
        st = s[:p][k]
        @parca[k].move!(tr(*(st[:vis] ? st[:off] : UZAK)) * @taban_tr[k])
      end
      @vidalar.each do |v|
        st = s[:v][v[:id]]
        next v[:inst].move!(tr(*UZAK) * v[:lt]) if st[:gizli] # demonte parça: görüş dışında
        v[:inst].move!(vida_tr(v, st[:adv], st[:ang]))
      end
      drv = s[:drv]
      return @arac.move!(tr(*UZAK)) unless drv
      v = @vidalar.find { |x| x[:id] == drv[:id] }
      ana = @parca[v[:parca]].transformation
      bas = Geom::Point3d.new(-v[:bas_h].mm, 0, 0).transform(ana * v[:inst].transformation)
      w = v[:w].transform(ana).normalize
      uc = bas.offset(w, (drv[:uz] * 80).mm)
      ax = w.axes
      @arac.move!(Geom::Transformation.axes(uc, w, ax[0], ax[1]) *
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

    # Montajlı son durum: tüm parçalar yerinde, vidalar ve ayaklar sıkılı.
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
