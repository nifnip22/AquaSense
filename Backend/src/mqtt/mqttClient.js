// src/mqtt/mqttClient.js
import mqtt from 'mqtt';
import 'dotenv/config';
import { supabase } from '../db/supabase.js';
import { evaluateTemp, evaluatePh, evaluateTurbidity, evaluateFeedLevel } from '../services/thresholds.js';
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
        clientId:        CLIENT_ID,
        clean:           true,
        reconnectPeriod: 5000,
        connectTimeout:  10000,
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
// Publish functions — dipakai dari routes
// ─────────────────────────────────────────────────────────────

/**
 * Kirim perintah feeding ke ESP32
 * Topic  : aquasense/{device_id}/command/feed
 * Payload: { "duration_sec": N }
 */
export function publishFeedCommand(device_id, duration_sec) {
    if (!client?.connected) {
        console.warn('[MQTT] Tidak terhubung, gagal kirim command feed.');
        return false;
    }
    const topic   = `aquasense/${device_id}/command/feed`;
    const payload = JSON.stringify({ duration_sec });
    client.publish(topic, payload, { qos: 1 });
    console.log(`[MQTT] 🐟 Feed command → ${topic} | ${payload}`);
    return true;
}

/**
 * Kirim perintah ON/OFF mixer ke ESP32
 * Topic  : aquasense/{device_id}/command/mixer
 * Payload: { "is_on": true, "duration_min": 15 }
 *          { "is_on": false }
 */
export function publishMixerCommand(device_id, is_on, duration_min = 0) {
    if (!client?.connected) {
        console.warn('[MQTT] Tidak terhubung, gagal kirim command mixer.');
        return false;
    }
    const topic   = `aquasense/${device_id}/command/mixer`;
    const payload = JSON.stringify(
        is_on ? { is_on: true, duration_min } : { is_on: false }
    );
    client.publish(topic, payload, { qos: 1 });
    console.log(`[MQTT] 🔄 Mixer command → ${topic} | ${payload}`);
    return true;
}

/**
 * Sync semua jadwal mixer aktif ke ESP32
 * Topic  : aquasense/{device_id}/command/mixer_schedules
 * Payload: {
 *   "schedules": [
 *     { "time": "08:00", "duration_min": 15 },
 *     { "time": "14:00", "duration_min": 10 }
 *   ]
 * }
 *
 * ESP32 akan replace seluruh jadwal internalnya dengan list ini.
 * Array kosong = hapus semua jadwal.
 */
export function publishMixerSchedules(device_id, schedules) {
    if (!client?.connected) {
        console.warn('[MQTT] Tidak terhubung, gagal sync jadwal mixer.');
        return false;
    }
    const topic   = `aquasense/${device_id}/command/mixer_schedules`;
    const payload = JSON.stringify({ schedules });
    client.publish(topic, payload, { qos: 1 });
    console.log(`[MQTT] 📅 Mixer schedules → ${topic} | ${schedules.length} jadwal`);
    return true;
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

    if (msgType === 'sensors')      await handleSensorData(device_id, data);
    else if (msgType === 'feeding') await handleFeedingLog(device_id, data);
}

// ─────────────────────────────────────────────────────────────
// handleSensorData()
//
// Payload dari ESP32 (mqtt_manager.cpp):
// {
//   "temperature":      27.50,
//   "ph":               7.20,
//   "turbidity_raw":    1200,
//   "feed_sensor_ok":   true,
//   "feed_level_pct":   65.3,
//   "feed_distance_mm": 450,
//   "rssi":             -65,
//   "uptime_ms":        123456
// }
// ─────────────────────────────────────────────────────────────
async function handleSensorData(device_id, raw) {
    const temp_status      = evaluateTemp(raw.temperature);
    const ph_status        = evaluatePh(raw.ph);
    const turbidity_status = evaluateTurbidity(raw.turbidity_raw);
    const feed_status      = raw.feed_sensor_ok
        ? evaluateFeedLevel(raw.feed_level_pct)
        : 'unknown';

    const row = {
        device_id,
        recorded_at: new Date().toISOString(),

        temperature:  raw.temperature  ?? null,
        temp_status,

        ph:        raw.ph        ?? null,
        ph_status,

        turbidity_raw:    raw.turbidity_raw    ?? null,
        turbidity_status,

        feed_level_pct:   raw.feed_sensor_ok ? (raw.feed_level_pct   ?? null) : null,
        feed_distance_mm: raw.feed_sensor_ok ? (raw.feed_distance_mm ?? null) : null,
        feed_sensor_ok:   raw.feed_sensor_ok  ?? false,
        feed_status,

        rssi:      raw.rssi      ?? null,
        uptime_ms: raw.uptime_ms ?? null,
    };

    const { error } = await supabase
        .from('sensor_readings')
        .insert([row]);

    if (error) {
        console.error('[Supabase] ❌ Gagal insert sensor_readings:', error.message);
        return;
    }

    console.log(
        `[Supabase] ✅ Tersimpan | ` +
        `Temp: ${raw.temperature}°C (${temp_status}) | ` +
        `PH: ${raw.ph} (${ph_status}) | ` +
        `TurbRAW: ${raw.turbidity_raw} (${turbidity_status}) | ` +
        `Feed: ${raw.feed_level_pct}% (${feed_status})`
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
        console.error('[Supabase] ❌ Gagal insert feeding_logs:', error.message);
        return;
    }

    console.log(`[Supabase] 🐟 Feeding log | trigger: ${row.trigger_type} | durasi: ${row.duration_sec}s`);
}