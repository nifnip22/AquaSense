// src/mqtt/mqttClient.js
import mqtt from 'mqtt';
import 'dotenv/config';
import { appendFileSync } from 'fs';
import { join } from 'path';
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

// #region agent log
const DEBUG_LOG_PATH = join(process.cwd(), '../Arduino/ESP32/debug-fafb2e.log');
function _agentLog(location, message, data = {}, hypothesisId = 'C', runId = 'pre-fix') {
    const entry = {
        sessionId: 'fafb2e',
        runId,
        hypothesisId,
        location,
        message,
        data,
        timestamp: Date.now(),
    };
    try { appendFileSync(DEBUG_LOG_PATH, JSON.stringify(entry) + '\n'); } catch {}
    fetch('http://127.0.0.1:7573/ingest/61263a7c-8ce0-4bf4-9952-f0bafbdf00fd', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'X-Debug-Session-Id': 'fafb2e' },
        body: JSON.stringify(entry),
    }).catch(() => {});
}
// #endregion

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
        // #region agent log
        _agentLog('mqttClient.js:connect', 'MQTT backend connected', { broker: BROKER_URL, clientId: CLIENT_ID }, 'C');
        // #endregion
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
    const connected = !!client?.connected;
    if (!connected) {
        console.warn('[MQTT] Tidak terhubung, gagal kirim command mixer.');
        // #region agent log
        _agentLog('mqttClient.js:publishMixerCommand', 'MQTT publish blocked — not connected', { device_id, is_on, duration_min, connected }, 'C');
        // #endregion
        return false;
    }
    const topic   = `aquasense/${device_id}/command/mixer`;
    const payload = JSON.stringify(
        is_on ? { is_on: true, duration_min } : { is_on: false }
    );
    client.publish(topic, payload, { qos: 1, retain: true });
    console.log(`[MQTT] 🔄 Mixer command → ${topic} | ${payload}`);
    // #region agent log
    _agentLog('mqttClient.js:publishMixerCommand', 'Mixer command published', { device_id, topic, payload, connected, expectedEsp32DeviceId: 'ESP32-DEVKIT-01' }, 'B');
    // #endregion
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
    const connected = !!client?.connected;
    if (!connected) {
        console.warn('[MQTT] Tidak terhubung, gagal sync jadwal mixer.');
        // #region agent log
        _agentLog('mqttClient.js:publishMixerSchedules', 'Schedule sync blocked — not connected', { device_id, scheduleCount: schedules?.length ?? 0, connected }, 'C');
        // #endregion
        return false;
    }
    const topic   = `aquasense/${device_id}/command/mixer_schedules`;
    const payload = JSON.stringify({ schedules });
    client.publish(topic, payload, { qos: 1 });
    console.log(`[MQTT] 📅 Mixer schedules → ${topic} | ${schedules.length} jadwal`);
    // #region agent log
    _agentLog('mqttClient.js:publishMixerSchedules', 'Mixer schedules published', { device_id, topic, scheduleCount: schedules.length, schedulesPreview: schedules.slice(0, 3) }, 'F');
    // #endregion
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

    // #region agent log
    if (raw.mixer_on !== undefined || raw.mixer_schedule_count !== undefined) {
        _agentLog('mqttClient.js:handleSensorData', 'ESP32 mixer state from sensors topic', {
            device_id,
            mixer_on: raw.mixer_on ?? null,
            mixer_remaining_sec: raw.mixer_remaining_sec ?? null,
            mixer_schedule_count: raw.mixer_schedule_count ?? null,
        }, 'A');
    }
    // #endregion

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


// ─────────────────────────────────────────────────────────────
// Polling Listener: Supabase (Database) -> MQTT
// ─────────────────────────────────────────────────────────────
let lastMixerState = null; // Menyimpan status terakhir agar tidak spam MQTT

export function startPollingMixerStatus() {
    console.log("⏳ Memulai Polling ke tabel mixer_status setiap 3 detik...");

    // Set interval setiap 3000 milidetik (3 detik)
    setInterval(async () => {
        try {
            // Ambil data terbaru dari Supabase
            const { data, error } = await supabase
                .from('mixer_status')
                .select('is_on')
                .eq('id', 1)
                .single();

            if (error) {
                console.error("❌ Gagal polling DB:", error.message);
                return;
            }

            // Jika statusnya BERBEDA dari status sebelumnya, berarti FE baru saja update
            if (lastMixerState !== null && lastMixerState !== data.is_on) {
                console.log(`🔔 Perubahan terdeteksi dari FE! Mixer di DB sekarang: ${data.is_on ? 'ON' : 'OFF'}`);
                
                // Kirim perintah ke ESP32 via fungsi publish yang sudah ada
                // Asumsi durasi 15 menit jika dinyalakan
                publishMixerCommand('ESP32-DEVKIT-01', data.is_on, data.is_on ? 15 : 0);
            }

            // Update memori status terakhir
            lastMixerState = data.is_on;

        } catch (err) {
            console.error("⚠️ Error saat polling mixer_status:", err);
        }
    }, 3000); // Angka 3000 bisa kamu ganti (misal 5000 untuk 5 detik)
}    