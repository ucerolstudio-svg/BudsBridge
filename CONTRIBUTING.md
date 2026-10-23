# Katkıda bulunma

[README’ye dön](README.md) · [Uyumluluk](docs/COMPATIBILITY.md) · [Protokol notları](docs/PROTOCOL.md) · [Gizlilik](PRIVACY.md) · [Hukuki açıklamalar](LEGAL.md)

BudsBridge deneysel bir macOS uygulamasıdır. Tek bir gerçek donanım birleşiminden genel destek sonucu çıkarmadan, tekrarlanabilir gözlemler ve küçük, açıklanabilir değişikliklerle ilerliyoruz.

## Hata veya uyumluluk bildirimi

[Yeni issue](https://github.com/ucerolstudio-svg/BudsBridge/issues/new) içinde şunları belirt:

- BudsBridge sürümü veya commit; hazır uygulama mı kaynak derlemesi mi?
- Mac modeli/mimarisi ve macOS sürümü.
- Kulaklık modeli ve firmware sürümü; telefon modeli ve işletim sistemi sürümü.
- Sorunu üretme adımları, beklenen ve gerçekleşen sonuç.
- Her iki cihazın yalnız eşleştirilmiş mi, aynı anda gerçekten bağlı mı olduğu.
- Varsa uygulamadaki kısa ve ilgili günlük bölümü; protokol onayı, arama başlangıcı/sonu ve ses çıkışı sonucu yeterlidir.

Paylaşmadan önce kişisel cihaz adlarını, Bluetooth/MAC adreslerini, seri numaralarını, telefon numaralarını, hesap bilgilerini ve yerel kullanıcı yollarını temizle. Tüm telefon Bluetooth dökümlerini veya Samsung APK/decompiled kaynaklarını issue’ya yükleme.

iPhone sonuçlarında iPhone modeli, iOS ve Buds firmware sürümünü ekle. Normal Bluetooth müzik/arama çalışmasını, Mac ile birlikte bağlı kalmayı ve BudsBridge arama geçişini ayrı ayrı raporla.

Widget hatalarında uygulamanın Applications klasöründe olup olmadığını, macOS sürümünü, galeride görünüp görünmediğini ve veri gösterip göstermediğini belirt. “Uzantı kayıtlı” ile “widget ekranda doğru çiziliyor” farklı sonuçlardır.

## Geliştirme

macOS 14+, Swift 6.3+ ve onunla uyumlu Apple Command Line Tools/macOS SDK kullan. Kurulum ayrıntıları [README](README.md#kaynaktan-derleme) içindedir.

```bash
bash scripts/test-macos.sh
bash scripts/build-macos.sh
```

Tam widget paketini üretmek için build scriptini kullan. Değiştirdiğin davranışın uygun saf protokol testlerini çalıştır; Bluetooth ve WidgetKit değişikliklerini ayrıca gerçek cihaz/host üzerinde doğrula. Donanım erişimin yoksa PR’da açıkça belirt.

## Değişiklik gönderme

1. Depoyu fork et ve değişiklik için bir dal aç.
2. Değişikliği tek bir problem veya açık bir kapsam etrafında tut.
3. PR açıklamasına sorunu, yeni davranışı ve gerçekleştirdiğin doğrulamayı yaz.
4. Protokol değişikliklerinde model/firmware kapsamını ve dayandığın yayımlanmış kaynağı belirt. Sentetik test verisini gerçek donanım gözleminden ayır.
5. Kullanıcı davranışı, desteklenen platform veya paketleme değişiyorsa ilgili dokümanları güncelle.

Yeni sorguların sıklığını ve bağlantı ömrüne etkisini açıkla. Sürekli tarama/sorgulama veya sınırsız yeniden bağlanma eklemek yerine olay temelli davranışı koru. Bekleyen ses dönüşü cihaz seçimi, yeni arama veya kullanıcı iptalinden sonra çalışmamalıdır.

Samsung’un özel uygulama kaynaklarını, APK’larını, firmware görüntülerini, kişisel günlükleri veya derleme araçlarını depoya ekleme. Üçüncü taraf kod/varlık ekliyorsan kaynağını, lisansını ve gerekli atıfları belirt; projenin GPL-3.0 lisansıyla uyumunu değerlendirmeden dahil etme.

## Donanım doğrulama notu

İlgili değişikliklerde şu durumların hangilerini denediğini bildir:

- İlk bağlantı ve `asVer` cevabı; Mac ve telefonun birlikte bağlı kalması.
- Mac’te ses çalarken gelen arama, arama sırasında çıkışın korunması ve arama sonrası Mac çıkışına dönüş.
- Giden, reddedilen veya cevapsız aramalar; test edilen görüşme uygulaması.
- Mac’te sessiz bekleme, duraklatıp devam etme ve kontrol kanalının boşta kapanması.
- Kulaklığı kutuya koyup yeniden açma, Mac uyku/uyanma ve bağlantı kaybı.
- Kullanıcının başka ses çıkışı veya başka kulaklık seçmesi.
- Değiştirilen ayarın cihazdan geri okunması; widget için gerçek galeride ekleme ve veri gösterimi.

Her PR için bütün matrisi çalıştırmak gerekmez; değişikliğin etkilediği senaryoları seç ve çalıştırılmayanları belirt. Pil iddialarında süre, ses kaynağı, ses seviyesi, ANC, codec ve bağlantı koşulları karşılaştırılabilir olmalıdır. Uygulamanın düşük CPU kullanması tek başına kulaklık pil ölçümü değildir.

## Lisans

Katkılar projenin [GNU GPL v3](LICENSE) lisansıyla dağıtılır. Mevcut kaynak ve atıfları [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) içinde koru. Bu depo Samsung ile bağlantılı değildir.

Garanti ve sorumluluk çerçevesi [LEGAL.md](LEGAL.md) ve GPL bölüm 15–17’de, veri işleme kapsamı [PRIVACY.md](PRIVACY.md) içindedir. Katkılarda mutlak hukuki sorumsuzluk veya ölçülmemiş performans/pil garantileri ileri sürme.
