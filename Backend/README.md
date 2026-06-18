# AquaSense Backend

Node.js backend untuk sistem monitoring akuakultur AquaSense.
Stack: **Express (Hono)** + **MQTT** + **Supabase**

---

## 📁 Struktur Project

```
aquasense-backend/
├── src/
│   ├── index.js                  ← Entry point (Hono + MQTT)
│   ├── db/
│   │   └── supabase.js           ← Supabase client
│   ├── mqtt/
│   │   └── mqttClient.js         ← Subscribe & proses data ESP32
│   │                                + publish command ke ESP32
│   ├── services/
│   │   ├── thresholds.js         ← Konstanta threshold (sinkron config.h)
│   │   └── alertService.js       ← Auto-alert engine
│   └── routes/
│       ├── sensors.js            ← GET /api/sensors/*
│       ├── alerts.js             ← GET/PATCH /api/alerts/*
│       ├── feeding.js            ← GET/POST /api/feeding
│       └── stirrer.js            ← POST /api/stirrer/schedule|manual  ← BARU
├── scripts/
│   └── dummy-publish.js          ← Simulasi ESP32 (test backend)
├── supabase_schema.sql           ← Schema tabel Supabase
├── .env.example
└── package.json
```

---

## ⚙️ Setup

### 1. Clone & Install

```bash
cd aquasense-backend
npm install
```

### 2. Konfigurasi .env

```env
SUPABASE_URL=https://xxxx.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGci...
MQTT_BROKER_URL=mqtts://xxxx.hivemq.cloud:8883
MQTT_USERNAME=AquaSense
MQTT_PASSWORD=yourpassword
MQTT_CLIENT_ID=BackendAquaSense
PORT=3000
```

### 3. Setup Supabase

Buka **Supabase → SQL Editor**, jalankan `supabase_schema.sql`.

> Jika tabel `sensor_readings` **sudah ada**, jalankan hanya bagian MIGRASI
> (bagian ALTER TABLE di dalam komentar schema) untuk menambah kolom stirrer.

### 4. Jalankan Backend

```bash
npm run dev     # development (nodemon)
npm start       # production
```

---

## 📡 MQTT Topics

### ESP32 → Backend (Subscribe)

| Topic | Deskripsi |
|-------|-----------|
| `aquasense/{device_id}/sensors` | Data semua sensor + stirrer status |
| `aquasense/{device_id}/feeding` | Event feeding dari ESP32 |

**Payload `sensors` (terbaru):**
```json
{
  "temperature":        27.50,
  "ph":                 7.20,
  "turbidity_raw":      1200,
  "feed_sensor_ok":     true,
  "feed_level_pct":     65.3,
  "feed_distance_mm":   450,
  "stir_interval_min":  30,
  "stir_duration_sec":  10,
  "stir_running":       false,
  "stir_last_direction": 0,
  "stir_next_run_ms":   1234567,
  "rssi":               -65,
  "uptime_ms":          123456
}
```

### Backend → ESP32 (Publish)

| Topic | Deskripsi |
|-------|-----------|
| `aquasense/{device_id}/command/feed` | Perintah buka gate pakan |
| `aquasense/{device_id}/command/stir` | Update jadwal / kontrol manual stirrer |

**Payload `command/feed`:**
```json
{ "duration_sec": 5 }
```

**Payload `command/stir` — mode jadwal:**
```json
{ "mode": "schedule", "interval_min": 30, "duration_sec": 10 }
```

**Payload `command/stir` — mode manual:**
```json
{ "mode": "manual", "action": "on" }
{ "mode": "manual", "action": "off" }
```

---

## 🌐 REST API Endpoints

### Sensor Data

| Method | Endpoint | Deskripsi |
|--------|----------|-----------|
| GET | `/api/sensors/latest` | Data terbaru per device (termasuk stirrer status) |
| GET | `/api/sensors/history?device_id=&limit=50` | Riwayat pembacaan |
| GET | `/api/sensors/stats?period=24h` | Statistik min/max/avg + stirrer config |

### Alerts

| Method | Endpoint | Deskripsi |
|--------|----------|-----------|
| GET | `/api/alerts?resolved=false` | Daftar alert aktif |
| PATCH | `/api/alerts/:id/resolve` | Resolve alert manual |

### Feeding

| Method | Endpoint | Deskripsi |
|--------|----------|-----------|
| GET | `/api/feeding` | Riwayat feeding |
| POST | `/api/feeding` | Trigger feeding manual (publish MQTT → ESP32) |

### Stirrer ← BARU

| Method | Endpoint | Deskripsi |
|--------|----------|-----------|
| POST | `/api/stirrer/schedule` | Update jadwal pengadukan |
| POST | `/api/stirrer/manual` | Kontrol ON/OFF manual |

**Body `POST /api/stirrer/schedule`:**
```json
{
  "device_id":    "ESP32-DEVKIT-01",
  "interval_min": 30,
  "duration_sec": 10
}
```

**Body `POST /api/stirrer/manual`:**
```json
{
  "device_id": "ESP32-DEVKIT-01",
  "action":    "on"
}
```

### Health Check

```
GET /health
```

---

## 🚨 Auto Alert System

| Sensor | Kondisi | Severity |
|--------|---------|----------|
| Temperature | < 25°C atau > 30°C | warning |
| Temperature | sensor error (-999) | danger |
| pH | < 6.5 | warning |
| pH | > 8.5 | danger |
| pH | sensor error | danger |
| Turbidity | ADC 801–899 | warning |
| Turbidity | ADC ≤ 800 | danger |
| Turbidity | ADC ≥ 2100 | warning (too_clear) |
| Feed Level | ≤ 25% | warning |
| Feed Level | ≤ 10% | warning (critical) |
| Feed Level | 0% | danger (empty) |

Alert tidak duplikat dalam 10 menit untuk kondisi yang sama.

---

## 🧪 Test dengan Dummy Publisher

```bash
# Kirim satu payload (verifikasi cepat)
node scripts/dummy-publish.js --once

# Loop setiap 3 detik, 10 kali
node scripts/dummy-publish.js --count 10 --interval 3000

# Loop terus + sertakan feeding event setiap 30 detik
node scripts/dummy-publish.js --include-feeding

# Ganti device ID
node scripts/dummy-publish.js --device-id ESP32-DEVKIT-02
```
