"""Fırın Dolabı (Tablalı) kurulum kılavuzu PDF'i (Aren köşe saksılık kılavuzuyla aynı biçim): kapak + paket içeriği,
montaj adımları (sayfa başına 2), kurulum tamamlandı + destek kutusu.
Kullanım: python kilavuz_pdf_firin_tablali.py <çıktı.pdf> <adım klasörü> <ek görsel klasörü>
  adım klasörü: adim_gorselleri çıktısı (başlıksız NNa_islem / NNb_vida / NNc_sonuc kareleri)
  ek görsel klasörü: kapak_urun.png, bitti_firinli.png, parca_<anahtar>.png (kutu içeriğindeki her parça tek başına)"""
import io
import os
import sys

import fitz
from PIL import Image, ImageDraw, ImageOps

ADIM = EK = None # main() argümanlardan doldurur
LOGO = r'C:/Users/pc/OneDrive/Ekler/Masaüstü/çıktılar/pdf_extracted/ozcan_logo.png'
KALIN = r'C:/Windows/Fonts/segoeuib.ttf'
NORMAL = r'C:/Windows/Fonts/segoeui.ttf'
SEMBOL = r'C:/Windows/Fonts/seguisym.ttf'
URUN = 'FIRIN DOLABI (TABLALI)'
KOYU = (0.11, 0.11, 0.12)
GRI = (0.35, 0.35, 0.37)
CIZGI = (0.72, 0.72, 0.74)
A4 = fitz.paper_rect('a4')
W, Hh = A4.width, A4.height
M = 42

PARCALAR = [('A', 'Sol yan', 'sol_yan'), ('B', 'Sağ yan', 'sag_yan'), ('C', 'Alt tabla', 'alt_tabla'),
            ('D', 'Orta tabla', 'orta_tabla'), ('E', 'Üst tabla (36 mm)', 'tabla'), ('F', 'Baza', 'baza'),
            ('G', 'Klapa kapak (kulplu)', 'kapak'), ('H', 'Arkalık (3 mm)', 'arkalik')]
HIRDAVAT = [('ayak', 'Ayarlı ayak', '4 adet'), ('ayak_vidasi', 'Ayak vidası 3,5×16', '16 adet'),
            ('baza_vidasi', 'Baza vidası 4×40', '3 adet'),
            ('mentese', 'Menteşe', '2 adet'), ('mentese_vidasi', 'Menteşe vidası', '4 adet'),
            ('kosebent_vidasi', 'Köşebent vidası 3,5×16', '4 adet'), ('civi', 'Arkalık çivisi', '16 adet')]
ADIMLAR = [
    ('Bazayı alt tablaya vidalayın, ayakları takın',
     'F bazasını C alt tablanın ön kenarının altına hizalayın; alt tablanın üstünden üç vidayla bazaya vidalayın. '
     'Dört ayağı alt tablanın altına dörder vidayla takın.', 'c', 'Baza · 3 vida (4×40)\nAyaklar · 16 vida'),
    ('Yanları orta tablaya monte edin',
     'A sol yanı ve B sağ yanı D orta tablanın iki ucuna geçirin. Yanların iç yüzündeki dört çektirme vidasını alttan '
     'sıkın; dar yerde kısa tornavida kullanın.', 'c', 'Çektirme vidası · 4 adet'),
    ('Alt tabla grubunu yanlara monte edin',
     'Bazası ve ayakları takılı C alt tablayı yanların arasına alttan oturtun. Alt tablanın üstündeki dört çektirme '
     'vidasını sıkın.', 'a', 'Çektirme vidası · 4 adet'),
    ('Üst tablayı vidalayın',
     'E üst tablayı yanların üstüne, arkası gövdeyle hizalı oturtun. Yanlardaki dört köşebentten alttan vidalayın.',
     'a', 'Köşebent vidası · 4 adet'),
    ('Arkalığı arkaya çivileyin',
     'H arkalığı gövdenin arkasına yerleştirin. Yanlara, alt ve orta tablanın arka kenarına yaklaşık 15 cm arayla çakın.',
     'a', 'Arkalık çivisi · 16 adet'),
    ('Kapak menteşelerini takın',
     'G klapa kapağı arkası yukarı bakacak şekilde yatırın. İki menteşeyi alttaki 35 mm yuvalara oturtup ikişer vidayla '
     'sabitleyin.', 'a', 'Menteşe vidası · 4 adet'),
    ('Menteşeyi alt tablaya bağlayın',
     'Kapağı açık tutarak menteşe kollarını alt tabladaki tabanlara geçirin, sabitleme vidalarını sıkın. '
     'Kapağı kapatıp hizasını kontrol edin.', 'a', 'Menteşe sabitleme vidası · 2 adet'),
]


