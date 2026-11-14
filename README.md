# AquaSense

**Sistem monitoring dan otomasi budidaya ikan air tawar berbasis IoT.**

AquaSense membaca parameter air kolam secara real-time, mengontrol pemberian
pakan dan pengadukan secara otomatis, mengirim peringatan saat kondisi air
keluar dari batas aman, dan menyediakan asisten AI yang bisa ditanya soal
kondisi kolam maupun budidaya ikan air tawar.

---

## Fitur Utama

- **Monitoring real-time** — suhu air, pH, kekeruhan (turbidity), dan level
  pakan dibaca terus-menerus dan dikirim ke server.
- **Auto feeder** — pakan diberikan otomatis sesuai jadwal, atau manual dari
  aplikasi. Level pakan di wadah dipantau pakai sensor jarak.
- **Pengadukan pakan & mixer** — motor pengaduk dan mixer/aerator bisa
  dijadwalkan (interval + durasi) atau dikontrol manual.
- **Sistem peringatan** — server mengevaluasi setiap pembacaan terhadap ambang
  batas, membuat alert, dan menandainya selesai setelah ditangani.
- **AquaBot (asisten AI)** — chat asisten perikanan yang menjawab dengan
  konteks data sensor kolam saat itu juga.
- **Notifikasi WhatsApp** — peringatan kondisi kritis dikirim ke WhatsApp.
- **Aplikasi mobile** — dashboard, monitoring, feeding, riwayat, dan pengaturan
  dalam satu aplikasi Flutter.

---

## Arsitektur

```
  ┌──────────────┐        MQTT         ┌────────────────────┐
  │   ESP32      │ ──────────────────► │  Backend (Hono)    │
  │  (sensor +   │  aquasense/{id}/    │  Node.js           │
  │   aktuator)  │      sensors        │                    │
  │              │ ◄────────────────── │  ┌──────────────┐  │
  │ DS18B20      │  aquasense/{id}/    │  │ MQTT Client  │  │
  │ Turbidity    │   command/feed      │  └──────────────┘  │
  │ pH           │   command/mixer     │  ┌──────────────┐  │
  │ VL53L0X      │   command/stir      │  │ REST API     │  │
  │ Servo feeder │                     │  └──────────────┘  │
  └──────────────┘                     │  ┌──────────────┐  │
                                       │  │ AquaBot (AI) │──┼──► Groq API
                                       │  └──────────────┘  │
                                       │  ┌──────────────┐  │
                                       │  │ WhatsApp Bot │  │
                                       │  └──────────────┘  │
                                       └─────────┬──────────┘
                                                 │
                                        ┌────────▼────────┐
                                        │    Supabase     │
                                        │  (PostgreSQL)   │
                                        └────────┬────────┘
                                                 │
                                        ┌────────▼────────┐
                                        │  Flutter App    │
                                        │  (Android)      │
                                        └─────────────────┘
```

Alur singkat:

1. ESP32 membaca sensor → publish ke `aquasense/{device_id}/sensors`.
2. Backend menerima, menyimpan ke Supabase, dan mengevaluasi ambang batas.
3. Kalau ada parameter di luar batas → alert dibuat + notifikasi WhatsApp.
4. Aplikasi Flutter membaca data dari Supabase dan REST API backend.
5. Perintah dari aplikasi (pakan, mixer, pengaduk) dikirim lewat MQTT ke ESP32.

---

## Hardware

| Komponen | Fungsi | Pin (ESP32) |
|---|---|---|
| ESP32 DevKit v1 | Mikrokontroler utama | — |
| DS18B20 | Suhu air | GPIO 4 (OneWire) |
| Sensor turbidity | Kekeruhan air | GPIO 35 (ADC) |
| Sensor pH | Keasaman air | GPIO 32 (ADC) |
| VL53L0X (ToF) | Level pakan di wadah | I2C — SDA 21 / SCL 22 |
| Servo | Pembuka pakan (feeder) | sesuai konfigurasi |
| Motor + driver | Pengaduk pakan & mixer | via aktuator |

Catatan pemrosesan di sisi ESP32:

- Pembacaan sensor difilter pakai **EMA (exponential moving average)** supaya
  nilainya tidak goyang.
- Ada **edge anomaly detection** untuk suhu — lonjakan di luar toleransi
  diabaikan supaya tidak memicu alert palsu.
- Jadwal pengadukan disimpan di **NVS (Preferences)**, jadi tetap tersimpan
  setelah perangkat restart.

---

## Struktur Repositori

