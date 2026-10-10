# encoding: UTF-8
# Aren Köşe Saksılık (köşe merdiven raf, taban 63 x 63, yükseklik 175 cm) — kurulum kılavuzu modeli.
# Duvar köşesinde L oluşturan iki köşe dikmesi, iki duvar boyunca yukarı doğru içe eğilen iki
# eğik dikme ve aralarında beş çeyrek daire meşe raf (alttan üste 63, 50, 40, 30, 22 cm; en alttaki
# yerden 6 cm, raflar arası 40 cm). Dikmeler 18 mm krem sunta, 6,5 cm genişlik. Tüm birleşimler
# alyan (konfirmat) vida + alyan anahtarı; vidalar dikmelerin duvar tarafındaki yuvalardan girer.
# Ölçüler ürün belgesinden (Ürün 13 — Köşe Merdiven Raf), biçim fotoğraflardan.
#
# Her parça ayrı bileşen; dikmelerde vida yuvaları açık gelir, vidalar ve alyan anahtarı ayrı.
# Kurulum sırası:
#   1 köşe dikmeleri (L)  2 raflar alttan üste köşe dikmelerine  3 sol eğik dikme  4 sağ eğik dikme
#
# SketchUp > Pencere > Ruby Konsolu:
#   load 'C:/.../scripts/product-3d/kurulum/kose_saksilik.rb'
#   OzcanKurulum::KoseSaksilik.kur               # AÇIK MODELİ TEMİZLER, modeli sıfırdan kurar
#   OzcanKurulum::KoseSaksilik.oynat             # montaj animasyonunu ekranda oynatır
#   OzcanKurulum::KoseSaksilik.kumanda           # klavyeyle adım adım: → ← Enter, K serbest kamera, Esc
#   (konsoldan: sonraki, onceki, durdur, devam, adim(3), git(3), bitir)
#   OzcanKurulum::KoseSaksilik.kaydet('C:/kareler') # animasyonu PNG karelere yazar
#
# Koordinatlar mm: köşe (0, 0); raflar X ≥ 0, Y ≥ 0 bölgesinde, dikmeler duvar tarafında
# (Y = -18..0 sol duvar, X = -18..0 sağ duvar); Z yükseklik (0 = zemin).

