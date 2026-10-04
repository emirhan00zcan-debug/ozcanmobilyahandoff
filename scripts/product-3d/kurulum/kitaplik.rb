# encoding: UTF-8
# Kitaplık (80 x 97 x 22 cm) — kurulum kılavuzu modeli.
# İki yan arasında dört yatay tabla (alt, iki ara, üst) üç göz oluşturur; her gözde bir dikey
# bölme (alt ve üst gözde solda, ortada sağda) ve arka köşelerde dört adet 45° üçgen köşe
# parçası. Arkalık yok. Tüm birleşimler alyan (konfirmat) vida + alyan anahtarı; vida
# başları en son tıpayla kapatılır. Ölçüler fotoğraflardan (18 mm panel kalınlığı referans).
#
# Her panel ayrı bileşen; vida yuvaları panellerde açık gelir, vidalar ve tıpalar demonte.
# Kurulum sırası kullanıcının anlattığı gibidir:
#   1 sol yan + alt tabla  2 sağ yan (U)  3-5 ara tablalar ve üst tabla, alttan yukarı
#   6 dikey bölmeler, alttan yukarı  7 köşe parçaları  8 tıpalar
#
# SketchUp > Pencere > Ruby Konsolu:
#   load 'C:/.../scripts/product-3d/kurulum/kitaplik.rb'
#   OzcanKurulum::Kitaplik.kur               # AÇIK MODELİ TEMİZLER, modeli sıfırdan kurar
#   OzcanKurulum::Kitaplik.oynat             # montaj animasyonunu ekranda oynatır
#   OzcanKurulum::Kitaplik.kumanda           # klavyeyle adım adım: → ← Enter, K serbest kamera, Esc
#   (konsoldan: sonraki, onceki, durdur, devam, adim(3), git(3), bitir)
#   OzcanKurulum::Kitaplik.kaydet('C:/kareler') # animasyonu PNG karelere yazar
#
# Koordinatlar mm: X genişlik (0 = sol dış yüz), Y derinlik (0 = ön yüz, +Y arkaya),
# Z yükseklik (0 = zemin).

