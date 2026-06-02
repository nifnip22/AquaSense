// src/mqtt/mqttClient.js
import mqtt from 'mqtt';
import 'dotenv/config';
import { supabase } from '../db/supabase.js';
import { evaluateTemp, evaluateTurbidity, evaluateMoisture } from '../services/thresholds.js';
import { processAlerts } from '../services/alertService.js';

// ─────────────────────────────────────────────────────────────
// MQTT Topic Structure:
//   aquasense/{device_id}/sensors   → payload JSON semua sensor
//   aquasense/{device_id}/feeding   → event feeding log
//
// Contoh publish dari ESP32 (gunakan ArduinoJson):
//   Topic : aquasense/ESP32-DEVKIT-01/sensors
//   Payload:
//   {
//     "temperature": 27.5,
//     "turbidity_ntu": 2400.0,
//     "turbidity_volt": 2.140,
//     "turbidity_raw": 2654,
//     "moisture_pct": 62.3,
//     "moisture_raw": 1820,
//     "rssi": -65,
//     "uptime_ms": 123456
//   }
// ─────────────────────────────────────────────────────────────

const BROKER_URL  = process.env.MQTT_BROKER_URL  || 'mqtt://localhost:1883';
const CLIENT_ID   = process.env.MQTT_CLIENT_ID   || 'aquasense-backend';
const USERNAME    = process.env.MQTT_USERNAME;
const PASSWORD    = process.env.MQTT_PASSWORD;

const TOPIC_SENSORS = 'aquasense/+/sensors';
const TOPIC_FEEDING = 'aquasense/+/feeding';

let client;

// ─────────────────────────────────────────────────────────────
export function startMqttClient() {
  const options = {
    clientId: CLIENT_ID,
    clean: true,
    reconnectPeriod: 5000,
    connectTimeout: 10000,
    ...(USERNAME && { username: USERNAME }),
    ...(PASSWORD && { password: PASSWORD }),
  };

  client = mqtt.connect(BROKER_URL, options);

  // ── Events ──────────────────────────────────────────────
  client.on('connect', () => {
    console.log(`[MQTT] ✅ Terhubung ke broker: ${BROKER_URL}`);

    client.subscribe([TOPIC_SENSORS, TOPIC_FEEDING], { qos: 1 }, (err) => {
      if (err) {
        console.error('[MQTT] Gagal subscribe:', err.message);
      } else {
        console.log(`[MQTT] 📡 Subscribe ke: ${TOPIC_SENSORS}, ${TOPIC_FEEDING}`);
      }
    });
  });

  client.on('message', async (topic, payload) => {
    await handleMessage(topic, payload);
  });

  client.on('reconnect', () => {
    console.warn('[MQTT] 🔄 Reconnecting...');
  });

  client.on('error', (err) => {
    console.error('[MQTT] ❌ Error:', err.message);
  });

  client.on('offline', () => {
    console.warn('[MQTT] ⚠️  Client offline');
  });

  return client;
}

// ─────────────────────────────────────────────────────────────
// Handler utama: routing berdasarkan topic
// ─────────────────────────────────────────────────────────────
async function handleMessage(topic, payload) {
  let data;
  try {
    data = JSON.parse(payload.toString());
  } catch {
    console.error(`[MQTT] Payload bukan JSON valid dari topic: ${topic}`);
    return;
  }

  // Ekstrak device_id dari topic: aquasense/{device_id}/xxx
  const parts     = topic.split('/');
  const device_id = parts[1] || 'unknown';
  const msgType   = parts[2];

  console.log(`[MQTT] ← ${topic} | device: ${device_id}`);

  if (msgType === 'sensors') {
    await handleSensorData(device_id, data);
  } else if (msgType === 'feeding') {
    await handleFeedingLog(device_id, data);
  }
}

// ─────────────────────────────────────────────────────────────
// Handler: data sensor → Supabase sensor_readings
// ─────────────────────────────────────────────────────────────
async function handleSensorData(device_id, raw) {
  // Evaluate status dari tiap sensor
  const temp_status       = evaluateTemp(raw.temperature);
  const turbidity_status  = evaluateTurbidity(raw.turbidity_ntu);
  const moisture_status   = evaluateMoisture(raw.moisture_pct);

  const row = {
    device_id,
    recorded_at:      new Date().toISOString(),

    temperature:      raw.temperature      ?? null,
    temp_status,

    turbidity_ntu:    raw.turbidity_ntu    ?? null,
    turbidity_volt:   raw.turbidity_volt   ?? null,
    turbidity_raw:    raw.turbidity_raw    ?? null,
    turbidity_status,

    moisture_pct:     raw.moisture_pct     ?? null,
    moisture_raw:     raw.moisture_raw     ?? null,
    moisture_status,

    rssi:             raw.rssi             ?? null,
    uptime_ms:        raw.uptime_ms        ?? null,
  };

  const { error } = await supabase
    .from('sensor_readings')
    .insert([row]);

  if (error) {
    console.error('[Supabase] Gagal insert sensor_readings:', error.message);
    return;
  }

  console.log(`[Supabase] ✅ Data tersimpan | Temp: ${raw.temperature}°C | NTU: ${raw.turbidity_ntu} | Moisture: ${raw.moisture_pct}%`);

  // Proses alert otomatis
  await processAlerts(device_id, row);
}

// ─────────────────────────────────────────────────────────────
// Handler: feeding event → Supabase feeding_logs
// ─────────────────────────────────────────────────────────────
async function handleFeedingLog(device_id, raw) {
  const row = {
    device_id,
    fed_at:       raw.fed_at       ?? new Date().toISOString(),
    trigger_type: raw.trigger_type ?? 'manual',
    duration_sec: raw.duration_sec ?? null,
    notes:        raw.notes        ?? null,
  };

  const { error } = await supabase
    .from('feeding_logs')
    .insert([row]);

  if (error) {
    console.error('[Supabase] Gagal insert feeding_logs:', error.message);
    return;
  }

  console.log(`[Supabase] 🐟 Feeding log tersimpan | trigger: ${row.trigger_type}`);
}