module OzcanKurulum
  module KoseSaksilik
    extend self

    # ------------------------------------------------------------------
    # Ölçüler (mm)
    # ------------------------------------------------------------------
    T = 18.0             # panel kalınlığı
    H = 1750.0           # yükseklik
    DIKME_W = 65.0       # dikme genişliği
    # Raflar alttan üste: [yarıçap, alt yüz Z] — en alttaki yerden 6 cm, aralar 40 cm
    RAFLAR = [630.0, 500.0, 400.0, 300.0, 220.0].each_with_index.map { |r, i| [:"raf_#{i + 1}", [r, 60.0 + i * (T + 400)]] }.to_h.freeze
    # Eğik dikmenin dış kenarı: alt raf ucundan üst raf ucuna doğru (Z → X ya da Y)
    EGIK_DIS = ->(z) { 630.0 + (220.0 - 630.0) * (z - 60.0) / (H - 60.0 - 18.0) }
    EGIK_YATAY = DIKME_W / Math.cos(Math.atan((630.0 - 220.0) / (H - 78.0))) # yatay kesitteki genişlik
    L_Z = [250.0, 660.0, 1080.0, 1500.0, 1700.0].freeze # köşe dikmelerini birleştiren vidalar
    VIDA_BAS = 2.5       # vida başı yüksekliği = dikmedeki havşa yuvası derinliği

    DIKEY_FOV = 30.0
    VIDEO_FOV = 50.0

    DICT = 'ozcan_kurulum'
    SIRA = (%i[kose_sol kose_sag] + RAFLAR.keys + %i[egik_sol egik_sag]).freeze
    AD = { kose_sol: 'Köşe Dikmesi (sol)', kose_sag: 'Köşe Dikmesi (sağ)', egik_sol: 'Eğik Dikme (sol)',
           egik_sag: 'Eğik Dikme (sağ)' }.merge(RAFLAR.keys.map.with_index { |k, i| [k, "#{i + 1}. Raf"] }.to_h).freeze
    ETIKET = { kose_sol: '01 Köşe Dikmeleri', kose_sag: '01 Köşe Dikmeleri', egik_sol: '03 Eğik Dikme (sol)',
               egik_sag: '04 Eğik Dikme (sağ)' }.merge(RAFLAR.keys.map { |k| [k, '02 Raflar'] }.to_h).freeze
    LISTE_TAG = '00 Parça Listesi'
    ARAC_TAG = '99 Alyan Anahtarı'

    # Kamera noktaları [göz, hedef] (mm)
    KAM = {
      liste:  [[3450, -3700, 5300], [3450, 850, 0]],
      1 =>    [[-2700, -3100, 1900], [0, 0, 875]],
      2 =>    [[3200, 3000, 2100], [220, 220, 875]],
      3 =>    [[1700, -3800, 1900], [260, 0, 875]],
      4 =>    [[-3800, 1700, 1900], [0, 260, 875]],
      bitti:  [[3600, 3400, 2300], [230, 230, 950]]
    }.freeze

    # Tüm parçalar dünya koordinatında çizilir
    ORIJIN = SIRA.map { |k| [k, [0, 0, 0]] }.to_h.freeze

    L_VIDALARI = (1..L_Z.size).map { |i| "kose_#{i}" }.freeze
    VIDALAR = (L_VIDALARI + RAFLAR.keys.flat_map { |k| %w[kose_sol kose_sag egik_sol egik_sag].map { |d| "#{k}_#{d}" } }).freeze

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
        raf: mk.('Meşe Desen', [190, 146, 96]),
        dikme: mk.('Krem', [238, 232, 216]),
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

    # Çeyrek daire raf: dik köşesi duvar köşesinde, düz kenarları dikmelere dayanır.
    def raf(k)
      r, z = RAFLAR[k]
      d = parca_tanimi(AD[k])
      e = d.entities
      yay = (0..32).map { |i| a = Math::PI / 2 * i / 32; P(r * Math.cos(a), r * Math.sin(a), z) }
      it(e, [P(0, 0, z)] + yay, yon(0, 0, 1), T)
      e.grep(Sketchup::Edge).each do |ed| # kavisli kenar yumuşak görünsün
        f = ed.faces
        next unless f.size == 2 && f.all? { |x| x.normal.z.abs < 0.01 } && f[0].normal.angle_between(f[1].normal) < 10.degrees
        ed.soft = true
        ed.smooth = true
      end
      boya(e, @mat[:raf])
      [d, ORIJIN[k]]
    end

    # Dikme çizimi: duvar düzleminde (s = duvar boyunca, z) kesit, duvara doğru T kalınlık.
    # sol duvar: s → X, kalınlık Y = -T..0;  sağ duvar: s → Y, kalınlık X = -T..0.
    def duvar_kesiti(e, sol, pts)
      it(e, pts.map { |a, z| sol ? P(a, -T, z) : P(-T, a, z) }, sol ? yon(0, 1, 0) : yon(1, 0, 0), T)
    end

    # Köşe dikmeleri: sol dikme köşeyi de kapsar (X -18..47), sağ dikme onun iç yüzüne dayanır (L).
    def kose(k)
      sol = k == :kose_sol
      d = parca_tanimi(AD[k])
      e = d.entities
      a0 = sol ? -T : 0.0
      duvar_kesiti(e, sol, [[a0, 0], [a0 + DIKME_W, 0], [a0 + DIKME_W, H], [a0, H]])
      if sol
        L_Z.each_with_index { |z, i| alyan_vida(e, [-T / 2, -T, z], [0, 1, 0], L_VIDALARI[i]) }
      end
      RAFLAR.each do |rk, (_, rz)|
        o = sol ? [25.0, -T, rz + T / 2] : [-T, 25.0, rz + T / 2]
        alyan_vida(e, o, sol ? [0, 1, 0] : [1, 0, 0], "#{rk}_#{k}")
      end
      boya(e, @mat[:dikme])
      [d, ORIJIN[k]]
    end

    # Eğik dikme: dış kenarı raf uçlarından geçer; uçları yere ve üst rafa yatay kesilir.
    def egik(k)
      sol = k == :egik_sol
      d = parca_tanimi(AD[k])
      e = d.entities
      a0 = EGIK_DIS.(0)
      a1 = EGIK_DIS.(H)
      duvar_kesiti(e, sol, [[a0 - EGIK_YATAY, 0], [a0, 0], [a1, H], [a1 - EGIK_YATAY, H]])
      RAFLAR.each do |rk, (r, rz)|
        o = sol ? [r - 25, -T, rz + T / 2] : [-T, r - 25, rz + T / 2]
        alyan_vida(e, o, sol ? [0, 1, 0] : [1, 0, 0], "#{rk}_#{k}")
      end
      boya(e, @mat[:dikme])
      [d, ORIJIN[k]]
    end

    def parca_yap(k)
      case k
      when :kose_sol, :kose_sag then kose(k)
      when :egik_sol, :egik_sag then egik(k)
      else raf(k)
      end
    end

    # ------------------------------------------------------------------
    # Model kurulumu
    # ------------------------------------------------------------------
    def kur(kayit_yolu = nil)
      @m = Sketchup.active_model
      @m.start_operation('Köşe saksılık kurulum modeli', true)
      @m.entities.clear!
      @m.pages.to_a.each { |p| @m.pages.erase(p) }
      @m.definitions.purge_unused
      @m.materials.purge_unused
      @m.layers.purge_unused
      malzemeler

      @vida = alyan_vida_tanimi
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
      "Kuruldu: #{SIRA.size} parça, #{VIDALAR.size} alyan vida, #{@m.pages.size} sahne"
    end

    # Kutu içeriği: parçalar yere yatırılmış (dikmelerin vida yuvaları üstte), vidalar ayrı.
    def parca_listesi(tag)
      rx = ->(a) { Geom::Transformation.rotation(ORIGIN, X_AXIS, a.degrees) }
      ry = ->(a) { Geom::Transformation.rotation(ORIGIN, Y_AXIS, a.degrees) }
      bir = Geom::Transformation.new
      rz = ->(a) { Geom::Transformation.rotation(ORIGIN, Z_AXIS, a.degrees) }
      yerlesim = {
        kose_sol: [rx.(-90), 1300, 0], kose_sag: [rz.(90) * ry.(90), 2000, 0], egik_sol: [rx.(-90), 2700, 0],
        egik_sag: [rz.(90) * ry.(90), 3400, 0],
        raf_1: [bir, 4200, 0], raf_2: [bir, 5000, 0], raf_3: [bir, 5700, 0], raf_4: [bir, 4200, 900],
        raf_5: [bir, 4800, 900]
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
      # demonte gelenler: alyan vidalar, alyan anahtarı
      ekler = []
      6.times { |i| ekler << [@vida, [2800, -420 - i * 30, 5], [1, 0, 0], [0, 0, 1], i.zero? ? "Alyan Vida 7x50 (#{VIDALAR.size})" : nil] }
      ekler << [@anahtar, [4000, -500, 2.3], [1, 0, 0], [0, 0, 1], 'Alyan Anahtarı']
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
        ['0 Kutu İçeriği', [], :liste, 'Dikmeler (vida yuvaları açık), raflar; alyan vidalar ve alyan anahtarı ayrı.'],
        ['1 Köşe Dikmeleri', %i[kose_sol kose_sag], 1, 'Köşe dikmelerini L şeklinde birleştirip 5 alyan vidasıyla bağlayın.'],
        ['2 Raflar', RAFLAR.keys, 2, 'Rafları alttan üste köşe dikmelerine oturtup her birini 2 alyan vidasıyla bağlayın.'],
        ['3 Sol Eğik Dikme', %i[egik_sol], 3, 'Sol eğik dikmeyi raf uçlarına yaslayıp 5 alyan vidasıyla bağlayın.'],
        ['4 Sağ Eğik Dikme', %i[egik_sag], 4, 'Sağ eğik dikmeyi raf uçlarına yaslayıp 5 alyan vidasıyla bağlayın.'],
        ['5 Bitmiş Ürün', [], :bitti, 'Kurulum tamamlandı; köşeye yerleştirip devrilmeye karşı duvara sabitleyin.']
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
      raise 'Model bulunamadı — önce OzcanKurulum::KoseSaksilik.kur' unless @parca.size == SIRA.size && @arac
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

    # Sıkılan vidaya yakın çekim: vidalar dikmelerin duvar tarafından girer; kamera o yandan,
    # biraz çapraz ve yukarıdan bakar; anahtar ve vida başı birlikte görünür.
    def yakin_kamera(id, sure = 0.7, yon: nil)
      @cz.kamera_dinamik(sure) do
        v = @vidalar.find { |x| x[:id] == id }
        ana = @parca[v[:parca]].transformation
        bas = Geom::Point3d.new(-v[:bas_h].mm, 0, 0).transform(ana * v[:inst].transformation)
        w = v[:w].transform(ana).normalize
        bak = if yon then Geom::Vector3d.new(*yon)
              elsif w.y < -0.5 then Geom::Vector3d.new(0.45, -1, 0.4)
              elsif w.x < -0.5 then Geom::Vector3d.new(-1, 0.45, 0.4)
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
      z.baslik('Kutu içeriği — dikmeler, raflar, alyan vidalar ve alyan anahtarı')
      z.kamera(0, KAM[:liste])
      z.bekle(3.5)

      z.baslik('1 · Köşe dikmelerini L şeklinde birleştirip beş alyan vidasıyla bağlayın')
      z.an do |s, _|
        s[:liste] = false
        s[:p][:kose_sol][:vis] = true
        s[:p][:kose_sag] = { vis: true, off: [0, 350, 0] }
      end
      z.kamera(1.2, KAM[1])
      hareket(:kose_sag, [0, 350, 0], [0, 0, 0], 1.6)
      vidala(L_VIDALARI)
      z.kamera(0.8, KAM[1])
      z.bekle(0.3)

      z.baslik('2 · Rafları alttan üste köşe dikmelerine oturtup her birini iki alyan vidasıyla bağlayın')
      RAFLAR.each_key do |k|
        z.kamera(1.0, KAM[2])
        hareket(k, [450, 450, 0], [0, 0, 0], 1.3)
        vidala(%w[kose_sol kose_sag].map { |d| "#{k}_#{d}" })
      end
      z.kamera(0.8, KAM[2])
      z.bekle(0.3)

      [[:egik_sol, '3 · Sol eğik dikmeyi raf uçlarına yaslayıp beş alyan vidasıyla bağlayın', [0, -350, 0], 3],
       [:egik_sag, '4 · Sağ eğik dikmeyi raf uçlarına yaslayıp beş alyan vidasıyla bağlayın', [-350, 0, 0], 4]].each do |k, baslik, gelis, kam|
        z.baslik(baslik)
        z.kamera(1.2, KAM[kam])
        hareket(k, gelis, [0, 0, 0], 1.6)
        vidala(RAFLAR.keys.map { |rk| "#{rk}_#{k}" })
        z.kamera(0.8, KAM[kam])
        z.bekle(0.3)
      end

      z.baslik('Kurulum tamamlandı — köşeye yerleştirip duvara sabitleyin')
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

    # Montajlı son durum: tüm parçalar yerinde, vidalar sıkılı.
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
    # Adımlar başlıkların sırasıdır: 0 kutu içeriği, 1-4 montaj, 5 bitmiş ürün.
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
