## Zorunlu @gensynai Hatasız Yeni Güncelleme Adımları (RTX-3060)

RL-Swarm’un altyapısı değişti, artık sistem **GenRL** ile çalışıyor.

---

### GenRL'nin Farkı Nedir?

Önceden:
* Tüm worker’lar merkezden kontrol ediliyordu.

Şimdi:
* Her worker kendi başına çalışıyor.
* Ortak bir görev havuzuna katkı sağlıyor.
* Modelini bağımsız güncelliyor, kimseye bağlı değil.

Bu sistem:
* Daha hızlı
* Daha esnek
* Ve en önemlisi: tamamen merkeziyetsiz

---

### Yeni Sürümle Gelen Varsayılan Modeller

Yeni güncellemede şu modeller destekleniyor:

* `Gensyn/Qwen2.5-0.5B-Instruct`
* `Qwen/Qwen3-0.6B`
* `nvidia/AceInstruct-1.5B`
* `dnotitia/Smoothie-Qwen3-1.7B`
* `Gensyn/Qwen2.5-1.5B-Instruct`

Bu modeller, **Reasoning Gym** veri kümesi ile birlikte çok görevli akıl yürütme eğitiminde kullanılıyor.

---

### Yeni Sürüme Temiz Geçiş Rehberi

En sorunsuz yöntem: Eski kurulumu tamamen silip, baştan kurmak.

#### 1. Eski Sürümü Sil

```bash
cd
rm -rf rl-swarm .venv
```

#### 2. Yeni Sürümü Çek

```bash
git clone https://github.com/gensyn-ai/rl-swarm.git && cd rl-swarm
git pull
```

#### 3. Screen Oluştur (Eskisini sil, yenisini aç)

**a. Var olan screen'leri listele:**

```bash
screen -ls
```

**b. Kodla screen’i kapat:**

```bash
kill [screen-kodu]
```

**c. Yeni screen başlat:**

```bash
screen -S swarm
```

#### 4. Node’u Başlat

```bash
cd ~/rl-swarm
python3 -m venv .venv
source .venv/bin/activate
./run_rl_swarm.sh
```

#### 5. Giriş Yap (Login)

**a. Screen'den çık:**

```bash
ctrl + a + d
```

**b. Giriş için bağlantıyı al:**

```bash
ngrok http 3000
```

* “Forwarding” satırındaki linke tarayıcıdan gir
* Mail adresini girip onayla
* Terminale dön, `ctrl + c` ile çık
* Ardından tekrar screene dön:

```bash
screen -r swarm
```

#### 6. İlk Soruları Yanıtla

* İlk gelen soruya: `N` yaz
* Model seçim ekranında:

* Sisteminiz zayıfsa `Enter` yaparak varsayılan modeli seçin
* Sisteminiz güçlü ise aşağıdaki modellerden birini seçebilirsiniz:

```text
Gensyn/Qwen2.5-0.5B-Instruct
Qwen/Qwen3-0.6B
nvidia/AceInstruct-1.5B
dnotitia/Smoothie-Qwen3-1.7B
Gensyn/Qwen2.5-1.5B-Instruct
```

---

✅Başarılı örnek çıktı:

![image](https://github.com/user-attachments/assets/4269cf84-390f-474e-884d-8f07edcaec52)
