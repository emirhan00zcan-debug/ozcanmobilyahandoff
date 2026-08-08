// Blog içeriği — şimdilik bir CMS/DB tablosu yok, sabit veri olarak tutuluyor
// (bkz. homepage-mock.ts aynı yaklaşım). İçerik "blok" listesi olarak modellenir,
// BlogPostBody bileşeni bunu sayfaya çevirir (bkz. src/components/blog/BlogPostBody.tsx).

export type BlogBlock =
  | { type: "paragraph"; text: string }
  | { type: "heading"; text: string }
  | { type: "image"; src: string; alt: string; caption?: string }
  | { type: "quote"; text: string };

export type BlogPost = {
  slug: string;
  title: string;
  excerpt: string;
  coverImage: string;
  category: string;
  readMinutes: number;
  publishedAt: string; // ISO tarih (YYYY-MM-DD)
  blocks: BlogBlock[];
};

export const BLOG_POSTS: BlogPost[] = [
  {
    slug: "masif-mi-mdf-lake-mi-malzeme-rehberi",
    title: "Masif mi, MDF Lake mi? Gardırop Seçerken Malzeme Rehberi",
    excerpt:
      "Bir gardırobun yıllarca dayanmasını sağlayan şey görünüşü değil, altındaki malzemedir. Masif ahşap, MDF lake ve yüzey kaplamaları arasındaki farkı, hangisinin ne zaman doğru seçim olduğunu anlatıyoruz.",
    coverImage: "/media/el-iscisi-zimparalama.png",
    category: "Malzeme & Kalite",
    readMinutes: 6,
    publishedAt: "2026-07-14",
    blocks: [
      {
        type: "paragraph",
        text: "Bir mobilya satın alırken çoğu kişi önce rengine, kapak tasarımına ya da fiyatına bakar — ki bu doğaldır, gözle görülen ilk şey odur. Ama bir gardırobun on yıl sonra hâlâ düzgün kapanıp kapanmayacağını, nem karşısında şişip şişmeyeceğini, güneş gören bir duvarda solup solmayacağını belirleyen şey, yüzeyin altındaki malzemedir. Bu yazıda masif ahşap ile MDF lake arasındaki gerçek farkı, birbirine karıştırılan terimleri ve Özcan Mobilya'da neden belirli bir standardı tercih ettiğimizi anlatıyoruz.",
      },
      {
        type: "heading",
        text: "Masif Ahşap: Doğal ama Hassas",
      },
      {
        type: "paragraph",
        text: "Masif ahşap, adından da anlaşılacağı gibi tek parça doğal kereste demektir; damarları, renk tonu farklılıkları ve dokusu tamamen doğaya aittir. Doğru işlenip doğru ortamda kullanıldığında nesiller boyu dayanabilir. Ama aynı zamanda 'canlı' bir malzemedir: nem oranındaki değişimlere göre genleşir, daralır; aşırı kuru ya da aşırı nemli ortamlarda çatlayabilir, çarpılabilir. Bu yüzden masif ahşap mobilya, özellikle nem oranı yüksek kıyı bölgelerinde veya kalorifer/klima kaynaklı ani sıcaklık değişimi olan evlerde ekstra bakım ister.",
      },
      {
        type: "heading",
        text: "E1 Sınıfı MDF Lake: Modern Üretimin Standardı",
      },
      {
        type: "paragraph",
        text: "MDF (Medium Density Fiberboard), ahşap liflerinin yüksek basınç altında sıkıştırılmasıyla elde edilen, yüzeyi tamamen düz ve homojen bir levha malzemesidir. 'Lake' ise bu levhanın üzerine uygulanan, kuruyunca sert ve pürüzsüz bir kaplama oluşturan boya sistemidir. İyi bir MDF lake mobilya, masife göre nem değişimlerine çok daha az tepki verir, çarpılma riski neredeyse yoktur ve yüzeyi kusursuz düzdür — özellikle çerçeve kapak gibi ince detayların net görünmesi için idealdir. Burada asıl belirleyici olan 'E1' sertifikasıdır: bu, kullanılan levhanın formaldehit emisyon değerinin Avrupa güvenlik standardının altında olduğu, yani çocuk odasında bile güvenle kullanılabileceği anlamına gelir. Sertifikasız veya düşük sınıf levha kullanan üreticilerde bu güvenlik garantisi yoktur.",
      },
      {
        type: "image",
        src: "/media/el-iscisi-zimparalama.png",
        alt: "Ustanın elle zımparaladığı mobilya kapağı",
        caption: "Lake öncesi elle zımparalama — yüzeydeki en ufak pürüz bile son kat boyada belli olur.",
      },
      {
        type: "heading",
        text: "Mat mı, Parlak mı? Yüzey Kaplamasının Farkı",
      },
      {
        type: "paragraph",
        text: "Mat lake, parmak izi ve ince çizikleri parlak yüzeye göre çok daha az belli eder; bu yüzden çocuklu evlerde ve yoğun kullanılan yatak odalarında pratik bir tercihtir. Ayrıca ışığı yumuşak şekilde yansıttığı için mekâna sakin, modern bir hava katar. Parlak lake ise ışığı doğrudan yansıtır, odayı daha ferah ve büyük gösterebilir; ama toz, çizik ve leke çok daha görünür olur, düzenli silme ister. İkisi arasındaki seçim tamamen estetik tercih ve kullanım alışkanlığı meselesidir — doğru ya da yanlışı yoktur, sadece evinize uygun olanı vardır.",
      },
      {
        type: "quote",
        text: "Bir kapağın kaç kat boyandığından çok, o boya kuruyana kadar yüzeyin kaç kez elle kontrol edildiği fark yaratır.",
      },
      {
        type: "heading",
        text: "Özcan Mobilya'da Malzeme Standardımız",
      },
      {
        type: "paragraph",
        text: "Sinop'taki atölyemizde tüm gövde ve kapaklarda 1. sınıf E1 sertifikalı yüksek yoğunluklu MDF kullanıyoruz; yüzeyler lake öncesi elle zımparalanıp kontrol ediliyor, böylece son kat boyada pürüzsüz bir sonuç garanti ediyoruz. Her ürünümüz 2 yıl garanti kapsamındadır — bu, malzemeye ve işçiliğe güvendiğimizin en somut göstergesi. Hangi ürünün size uygun olduğuna karar veremiyorsanız, ücretsiz kumaş ve ahşap numunesi isteyerek rengi ve dokuyu evinizde, gün ışığında görebilirsiniz.",
      },
    ],
  },
  {
    slug: "kapak-tipleri-cerceve-duz-kemer-detay",
    title: "Çerçeve Kapak, Düz Kapak, Kemer Detay: Kapak Tipleri Neyi Anlatır?",
    excerpt:
      "Bir gardırobun karakterini belirleyen en büyük detay kapaklarıdır. Çerçeveli panel, düz yüzey ve kemer detaylı tasarımlar arasındaki farkı, hangi tarzın hangi odaya yakıştığını görsellerle anlatıyoruz.",
    coverImage: "/media/k602_front.png",
    category: "Tasarım & Detaylar",
    readMinutes: 5,
    publishedAt: "2026-07-21",
    blocks: [
      {
        type: "paragraph",
        text: "İki gardırop aynı ölçüde, aynı renkte olabilir; ama kapak tasarımı farklıysa tamamen farklı bir oda hissi yaratırlar. Kapak, bir dolabın 'yüzü'dür — ışığı nasıl yansıtacağını, gölgeyi nereye düşüreceğini, odaya klasik mi modern mi bir hava katacağını belirler. Bu yazıda üç temel kapak dilini karşılaştırıyoruz.",
      },
      {
        type: "heading",
        text: "Çerçeve Kapak: Zamansız ve Dokulu",
      },
      {
        type: "paragraph",
        text: "Çerçeve (panel) kapakta, düz bir yüzeyin etrafına kabartma bir çerçeve profili işlenir; ışık bu profilin kenarlarında ince gölgeler oluşturur ve kapak, düz bir yüzeyden çok daha dokulu, üç boyutlu görünür. Modern Klasik serimizdeki çerçeveli kapaklar tam olarak bu etkiyi hedefler: ne aşırı süslü ne de tamamen sade — hem country hem modern yatak odalarına aynı rahatlıkla uyum sağlayan, zamana karşı dayanıklı bir tasarım dili.",
      },
      {
        type: "image",
        src: "/media/k602_front.png",
        alt: "Çerçeve kapaklı mat beyaz gardırop, ön görünüm",
        caption: "Modern Klasik 3 Kapaklı Çerçeve Kapaklı Gardırop — kabartma panel profili ve taç detayı.",
      },
      {
        type: "heading",
        text: "Kemer Detay: Klasik Zarafetin İmzası",
      },
      {
        type: "paragraph",
        text: "Kemer detaylı kapaklarda panelin üst köşeleri yumuşak bir kavis çizer; bu ufak detay, mobilyaya belirgin biçimde klasik ve zarif bir karakter kazandırır. Alya serimizde gördüğünüz kemer detayı, özellikle yüksek tavanlı, klasik mobilyalarla döşenmiş yatak odalarında güçlü bir görsel imza oluşturur. Kemer detay, düz çerçeveye göre daha 'iddialı' bir tercihtir — odanın geri kalanının da bu klasik dile eşlik etmesi gerekir.",
      },
      {
        type: "heading",
        text: "Sade Düz Kapak: Minimalist ve Ferah",
      },
      {
        type: "paragraph",
        text: "Hiçbir kabartma profili olmayan, tamamen düz yüzeyli kapaklar minimalist ve modern bir çizgi arar. Işığı kırmadan, tek bir düzlem olarak yansıttığı için küçük odalarda mekânı daha sade ve ferah gösterir. K37 serisindeki 4 kapılı tasarım bu yaklaşımın iyi bir örneğidir: dekoratif detay yerine oranların dengesine ve kulp/çekmece hizalarının kusursuzluğuna odaklanır.",
      },
      {
        type: "quote",
        text: "Kapak tasarımı seçerken kendinize sorun: bu oda ışığı yumuşatan bir doku mu istiyor, yoksa düz bir yüzeyin sakinliğini mi?",
      },
      {
        type: "heading",
        text: "Hangisi Size Uygun?",
      },
      {
        type: "paragraph",
        text: "Kesin bir kural yok; ama genel bir rehber olarak: küçük veya az ışık alan odalarda düz/sade kapaklar mekânı daha büyük gösterir, yüksek tavanlı ve klasik mobilyalı odalarda kemer detay güçlü durur, çoğu tarza uyan orta yol ise çerçeve kapaktır. Katalog sayfamızda ürünleri yan yana karşılaştırma özelliğiyle inceleyebilir, karar vermeden önce ücretsiz numune isteyebilirsiniz.",
      },
    ],
  },
  {
    slug: "gardirop-olculeri-nasil-okunur",
    title: "Gardırop Ölçüleri Nasıl Okunur? Doğru Boyutu Seçme Rehberi",
    excerpt:
      "Genişlik, yükseklik, derinlik, ayak yüksekliği, taç dahil mi değil mi... Bir ürün sayfasındaki ölçü tablosunu doğru okumak, kapıdan geçmeyen ya da odaya sığmayan bir mobilyayla karşılaşmamanın tek yoludur.",
    coverImage: "/media/wardrobe_technical_drawing_v3.jpg",
    category: "Satın Alma Rehberi",
    readMinutes: 5,
    publishedAt: "2026-07-29",
    blocks: [
      {
        type: "paragraph",
        text: "Online mobilya alışverişinde en sık yaşanan hayal kırıklığı, ürünün fotoğrafta göründüğünden büyük ya da küçük çıkması değil — genelde sorun, ölçü tablosunun yanlış okunmasıdır. Bu yazıda bir ürün sayfasındaki ölçülerin ne anlama geldiğini ve odanıza uygun boyutu nasıl belirleyeceğinizi adım adım anlatıyoruz.",
      },
      {
        type: "heading",
        text: "Dış Ölçüler: Genişlik (G), Yükseklik (Y), Derinlik (D)",
      },
      {
        type: "paragraph",
        text: "Genişlik (G) gardırobun soldan sağa kapladığı alan, yükseklik (Y) zeminden en üst noktaya kadarki mesafe, derinlik (D) ise duvardan dışarı doğru ne kadar çıktığıdır. Bu üçü her zaman gardırobun en dış noktalarına göre ölçülür — yani kapak kulpları, taç profili gibi çıkıntılar da dahildir. Bir ürün sayfasında 'Yükseklik: 220 cm (Taç Dahil)' notunu görürseniz, bu ölçünün üstteki dekoratif taç profilini de kapsadığı, tavana olan mesafeyi hesaplarken bu tam rakamı kullanmanız gerektiği anlamına gelir.",
      },
      {
        type: "image",
        src: "/media/wardrobe_technical_drawing_v3.jpg",
        alt: "Gardırop teknik ölçü çizimi",
        caption: "Bir ürün sayfasındaki ölçü tablosu, tam olarak bu teknik çizimdeki noktalara karşılık gelir.",
      },
      {
        type: "heading",
        text: "Ayak Yüksekliği Neden Ayrı Yazılır?",
      },
      {
        type: "paragraph",
        text: "Bazı gardırop modellerinde gövde zeminden birkaç santim yükseklikte, ayaklar üzerinde durur. Bu 'ayak yüksekliği' değeri toplam yüksekliğe zaten dahildir, ayrıca belirtilmesinin sebebi robot süpürge kullanan evler için önemli olmasıdır: 10 cm ve üzeri ayak yüksekliği genelde robot süpürgenin dolabın altına rahatça girebilmesi anlamına gelir. Ayak tipi bazı ürünlerde varyasyon olarak seçilebilir ve bu seçim toplam yüksekliği birkaç santim değiştirebilir — ürün sayfasındaki ölçü tablosu seçtiğiniz varyasyona göre otomatik güncellenir.",
      },
      {
        type: "heading",
        text: "İç Ölçüler: Raf, Askı ve Çekmece Alanı",
      },
      {
        type: "paragraph",
        text: "Dış ölçüler dolabın odaya sığıp sığmayacağını gösterirken, iç ölçüler dolabın gerçekte ne kadar eşya alacağını gösterir. Askı çubuğunun yerden yüksekliği, mont/palto gibi uzun kıyafetlerin sığıp sığmayacağını belirler; raf derinliği katlanmış kazak yığınlarının boyutunu; çekmece iç ölçüleri ise iç çamaşırı, aksesuar gibi küçük eşyalar için ne kadar alan olduğunu gösterir. Bu ayrıntılar özellikle mevcut kıyafet dolabınızı yeni bir gardıroba taşıyacaksanız kritik önem taşır.",
      },
      {
        type: "quote",
        text: "Ölçü almadan önce: kapı, koridor ve merdiven genişliğini de kontrol edin — bir gardırop odaya sığsa bile eve girmeyebilir.",
      },
      {
        type: "heading",
        text: "Odanıza Sığar mı? Hemen Kontrol Edin",
      },
      {
        type: "paragraph",
        text: "Her ürün sayfamızda yer alan 'Odama Sığar Mı?' aracına oda ölçülerinizi girerek, seçtiğiniz gardırobun bıraktığı boş alanı saniyeler içinde görebilirsiniz. Daha da somut bir önizleme isterseniz, AR modeli bulunan ürünlerde 'Odanızda Görün' sekmesini kullanarak gardırobu telefonunuzun kamerasıyla gerçek 1:1 ölçekte kendi odanıza yerleştirebilirsiniz — bu konuyu ayrı bir yazıda detaylıca anlattık.",
      },
    ],
  },
  {
    slug: "gardirop-ici-duzenleme-rehberi",
    title: "Gardırop İçini Verimli Kullanmak: Raf, Çekmece ve Askı Alanı Planlama",
    excerpt:
      "Aynı iç hacme sahip iki gardırop, farklı raf/askı/çekmece dağılımıyla tamamen farklı miktarda eşya alabilir. İç düzeni doğru planlamanın pratik kurallarını anlatıyoruz.",
    coverImage: "/media/k602_open_interior_1782831500815.jpg",
    category: "Kullanım İpuçları",
    readMinutes: 5,
    publishedAt: "2026-08-04",
    blocks: [
      {
        type: "paragraph",
        text: "Bir gardırobun 'yeterince büyük' olup olmadığı sadece dış ölçüsüne değil, iç hacmin nasıl bölündüğüne bağlıdır. Aynı genişlikte iki dolaptan biri sizi eşyalarınızı katlayıp istifleme zorunda bırakırken, diğeri her parçaya kendi yerini verebilir. İşte iç alanı verimli kullanmanın pratik kuralları.",
      },
      {
        type: "image",
        src: "/media/k602_open_interior_1782831500815.jpg",
        alt: "İç düzeni gösterilmiş açık gardırop, raflar ve askı bölümü",
        caption: "Raf, uzun askı ve kısa askı bölümlerinin dengeli dağılımı — her kıyafet türüne kendi alanı.",
      },
      {
        type: "heading",
        text: "Uzun Askı ve Kısa Askı Alanını Ayırın",
      },
      {
        type: "paragraph",
        text: "Mont, elbise ve palto gibi parçalar askı çubuğundan yere yakın bir mesafeye kadar uzanır ve genelde 140-160 cm'lik bir yükseklik ister. Gömlek, ceket ve bluz gibi kısa parçalar ise 90-110 cm yeterlidir — bu, kısa askı bölümünün altına ikinci bir raf ya da çekmece bloğu sığdırabileceğiniz anlamına gelir. İyi tasarlanmış bir gardırop, bu iki alanı ayrı bölümlerde sunar; böylece kısa parçaların altındaki boşluk boşa gitmez.",
      },
      {
        type: "heading",
        text: "Raf mı, Çekmece mi?",
      },
      {
        type: "paragraph",
        text: "Açık raflar, sık kullandığınız ve katlayarak sakladığınız kazak/tişört gibi parçalar için hızlı erişim sağlar ama toza ve düzensizliğe daha açıktır. Çekmeceler ise iç çamaşırı, çorap, aksesuar gibi küçük eşyaları hem tozdan korur hem de görünümü derli toplu tutar. Genel kural: haftalık kullandığınız, hızlı ulaşmak istediğiniz parçalar rafta; küçük ve düzenli tutulması gereken eşyalar çekmecede olmalı.",
      },
      {
        type: "heading",
        text: "Mevsimsel Rotasyon Yapın",
      },
      {
        type: "paragraph",
        text: "Gardırop ne kadar büyük olursa olsun, dört mevsimin kıyafetini aynı anda önde tutmaya çalışmak alanı verimsiz kullanmanıza yol açar. Üst raflar — genelde en zor ulaşılan bölüm — mevsim dışı kıyafetler için idealdir; sezonu geldiğinde bu parçaları öne, geçen sezonu üst rafa taşıyan basit bir rotasyon, aynı dolapta çok daha fazla eşyayı rahatça barındırmanızı sağlar.",
      },
      {
        type: "quote",
        text: "En büyük gardırop değil, en doğru bölünmüş gardırop, eşyalarınıza en çok yer açandır.",
      },
      {
        type: "heading",
        text: "Satın Almadan Önce İç Düzeni İnceleyin",
      },
      {
        type: "paragraph",
        text: "Ürün sayfalarımızdaki iç görünüm fotoğrafları, her modelin raf/askı/çekmece dağılımını net şekilde gösterir. Kıyafet koleksiyonunuz ağırlıklı olarak uzun askılık parçalardan mı, yoksa katlanan kazak/tişört türünden mi oluşuyor — bu sorunun cevabı, hangi iç düzenin size daha çok yer açacağını doğrudan belirler.",
      },
    ],
  },
  {
    slug: "artirilmis-gerceklik-ar-ile-mobilya-deneyimi",
    title: "Telefonunuzla Odanızda Deneyin: Özcan Mobilya'da Artırılmış Gerçeklik (AR)",
    excerpt:
      "Bir gardırop odanıza gerçekten yakışır mı, kapıyı açtığınızda yeterli boşluk kalır mı? Artık bunu satın almadan önce, telefonunuzun kamerasıyla kendi odanızda, gerçek 1:1 ölçekte görebilirsiniz.",
    coverImage: "/media/k602_lifestyle_1782831673363.jpg",
    category: "Teknoloji",
    readMinutes: 4,
    publishedAt: "2026-08-07",
    blocks: [
      {
        type: "paragraph",
        text: "Mobilya alışverişinin en büyük belirsizliği her zaman aynıdır: fotoğrafta güzel görünen bir parça, gerçek odanızda nasıl duracak? Ölçü tablosunu okuyup zihninizde canlandırmaya çalışmak yerine, artık bunu doğrudan gözünüzle görebiliyorsunuz — Özcan Mobilya'da seçili ürünlerde artık AR (Artırılmış Gerçeklik) desteği var.",
      },
      {
        type: "image",
        src: "/media/k602_lifestyle_1782831673363.jpg",
        alt: "Yatak odasında gardırop, gerçek yaşam alanı görünümü",
        caption: "Fotoğrafta odaya nasıl yakıştığını görmek başka, kendi odanızda görmek başka.",
      },
      {
        type: "heading",
        text: "Nasıl Çalışıyor?",
      },
      {
        type: "paragraph",
        text: "AR desteği olan bir ürün sayfasında galerinin üstünde '3D / Odanızda Görün' sekmesini görürsünüz. Buna dokunduğunuzda ürünün 3 boyutlu modeli açılır; içindeki 'Odanızda Görün (AR)' butonuna bastığınızda telefonunuzun kamerası devreye girer. Android'de Google'ın Scene Viewer'ı, iPhone'da Apple'ın AR Quick Look'u kamerayı açar, zemini birkaç saniyede tarar ve mobilyayı tam önünüzdeki boş alana yerleştirir. Parmağınızla dokunup istediğiniz yere sürükleyebilir, çevirebilirsiniz.",
      },
      {
        type: "heading",
        text: "Neden Gerçek Ölçek Bu Kadar Önemli?",
      },
      {
        type: "paragraph",
        text: "AR modellerimiz, her ürünün gerçek santimetre ölçülerine (genişlik, yükseklik, derinlik) birebir kilitlenecek şekilde üretilir — yani telefonunuzda gördüğünüz gardırop, kapınızdan gelecek olan gardırop ile tam olarak aynı büyüklüktedir, ne bir santim fazla ne eksik. Bu yüzden ölçeği elle büyütüp küçültme özelliği bilinçli olarak kapalıdır: amaç hoş bir görsel oyun değil, satın almadan önce gerçek bir karar aracı sunmaktır. Bir dolabın kapısı açıldığında koridora taşıp taşmayacağını, yatağın yanına konduğunda geçiş boşluğu kalıp kalmayacağını bu sayede net görebilirsiniz.",
      },
      {
        type: "quote",
        text: "En iyi ölçü tablosu bile 'gözünüzle görmenin' yerini tutmaz — AR, bu ikisi arasındaki farkı kapatıyor.",
      },
      {
        type: "heading",
        text: "Hangi Ürünlerde Var?",
      },
      {
        type: "paragraph",
        text: "AR desteğini tüm kataloğumuza kademeli olarak yayıyoruz; bir ürünün AR modeli hazırsa bunu ürün sayfasındaki '3D / Odanızda Görün' sekmesinden anlayabilirsiniz. Özellikle büyük hacimli gardırop ve dolap modellerinde bu özelliği kullanmanızı öneririz — küçük bir aksesuarda ölçü hatası affedilir, ama bir gardırop yanlış ölçüldüğünde taşıması da iadesi de zahmetlidir.",
      },
    ],
  },
];

export function getAllBlogPosts(): BlogPost[] {
  return [...BLOG_POSTS].sort((a, b) => (a.publishedAt < b.publishedAt ? 1 : -1));
}

export function getBlogPostBySlug(slug: string): BlogPost | undefined {
  return BLOG_POSTS.find((post) => post.slug === slug);
}

export function getAllBlogSlugs(): string[] {
  return BLOG_POSTS.map((post) => post.slug);
}

export function getRelatedBlogPosts(slug: string, limit = 3): BlogPost[] {
  return getAllBlogPosts().filter((post) => post.slug !== slug).slice(0, limit);
}

export function formatBlogDate(iso: string): string {
  return new Date(iso).toLocaleDateString("tr-TR", { day: "numeric", month: "long", year: "numeric" });
}
