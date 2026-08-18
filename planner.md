apps/planner | IKEA Kreativ Modelinde Ürün Geliştirme ve Tasarım İlkeleri
Amaç: Pazar analizinden elde edilen bulgular doğrultusunda, apps/planner uygulamasını geleneksel karmaşık CAD sistemlerinden ayırıp IKEA Kreativ çizgisinde hızlı, yüksek görsel tatmin sunan ve doğrudan satın almaya dönüştüren bir deneyime dönüştürmek.

📐 Çekirdek Felsefe
Kullanıcıyı teknik çizim veya karmaşık ölçü hesaplarıyla yormak yerine; "Gör, Dene, Doğrula, Satın Al" döngüsünü en az sürtünmeyle sunmak. CAD hassasiyetinden ziyade anında 3D onay ve boş tuval korkusunu yok eden yapay zekâ desteği önceliklidir.

✅ KULLANILMALI (Prerequisites & Must-Haves)
1. "Sürükle - Bırak & Anında 3D Onay" Akışı
Canlı Büyü (Live Visual Feedback): Modül veya mobilya sahneye bırakıldığı an kullanıcı 3D yansımayı ve ortam ışığıyla uyumunu anında görmeli.

Akıllı Modüler Snap: Modüller birbirine yaklaştığında mikrometre hassasiyetinde değil, sezgisel ve "mıknatıs" hissi veren tam sayı (mm) snap davranışı göstermeli.

2. Yapay Zekâ ile "Boş Tuval Bariyerini" Kaldırma
Fotoğraftan / Odadan 3D Kopya: Kullanıcının telefonla odayı taraması veya bir oda fotoğrafı yüklemesiyle ölçekli 3D sahne oluşturulmalı.

Auto-Layout / AI Decoration: Boş odaya stil ve ölçüye göre tek tıkla hazır mobilya yerleşim önerileri sunulmalı (IKEA Kreativ & HomeByMe AutoDesign modeli).

3. Akıllı Katalog ve Gerçek Zamanlı BOM (Bill of Materials)
Canlı Fiyatlandırma: Eklenen veya çıkarılan her modülde toplam tutar ekranda canlı güncellenmeli.

Doğrudan Sepete Aktarım (Handoff-Token API): IKEA PAX'teki gibi statik bir çıktı belgesi vermek yerine, oluşturulan malzeme listesi API üzerinden tek tıkla e-ticaret sepetine aktarılmalı.

4. Performans ve Arayüz Disiplini
Büyük Tuval, Görünmez Arayüz: Arayüz elemanları minimumda tutulmalı, odak noktası tasarımın kendisi olmalı.

Three.js Lazy-Loading & WebGL İyileştirmesi: Büyük projelerde kasma ve donmaları önlemek için hafifletilmiş 3D varlıklar (LOD - Level of Detail) ve kademeli yükleme kullanılmalı.

❌ KULLANILMAMALI (Anti-Patterns & Avoids)
1. Karmaşık CAD & Çizim Araçları
Kafa Karıştıran Duvar Çizimleri: HomeByMe'deki gibi kullanıcıyı duvar çizmekle uğraştıran karmaşık araçlardan kaçınılmalı. Şablon odalar veya otomatik duvar tanıma tercih edilmeli.

Gereksiz Teknik Koordinat Girişleri: Kullanıcıya manuel X/Y/Z koordinatı girdirilmemeli; her şey sürükle-bırak ve hizalama yönlendirmeleriyle çözülmeli.

2. Arayüz ve Akış Engelleri (UX Friction)
Paywall / Tasarım Ortasında Kısıtlama: Kullanıcıyı tasarımın ortasında ücretli katmana çarptıran agresif kısıtlamalar yapılmamalı. Render ve kaydetme süreçleri akıcı hissettirmeli.

Teknoloji Borcu Yansıtan Arayüzler: Eski Flash/Web Player hissi veren, ağır ve tepkisiz menülerden kesinlikle kaçınılmalı.

3. Statik ve Kopuk Süreçler
Statik Katalog Sayfaları: Ürünü sadece 2D fotoğrafla gösteren Bellona/İstikbal tarzı pasif vitrin anlayışı terk edilmeli.

Manuel Sipariş Listeleri: Kullanıcının tasarladığı ürünü kağıda yazıp mağazaya götürmesini gerektiren kopuk sipariş akışları kullanılmamalı.

🎯 apps/planner Yol Haritası (Faz Özeti)
[Faz 1 & 2: Mevcut Güçlü Temel] ──► [Faz 3: Doğrudan Satış Integration] ──► [Faz 4: IKEA Kreativ Vizyonu]
 - 2D/3D Hızlı Geçiş                - BOM -> Sepet API Handoff           - AR Oda Tarama & AI Layout
 - Tam Sayı mm Snap                 - Modül Bazlı Canlı Fiyat            - Foto-Gerçekçi AI Render Engine
 - Lightweight Three.js Architecture
 