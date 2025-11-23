# Alpine Linux Termux Yükleyici

Türkçe | [English](README.md)

Termux için otomatik Alpine Linux kurulum scripti (root gerektirmez).

## Özellikler

- Termux üzerinde otomatik Alpine Linux kurulumu
- Root erişimi gerektirmez
- PRoot kullanır (proot-distro kullanmaz)
- Birden fazla Alpine Linux sürümünü destekler
- Otomatik sürüm algılama ve seçimi
- Sudo yetkilerine sahip kullanıcı oluşturma
- Otomatik başlatma seçeneği
- Pipe kurulum desteği

## Desteklenen Mimariler

- ARM64 (aarch64)
- ARMv7
- x86_64
- x86

## Kurulum

### Yöntem 1: Tek Komutla Otomatik Kurulum

```bash
curl -fsSL https://raw.githubusercontent.com/ozbilgic/install-alpine-on-termux/main/alpine-installer.sh | bash
```


### Yöntem 2: Doğrudan Kurulum

```bash
bash alpine-installer.sh
```


## Kullanım

1. Kurulum scriptini çalıştırın:
   ```bash
   bash alpine-installer.sh
   ```

2. Ekrandaki talimatları izleyin:
   - Alpine Linux sürümünü seçin (en son 4 sürüm mevcut)
   - Otomatik başlatmayı etkinleştirip etkinleştirmeyeceğinizi seçin
   - Alpine'ı hemen başlatıp başlatmayacağınıza karar verin

3. Alpine'a ilk girişte kurulum scriptini çalıştırın:
   ```bash
   sh /root/first-setup.sh
   ```

4. İlk kurulum şunları yapacaktır:
   - Paket listelerini güncelleyecek
   - Temel paketleri yükleyecek (nano, vim, wget, curl, git, sudo, bash)
   - Sudo yetkilerine sahip root olmayan bir kullanıcı oluşturma seçeneği sunacak

## Alpine Linux'u Başlatma

Otomatik başlatmayı etkinleştirmediyseniz, Alpine Linux'u manuel olarak başlatabilirsiniz:

```bash
./start-alpine.sh
```

## Otomatik Başlatma

Otomatik başlatmayı etkinleştirdiyseniz, Alpine Linux her Termux açışınızda otomatik olarak başlayacaktır.

Otomatik başlatmayı devre dışı bırakmak için:
```bash
nano ~/.bashrc
# Dosyanın sonundaki Alpine Linux otomatik başlatma bölümünü silin
```

## Alpine Linux'tan Çıkış

Alpine Linux'tan çıkıp Termux'a dönmek için:
```bash
exit
```

## Yeniden Kurulum

Alpine Linux'u yeniden kurmak isterseniz:

1. Mevcut kurulumu kaldırın:
   ```bash
   rm -rf ~/alpine-fs
   ```

2. Yükleyiciyi tekrar çalıştırın:
   ```bash
   bash alpine-installer.sh
   ```

## Neler Yüklenir

- Alpine Linux minirootfs (minimal kurulum)
- Temel paketler: nano, vim, wget, curl, git, sudo, bash, shadow
- DNS yapılandırması (Google DNS: 8.8.8.8, 8.8.4.4)
- Alpine çalıştırmak için PRoot ortamı

## Dizin Yapısı

```
$HOME/
├── alpine-fs/           # Alpine Linux kök dosya sistemi
└── start-alpine.sh      # Başlatma scripti
```

## Sorun Giderme

### wget çalışmıyor
Termux'u tamamen kapatın, yeniden açın ve scripti tekrar çalıştırın.

### İndirme başarısız oluyor
Seçilen sürüm indirilemezse, script otomatik olarak alternatif Alpine Linux sürümleri sunacaktır.

### Çıkarma başarısız oluyor
Çıkarma başarısız olursa, script tar dosyasını doğrulayacak ve yeniden indirecektir.

### Paket kurulum sorunları
Termux paketlerini güncelleyin:
```bash
pkg update -y
pkg upgrade -y
```

## Alpine Linux vs Ubuntu

Alpine Linux:
- Ubuntu'dan çok daha hafif ve hızlıdır
- Daha az depolama alanı kullanır
- `apt` yerine `apk` paket yöneticisi kullanır
- systemd yerine OpenRC kullanır
- Minimal kurulumlar ve konteynerler için idealdir

## Lisans

MIT License

## Katkıda Bulunma

Katkılarınızı bekliyoruz! Lütfen Pull Request göndermekten çekinmeyin.
