// scripts/dummy-publish.js
// Jalankan: node scripts/dummy-publish.js
//
// Script ini simulate ESP32 publish data sensor ke MQTT broker
// sehingga backend bisa terima dan simpan ke Supabase

import mqtt from 'mqtt';
import 'dotenv/config';

const BROKER_URL = process.env.MQTT_BROKER_URL || 'mqtt://localhost:1883';
const USERNAME   = process.env.MQTT_USERNAME;
const PASSWORD   = process.env.MQTT_PASSWORD;
const DEVICE_ID  = 'ESP32-DEVKIT-01';
const TOPIC      = `aquasense/${DEVICE_ID}/sensors`;

const client = mqtt.connect(BROKER_URL, {
  clientId: 'aquasense-dummy-publisher',
  clean: true,
  ...(USERNAME && { username: USERNAME }),
  ...(PASSWORD && { password: PASSWORD }),
});

// ── Generate dummy sensor data ────────────────────────────────
function generatePayload() {
  return {
    temperature:      +(24 + Math.random() * 8).toFixed(2),   // 24–32°C
    turbidity_raw:    Math.floor(900 + Math.random() * 1500),  // ADC 900–2400
    moisture_pct:     +(30 + Math.random() * 60).toFixed(1),   // 30–90%
    moisture_raw:     Math.floor(800 + Math.random() * 2000),
    feed_sensor_ok:   true,
    feed_level_pct:   +(10 + Math.random() * 90).toFixed(1),   // 10–100%
    feed_distance_mm: Math.floor(50 + Math.random() * 1000),
    rssi:             -Math.floor(50 + Math.random() * 40),    // -50 ~ -90 dBm
    uptime_ms:        Date.now() % 1000000,
  };
}

client.on('connect', () => {
  console.log(`[Dummy] ✅ Terhubung ke broker: ${BROKER_URL}`);
  console.log(`[Dummy] 📡 Publish ke topic: ${TOPIC}`);
  console.log('[Dummy] Tekan Ctrl+C untuk berhenti\n');

  // Publish pertama langsung
  publishOnce();

  // Lalu tiap 5 detik
  setInterval(publishOnce, 5000);
});

function publishOnce() {
  const payload = generatePayload();
  const json    = JSON.stringify(payload);

  client.publish(TOPIC, json, { qos: 1 }, (err) => {
    if (err) {
      console.error('[Dummy] ❌ Gagal publish:', err.message);
    } else {
      console.log(`[Dummy] ✅ Published: ${json}`);
    }
  });
}

client.on('error', (err) => {
  console.error('[Dummy] ❌ Error:', err.message);
});
