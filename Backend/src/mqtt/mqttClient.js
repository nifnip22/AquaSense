// src/mqtt/mqttClient.js
import mqtt from 'mqtt';
import 'dotenv/config';
import { supabase } from '../db/supabase.js';
import {
    evaluateTemp,
    evaluatePh,
    evaluateTurbidity,
    evaluateFeedLevel
} from '../services/thresholds.js';
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
        startPollingMixerStatus();
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
// Publish functions
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
 *        | { "is_on": false }
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
    client.publish(topic, payload, { qos: 1, retain: true });
    console.log(`[MQTT] 🔄 Mixer command → ${topic} | ${payload}`);
    return true;
}

/**
 * Sync semua jadwal mixer aktif ke ESP32
 * Topic  : aquasense/{device_id}/command/mixer_schedules
 * Payload: { "schedules": [{ "time": "08:00", "duration_min": 15 }, ...] }
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

/**
 * Kirim perintah jadwal stirrer ke ESP32
 * Topic  : aquasense/{device_id}/command/stir
 * Payload: { "mode": "schedule"|"manual", "interval_min": N, "duration_sec": N }
 */
export function publishStirCommand(device_id, payload_obj) {
    if (!client?.connected) {
        console.warn('[MQTT] Tidak terhubung, gagal kirim command stir.');
        return false;
    }
    const topic   = `aquasense/${device_id}/command/stir`;
    const payload = JSON.stringify(payload_obj);
    client.publish(topic, payload, { qos: 1 });
    console.log(`[MQTT] 🌀 Stir command → ${topic} | ${payload}`);
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
// PENTING:
// ESP32 mengirim "turbidity_filtered" (moving average dari edge computing),
// BUKAN "turbidity_raw". Field ini yang disimpan ke DB dan dievaluasi.
// ─────────────────────────────────────────────────────────────
async function handleSensorData(device_id, raw) {
    // Evaluasi status setiap sensor berdasarkan threshold
    const temp_status      = evaluateTemp(raw.temperature);
    const ph_status        = evaluatePh(raw.ph);
    // ✅ Gunakan turbidity_filtered sesuai payload ESP32
    const turbidity_status = evaluateTurbidity(raw.turbidity_filtered);
    const feed_status      = raw.feed_sensor_ok
        ? evaluateFeedLevel(raw.feed_level_pct)
        : 'unknown';

    const row = {
        device_id,
        recorded_at: new Date().toISOString(),

        // ── Temperature ─────────────────────────────────────────
        temperature: raw.temperature ?? null,
        temp_status,

        // ── pH ──────────────────────────────────────────────────
        ph:        raw.ph ?? null,
        ph_status,

        // ── Turbidity (filtered moving average dari ESP32) ──────
        // ✅ Field di DB sekarang turbidity_filtered, bukan turbidity_raw
        turbidity_filtered: raw.turbidity_filtered ?? null,
        turbidity_status,

        // ── Feed Level ──────────────────────────────────────────
        feed_level_pct:   raw.feed_sensor_ok ? (raw.feed_level_pct   ?? null) : null,
        feed_distance_mm: raw.feed_sensor_ok ? (raw.feed_distance_mm ?? null) : null,
        feed_sensor_ok:   raw.feed_sensor_ok  ?? false,
        feed_status,

        // ── Mixer Snapshot ─────────────────────────────────────
        // ✅ Field baru: status mixer saat data dikirim dari ESP32
        mixer_on:             raw.mixer_on             ?? false,
        mixer_remaining_sec:  raw.mixer_remaining_sec  ?? 0,
        mixer_schedule_count: raw.mixer_schedule_count ?? 0,

        // ── Metadata ────────────────────────────────────────────
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
        `Turbidity: ${raw.turbidity_filtered} ADC (${turbidity_status}) | ` +
        `Feed: ${raw.feed_level_pct}% (${feed_status}) | ` +
        `Mixer: ${raw.mixer_on ? 'ON' : 'OFF'} (sisa ${raw.mixer_remaining_sec}s)`
    );

    // Update mixer_status table agar dashboard realtime sinkron
    await syncMixerStatus(device_id, raw);

    // Proses alert otomatis
    await processAlerts(device_id, row);
}

// ─────────────────────────────────────────────────────────────
// Sinkronisasi mixer_status dari data sensor yang masuk
// Lebih efisien dari polling karena dipicu oleh data aktual ESP32
// ─────────────────────────────────────────────────────────────
async function syncMixerStatus(device_id, raw) {
    if (raw.mixer_on === undefined) return; // ESP32 tidak kirim data mixer

    const { error } = await supabase
        .from('mixer_status')
        .upsert({
            id:            1,
            device_id,
            is_on:         raw.mixer_on             ?? false,
            remaining_sec: raw.mixer_remaining_sec  ?? 0,
            schedule_count: raw.mixer_schedule_count ?? 0,
            updated_at:    new Date().toISOString(),
        }, { onConflict: 'id' });

    if (error) {
        console.error('[Supabase] ❌ Gagal update mixer_status:', error.message);
    }
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

// ─────────────────────────────────────────────────────────────
// Polling fallback: DB → MQTT (backup jika FE update langsung ke DB)
// Idealnya FE selalu lewat POST /api/mixer/control, bukan edit DB langsung.
// ─────────────────────────────────────────────────────────────
let lastMixerState = null;

export function startPollingMixerStatus() {
    console.log('⏳ Memulai polling mixer_status setiap 3 detik...');

    setInterval(async () => {
        try {
            const { data, error } = await supabase
                .from('mixer_status')
                .select('is_on')
                .eq('id', 1)
                .single();

            if (error) {
                console.error('❌ Gagal polling DB:', error.message);
                return;
            }

            // Hanya publish MQTT jika status berubah (mencegah spam)
            if (lastMixerState !== null && lastMixerState !== data.is_on) {
                console.log(`🔔 Perubahan mixer dari FE terdeteksi: ${data.is_on ? 'ON' : 'OFF'}`);
                publishMixerCommand('ESP32-DEVKIT-01', data.is_on, data.is_on ? 15 : 0);
            }

            lastMixerState = data.is_on;
        } catch (err) {
            console.error('⚠️ Error polling mixer_status:', err);
        }
    }, 3000);
}