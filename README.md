# Gensyn GPU Node Kurulum Rehberi

Bu rehber, Gensyn RL Swarm projesinde GPU ile (örn. RTX 3090/4090) ile testnete katılmanızı sağlar. Ubuntu kurulumuna göre daha maliyetli olsa da, kurulum adımları daha az sorunludur ve performans çok daha yüksektir.

---

## Genel Bilgiler

| Özellik                 | Açıklama                                  |
| ----------------------- | ----------------------------------------- |
| Platform                | [gensyn.ai](https://gensyn.ai)            |
| Kurulum Tipi            | GPU Üzerinde                              |
| Önerilen GPU            | RTX 3090 veya üzeri                       |
| Gereken İşletim Sistemi | Vast.ai üzerinde hazır template (Jupyter) |

---

## 1. Vast.ai Üzerinden Sunucu Kiralama

🔗 [Kayıt ve Giriş](https://cloud.vast.ai/?ref_id=222215)
- Sağ üstten **Login** butonuna tıklayarak kayıt ol.
- Sol menüden **Billing** > **Add Credit** yolunu izleyerek bakiye yükle (Base ağı üzerinden).

---

## 2. Template Seçimi

- Sol menüden **Templates** kısmına gel.
- **NVIDIA CUDA** template’ini seç.
- GPU bölümünden **RTX 3090** ile **RTX 4090** arasında seçim yap.
- **Disk Space**: 75-100 GB arası gir.
- **Max Duration**: 2 ay üzeri seçmeye çalış.

---

## 3. Terminale Giriş

- Sol menüdeki **Instances** sekmesine git.
- Kiraladığın sunucunun sağında bulunan **terminal** ikonuna tıkla.
- **Open Jupyter Terminal** seçeneğine tıkla.

---

## 4. Gerekli Paketlerin Kurulumu

```bash
cd $HOME
sudo apt-get update && sudo apt-get upgrade -y
sudo apt install screen curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip -y
```

---

## 5. Python & Node.js Kurulumu

```bash
sudo apt install -y python3 python3-pip python3.10-venv

curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
sudo npm install -g yarn
```

---

## 6. RL Swarm Node Kurulumu

```bash
git clone https://github.com/gensyn-ai/rl-swarm.git && cd rl-swarm
```
```bash
git pull
```
```bash
screen -S swarm
```
```bash
python3 -m venv .venv
source .venv/bin/activate
```

```bash
cd modal-login/
yarn upgrade 
yarn add next@latest
yarn add viem@latest
```
```bash
cd ..
```
```bash
source .venv/bin/activate
./run_rl_swarm.sh
```

Soru geldiğinde **Y** tuşuna basarak devam edin.

---

## 7. Model Seçimi (Swarm ve Parametre Ayarı)

Kurulum sırasında aşağıdaki seçenekler gelecektir:

```
Which swarm do you want to join?
a) Math
b) Math Hard
```

| Seçenek | Açıklama                                  |
| ------- | ----------------------------------------- |
| a       | Düşük GPU’lar için (3070 ve altı)         |
| b       | Güçlü GPU’lar için (3090, 4090, A100 vb.) |

Devamında model boyutunu girin:

| GPU           | Önerilen Parametre |
| ------------- | ------------------ |
| RTX 3070/3090 | 0.5                |
| RTX 3090/4090 | 1.5                |

📊 Takip Paneli:

* Math Swarm: [https://dashboard-math.gensyn.ai](https://dashboard-math.gensyn.ai)
* Math Hard Swarm: [https://dashboard-math-hard.gensyn.ai](https://dashboard-math-hard.gensyn.ai)

Screen’den çıkmak için:

```bash
CTRL + A ardından D
```

---

## 8. Ngrok Kurulumu ve Yetkilendirme:

```bash
wget https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz
tar -xvzf ngrok-v3-stable-linux-amd64.tgz
mv ngrok /usr/local/bin/
```

- [Ngrok'a Git](https://ngrok.com)
- Hesap oluştur, ardından **Authtoken**’ı kopyalayıp terminale gir:

```bash
ngrok config add-authtoken <BURAYA_TOKEN>
```

---

## 9. Testnet Login:

```bash
ngrok http 3000
```

- “Forwarding” linkini kopyalayıp tarayıcıya yapıştırın
- Google hesabınızla giriş yapın

---

## 10. Login Sorunu Yaşarsanız:

Login modal’ı açılmıyorsa aşağıdaki komutu uygulayın:

```bash
sed -i '/return (\s*$/i\
\n  useEffect(() => {\n    if (!user && !signerStatus.isInitializing) {\n      openAuthModal(); \n    }\n  }, [user, signerStatus.isInitializing]);\n' modal-login/app/page.tsx
```

---

## 11. Screen Komutları

| Komut                 | Açıklama                         |
| --------------------- | -------------------------------- |
| `screen -r swarm`     | Screen’e tekrar giriş            |
| `CTRL + A ardından D` | Ekrandan çıkış                   |
| `screen -ls`          | Tüm screen oturumlarını gösterir |
| `screen -S <isim>`    | Yeni screen oluşturur            |

---

## 📌 Tavsiyeler

* Başlatmadan önce `git fetch origin && git reset --hard origin/main` ile güncelleyin.
* Sorun yaşarsanız `CTRL + C` ile durdurup `./run_rl_swarm.sh` ile tekrar başlatabilirsiniz.

---

Hazırlayan: [@UfukDegen](https://x.com/UfukDegen)
Sorularınız için bana ulaşabilirsiniz.

---
