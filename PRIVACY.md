# Gizlilik

BudsBridge'in normal çalışması internete, Wi-Fi bağlantısına, hesaba veya
telefonda bir yardımcı uygulamaya ihtiyaç duymaz. Telemetri, reklam, analiz
servisi ve otomatik hata raporu gönderimi içermez. Telefonun arama numarası,
rehberi, mesajları veya arama ses kaydı okunmaz.

Mac'in eşleşmiş Bluetooth cihaz listesinden kulaklık adı ve Bluetooth adresi
okunur. Seçilen cihaz adresi ve tercihler Mac'teki uygulama ayarlarında yerel
olarak saklanır. Pil, mod, bağlantı ve arama durumu kulaklığın Bluetooth
protokolünden alınır; arama durumu kişi veya numara içermez.

Widget, ana uygulamanın kaydettiği pil/mod/durum özetini okur. Bluetooth açmaz
ve telefona bağlanmaz. Sandbox izni yalnızca BudsBridge'in tercih alanını
okumakla sınırlıdır; bu alan seçilen cihaz tercihini de içerebilir.

İşlem günlüğü varsayılan olarak uygulama belleğinde sınırlı sayıda satır tutar.
“Günlüğü kopyala” ile paylaşım kullanıcıya bırakılır. Geliştiricinin açıkça
verdiği `--diagnostics /dosya/yolu` seçeneği günlüğü yerel dosyaya kaydeder.
Günlükler cihaz adı/adresi veya kurulum bilgisi içerebilir; GitHub'a göndermeden
önce kişisel alanları temizle. Uygulama bunları kendiliğinden yüklemez.

Uygulamayı kaldırmak için çıkış yapıp uygulamayı ve eklediğin widget'ı sil.
Yerel tercihler `~/Library/Preferences/dev.budsbridge.mac.plist` alanında kalabilir.
Kaynak/release paketleri kullanıcı tercihlerini, Bluetooth günlüklerini,
Samsung APK dosyalarını veya geliştirmede kullanılan araçları içermez.

GitHub'ı ziyaret etmek veya GitHub'dan indirmek GitHub'ın kendi gizlilik
koşullarına tabidir; bu işlemler uygulamanın Bluetooth çalışma yolundan ayrıdır.
