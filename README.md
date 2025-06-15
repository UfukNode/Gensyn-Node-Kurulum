![GnyTCGSXsAAGwvK](https://github.com/user-attachments/assets/bd204cd5-7683-4366-8cc8-42738fb58838)

# Gensyn GPU Node Kurulum Rehberi

Bu rehber, Gensyn RL Swarm projesinde GPU ile (örn. RTX 3090/4090) ile testnete katılmanızı sağlar. Ubuntu kurulumuna göre daha maliyetli olsa da, kurulum adımları daha az sorunludur ve performans çok daha yüksektir.

---

## Genel Bilgiler

| Özellik                 | Açıklama                                  |
| ----------------------- | ----------------------------------------- |
| Platform                | [gensyn.ai](https://gensyn.ai)            |
| Kurulum Tipi            | GPU Üzerinde                              |
| Önerilen GPU            | RTX 3090 veya 4090                       |
| Gereken İşletim Sistemi | Vast.ai üzerinde hazır template (Jupyter) |

---

## 1. Vast.ai Üzerinden Sunucu Kiralama:

🔗 [Kayıt ve Giriş](https://cloud.vast.ai/?ref_id=222215)
- Sağ üstten **Login** butonuna tıklayarak kayıt ol.
- Sol menüden **Billing** > **Add Credit** yolunu izleyerek bakiye yükle (Base ağı üzerinden).

---

## 2. Template Seçimi:

- Sol menüden **Templates** kısmına gel.
- **NVIDIA CUDA** template’ini seç.
- GPU bölümünden **RTX 3090** ile **RTX 4090** arasında seçim yap.
- **Disk Space**: 75-100 GB arası gir.
- **Max Duration**: 2 ay üzeri seçmeye çalış.

![1 (1)](https://github.com/user-attachments/assets/a27c1a8b-5262-40a4-a081-d4a9392b3622)

---

## 3. Terminale Giriş:

- Sol menüdeki **Instances** sekmesine git.
- Kiraladığın sunucunun sağında bulunan **terminal** ikonuna tıkla.
- **Open Jupyter Terminal** seçeneğine tıkla.

![1 (1)](https://github.com/user-attachments/assets/c1276b17-1db6-4a02-add0-615c55d29cdb)

---

## 4. Gerekli Paketlerin Kurulumu:

```bash
cd $HOME
sudo apt-get update && sudo apt-get upgrade -y
sudo apt install screen curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip -y
```

---

## 5. Python & Node.js Kurulumu:

```bash
sudo apt install -y python3 python3-pip python3.10-venv
```
```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
sudo npm install -g yarn
```

---

## 6. Repoyu Klonla ve Güncelle:

```bash
git clone https://github.com/gensyn-ai/rl-swarm.git && cd rl-swarm
```
```bash
git pull
```

---

## RTX 3060 Cihazda b-15 Modelini Çalıştırmak İçin Ayarlar (Opsiyonel):

### A- Ayarlara Git:
```bash
nano hivemind_exp/configs/gpu/grpo-qwen-2.5-1.5b-deepseek-r1.yaml
```
📌 CTRL + K yaparak tüm sayfayı temizle ve aşağıdaki ayarları yapıştır.

### B- Aşağıdaki Optimize Edilmiş Ayarları Gir:
```bash
# Model arguments
model_revision: main
torch_dtype: float16
attn_implementation: flash_attention_2
bf16: false
tf32: true

# Dataset arguments
dataset_id_or_path: 'openai/gsm8k'

# Training arguments
max_steps: 10 # Original 450
num_train_epochs: 1
gradient_accumulation_steps: 1
gradient_checkpointing: true
gradient_checkpointing_kwargs:
  use_reentrant: false
learning_rate: 5.0e-7 # 1.0e-6 as in the deepseek math paper 5-e7 from https://hijkzzz.notion.site/unraveling-rlhf-and-its-variants-engineering-insights#147d9a33ecc98>
lr_scheduler_type: cosine
warmup_ratio: 0.03

# GRPO arguments
use_vllm: false
num_generations: 2
per_device_train_batch_size: 1
beta: 0.001 # 0.04 as in the deepseek math paper 0.001 from https://hijkzzz.notion.site/unraveling-rlhf-and-its-variants-engineering-insights#147d9a33ecc9806090f3d5c7>
max_prompt_length: 64
max_completion_length: 128

# Logging arguments
logging_strategy: steps
logging_steps: 2
report_to:
- wandb
save_strategy: "steps"
save_steps: 25
seed: 42

# Script arguments
public_maddr: "/ip4/38.101.215.12/tcp/30002"
host_maddr: "/ip4/0.0.0.0/tcp/38331"
max_rounds: 10000

# Model-specific arguments
model_name_or_path: Gensyn/Qwen2.5-1.5B-Instruct
output_dir: runs/gsm8k/multinode/Qwen2.5-1.5B-Instruct-Gensyn-Swarm
```
- Bu ayarları daha düşük cihazlarda çalıştırarak maliyet düşürebilirsiniz.

---

## 7. RL Swarm Node Kurulumu
```bash
screen -S swarm
```
```bash
python3 -m venv .venv
source .venv/bin/activate
```
```bash
cd
cd rl-swarm
```
```bash
./run_rl_swarm.sh
```

Soru geldiğinde **Y** tuşuna basarak devam edin.

![image](https://github.com/user-attachments/assets/8a9e8b42-ec6d-401a-8348-78cd8bce4bfe)

---

## 8. Model Seçimi (Swarm ve Parametre Ayarı):

Kurulum sırasında aşağıdaki seçenekler gelecektir:

```
Which swarm do you want to join?
a) Math
b) Math Hard
```

| Seçenek | Açıklama                                  |
| ------- | ----------------------------------------- |
| a       | Düşük GPU’lar için (3090 ve altı)         |
| b       | Güçlü GPU’lar için (3090, 4090, A100 vb.) |

Devamında model boyutunu girin:

| GPU           | Önerilen Parametre |
| ------------- | ------------------ |
| RTX 3070/3090 | 0.5                |
| RTX 4090 | 1.5                |

Model seçimi yaptıktan ve aşağıdaki gibi çıktı geldikten sonra Screen’den çıkıp adımlara devam etmek için:

![image](https://github.com/user-attachments/assets/6eaa2542-e6f3-4869-a448-dc266fd62de0)

```bash
CTRL + A ardından D
```

---

## 9. Ngrok Kurulumu ve Yetkilendirme:

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

![1 (1)](https://github.com/user-attachments/assets/20f5445b-a89a-43d9-96ef-2e264fd0e2f4)

---

## 10. Testnet Login:

```bash
ngrok http 3000
```

- “Forwarding” linkini kopyalayıp tarayıcıya yapıştırın
- Google hesabınızla giriş yapın

![Adsız tasarım](https://github.com/user-attachments/assets/3b833995-1a06-473c-be2e-e7cba7236730)

---

## ⚠️ Login Sorunu Yaşarsanız:

Login modal’ı açılmıyorsa aşağıdaki komutu uygulayın:

```bash
sed -i '/return (\s*$/i\
\n  useEffect(() => {\n    if (!user && !signerStatus.isInitializing) {\n      openAuthModal(); \n    }\n  }, [user, signerStatus.isInitializing]);\n' modal-login/app/page.tsx
```

## 11. Soruya Yanıt Ver:

```bash
screen -r swarm
```
- Yüklemeler tamamlandıktan sonra çıkan soruya **N** yanıtını verin.

![image](https://github.com/user-attachments/assets/8423608b-eb4b-49cd-9f5c-52d11e7d6307)

---

## ✅ Peer ID ve Kullanıcı Adı:
Eğer node’unuz başarıyla ağa katılır ve ilk eğitim görevine başlarsa, sistem sizin için otomatik olarak bir Peer ID ve Kullanıcı Adı verir. Onları sıralamanızı ve takip için bir yere kopyalayabilirsiniz.
Aşağıdaki çıktıdaki gibi:

![Adsız tasarım](https://github.com/user-attachments/assets/9e304df6-a27f-4988-ad49-f710662d85dc)

---

## 12 `swarm.pem` Dosyasını Kaydet (ÇOK ÖNEMLİ)

Bu dosya senin **node kimliğini temsil eder**. Özel bir anahtar gibi düşün. Eğer kaybedersen:

* Node’unu başka bir sunucuya taşıyamazsın.
* Her şeye **sıfırdan başlamak zorunda kalırsın**.

### `swarm.pem` Yedekleme (Vast.ai Üzerinden):

1. [https://cloud.vast.ai/?ref\_id=222215](https://cloud.vast.ai/?ref_id=222215) adresine git.
2. Sol menüden **Instances** sekmesine tıkla.
3. Sunucunun sağ alt köşesinde bulunan **küçük kutucuğa** tıkla.
4. Açılan pencere üzerinden şu yolu izle:
```
root > rl-swarm
```
5. `swarm.pem` dosyasını seç ve sağ üstten **Download** butonuna basarak bilgisayarına indir.

>  Bu dosyayı güvenli bir klasörde sakla. Silinirse kurtarılamaz. Başka bir sunucuya geçeceksen bu dosyayı oraya taşıman gerekir.

![GoMa3XZWwAAH7qO](https://github.com/user-attachments/assets/14082cea-cfde-433d-a6a9-5f9b3b8c45be)

---

## Screen Komutları

| Komut                 | Açıklama                         |
| --------------------- | -------------------------------- |
| `screen -r swarm`     | Screen’e tekrar giriş            |
| `CTRL + A ardından D` | Ekrandan çıkış                   |
| `screen -ls`          | Tüm screen oturumlarını gösterir |
| `screen -S <isim>`    | Yeni screen oluşturur            |

---

📊 Takip Paneli:

* Math Swarm: [https://dashboard-math.gensyn.ai](https://dashboard-math.gensyn.ai)
* Math Hard Swarm: [https://dashboard-math-hard.gensyn.ai](https://dashboard-math-hard.gensyn.ai)
* Telegram Bot: @gensynImpek_bot

![image](https://github.com/user-attachments/assets/77b31150-ff34-4a8a-916b-da1d29ad45f7)

---

## ✅ Tavsiyeler

* Her güncellemede node'u durdurup `git fetch origin && git reset --hard origin/main` komutunu çalıştırıp node'u güncelleyebilirsiniz.
* Sorun yaşarsanız `CTRL + C` ile durdurup `./run_rl_swarm.sh` ile tekrar başlatabilirsiniz.

---

Hazırlayan: [@UfukDegen](https://x.com/UfukDegen)
Sorularınız için bana ulaşabilirsiniz.

---
