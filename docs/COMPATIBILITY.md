# Uyumluluk

[README’ye dön](../README.md)

Galaxy Buds3 Pro, Galaxy S25+ ve Apple Silicon Mac ile gerçek telefon aramasında
sesin telefona geçmesi ve arama bitince Mac’e dönmesi doğrulandı. Bu sonuç diğer
telefonları, Buds modellerini veya tüm firmware sürümlerini kapsamaz.

| Bileşen | Durum |
| --- | --- |
| Hazır uygulama | Apple Silicon için arm64; ad-hoc imzalı. Developer ID ile imzalanmış ve noterlenmiş genel dağıtım değildir. |
| Intel Mac | Kaynaktan derleme mümkün olabilir; derleme ve çalışma doğrulanmadı. |
| Ana uygulama ve küçük WidgetKit widget’ı | macOS 14 veya sonrası gerekir. |
| Widget doğrulaması | Galeride görünmesi, kullanıcı tarafından masaüstüne eklenmesi ve gerçek kulaklık pil verisini göstermesi yerel kurulumda doğrulandı. Bu sonuç tüm Mac/macOS birleşimlerini kapsamaz. |

Cihaz algılama Bluetooth adına bağlıdır: listede görünmek için adında `buds`,
etkinleştirme ve kontrol komutları için `Buds3 Pro` bulunmalıdır.
Kulaklığın adı değiştirilirse listelenmeyebilir veya etkinleştirilemeyebilir.
Komutlar yalnızca Buds3 Pro adına sahip cihazlarda etkinleştirilir; diğer Buds
modelleri desteklenmez.

iPhone’da Buds3 Pro ile normal Bluetooth bağlantısı üzerinden müzik dinleme ve
arama yapma Samsung tarafından desteklenir; Buds3 Pro, Galaxy Buds iOS uygulaması
tarafından desteklenmez. [Samsung’un iOS uyumluluk açıklaması](https://www.samsung.com/us/support/answer/ANS10003617/)

BudsBridge ile Mac ve iPhone bağlantılarının aynı anda açık kalması, aramada
otomatik geçiş ve arama sonrası Mac’e dönüş test edilmedi; bu kullanım deneyseldir.
Samsung’un standart Auto Switch özelliği de iOS’ta sunulmaz.
[Samsung’un Auto Switch açıklaması](https://www.samsung.com/us/support/answer/ANS10002627/)

Uygulama Mac’e SSC/UHQ, 360 Ses veya canlı çeviri özelliklerini eklemez. İki
cihazın sesini aynı anda karıştırma/çalma özelliği de sunmaz.

Uzun süreli kulaklık ve telefon pil tüketimi ölçülmedi. Samsung’un kendi cihazları
arasındaki geçişiyle aynı pil tüketimi veya enerji verimliliği garanti edilmez.
