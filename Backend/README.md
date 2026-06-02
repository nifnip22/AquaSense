# AquaSense Backend

Node.js backend untuk sistem monitoring akuakultur AquaSense.
Stack: **Express** + **MQTT** + **Supabase**

---

## 📁 Struktur Project

```
aquasense-backend/
├── src/
│   ├── index.js                  ← Entry point (Express + MQTT)
│   ├── db/
│   │   └── supabase.js           ← Supabase client
│   ├── mqtt/
│   │   └── mqttClient.js         ← Subscribe & proses data ESP32
│   ├── services/
│   │   ├── thresholds.js         ← Konstanta threshold (sinkron config.h)
│   │   └── alertService.js       ← Auto-alert engine
│   └── routes/
│       ├── sensors.js            ← GET /api/sensors/*
│       ├── alerts.js             ← GET/PATCH /api/alerts/*
│       └── feeding.js            ← GET/POST /api/feeding
├── supabase_schema.sql           ← Schema tabel Supabase
├── .env.example                  ← Template environment variables
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

```bash
cp .env.example .env
```

Isi file `.env`:
```env
SUPABASE_URL=https://xxxx.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGci...
MQTT_BROKER_URL=mqtt://localhost:1883
PORT=3000
```

### 3. Setup Supabase

Buka **Supabase → SQL Editor**, jalankan `supabase_schema.sql`.

### 4. Setup MQTT Broker (Mosquitto lokal)

```bash
# Install Mosquitto
sudo apt install mosquitto mosquitto-clients

# Jalankan
sudo systemctl start mosquitto
```

Atau gunakan cloud broker:
- **HiveMQ**: `mqtt://broker.hivemq.com:1883`
- **EMQX**: `mqtt://broker.emqx.io:1883`

### 5. Jalankan Backend

```bash
npm run dev     # development (nodemon)
npm start       # production
```

---

## 📡 MQTT Topics

### ESP32 → Backend (Publish dari ESP32)

| Topic | Deskripsi |
|-------|-----------|
| `aquasense/{device_id}/sensors` | Data semua sensor |
| `aquasense/{device_id}/feeding` | Event feeding |

**Contoh payload `sensors`:**
```json
{
  "temperature": 27.5,
  "turbidity_ntu": 2400.0,
  "turbidity_volt": 2.140,
  "turbidity_raw": 2654,
  "moisture_pct": 62.3,
  "moisture_raw": 1820,
  "rssi": -65,
  "uptime_ms": 123456
}
```

**Contoh payload `feeding`:**
```json
{
  "trigger_type": "scheduled",
  "duration_sec": 5
}
```

---

## 🌐 REST API Endpoints

### Sensor Data

| Method | Endpoint | Deskripsi |
|--------|----------|-----------|
| GET | `/api/sensors/latest` | Data terbaru per device |
| GET | `/api/sensors/history?device_id=&limit=50` | Riwayat pembacaan |
| GET | `/api/sensors/stats?period=24h` | Statistik min/max/avg |

### Alerts

| Method | Endpoint | Deskripsi |
|--------|----------|-----------|
| GET | `/api/alerts?resolved=false` | Daftar alert aktif |
| PATCH | `/api/alerts/:id/resolve` | Resolve alert manual |

### Feeding

| Method | Endpoint | Deskripsi |
|--------|----------|-----------|
| GET | `/api/feeding` | Riwayat feeding |
| POST | `/api/feeding` | Trigger feeding manual |

### Health Check

```
GET /health
```

---

## 🔧 Integrasi ESP32

Tambahkan library **ArduinoJson** + **PubSubClient** ke `platformio.ini`:

```ini
lib_deps =
    paulstoffregen/OneWire @ ^2.3.8
    milesburton/DallasTemperature @ ^3.11.0
    bblanchon/ArduinoJson @ ^7.0.0
    knolleary/PubSubClient @ ^2.8
```

Contoh publish dari `main.cpp`:
```cpp
#include <WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>

// Setelah baca semua sensor:
StaticJsonDocument<256> doc;
doc["temperature"]    = suhu;
doc["turbidity_ntu"]  = turbidityNTU;
doc["turbidity_volt"] = voltage;
doc["turbidity_raw"]  = rawADC;
doc["moisture_pct"]   = kelembapan;
doc["rssi"]           = WiFi.RSSI();
doc["uptime_ms"]      = millis();

char payload[256];
serializeJson(doc, payload);
mqttClient.publish("aquasense/ESP32-DEVKIT-01/sensors", payload);
```

---

## 🚨 Auto Alert System

Backend otomatis membuat alert ke tabel `alerts` jika:

| Sensor | Kondisi | Severity |
|--------|---------|----------|
| Temperature | < 25°C atau > 30°C | warning |
| Turbidity | < 1600 NTU atau > 4200 NTU | warning |
| Turbidity | > 4550 NTU | danger |
| Moisture | < 40% | warning |

Alert tidak duplikat dalam 10 menit untuk kondisi yang sama.