def kirp(yol, pay=24, kare=False):
    """Beyaz kenarları kırpar; PNG bayt döner."""
    im = Image.open(yol).convert('RGB')
    ters = ImageOps.invert(im)
    kutu = ters.point(lambda v: 255 if v > 12 else 0).getbbox()
    if kutu:
        x0, y0, x1, y1 = kutu
        im = im.crop((max(0, x0 - pay), max(0, y0 - pay), min(im.width, x1 + pay), min(im.height, y1 + pay)))
    if kare:
        k = max(im.size)
        z = Image.new('RGB', (k, k), 'white')
        z.paste(im, ((k - im.width) // 2, (k - im.height) // 2))
        im = z
    b = io.BytesIO()
    im.save(b, 'PNG')
    return b.getvalue()


def daire(yol):
    """Yakın çekimin ortasından kare kesit, dairesel maske (dışı beyaz)."""
    im = Image.open(yol).convert('RGB')
    k = min(im.size)
    x0 = (im.width - k) // 2 + int(k * 0.04)
    im = im.crop((x0, (im.height - k) // 2, x0 + k, (im.height + k) // 2)).resize((700, 700))
    mask = Image.new('L', im.size, 0)
    ImageDraw.Draw(mask).ellipse((0, 0, 699, 699), fill=255)
    z = Image.new('RGB', im.size, 'white')
    z.paste(im, (0, 0), mask)
    b = io.BytesIO()
    z.save(b, 'PNG')
    return b.getvalue()


def resim(sayfa, rect, veri):
    """Görseli oranını koruyarak kutuya ortalar."""
    sayfa.insert_image(rect, stream=veri, keep_proportion=True)


def yazi(sayfa, x, y, metin, boy, kalin=False, renk=KOYU, ortala=False, genislik=None):
    ad = 'kb' if kalin else 'kn'
    font = fitz.Font(fontfile=KALIN if kalin else NORMAL)
    if ortala:
        x = x - font.text_length(metin, boy) / 2
    sayfa.insert_text((x, y), metin, fontname=ad, fontsize=boy, color=renk)
    return font.text_length(metin, boy)


def paragraf(sayfa, rect, metin, boy, renk=GRI, hiza=0):
    sayfa.insert_textbox(rect, metin, fontname='kn', fontsize=boy, color=renk, align=hiza, lineheight=1.25)


def yeni_sayfa(doc, alt_baslik, no):
    s = doc.new_page(width=W, height=Hh)
    s.insert_font(fontname='kb', fontfile=KALIN)
    s.insert_font(fontname='kn', fontfile=NORMAL)
    s.insert_font(fontname='ks', fontfile=SEMBOL)
    lg = 74
    s.insert_image(fitz.Rect(W / 2 - lg / 2, 26, W / 2 + lg / 2, 26 + lg * 160 / 324), filename=LOGO)
    yazi(s, W / 2, 84, URUN, 21, kalin=True, ortala=True)
    yazi(s, W / 2, 101, alt_baslik, 10.5, kalin=alt_baslik.isupper(), ortala=True)
    if no:
        yazi(s, W / 2, Hh - 26, 'ÖZCAN MOBİLYA', 7.5, kalin=True, ortala=True)
        yazi(s, W - M - 10, Hh - 26, f'{no:02d}', 7.5, kalin=True)
    return s


def rozet(s, x, y, n):
    s.draw_circle((x, y), 11, color=KOYU, fill=KOYU)
    yazi(s, x, y + 4.2, f'{n:02d}', 10, kalin=True, renk=(1, 1, 1), ortala=True)


def adim_blogu(s, y0, n, baslik, aciklama, kare, not_):
    rozet(s, M + 11, y0 + 11, n)
    yazi(s, M + 30, y0 + 15, baslik, 12.5, kalin=True)
    paragraf(s, fitz.Rect(M + 30, y0 + 21, W - M, y0 + 50), aciklama, 8.6)
    ana = os.path.join(ADIM, f'{n:02d}{kare}_' + ('sonuc.png' if kare == 'c' else 'islem.png'))
    resim(s, fitz.Rect(M, y0 + 56, M + 318, y0 + 300), kirp(ana))
    vida = os.path.join(ADIM, f'{n:02d}b_vida.png')
    if os.path.exists(vida):
        cx, cy, r = W - M - 80, y0 + 158, 74
        resim(s, fitz.Rect(cx - r, cy - r, cx + r, cy + r), daire(vida))
        s.draw_circle((cx, cy), r, color=KOYU, width=1.6)
        s.draw_polyline([(cx - r - 14, cy - 8), (cx - r - 1, cy), (cx - r - 14, cy + 8)], color=KOYU, width=1.6)
        for i, satir in enumerate(not_.split('\n')):
            yazi(s, cx, cy + r + 18 + 11 * i, satir, 8, kalin=True, ortala=True)


def kapak_sayfasi(doc):
    s = yeni_sayfa(doc, 'Kurulum Kılavuzu', 1)
    resim(s, fitz.Rect(W / 2 - 120, 112, W / 2 + 120, 352), kirp(os.path.join(EK, 'kapak_urun.png')))
    yazi(s, M, 380, 'PAKET İÇERİĞİ', 13, kalin=True)
    hg, hy = (W - 2 * M) / 4, 92
    for i, (harf, ad, anahtar) in enumerate(PARCALAR):
        x, y = M + (i % 4) * hg, 390 + (i // 4) * hy
        s.draw_rect(fitz.Rect(x, y, x + hg, y + hy), color=CIZGI, width=0.8)
        yazi(s, x + 5, y + 20, harf, 18, kalin=True)
        yazi(s, x + 24, y + 13, ad, 7.6, kalin=False)
        yazi(s, x + 24, y + 23, '1 adet', 7.2, renk=GRI)
        resim(s, fitz.Rect(x + 8, y + 28, x + hg - 8, y + hy - 4), kirp(os.path.join(EK, f'parca_{anahtar}.png')))
    y = 390 + 2 * hy + 14
    hb, hh = (W - 2 * M) / 3, 50
    satir = (len(HIRDAVAT) + 2) // 3
    s.draw_rect(fitz.Rect(M, y, W - M, y + satir * hh), color=CIZGI, width=0.8)
    for i, (anahtar, ad, adet) in enumerate(HIRDAVAT):
        x, yy = M + (i % 3) * hb, y + (i // 3) * hh
        resim(s, fitz.Rect(x + 6, yy + 6, x + 76, yy + hh - 6), kirp(os.path.join(EK, f'parca_{anahtar}.png')))
        yazi(s, x + 82, yy + 22, ad, 7.8)
        yazi(s, x + 82, yy + 33, adet, 7.4, renk=GRI)
        if i % 3:
            s.draw_line((x, yy + 8), (x, yy + hh - 8), color=CIZGI, width=0.6)
    paragraf(s, fitz.Rect(M, y + satir * hh + 8, W - M, y + satir * hh + 40),
             'Bağlantı elemanları (şeffaf çektirmeler, köşebentler, menteşe tabanları) ve kulp panellere takılı gelir; '
             'baza alt tablaya vidayla bağlanır. '
             'Kuruluma başlamadan önce parçaları kontrol edin.', 7.8)


def montaj_sayfalari(doc):
    no = 2
    for i in range(0, len(ADIMLAR), 2):
        s = yeni_sayfa(doc, 'MONTAJ', no)
        adim_blogu(s, 122, i + 1, *ADIMLAR[i])
        if i + 1 < len(ADIMLAR):
            s.draw_line((M, 462), (W - M, 462), color=CIZGI, width=0.8)
            adim_blogu(s, 478, i + 2, *ADIMLAR[i + 1])
        else:
            s.draw_line((M, 462), (W - M, 462), color=CIZGI, width=0.8)
            yazi(s, M, 494, 'FIRININ YERLEŞTİRİLMESİ', 12.5, kalin=True)
            paragraf(s, fitz.Rect(M, 502, W - M, 540),
                     'Ankastre fırını orta bölmeye önden sürün ve fırının kendi kılavuzundaki gibi sabitleyin. '
                     'Fırının ön paneli yanların ön kenarına oturur; fırın kutuya dahil değildir.', 8.6)
            resim(s, fitz.Rect(M + 60, 545, W - M - 60, 790), kirp(os.path.join(ADIM, '08a_islem.png')))
        no += 1
    return no


def son_sayfa(doc, no):
    s = yeni_sayfa(doc, 'KURULUM TAMAMLANDI', 0)
    resim(s, fitz.Rect(W / 2 - 150, 120, W / 2 + 150, 420), kirp(os.path.join(EK, 'bitti_firinli.png')))
    yazi(s, W / 2, 452, 'Tüm bağlantıların sıkılığını kontrol edin.', 10.5, ortala=True)
    yazi(s, W / 2, 468, 'Ayakları çevirerek dolabı terazileyin; klapa kapağın hizasını kontrol edin.', 10.5, ortala=True)
    k = fitz.Rect(M + 10, 492, W - M - 10, 592)
    s.draw_rect(k, color=KOYU, width=1.4, radius=0.06)
    yazi(s, W / 2, 516, 'DESTEĞE Mİ İHTİYACINIZ VAR?', 12.5, kalin=True, ortala=True)
    yazi(s, W / 2, 531, 'WhatsApp üzerinden bize ulaşın.', 8.5, renk=GRI, ortala=True)
    for x, ust, tel in [(k.x0 + 30, 'Teknik destek', '0552 703 57 57'),
                        (k.x0 + k.width / 2 + 20, 'Ürün hakkındaki sorularınız', '0505 442 38 09')]:
        s.draw_circle((x + 12, 562), 11, color=KOYU, width=1.2)
        sf = fitz.Font(fontfile=SEMBOL)
        s.insert_text((x + 12 - sf.text_length('✆', 12) / 2, 566.5), '✆', fontname='ks', fontsize=12, color=KOYU)
        yazi(s, x + 32, 555, ust, 7.5, renk=GRI)
        yazi(s, x + 32, 573, tel, 13, kalin=True)
    lg = 50
    s.insert_image(fitz.Rect(W / 2 - lg / 2, Hh - 70, W / 2 + lg / 2, Hh - 70 + lg * 160 / 324), filename=LOGO)
    yazi(s, W / 2, Hh - 26, f'{no:02d}', 7.5, kalin=True, ortala=True)


def main(cikti, adim, ek):
    global ADIM, EK
    ADIM, EK = adim, ek
    doc = fitz.open()
    kapak_sayfasi(doc)
    no = montaj_sayfalari(doc)
    son_sayfa(doc, no)
    doc.set_metadata({'title': f'{URUN} — Kurulum Kılavuzu', 'author': 'Özcan Mobilya'})
    doc.save(cikti, garbage=4, deflate=True)
    print(cikti, doc.page_count, 'sayfa')


if __name__ == '__main__':
    main(*sys.argv[1:4])
