from PIL import Image, ImageDraw, ImageFont

renkler = {'siyah': (0,0,0), 'mavi': (0,100,250), 'kirmizi': (220,20,20), 'sari': (255,180,0)}
w, h = 200, 300 

def tas_ureti():
    for renk_ad, rgb in renkler.items():
        for sayi in range(1, 14):
            # 1. Taşın Gövdesi
            img = Image.new('RGBA', (w, h), (0, 0, 0, 0))
            d = ImageDraw.Draw(img)
            d.rounded_rectangle([5, 5, 195, 295], radius=25, fill=(245, 245, 235), outline=(180, 180, 160), width=3)
            
            # 2. Sayıyı Yaz
            font = ImageFont.truetype('arialbd.ttf', 90)
            d.text((100, 100), str(sayi), fill=rgb, font=font, anchor="mm")
            
            # 3. Alt Kısım: Çember ve Kalp
            # Çember
            d.ellipse([70, 180, 130, 240], outline=rgb, width=3)
            # Kalp (Basit bir üçgen ve iki daire ile)
            d.polygon([(100, 225), (82, 205), (118, 205)], fill=rgb)
            d.ellipse([82, 195, 102, 215], fill=rgb)
            d.ellipse([98, 195, 118, 215], fill=rgb)
            
            img.save(f'{renk_ad}_{sayi}.png')

    # 4. TAŞIN ARKA YÜZÜ (Ters Çevrili Hali)
    arka = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    d_arka = ImageDraw.Draw(arka)
    d_arka.rounded_rectangle([5, 5, 195, 295], radius=25, fill=(100, 50, 20), outline=(60, 30, 10), width=4)
    # Arka yüze basit bir desen (opsiyonel)
    d_arka.line([40, 40, 160, 260], fill=(130, 70, 30), width=5)
    arka.save('tas_arka.png')
    print("52 taş ve Arka Yüz görseli hazır!")

tas_ureti()

from PIL import Image, ImageDraw

def beyaz_arka_uret():
    w, h = 200, 300
    arka = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(arka)
    # Taşın arkası artık fildişi/beyaz arası temiz bir renk
    d.rounded_rectangle([5, 5, 195, 295], radius=25, fill=(250, 250, 245), outline=(200, 200, 190), width=3)
    # Arka yüze çok hafif gri bir logo veya desen ekleyebilirsin
    d.ellipse([80, 130, 120, 170], outline=(220, 220, 210), width=2)
    arka.save('tas_arka.png')
    print("Beyaz arka yüz hazır!")

beyaz_arka_uret()