module OzcanKurulum
  module Kitaplik
    extend self

    # ------------------------------------------------------------------
    # Ölçüler (mm)
    # ------------------------------------------------------------------
    W = 800.0            # dış genişlik
    T = 18.0             # panel kalınlığı
    IW = W - 2 * T       # iç genişlik 764
    D = 220.0            # derinlik
    GOZ_H = 300.0        # göz iç yüksekliği
    H = 4 * T + 3 * GOZ_H # toplam yükseklik 972
    # Yatay tablaların alt yüzleri (alt tabla yerde)
    YATAY = { alt_tabla: 0.0, ara_tabla_1: T + GOZ_H, ara_tabla_2: 2 * (T + GOZ_H), ust_tabla: H - T }.freeze
    DAR = (IW - T) / 3   # dar gözün iç genişliği (~249)
    # Dikey bölmeler: [alttaki tabla, üstteki tabla, sol yüzü X]
    BOLME = {
      bolme_alt: [:alt_tabla, :ara_tabla_1, T + DAR],
      bolme_orta: [:ara_tabla_1, :ara_tabla_2, W - 2 * T - DAR],
      bolme_ust: [:ara_tabla_2, :ust_tabla, T + DAR]
    }.freeze
    KOSE_L = 105.0       # 45° köşe parçasının dik kenarları
    # Köşe parçaları (arka düzlemde üçgen plaka): [yan, yatay tabla, dik köşe X, dik köşe Z, X yönü, Z yönü]
    KOSE = {
      kose_sol_alt: [:sol_yan, :alt_tabla, T, T, 1, 1], kose_sag_alt: [:sag_yan, :alt_tabla, W - T, T, -1, 1],
      kose_sol_ust: [:sol_yan, :ust_tabla, T, H - T, 1, -1], kose_sag_ust: [:sag_yan, :ust_tabla, W - T, H - T, -1, -1]
    }.freeze
    VIDA_Y = [40.0, D - 40].freeze # alyan vidalarının derinlik konumları
    VIDA_YER = %w[on arka].freeze
    VIDA_BAS = 2.5       # vida başı yüksekliği = yüzdeki havşa yuvası derinliği

    DIKEY_FOV = 30.0
    VIDEO_FOV = 50.0

    DICT = 'ozcan_kurulum'
    SIRA = (%i[sol_yan alt_tabla sag_yan ara_tabla_1 ara_tabla_2 ust_tabla] + BOLME.keys + KOSE.keys).freeze
    ETIKET = {
      sol_yan: '01 Sol Yan', alt_tabla: '02 Alt Tabla', sag_yan: '03 Sağ Yan', ara_tabla_1: '04 Ara Tabla 1',
      ara_tabla_2: '05 Ara Tabla 2', ust_tabla: '06 Üst Tabla'
    }.merge(BOLME.keys.map { |k| [k, '07 Dikey Bölmeler'] }.to_h)
     .merge(KOSE.keys.map { |k| [k, '08 Köşe Parçaları'] }.to_h).freeze
    AD = {
      sol_yan: 'Sol Yan', alt_tabla: 'Alt Tabla', sag_yan: 'Sağ Yan', ara_tabla_1: 'Ara Tabla 1',
      ara_tabla_2: 'Ara Tabla 2', ust_tabla: 'Üst Tabla', bolme_alt: 'Dikey Bölme (alt)',
      bolme_orta: 'Dikey Bölme (orta)', bolme_ust: 'Dikey Bölme (üst)', kose_sol_alt: 'Köşe (sol alt)',
      kose_sag_alt: 'Köşe (sağ alt)', kose_sol_ust: 'Köşe (sol üst)', kose_sag_ust: 'Köşe (sağ üst)'
    }.freeze
    LISTE_TAG = '00 Parça Listesi'
    ARAC_TAG = '99 Alyan Anahtarı'

    # Kamera noktaları [göz, hedef] (mm)
    KAM = {
      liste:  [[2750, -2300, 3000], [2750, 400, 0]],
      1 =>    [[1500, -1500, 900], [320, 110, 200]],
      2 =>    [[1800, -1700, 1100], [400, 110, 300]],
      yatay:  [[1600, -2000, 1500], [400, 110, 460]],
      6 =>    [[1300, -2100, 1000], [400, 110, 486]],
      7 =>    [[-1000, 2300, 1400], [400, 110, 486]],
      8 =>    [[-1200, -1900, 1700], [400, 110, 486]],
      :"8b" => [[2000, -1800, 1600], [400, 110, 486]],
      bitti:  [[1600, -2100, 1300], [400, 110, 470]]
    }.freeze

    # Parçaların yerleşim orijini (panellerde min köşe, köşe parçalarında dik köşe)
    ORIJIN = { sol_yan: [0, 0, 0], sag_yan: [W - T, 0, 0] }
             .merge(YATAY.transform_values { |z| [T, 0, z] })
             .merge(BOLME.transform_values { |alt, _, x| [x, 0, YATAY[alt] + T] })
             .merge(KOSE.transform_values { |_, _, x, z, _, _| [x, D - T, z] }).freeze

    VIDALAR = (YATAY.keys.flat_map { |k| %w[sol sag].flat_map { |t| VIDA_YER.map { |y| "#{k}_#{t}_#{y}" } } } +
               BOLME.keys.flat_map { |b| %w[ust alt].flat_map { |u| VIDA_YER.map { |y| "#{b}_#{u}_#{y}" } } } +
               KOSE.keys.flat_map { |k| ["#{k}_yan", "#{k}_tabla"] }).freeze
    TIPALAR = VIDALAR.map { |id| "tipa_#{id}" }.freeze

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
        govde: mk.('Safir Meşe', [126, 80, 50]),
        cinko: mk.('Çinko Kaplama', [160, 164, 170]),
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

    # Vida tıpası: kubbe x∈[-1.5, 0] gövde renginde, tırnağı +x yönünde alyan yuvasına girer
    def tipa_tanimi
      d = @m.definitions.add('Vida Tıpası')
      torna(d.entities, [[-1.5, 0], [-1.5, 4.5], [-1, 5.5], [0, 6], [0, 2], [3, 2], [3, 0]], 24, @mat[:govde])
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

    # Alyan vida ve tıpası: o = parça-yerel yüzey noktası, n = vidalanma yönü (yüzeyden içeri).
    # Yüzde Ø10 havşa yuvası açılır; vida başı yüzle bir oturur, tıpa üstüne geçer.
    def alyan_vida(e, o, n, id)
      nv = Geom::Vector3d.new(*n)
      daire_it(e, P(*o), nv, 5, nv, VIDA_BAS, 20)
      dik = n[2].abs > 0.5 ? [1, 0, 0] : [0, 0, 1]
      ic = o.zip(n).map { |a, b| a + b * VIDA_BAS }
      geri = Geom::Vector3d.new(*n.map(&:-@))
      vida_koy(e, @vida, eksen(ic, n, dik), P(*ic), nv, 50.0, VIDA_BAS, geri, id)
      vida_koy(e, @tipa, eksen(o, n, dik), P(*o), nv, 25.0, 0.0, geri, "tipa_#{id}")
    end

    # Yan: dış yüzden yatay tablalara (her birine 2) ve köşe parçasına giden vidalar.
    def yan(ad, parca, sx)
      d = parca_tanimi(ad)
      e = d.entities
      kutu(e, 0, 0, 0, T, D, H)
      taraf = sx > 0 ? 'sol' : 'sag'
      xd = sx > 0 ? 0.0 : T # dış yüz
      YATAY.each do |k, z0|
        VIDA_Y.zip(VIDA_YER).each { |y, yer| alyan_vida(e, [xd, y, z0 + T / 2], [sx, 0, 0], "#{k}_#{taraf}_#{yer}") }
      end
      KOSE.each do |k, (yan, _, _, cz, _, sz)|
        alyan_vida(e, [xd, D - T / 2, cz + sz * KOSE_L / 2], [sx, 0, 0], "#{k}_yan") if yan == parca
      end
      boya(e, @mat[:govde])
      [d, ORIJIN[parca]]
    end

    # Yatay tabla: dikey bölmelere üstten/alttan, köşe parçalarına giden vidalar.
    def yatay(k)
      d = parca_tanimi(AD[k])
      e = d.entities
      kutu(e, 0, 0, 0, IW, D, T)
      BOLME.each do |b, (alt, ust, bx)|
        xb = bx + T / 2 - T # bölme ortası, tabla-yerel
        VIDA_Y.zip(VIDA_YER).each do |y, yer|
          alyan_vida(e, [xb, y, T], [0, 0, -1], "#{b}_ust_#{yer}") if ust == k # üstteki tabladan aşağı
          alyan_vida(e, [xb, y, 0], [0, 0, 1], "#{b}_alt_#{yer}") if alt == k  # alttaki tablanın altından yukarı
        end
      end
      KOSE.each do |kk, (_, tabla, cx, _, sx, sz)|
        next unless tabla == k
        alyan_vida(e, [cx + sx * KOSE_L / 2 - T, D - T / 2, sz > 0 ? 0.0 : T], [0, 0, sz], "#{kk}_tabla")
      end
      boya(e, @mat[:govde])
      [d, ORIJIN[k]]
    end

    def bolme(k)
      d = parca_tanimi(AD[k])
      kutu(d.entities, 0, 0, 0, T, D, GOZ_H)
      boya(d.entities, @mat[:govde])
      [d, ORIJIN[k]]
    end

    # 45° köşe parçası: dik köşesi orijinde, kenarları X ve Z yönünde, arka düzlemde 18 mm plaka.
    def kose(k)
      _, _, _, _, sx, sz = KOSE[k]
      d = parca_tanimi(AD[k])
      it(d.entities, [P(0, 0, 0), P(sx * KOSE_L, 0, 0), P(0, 0, sz * KOSE_L)], yon(0, 1, 0), T)
      boya(d.entities, @mat[:govde])
      [d, ORIJIN[k]]
    end

    def parca_yap(k)
      case k
      when :sol_yan then yan('Sol Yan', k, 1)
      when :sag_yan then yan('Sağ Yan', k, -1)
      when *YATAY.keys then yatay(k)
      when *BOLME.keys then bolme(k)
      else kose(k)
      end
    end

    # ------------------------------------------------------------------
    # Model kurulumu
    # ------------------------------------------------------------------
    def kur(kayit_yolu = nil)
      @m = Sketchup.active_model
      @m.start_operation('Kitaplık kurulum modeli', true)
      @m.entities.clear!
      @m.pages.to_a.each { |p| @m.pages.erase(p) }
      @m.definitions.purge_unused
      @m.materials.purge_unused
      @m.layers.purge_unused
      malzemeler

      @vida = alyan_vida_tanimi
      @tipa = tipa_tanimi
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
      "Kuruldu: #{SIRA.size} parça, #{VIDALAR.size} alyan vida, #{TIPALAR.size} tıpa, #{@m.pages.size} sahne"
    end

    # Kutu içeriği: paneller yere yatırılmış (vida yuvaları üstte), vidalar ve tıpalar ayrı.
    def parca_listesi(tag)
      rx = ->(a) { Geom::Transformation.rotation(ORIGIN, X_AXIS, a.degrees) }
      ry = ->(a) { Geom::Transformation.rotation(ORIGIN, Y_AXIS, a.degrees) }
      rz = ->(a) { Geom::Transformation.rotation(ORIGIN, Z_AXIS, a.degrees) }
      bir = Geom::Transformation.new
      yerlesim = {
        sol_yan: [rz.(90) * ry.(90), 1400, 0], sag_yan: [rz.(90) * ry.(-90), 1700, 0],
        alt_tabla: [rx.(180), 2050, 0], ara_tabla_1: [bir, 2050, 420], ara_tabla_2: [bir, 2950, 0],
        ust_tabla: [bir, 2950, 420],
        bolme_alt: [ry.(90), 2150, 920], bolme_orta: [ry.(90), 2650, 920], bolme_ust: [ry.(90), 3150, 920],
        kose_sol_alt: [rx.(90), 3600, 920], kose_sag_alt: [rx.(90), 3950, 920],
        kose_sol_ust: [rx.(90), 3600, 1220], kose_sag_ust: [rx.(90), 3950, 1220]
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
        on = Geom::Point3d.new(bb.center.x, bb.min.y, 0).transform(kay) # ön kenarın ortası, zeminde
        txt = @m.entities.add_text(AD[k], on, Geom::Vector3d.new(0, -90.mm, 0))
        txt.layer = tag
      end
      # demonte gelenler: alyan vidalar, tıpalar, alyan anahtarı
      ekler = []
      6.times { |i| ekler << [@vida, [1700, -420 - i * 30, 5], [1, 0, 0], [0, 0, 1], i.zero? ? "Alyan Vida 7x50 (#{VIDALAR.size})" : nil] }
      6.times { |i| ekler << [@tipa, [2300 + (i % 3) * 25, -420 - (i / 3) * 25, 3], [0, 0, -1], [1, 0, 0], i.zero? ? "Tıpa (#{TIPALAR.size})" : nil] }
      ekler << [@anahtar, [2950, -500, 2.3], [1, 0, 0], [0, 0, 1], 'Alyan Anahtarı']
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
        ['0 Kutu İçeriği', [], :liste, 'Paneller (vida yuvaları açık); alyan vidalar, tıpalar ve alyan anahtarı ayrı.'],
        ['1 Sol Yan + Alt Tabla', %i[sol_yan alt_tabla], 1, 'Sol yanı alt tablaya yanın dışından 2 alyan vidasıyla bağlayın.'],
        ['2 Sağ Yan', %i[sag_yan], 2, 'Sağ yanı alt tablaya 2 alyan vidasıyla bağlayın: U şekli oluşur.'],
        ['3 Ara Tabla 1', %i[ara_tabla_1], :yatay, 'Birinci ara tablayı yanların arasına koyup her yandan 2 vidayla bağlayın.'],
        ['4 Ara Tabla 2', %i[ara_tabla_2], :yatay, 'İkinci ara tablayı yerleştirip her yandan 2 vidayla bağlayın.'],
        ['5 Üst Tabla', %i[ust_tabla], :yatay, 'Üst tablayı yerleştirip her yandan 2 vidayla bağlayın.'],
        ['6 Dikey Bölmeler', BOLME.keys, 6, 'Dikey bölmeleri alttan yukarı yerleştirin; her birini üstten 2, alttan 2 vidayla bağlayın.'],
        ['7 Köşe Parçaları', KOSE.keys, 7, '45° köşe parçalarını arkaya yerleştirin; yandan ve tabladan birer vidayla bağlayın.'],
        ['8 Tıpalar', [], 8, 'Vida başlarını tıpalarla kapatın.'],
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
        if k == 'anahtar' then @arac = i
        else
          @parca[k.to_sym] = i
          @taban_tr[k.to_sym] = i.transformation
        end
      end
      raise 'Model bulunamadı — önce OzcanKurulum::Kitaplik.kur' unless @parca.size == SIRA.size && @arac
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

    # Sıkılan vidaya yakın çekim: anahtarın geldiği yandan, önden-yukarıdan bakar (alttan
    # sıkılan vidalara aşağıdan); anahtar ve vida başı birlikte görünür.
    def yakin_kamera(id, sure = 0.7, yon: nil)
      @cz.kamera_dinamik(sure) do
        v = @vidalar.find { |x| x[:id] == id }
        ana = @parca[v[:parca]].transformation
        bas = Geom::Point3d.new(-v[:bas_h].mm, 0, 0).transform(ana * v[:inst].transformation)
        w = v[:w].transform(ana).normalize
        bak = if yon then Geom::Vector3d.new(*yon)
              elsif w.z < -0.5 then Geom::Vector3d.new(0.35, -0.6, -0.7)
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

    def yatay_vidalari(k, taraf)
      VIDA_YER.map { |y| "#{k}_#{taraf}_#{y}" }
    end

    def cizelge
      @cz = z = Cizelge.new
      z.an { |s, _| (VIDALAR + TIPALAR).each { |id| s[:v][id] = { gizli: true } } } # takılana kadar görünmesin
      z.baslik('Kutu içeriği — paneller, alyan vidalar, tıpalar ve alyan anahtarı')
      z.kamera(0, KAM[:liste])
      z.bekle(3.5)

      z.baslik('1 · Sol yanı alt tablaya iki alyan vidasıyla bağlayın')
      z.an do |s, _|
        s[:liste] = false
        s[:p][:sol_yan][:vis] = true
        s[:p][:alt_tabla] = { vis: true, off: [500, 0, 0] }
      end
      z.kamera(1.2, KAM[1])
      hareket(:alt_tabla, [500, 0, 0], [0, 0, 0], 1.8)
      vidala(yatay_vidalari(:alt_tabla, 'sol'))
      z.kamera(0.8, KAM[1])
      z.bekle(0.3)

      z.baslik('2 · Sağ yanı alt tablaya bağlayın: U şekli oluşur')
      z.kamera(1.2, KAM[2])
      hareket(:sag_yan, [500, 0, 0], [0, 0, 0], 1.8)
      vidala(yatay_vidalari(:alt_tabla, 'sag'))
      z.kamera(0.8, KAM[2])
      z.bekle(0.3)

      [[:ara_tabla_1, '3 · Birinci ara tablayı yanların arasına koyup iki yandan vidalayın', [0, -500, 0]],
       [:ara_tabla_2, '4 · İkinci ara tablayı yerleştirip iki yandan vidalayın', [0, -500, 0]],
       [:ust_tabla, '5 · Üst tablayı yerleştirip iki yandan vidalayın', [0, 0, 300]]].each do |k, baslik, gelis|
        z.baslik(baslik)
        z.kamera(1.2, KAM[:yatay])
        hareket(k, gelis, [0, 0, 0], 1.6)
        vidala(yatay_vidalari(k, 'sol') + yatay_vidalari(k, 'sag'))
        z.kamera(0.8, KAM[:yatay])
        z.bekle(0.3)
      end

      z.baslik('6 · Dikey bölmeleri alttan yukarı yerleştirin; üstten ve alttan ikişer vidayla bağlayın')
      BOLME.each_key do |b|
        z.kamera(1.0, KAM[6])
        hareket(b, [0, -450, 0], [0, 0, 0], 1.4)
        vidala(%w[ust alt].flat_map { |u| VIDA_YER.map { |y| "#{b}_#{u}_#{y}" } })
      end
      z.kamera(0.8, KAM[6])
      z.bekle(0.3)

      z.baslik('7 · 45° köşe parçalarını arkaya yerleştirin; yandan ve tabladan birer vidayla bağlayın')
      KOSE.each_key do |k|
        z.kamera(1.0, KAM[7])
        hareket(k, [0, 350, 0], [0, 0, 0], 1.2)
        vidala(["#{k}_yan", "#{k}_tabla"])
      end
      z.kamera(0.8, KAM[7])
      z.bekle(0.3)

      z.baslik('8 · Vida başlarını tıpalarla kapatın')
      z.kamera(1.2, KAM[8])
      z.an { |s, _| TIPALAR.each { |id| s[:v][id] = { adv: 1.0, ang: 0.0 } } }
      z.olay(1.6) { |s, u| TIPALAR.each { |id| s[:v][id] = { adv: 1.0 - u, ang: 0.0 } } }
      z.bekle(0.6)
      z.kamera(2.0, KAM[:"8b"])
      z.bekle(0.3)

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

    # Montajlı son durum: tüm parçalar yerinde, vidalar sıkılı, tıpalar takılı.
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
    # Adımlar başlıkların sırasıdır: 0 kutu içeriği, 1-8 montaj, 9 bitmiş ürün.
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
