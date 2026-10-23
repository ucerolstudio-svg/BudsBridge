# Protokol ve mimari

[README’ye dön](../README.md) · [Uyumluluk](COMPATIBILITY.md)

Bu belge uygulamanın kullandığı mesajları ve kanıt sınırlarını açıklar. Resmî Samsung protokol şartnamesi değildir. Kaynak ve upstream sürüm bilgileri [THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md) içindedir.

## İki Bluetooth kanalı

| Kanal | UUID | Kullanım |
| --- | --- | --- |
| SMEP RFCOMM | `f8620674-a1ed-41ab-a8b9-de9ad655729d` | Geçici çoklu bağlantı sürüm bilgisini yazma ve cevabını doğrulama. İşlem bitince kapanır. |
| Normal Buds SPP/RFCOMM | `2e73a4ad-332d-41fc-90e2-16bef06523f2` | Pil/ayar okumaları, kullanıcı komutları ve çoklu bağlantı durum olayları. Gerektiğinde açık tutulur. |

UUID’ler servis tanımlayıcılarıdır; kullanıcıya ait Bluetooth adresleri değildir. Kanal numaraları sabitlenmez; SDP hizmet kaydından bulunur. Uygulama eşleşmiş cihazlarla çalışır ve sürekli Bluetooth keşfi başlatmaz.

## SMEP etkinleştirmesi

`MDE_VERSION` içindeki `asVer` alanı `2` olarak yazılır. Kullanılan doğrulanmış 15 baytlık çerçeve:

```text
FC 0B 00 01 43 04 03 04 00 00 0B 02 1E AF CC
```

İç içe `WRITE_PROPERTY` (`0x43`) mesajındaki sürüm alanıdır; firmware görüntüsü veya eşleşme anahtarı yazılmaz. Uygulama, `NOTIFY_PROPERTY` (`0x45`) cevabının ilgili alanını denetler ve kısa bir pencere boyunca gelen durumların son değerini kullanır. Bu pencere önemlidir: cevap kümesi eski ve yeni değerleri birlikte içerebilir. `2` veya `3` raporlandığında protokol onayı gösterilir; yalnızca yazmanın başarılı olması onay sayılmaz.

Peer kaydının RAM’de tutulduğu ve kulaklık yeniden başladığında değerin kaybolduğu upstream firmware araştırmasının sonucudur. Normal bağlantı kopması kaydı mutlaka silmez. Otomatik mod bağlantı olayında yeniden uygular; aynı bağlantı için sürekli yazma yapmaz.

Bu onay yalnız sürüm alanını doğrular. İki ses bağlantısının birlikte kalması ve arama önceliği ayrıca donanımda test edilmelidir. BudsBridge’in gerçek Buds3 Pro testinde hem sürüm cevabı hem çağrı geçişi gözlendi.

## Normal durum ve komutlar

Normal çerçeveler `0xFD` ile başlar, `0xDD` ile biter; boyut alanı, mesaj kimliği, yük ve CRC taşır. Akış ayrıştırıcı parçalanmış veya bir okumada birleşmiş çerçeveleri işler; CRC’si bozuk mesajları ve desteklenmeyen parçalı mesaj biçimini durum olayına dönüştürmez.

| Mesaj | Rol |
| --- | --- |
| `0x88 MANAGER_INFO` | Mevcut istemci başlangıç bilgisi `[1, 1, 34]`. Upstream Samsung türü ve SDK alanıyla uyumludur; gerçek Mac işletim sistemi sürümünü belirtmez. |
| `0x60 STATUS_UPDATED` | Temel pil/durum bildirimi. |
| `0x61 EXTENDED_STATUS_UPDATED` | Pil ve ayar alanları; başlangıçta bir kez istenir, kabul edilmiş kullanıcı komutundan sonra yeniden okunabilir. |
| `0x76 MULTIPOINT_INFO` | Ses odağı ve ön plandaki akış türü. Extended status hazır olduğunda oturum başına bir kez boş yükle istenir; sonrasında olaylar dinlenir. |
| `0x77 / 0x78` | Gürültü modu bildirimi / ayarı. |
| `0x86` | EQ modu. Farklı modellerin indekslerini aynı kabul etmemek gerekir. |
| `0x69 / 0x89` | EQ tablosunu okuma / dokuz bant değerini gönderme. Özel kontrol geçerli dokuz bant cevabı geldikten sonra açılır. |
| `0x90` | Dokunma ve arama kontrol tercihleri. |
| `0x51 RESP` | Komut sonucu; başarı cevabı ardından güncel ayarlar okunur. |