```
AquaSense/
├── Backend/                  # Server Node.js
│   ├── src/
│   │   ├── bot/              # Bot WhatsApp & bot alert
│   │   ├── db/               # Koneksi Supabase
│   │   ├── knowledge/        # Basis pengetahuan budidaya ikan
│   │   ├── mqtt/             # MQTT client (subscribe & publish)
│   │   ├── routes/           # Endpoint REST
│   │   ├── services/         # AI, alert, ambang batas
│   │   └── index.js          # Entry point server
│   ├── supabase/             # Konfigurasi & migrasi Supabase
│   └── supabase_schema.sql   # Skema database lengkap
│
├── ESP32/                    # Firmware (PlatformIO)
│   ├── include/
│   │   ├── config.h          # Pin, ambang batas, interval pembacaan
│   │   └── secrets.h         # Kredensial WiFi & MQTT (tidak di-commit)
│   ├── src/main.cpp          # Program utama
│   └── platformio.ini        # Konfigurasi board & library
│
└── aquasense_frontend/       # Aplikasi mobile Flutter
    ├── lib/
    │   ├── features/         # dashboard, monitoring, feeding, history, settings
    │   ├── shared/           # services & widget bersama
    │   └── main.dart
    └── pubspec.yaml
```

---

## Teknologi

| Lapisan | Teknologi |
|---|---|
| Firmware | ESP32, Arduino framework, PlatformIO |
| Library ESP32 | OneWire, DallasTemperature, VL53L0X, ArduinoJson, PubSubClient, ESP32Servo |
| Backend | Node.js, Hono, MQTT (mqtt.js) |
| Basis data | Supabase (PostgreSQL) |
| AI | Groq API — `llama-3.1-8b-instant` |
| Notifikasi | WhatsApp (Baileys) |
| Mobile | Flutter, Provider, fl_chart, supabase_flutter, flutter_local_notifications |

---

## Instalasi

### 1. Backend

```bash
cd Backend
npm install
cp .env.example .env   # lalu isi kredensial
node src/index.js
```

Server jalan di `http://localhost:3000` (atau sesuai `PORT`).
Cek cepat: `GET /health`.

### 2. ESP32

```bash
cd ESP32
pio run            # build
pio run -t upload  # flash ke board
pio device monitor # lihat log serial (9600 baud)
```

Siapkan `include/secrets.h` lebih dulu (lihat bagian Konfigurasi).

### 3. Aplikasi Flutter

```bash
cd aquasense_frontend
flutter pub get
flutter run
```

Buat file `.env` di root folder Flutter berisi kredensial Supabase
(URL project dan anon key), karena `.env` didaftarkan sebagai asset
di `pubspec.yaml`.

---

## Konfigurasi

### Backend — `.env`

| Variabel | Keterangan |
|---|---|
| `SUPABASE_URL` | URL project Supabase |
| `SUPABASE_SERVICE_ROLE_KEY` | Service role key (akses server) |
| `MQTT_BROKER_URL` | Alamat broker MQTT |
| `MQTT_USERNAME` | Username broker MQTT |
| `MQTT_PASSWORD` | Password broker MQTT |
| `MQTT_CLIENT_ID` | Client ID backend (default: `aquasense-backend`) |
| `GROQ_API_KEY` | API key Groq untuk AquaBot |
| `TEMP_MIN` / `TEMP_MAX` | Ambang suhu yang dipakai backend |
| `PORT` | Port server (default: `3000`) |

### ESP32 — `include/secrets.h`

| Define | Keterangan |
|---|---|
| `WIFI_SSID` / `WIFI_PASSWORD` | Kredensial WiFi |
| `MQTT_BROKER` | Alamat broker MQTT |
| `MQTT_PORT` | Port broker |
| `MQTT_USERNAME` / `MQTT_PASSWORD` | Kredensial MQTT |
| `MQTT_DEVICE_ID` | ID perangkat (default: `ESP32-DEVKIT-01`) |

> `secrets.h` sudah masuk `.gitignore` — jangan pernah commit kredensial.

---

## MQTT Topics

| Topic | Arah | Isi |
|---|---|---|
| `aquasense/{device_id}/sensors` | ESP32 → Backend | Suhu, pH, turbidity, level pakan |
| `aquasense/{device_id}/feeding` | ESP32 → Backend | Konfirmasi pemberian pakan |
| `aquasense/{device_id}/command/feed` | Backend → ESP32 | Perintah pakan (durasi, trigger) |
| `aquasense/{device_id}/command/mixer` | Backend → ESP32 | Perintah mixer on/off |
| `aquasense/{device_id}/command/mixer_schedules` | Backend → ESP32 | Daftar jadwal mixer |
| `aquasense/{device_id}/command/stir` | Backend → ESP32 | Perintah pengaduk (manual / jadwal) |

