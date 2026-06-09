// scripts/dummy-publish.js
// Jalankan: node scripts/dummy-publish.js
//
// Simulate ESP32 publish data sensor ke MQTT broker
// Payload sesuai dengan firmware ESP32 yang sudah difix

import mqtt from 'mqtt';
import 'dotenv/config';

const BROKER_URL = process.env.MQTT_BROKER_URL || 'mqtt://localhost:1883';
const USERNAME   = process.env.MQTT_USERNAME;
const PASSWORD   = process.env.MQTT_PASSWORD;
const DEVICE_ID  = 'ESP32-DEVKIT-01';

const TOPIC_SENSORS = `aquasense/${DEVICE_ID}/sensors`;
const TOPIC_FEEDING = `aquasense/${DEVICE_ID}/feeding`;

const client = mqtt.connect(BROKER_URL, {
    clientId: 'aquasense-dummy-publisher',
    clean: true,
    ...(USERNAME && { username: USERNAME }),
    ...(PASSWORD && { password: PASSWORD }),
});

// ── Generate dummy sensor payload (sesuai ESP32 firmware) ──────
function generateSensorPayload() {
    const feedOK      = Math.random() > 0.1; // 90% sensor OK
    const feedLevelPct = +(10 + Math.random() * 90).toFixed(1);   // 10–100%
    const feedDist    = Math.floor(100 + (1 - feedLevelPct / 100) * 1100); // estimasi jarak

    return {
        // ── DS18B20 — Temperature ──
        temperature: +(23 + Math.random() * 9).toFixed(2),        // 23–32°C

        // ── TSW-20M — Turbidity RAW ADC ──
        turbidity_raw: Math.floor(600 + Math.random() * 1800),    // ADC 600–2400

        // ── VL53L0X — Feed Level ──
        feed_sensor_ok:   feedOK,
        feed_level_pct:   feedOK ? feedLevelPct : null,
        feed_distance_mm: feedOK ? feedDist     : null,

        // ── Metadata ESP32 ──
        rssi:      -Math.floor(45 + Math.random() * 40),          // -45 ~ -85 dBm
        uptime_ms: Date.now() % 10000000,
    };
}

function generateFeedingPayload() {
    return {
        trigger_type: 'scheduled',
        duration_sec: 3 + Math.floor(Math.random() * 5),  // 3–8 detik
    };
}

client.on('connect', () => {
    console.log(`✅ Terhubung ke broker: ${BROKER_URL}`);
    console.log(`📡 Publish sensor → ${TOPIC_SENSORS}`);
    console.log('Tekan Ctrl+C untuk berhenti\n');

    // Publish pertama langsung
    publishSensors();

    // Sensor data setiap 5 detik
    setInterval(publishSensors, 5000);

    // Simulasi feeding setiap 30 detik
    setInterval(publishFeeding, 30000);
});

function publishSensors() {
    const payload = JSON.stringify(generateSensorPayload());
    client.publish(TOPIC_SENSORS, payload, { qos: 1 }, (err) => {
        if (err) console.error('❌ Gagal publish sensor:', err.message);
        else     console.log(`✅ Sensor: ${payload}`);
    });
}

function publishFeeding() {
    const payload = JSON.stringify(generateFeedingPayload());
    client.publish(TOPIC_FEEDING, payload, { qos: 1 }, (err) => {
        if (err) console.error('❌ Gagal publish feeding:', err.message);
        else     console.log(`🐟 Feeding: ${payload}`);
    });
}

client.on('error', (err) => {
    console.error('❌ MQTT Error:', err.message);
});

client.on('reconnect', () => {
    console.log('🔄 Reconnecting...');
});