Diğer ayar mesajları [Model.swift](../macOS/Sources/BudsBridge/Model.swift) içindeki `setFeature` eşlemesinde bulunur. Mesaj kimliğinin bilinmesi, her modelde veya firmware’de aynı yük düzeninin desteklendiği anlamına gelmez.

## Aramadan sonra ses çıkışının geri alınması

`0x76` yükünün ilk beş baytı:

| Ofset | Alan |
| --- | --- |
| `0` | Revizyon |
| `1` | Çoklu bağlantı desteği |
| `2` | Çoklu bağlantı durumu |
| `3` | Ses odağı: `0` ön plan, `1` arka plan |
| `4` | Ön plandaki akış bit maskesi |

Upstream eşlemesi A2DP müziği `1`, HFP aramayı `2`, CIS müziği `4`, BIS’i `8`, CIS aramayı `16` olarak tanımlar. Uygulama arama için `mask & 0x12 != 0` kontrolü kullanır. **Gerçek cihaz testinde HFP yolu (`2`) doğrulandı; CIS/LE Audio arama yolu henüz donanımda doğrulanmadı.**

Samsung plugininin incelenen ayrıştırıcısı aynı beş alanı işler; extended status sonrası tek seferlik boş `0x76` sorgusu gönderir. Bu olaylar ayrı bir “telefon araması bitti” komutu değil, güncel akış durumudur. Mac’e gelen gerçek test akışında arka plan/arama `2` durumundan ön plan/müzik `1` durumuna geçiş gözlendi.

Geri dönüş politikası:

1. Arama başlangıcı gerçekten gözlenmelidir.
2. Mac’in aramadan önce Buds’ı tercih ettiği ve otomatik dönüşün açık olduğu kaydedilir.
3. Arama biti temizlenince 500 ms beklenir. Yeni arama, cihaz seçimi değişikliği veya iptal bekleyen işlemi geçersiz kılar.
4. CoreAudio varsayılan çıkışı seçilir; kısa gecikmeden sonra seçimin kaldığı kontrol edilir. Geçici başarısızlıklar sınırlı sayıda yeniden denenir.

Geri dönüş cihaz adresi ve oturum nesliyle ilişkilendirilir. Eski kontrol kanalının cevabı yeni seçilen kulaklığa uygulanmaz. Bağlantının kapanması tek başına aramanın bittiği anlamına gelmez. Arama sırasında kontrol kanalı kaybolursa sınırlı yeniden açma denenir.

CoreAudio yalnız Mac’in ses cihazını/çıkışını bilir; telefonun arama yaşam döngüsünü doğrudan bildirmez. Bu nedenle Buds durum kanalı önemlidir. Eski IOBluetooth bağlantı bilgisinin yanlış negatif verdiği gözlendiğinden, uygulama erişilebilir Bluetooth CoreAudio çıkışıyla bağlantı durumunu çapraz kontrol eder.

## Bağlantı ömrü ve enerji

Kontrol kanalı kullanıcı işlemi, Mac ses kullanımı ve gözlenen arama için tutulur. Mac ses cihazı çalışmıyorsa ve arama yoksa 20 saniyelik tek seferlik boşta kapanma planlanır. CoreAudio/Bluetooth olayları ve kullanıcı komutları kanalı yeniden açabilir; düzenli durum sorgulama döngüsü yoktur. Sorgu, yazma, ilk bağlantı ve hata kurtarma işlemleri yine radyo trafiği üretir.

