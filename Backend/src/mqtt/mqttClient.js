// src/mqtt/mqttClient.js
import mqtt from 'mqtt';
import 'dotenv/config';
import { supabase } from '../db/supabase.js';
import { evaluateTemp, evaluateTurbidity, evaluateMoisture, evaluateFeedLevel } from '../services/thresholds.js';
import { processAlerts } from '../services/alertService.js';

const BROKER_URL = process.env.MQTT_BROKER_URL || 'mqtt://localhost:1883';
const CLIENT_ID  = process.env.MQTT_CLIENT_ID  || 'aquasense-backend';
const USERNAME   = process.env.MQTT_USERNAME;
const PASSWORD   = process.env.MQTT_PASSWORD;

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

  client.on('connect', () => {
    console.log(`[MQTT] ✅ Terhubung ke broker: ${BROKER_URL}`);
    client.subscribe([TOPIC_SENSORS, TOPIC_FEEDING], { qos: 1 }, (err) => {
      if (err) console.error('[MQTT] Gagal subscribe:', err.message);
      else     console.log(`[MQTT] 📡 Subscribe: ${TOPIC_SENSORS}, ${TOPIC_FEEDING}`);
    });
  });

  client.on('message', async (topic, payload) => {
    await handleMessage(topic, payload);
  });

  client.on('reconnect', () => console.warn('[MQTT] 🔄 Reconnecting...'));
  client.on('error',     (err) => console.error('[MQTT] ❌ Error:', err.message));
  client.on('offline',   () => console.warn('[MQTT] ⚠️  Offline'));

  return client;
}

// ─────────────────────────────────────────────────────────────
async function handleMessage(topic, payload) {
  let data;
  try {
    data = JSON.parse(payload.toString());
  } catch {
    console.error(`[MQTT] Payload bukan JSON valid: ${topic}`);
    return;
  }

  const parts     = topic.split('/');
  const device_id = parts[1] || 'unknown';
  const msgType   = parts[2];

  console.log(`[MQTT] ← ${topic} | device: ${device_id}`);

  if (msgType === 'sensors') await handleSensorData(device_id, data);
  else if (msgType === 'feeding') await handleFeedingLog(device_id, data);
}

// ─────────────────────────────────────────────────────────────
async function handleSensorData(device_id, raw) {
  const temp_status      = evaluateTemp(raw.temperature);
  const turbidity_status = evaluateTurbidity(raw.turbidity_raw);
  const moisture_status  = evaluateMoisture(raw.moisture_pct);
  const feed_status      = raw.feed_sensor_ok
    ? evaluateFeedLevel(raw.feed_level_pct)
    : 'unknown';

  const row = {
    device_id,
    recorded_at:      new Date().toISOString(),

    // Temperature
    temperature:      raw.temperature      ?? null,
    temp_status,

    // Turbidity — RAW ADC only, no NTU/volt
    turbidity_raw:    raw.turbidity_raw    ?? null,
    turbidity_status,

    // Moisture
    moisture_pct:     raw.moisture_pct     ?? null,
    moisture_raw:     raw.moisture_raw     ?? null,
    moisture_status,

    // Feed level
    feed_level_pct:   raw.feed_sensor_ok ? (raw.feed_level_pct ?? null) : null,
    feed_distance_mm: raw.feed_sensor_ok ? (raw.feed_distance_mm ?? null) : null,
    feed_sensor_ok:   raw.feed_sensor_ok  ?? false,
    feed_status,

    // Metadata
    rssi:      raw.rssi      ?? null,
    uptime_ms: raw.uptime_ms ?? null,
  };

  const { error } = await supabase
    .from('sensor_readings')
    .insert([row]);

  if (error) {
    console.error('[Supabase] Gagal insert:', error.message);
    return;
  }

  console.log(
    `[Supabase] ✅ Tersimpan | Temp: ${raw.temperature}°C | ` +
    `TurbidityRAW: ${raw.turbidity_raw} | Moisture: ${raw.moisture_pct}% | ` +
    `Feed: ${raw.feed_level_pct}%`
  );

  await processAlerts(device_id, row);
}

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