---

## API Endpoints

| Method | Endpoint | Fungsi |
|---|---|---|
| `GET` | `/health` | Cek status server |
| `GET` | `/api/sensors/latest` | Pembacaan sensor terbaru |
| `GET` | `/api/sensors/history` | Riwayat pembacaan sensor |
| `GET` | `/api/sensors/stats` | Statistik ringkas sensor |
| `GET` | `/api/alerts` | Daftar alert |
| `PATCH` | `/api/alerts/:id/resolve` | Tandai alert selesai |
| `GET` | `/api/feeding` | Riwayat pemberian pakan |
| `POST` | `/api/feeding` | Kirim perintah pakan |
| `GET` | `/api/mixer/status` | Status mixer saat ini |
| `POST` | `/api/mixer/control` | Kontrol mixer on/off |
| `GET` | `/api/mixer/schedules` | Daftar jadwal mixer |
| `POST` | `/api/mixer/schedules` | Tambah jadwal mixer |
| `PATCH` | `/api/mixer/schedules/:id` | Ubah jadwal mixer |
| `DELETE` | `/api/mixer/schedules/:id` | Hapus jadwal mixer |
| `POST` | `/api/stirrer/schedule` | Set jadwal pengaduk |
| `POST` | `/api/stirrer/manual` | Kontrol pengaduk manual |

---

## Skema Database

Skema lengkap ada di `Backend/supabase_schema.sql`.

| Tabel / View | Isi |
|---|---|
| `sensor_readings` | Seluruh pembacaan sensor yang masuk |
| `latest_readings` (view) | Pembacaan terbaru per perangkat |
| `alerts` | Peringatan beserta status penyelesaian |
| `feeding_logs` | Riwayat pemberian pakan |
| `mixer_schedules` | Jadwal mixer |
| `mixer_status` | Status mixer terkini |
| `feeder_status` | Status wadah pakan |

---

## AquaBot

AquaBot adalah asisten AI yang menjawab pertanyaan seputar kolam dan budidaya
ikan air tawar. Cara kerjanya:

- Basis pengetahuan berisi panduan budidaya **nila, patin, dan lele** —
  parameter air optimal, kepadatan tebar, frekuensi pakan, penyakit umum,
  tanda ikan stres, tindakan darurat, dan jadwal perawatan kolam.
- Sumber acuan yang dipakai: **SNI 7550:2009, FAO, Boyd (1990), Zonneveld (1991)**.
- Setiap pertanyaan digabung dengan **data sensor kolam real-time** dan tren
  10 pembacaan terakhir, jadi jawabannya menyesuaikan kondisi kolam pengguna —
  bukan jawaban umum.
- Model: `llama-3.1-8b-instant` lewat Groq API.

---

## Kontributor

| GitHub | Nama |
|---|---|
| [@nifnip22](https://github.com/nifnip22) | Hanif Ahmad |
| [@OkeaHas](https://github.com/OkeaHas) | RenggaX |

---

## Lisensi

Belum ditetapkan.

---

<details>
<summary><b>English Overview</b></summary>

**AquaSense** is an IoT system for freshwater fish farming that monitors pond
parameters in real time and automates feeding and mixing.

- **Sensing:** an ESP32 reads water temperature (DS18B20), pH, turbidity, and
  feed level (VL53L0X time-of-flight), applying EMA filtering and temperature
  spike rejection before publishing.
- **Transport:** MQTT, with sensor data flowing up and control commands
  (feed / mixer / stir) flowing back down per device.
- **Backend:** Node.js with Hono, MQTT client, and Supabase (PostgreSQL).
  It stores readings, evaluates thresholds, raises and resolves alerts, and
  exposes a REST API.
- **AquaBot:** an AI assistant powered by Groq (`llama-3.1-8b-instant`) that
  answers fish-farming questions using a knowledge base drawn from
  SNI 7550:2009, FAO, Boyd (1990), and Zonneveld (1991) — combined with the
  pond's live sensor readings.
- **Notifications:** critical conditions are pushed to WhatsApp.
- **Mobile app:** Flutter (Provider, fl_chart, supabase_flutter) with
  dashboard, monitoring, feeding, history, and settings screens.

</details>