RFCOMM kanalının açık olması radyonun sürekli tam etkin kaldığını kanıtlamaz. Bluetooth Classic, bağlantıyı koruyarak belirli aralıklarda dinlemeyi sağlayan sniff kipini tanımlar; bunun kullanımı iki uçtaki bağlantı yönetimine bağlıdır. BudsBridge macOS denetleyicisinin bu politikasını zorlamaz. [Bluetooth Core belirtimi](https://www.bluetooth.com/wp-content/uploads/Files/Specification/HTML/Core-54/out/en/br-edr-controller/link-manager-protocol-specification.html).

Samsung tarafında kontrol plugininin normal SPP’yi, Android Bluetooth sisteminin ise SMEP’yi ayrı yönettiği gözlendi. Plugin mesajlarını kullanmak, Samsung’un ayrıcalıklı sistem entegrasyonunun ve güç politikasının tamamını Mac’e taşımak anlamına gelmez. Eşit pil ömrü iddiası için karşılaştırmalı ölçüm gerekir.

## WidgetKit veri paylaşımı

Host uygulama `BudsWidgetSnapshot` verisini kendi `dev.budsbridge.mac` tercih alanında saklar. Snapshot yalnız pil değerleri, gürültü modu, bağlantı/arama işaretleri ve güncelleme zamanından oluşur. Widget kendi Bluetooth oturumunu açmaz.

Mevcut yerel dağıtımda widget sandbox’ı, uygulamanın bu tercih alanına salt okunur geçici entitlement ile erişir. Apple imzalama kimliği ve App Group provisioning kullanılan bir dağıtım henüz hazırlanmadı. Mevcut ad hoc paketle widget’ın yerel olarak çalışması ve pil verisini alması doğrulandı; farklı Mac’lerde dağıtım uyumluluğu ayrıca test edilmelidir.

Uygulama anlamlı snapshot değişimlerinde WidgetKit yenilemesi ister; uzantının timeline politikası `.never`dır. Güncellemelerin anlık geleceği veya uygulama kapalıyken verilerin güncel kalacağı garanti edilmez. Gerçek galeride görünme, masaüstüne ekleme, widget host yaşam döngüsü ve kulaklıktan gelen pil snapshot’ının uzantıda okunması yerel olarak doğrulandı.

Manuel derlenen uzantının sistem tarafından doğru başlatılabilmesi için linker giriş noktası `NSExtensionMain` olarak seçilir; yalnız uzantının kaydolması yeterli değildir. Bu giriş noktası düzeltmesi mevcut build scriptine dahildir. Kontrol, gerçek widget sunucusunun descriptor/timeline çağrıları ve kullanıcı tarafından eklenen widget ile tamamlandı.

## Kaynak yerleşimi ve doğrulama

| Yol | İçerik |
| --- | --- |
| `macOS/Sources/BridgeCore` | Saf protokol ayrıştırma, CRC, dönüş politikası ve widget veri modeli |
| `macOS/Sources/BudsBridge` | AppKit/SwiftUI arayüzü, IOBluetooth kanalları ve CoreAudio yönetimi |
| `macOS/Widget` | Gerçek küçük WidgetKit uzantısı, plist ve sandbox entitlement’ları |
| `macOS/Tests/BridgeCoreTests` | Donanımdan bağımsız protokol/politika kontrolleri |
| `scripts` | SDK seçimi, test ve `.app`/`.appex` paketleme |

Testler protokol doğruluğu için regresyon kontrolüdür. Kulaklık firmware davranışı, telefon önceliği, radyo enerji tüketimi, ses uygulamasının oynatmaya devam etmesi ve WidgetKit görünümü ayrı uçtan uca doğrulamalar gerektirir.
