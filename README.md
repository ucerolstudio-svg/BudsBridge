# BudsBridge

Galaxy Buds3 Pro’yu Mac ve telefon arasında kullanmak için açık kaynak, yerel bir macOS menü çubuğu uygulaması. Çoklu bağlantıyı etkinleştirmeyi dener, telefon araması bittiğinde Mac’in ses çıkışını kulaklığa geri alır ve kulaklık ayarlarını Mac’ten yönetir.

**Gerçek cihazda doğrulanan kurulum: Galaxy Buds3 Pro + Galaxy S25+ + Apple Silicon Mac.** Uygulama belirli bir kişiye veya telefona kilitli değildir; Mac’inde eşleştirilmiş kulaklığı seçerek çalışır. Diğer telefon, kulaklık, firmware ve macOS birleşimlerinin tamamında çalışacağı garanti edilmez. Ayrıntılar: [Uyumluluk](docs/COMPATIBILITY.md).

[Kurulum paketini indir](https://github.com/ucerolstudio-svg/BudsBridge/releases) · [Tüm sürümler](https://github.com/ucerolstudio-svg/BudsBridge/releases) · [Kaynaktan derle](#kaynaktan-derleme) · [Protokol notları](docs/PROTOCOL.md) · [Katkıda bulun](CONTRIBUTING.md) · [Gizlilik](PRIVACY.md) · [Hukuki açıklamalar](LEGAL.md)

> **English:** BudsBridge is an experimental native macOS 14+ app for Galaxy Buds3 Pro multipoint coexistence, returning Mac audio after phone calls, and earbud controls. Tested with Buds3 Pro, Galaxy S25+, and an Apple Silicon Mac, including the real small WidgetKit widget and its battery data. It needs no Android helper, Wi-Fi service, or USB connection. iPhone supports ordinary Bluetooth audio, but BudsBridge switching with iPhone is untested. Current binaries are arm64, ad hoc signed, and not notarized. This is a beta pre-release.

## Neler yapar?

| Özellik | Kapsam ve doğrulama |
| --- | --- |
| Çoklu bağlantıyı etkinleştirme | Samsung SMEP protokolündeki `MDE_VERSION / asVer=2` komutunu gönderir. Gerçek Buds3 Pro’dan onay alındı. |
| Telefon aramasına geçiş | Mac’te ses çalarken gelen S25+ aramasına geçiş gerçek cihazda doğrulandı. İki cihazın da kulaklığa bağlı olması gerekir. |
| Arama sonrası Mac’e dönüş | Gözlenen arama durumu sona erince, aramadan önce Buds seçiliyse Mac’in varsayılan ses çıkışını geri alır. Gerçek çağrıda doğrulandı. |
| Pil ve gürültü modu | Sol/sağ kulaklık ve mevcut olduğunda kutu pilini gösterir. Durum okuma ve gürültü modu değiştirme gerçek cihazda doğrulandı. |
| Ekolayzır | Hazır modlar ve kulaklık geçerli bir dokuz bant tablosu bildirdiğinde özel EQ kontrolleri bulunur. Bütün modlar ve özel EQ kalıcılığı ayrı ayrı doğrulanmış değildir. |
| Diğer kulaklık ayarları | Dokunma/sıkıştırma, konuşma ve siren algılama, tek kulaklıkla gürültü kontrolü, aramada kendi sesini duyma, daha net arama sesi, çıkarılınca duraklatma, uyarlanabilir ses ve kesintisiz bağlantı kontrolleri vardır. Destek ve görünürlük gelen durum verisine bağlıdır; her anahtarın davranışı henüz ayrı ayrı test edilmemiştir. |
| Küçük Apple widget’ı | Gerçek bir WidgetKit uzantısıdır. Galeride görünmesi, masaüstüne eklenmesi ve gerçek pil verisini göstermesi yerel kurulumda doğrulandı. Son bilinen pil/durum verileri ve **Mac’te dinle** kısayolu bulunur. |

SSC/UHQ codec desteği, 360 Ses, kafa takibi ve canlı çeviri gibi Samsung sistemine bağlı özellikler Mac’e eklenmez. İki cihazın sesini aynı anda karıştırma desteği yoktur. Ses çıkışını geri almak, müzik/video uygulamasının duraklattığı içeriği otomatik oynatacağını garanti etmez.

## Gereksinimler

- **macOS 14 veya sonrası.** Her macOS sürümü ayrı ayrı test edilmemiştir.
- **Hazır uygulama: Apple Silicon / `arm64`.** Intel Mac’te kaynak derlemesi henüz doğrulanmadı; hazır evrensel ikili sunulduğu varsayılmamalıdır.
- Mac ve telefonla eşleştirilmiş Galaxy Buds3 Pro; Mac’te Bluetooth izni.
- Arama geçişi için kulaklığın Mac ve telefona **aynı anda bağlı** olması. Yalnızca iki cihazla eşleştirilmiş olması yeterli değildir.

Bu sürümde protokol komutları ve ayar kontrolleri Buds3 Pro ile sınırlandırılmıştır. Başka bir Buds’ın listelenmesi, o model için komut desteği verildiği anlamına gelmez.

Telefonuna ek BudsBridge uygulaması kurman, USB kablosu bağlaman veya cihazları aynı Wi-Fi ağına alman gerekmez. Uygulama Samsung hesabına giriş istemez.

## Hazır uygulamayı kurma

1. [Releases](https://github.com/ucerolstudio-svg/BudsBridge/releases) bölümünden **BudsBridge-0.2.1-beta.1-macos-arm64.dmg** dosyasını indir ve aç.
2. **BudsBridge.app** simgesini yanındaki **Applications** klasörüne sürükle. Widget kaydı için uygulamayı bu konumda tut.
3. Applications içinden aç ve Bluetooth erişimine izin ver. Açılan **İlk kurulum · 3 adım** rehberini izle.
4. Buds3 Pro’yu Mac ve telefona eşleştir, uygulamadaki cihaz listesinden seç ve **Mac’e bağlan ve hazırla** düğmesine bas. Bu işlem otomatik uygulamayı ve arama sonrası Mac’e dönüşü açar.
5. Kulaklıktan protokol onayı geldikten sonra telefondan Buds’a yeniden bağlan. İki cihazda da bağlı göründüğünü kontrol edip bir arama dene.

ZIP paketini tercih edersen arşivi açıp uygulamayı Applications’a taşıman yeterli. Telefon uygulaması veya Terminal komutu gerekmez. Kısa Türkçe/İngilizce rehber DMG’nin içinde ve [burada](docs/GETTING_STARTED.txt) bulunur. Menü çubuğu uygulaması açık kalmalıdır; pencereyi kapatmak uygulamadan çıkmaz.

### İlk açılışta macOS engellerse

Bu sürüm **ad hoc imzalıdır**; Apple Developer ID ile imzalanmış ve noterlenmiş bir dağıtım değildir. İndirdiğin dosyanın bu deponun sürüm sayfasından geldiğini kontrol et. Geliştirici doğrulanamadığı için açılış engellenirse uygulamayı bir kez açmayı denedikten sonra **Sistem Ayarları → Gizlilik ve Güvenlik → Güvenlik → Yine de Aç / Open Anyway** yolunu kullan ve uygulama için açılışı onayla. Menü adları macOS sürümüne göre değişebilir. [Apple’ın açıklaması](https://support.apple.com/tr-tr/102445).

## Ayrıntılı bağlantı ve arama testi

1. Buds’ı telefonun Bluetooth ayarlarından eşleştir. Ardından Mac’in **Sistem Ayarları → Bluetooth** bölümünden de eşleştir ve Mac’e bağla. Bu sırada telefon bağlantısının kesilmesi mümkündür.
2. BudsBridge’i aç; **Cihaz** listesinden kendi kulaklığını seç. Gerekirse **Mac’e bağlan** düğmesini kullan. Kulaklık listede yoksa izinleri ve Bluetooth eşleşmesini kontrol edip **Bluetooth izni / yenile** düğmesine bas.
3. **Etkinleştir ve cevabı kontrol et** düğmesine bas. `Protokol onayı alındı · asVer=2` veya `asVer=3` cevabını bekle. “Komut gönderildi” mesajı tek başına onay değildir.
4. Telefonun Bluetooth ayarlarından Buds’a yeniden bağlan. **Hem telefonda hem Mac’te bağlı göründüğünü kontrol et.** Bu adım atlanırsa gelen arama geçişi beklenemez.
5. Mac’in ses çıkışını Buds seçip kısa bir müzik/video oynat. **Arama bitince Mac’in ses çıkışını Buds’a al** seçeneğini açık tut.
6. Başka bir telefondan kendi telefonunu ara ve cevapla. Arama sesinin Buds’a geçtiğini, ardından aramayı bitirdiğinde Mac’in ses çıkışının Buds’a döndüğünü kontrol et. İçerik durakladıysa oynatmaya elle devam et.
7. Kendi kurulumunda giden aramayı da ayrıca dene. Gelen arama testi, giden aramalar, reddedilen/cevapsız aramalar ve üçüncü taraf görüşme uygulamalarının tamamının doğrulandığı anlamına gelmez.
8. İlk test başarılıysa **Her Mac bağlantısında otomatik uygula** seçeneğini açabilirsin. Bu seçenek uygulamayı macOS açılışında kendiliğinden başlatmaz; bağlantı ve dönüş yönetimi için BudsBridge açık olmalıdır.

Çoklu bağlantı bilgisi kulaklığın geçici peer kaydına yazılır. Upstream araştırmaya göre kulaklıklar tamamen kapandığında bu değer kaybolur ve sonraki kullanımda yeniden uygulanmalıdır. Sıradan bir Bluetooth kopması her zaman değeri sıfırlamaz. Uygulamanın kapanması da mevcut değeri hemen silmez.

## iPhone ile kullanılabilir mi?

Galaxy Buds3 Pro, iPhone’da normal Bluetooth müzik ve telefon araması için kullanılabilir; Buds3 Pro’nun Galaxy Buds iOS uygulaması desteği yoktur. [Samsung’un iOS uyumluluk açıklaması](https://www.samsung.com/us/support/answer/ANS10003617/).

**BudsBridge ile Mac + iPhone çift bağlantısı, otomatik arama geçişi ve Mac’e dönüş henüz test edilmedi.** Samsung’un kendi Auto Switch özelliği iOS’ta desteklenmez. BudsBridge’in yöntemi farklıdır; bu durum tek başına bizim yöntemimizin iPhone’da çalıştığını veya çalışmadığını kanıtlamaz. [Samsung Auto Switch kapsamı](https://www.samsung.com/us/support/answer/ANS10002627/).

Denemek için yukarıdaki ilk kurulumdan sonra iPhone’da **Ayarlar → Bluetooth → Galaxy Buds3 Pro** üzerinden bağlan. İki bağlantının birlikte kaldığını doğrula; Mac’ten ses çalarken gelen arama, giden arama ve görüşme sonrası dönüşü ayrı ayrı test et. Sonucu iPhone modeli, iOS sürümü ve Buds firmware sürümüyle bildir. Bu kombinasyonlar şimdilik uyumluluk matrisinde **test edilmedi** olarak kalır.

## Küçük Apple widget’ını ekleme

**Doğrulama durumu:** widget’ın gerçek macOS galerisinde görünmesi, masaüstüne eklenmesi ve kulaklıktan gelen pil verisini göstermesi yerel kurulumda doğrulandı. Bu sonuç tüm Mac/macOS birleşimlerini kapsamaz.

1. Uygulamayı **Applications** klasöründen en az bir kez aç ve kulaklık durumunun gelmesini bekle.
2. Masaüstünün boş bir yerine sağ tıkla ve **Widget’ları Düzenle / Araç Takımlarını Düzenle** seçeneğini aç.
3. Galeride **BudsBridge** veya **Buds3 Pro** ara, küçük boyutu seç ve masaüstüne ekle. [Apple’ın widget kılavuzu](https://support.apple.com/tr-tr/guide/mac-help/mchl52be5da5/mac).
4. Widget’a tıklamak BudsBridge’i açar ve Mac sesini seçili Buds’a alma isteği gönderir. Kulaklık bağlı değilse önce uygulamadan bağlan; uygulama etkin arama algılıyorsa dönüş bekletilir.

Widget Bluetooth’a bağlanmaz; uygulamanın yerel olarak sakladığı son verileri okur. Uygulama kapalıyken veya kontrol kanalı uyurken pil ve bağlantı göstergeleri eski kalabilir. Yenileme zamanlamasını WidgetKit yönetir; widget anlık bir arama/pil monitörü değildir. Galeri/veri gösterimi sonucu için [issue](https://github.com/ucerolstudio-svg/BudsBridge/issues) açabilirsin.

## Pil tüketimi ve gizlilik

BudsBridge, Bluetooth ve CoreAudio durum olaylarıyla çalışır. Sürekli cihaz taraması veya periyodik kulaklık sorgusu kullanmaz. Bağlantı kurulduğunda başlangıç durumunu ister; kullanıcı komutu ve hata kurtarma sırasında sınırlı ek işlemler yapar. Mac’te kulaklık sesi çalışmıyorsa ve gözlenen bir arama yoksa kontrol kanalını yaklaşık **20 saniye** sonra kapatır. Ses kullanımı, bağlantı/çıkış olayı veya kullanıcı isteği gerektiğinde kanalı yeniden açar. Arama sırasında dönüş bildirimini alabilmek için kanalı açık tutar.

Bu yaklaşım gereksiz işi azaltır; **Samsung ile aynı pil ömrü** sağladığı veya pil tüketimini belirli bir oranda düşürdüğü ölçülmüş değildir. Telefon, Mac, codec, radyo koşulları ve iki bağlantının açık tutulması sonucu etkiler. Uzun süreli karşılaştırmalı pil testi henüz yapılmadı.

- Uygulama sunucuya, Wi-Fi servisine, bulut hesabına veya telefon yardımcı servisine bağlanmaz; telemetri göndermez.
- Seçili kulaklığın yerel Bluetooth kimliği, tercihler ve widget’ın son bilinen durumu Mac’te saklanır.
- Widget yalnızca uygulamanın kendi tercih alanındaki durum verisini okur; telefon rehberi veya arayan numarası istemez.
- İşlem günlüğü uygulamada tutulur. **Günlüğü kopyala** düğmesi otomatik bir gönderim yapmaz; paylaşmadan önce içeriği gözden geçir.
- Samsung APK’sı, decompiled kaynaklar ve araştırma araçları bu depoda veya uygulama dağıtımında bulunmaz.

Saklanan veriler ve paylaşım kapsamı için [Gizlilik açıklaması](PRIVACY.md).

## Sorun giderme

| Belirti | Kontrol et |
| --- | --- |
| Kulaklık listede yok | Mac’le eşleşme, Bluetooth izni ve kulaklık adı. Mevcut keşif adında “Buds” geçen eşleşmiş cihazları kullanır; özel adlar algılanmayabilir. |
| Etkinleştirme düğmesi pasif | Mac bağlantısı, seçili model, devam eden işlem veya arama. Listede görünmek tam model desteği anlamına gelmez. |
| `asVer` onayı yok | Kulaklığı Mac’e bağla, devam eden görüşmeyi bitir ve yeniden dene. Firmware/servis uyumsuzluğu olabilir. |
| Arama telefona geçmiyor | Telefonun da kulaklığa gerçekten bağlı olduğunu doğrula. Mac bağlantısı ve protokol onayı tek başına yeterli değildir. |
| Arama bitince ses hoparlörde | Dönüş seçeneğini, aramadan önce Buds’ın seçili olduğunu ve kontrol kanalı durumunu kontrol et. Mac’ten Buds’ı çıkış olarak seç veya **Mac’e bağlan** düğmesini kullan. |
| Bir kontrol görünmüyor | Kulaklık ilgili durum alanını bildirmemiş veya özellik desteği belirlenememiş olabilir. Özel EQ için önce **EQ verisini oku** düğmesini kullan. |
| Pil değeri değişmiyor | Son bilinen değer gösteriliyor olabilir. Uygulamayı açıp **Kontrol kanalını bağla** ile yeni durumun gelmesini bekle. Kutunun pili her durumda bildirilmez. |
| Widget görünmüyor/verisi boş | Güncel sürümü Applications klasöründen aç ve Bluetooth iznini kontrol et. Uygulamada güncel pil verisinin geldiğini doğrula ve WidgetKit’in yenilemesini bekle. Sorunda macOS sürümü ve uygulamanın konumunu bildir. |
| SDK/Swift sürümü hatası | CLT ile uyumlu bir SDK seç; aşağıdaki `BUDSBRIDGE_SDK` ayarını kullan. |

### Kapatma, geri alma ve kaldırma

Otomatik uygulamayı kapat, menü çubuğundan **Çıkış** seç ve kulaklıkları kutuda tamamen kapanacak şekilde bırakıp yeniden aç. Upstream araştırmaya göre bu, geçici çoklu bağlantı kaydını sıfırlar. ANC/EQ gibi değiştirdiğin normal kulaklık ayarları ayrı ayarlardır; bu işlem onların tümünü geri almayı vaat etmez.

Uygulamayı kaldırmak için widget eklediysen masaüstünden kaldır, BudsBridge’den çık ve `BudsBridge.app` dosyasını Applications klasöründen Çöp Sepeti’ne taşı. Normal Bluetooth eşleşmeleri bu işlemle silinmez.

## Kaynaktan derleme

**Swift 6.3 veya sonrası**, Apple Command Line Tools ya da uyumlu Xcode araçları ve derleyiciyle eşleşen bir macOS SDK kullan. Swift dosyaları scriptlerde Swift 5 dil kipinde derlenir. SDK, macOS 14 API’lerini içermelidir. Test edilen geliştirme ortamı Apple Silicon’dur.

Command Line Tools kurulu değilse Apple’ın kurulum penceresini aç:

```bash
xcode-select --install
```

Ardından:

```bash
git clone https://github.com/ucerolstudio-svg/BudsBridge.git
cd BudsBridge
xcrun swiftc --version
bash scripts/test-macos.sh
bash scripts/build-macos.sh
open dist/BudsBridge.app
```

Normal kullanım için Finder’dan üretilen uygulamayı Applications klasörüne kopyala. Güncellemede önce çalışan eski sürümden çık. Build scripti çalıştığı Mac’in mimarisi için `.app` ve içine gömülü WidgetKit `.appex` üretir, ad hoc imzalar ve imzaları doğrular; evrensel ikili veya noterleme üretmez. Üçüncü taraf Swift paketi gerekmez.

Script uyumlu kurulu SDK bulmaya çalışır. Gerekirse tam SDK yolunu açıkça belirt:

```bash
export BUDSBRIDGE_SDK="/tam/yol/MacOSX.sdk"
bash scripts/test-macos.sh
bash scripts/build-macos.sh
```

SwiftPM manifesti [macOS/Package.swift](macOS/Package.swift) içindedir. Tam uygulama paketi ve widget için yukarıdaki scripti kullan; yalnız `swift build`, widget içeren dağıtım paketini oluşturmaz. Test scripti temel protokol çerçeveleme, CRC, bozuk/parçalı paketler ve arama dönüş politikasını kontrol eder. Testlerin geçmesi Bluetooth donanımı veya WidgetKit görünümünün çalıştığını kanıtlamaz.

Kaynak yerleşimi ve mesaj açıklamaları için [Protokol ve mimari](docs/PROTOCOL.md), hata bildirimi ve değişiklikler için [Katkı rehberi](CONTRIBUTING.md).

## Lisans ve kaynaklar

BudsBridge **GNU GPL sürüm 3** altında yayımlanır. [LICENSE](LICENSE) ve [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) dosyalarını incele. Protokol araştırması ve çoklu bağlantı yöntemi, Tim Schneeberger ve katkıda bulunanların [GalaxyBudsClient](https://github.com/timschneeb/GalaxyBudsClient) çalışmasından yararlanır; kullanılan upstream commitleri atıf dosyasında kayıtlıdır.

Samsung ile bağlantılı veya Samsung tarafından desteklenen bir ürün değildir. Galaxy ve Galaxy Buds adları ilgili sahiplerinin ticari markalarıdır.

Garanti ve sorumluluk açıklamaları için [LEGAL.md](LEGAL.md), GPL’nin ilgili hükümleri için [LICENSE](LICENSE) bölüm 15–17’ye bak. Bu açıklamalar uygulanabilir hukuktaki hakları veya yükümlülükleri ortadan kaldırma garantisi değildir.
