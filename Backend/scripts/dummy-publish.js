// scripts/dummy-publish.js
// Simulasi publish data sensor ESP32 ke MQTT broker — sinkron dengan
// payload terbaru di ESP32/lib/mqtt_manager/mqtt_manager.cpp
//
// Jalankan:
//   node scripts/dummy-publish.js --once
//   node scripts/dummy-publish.js --count 10 --interval 2000
//   node scripts/dummy-publish.js --sensor-only
//   node scripts/dummy-publish.js --include-feeding

import mqtt from 'mqtt';
import 'dotenv/config';

const argv = parseArgs(process.argv.slice(2));

const BROKER_URL            = process.env.MQTT_BROKER_URL || 'mqtt://localhost:1883';
const USERNAME              = process.env.MQTT_USERNAME;
const PASSWORD              = process.env.MQTT_PASSWORD;
const DEVICE_ID             = argv['device-id'] || process.env.MQTT_DEVICE_ID || 'ESP32-DEVKIT-01';
const PUBLISH_INTERVAL_MS   = toNumber(argv.interval, 5000);
const FEEDING_INTERVAL_MS   = toNumber(argv['feeding-interval'], 30000);
const PUBLISH_COUNT         = argv.once ? 1 : toNumber(argv.count, 0);
const INCLUDE_FEEDING       = argv['include-feeding'] ?? false;
const SENSOR_ONLY           = argv['sensor-only'] ?? false;

const TOPIC_SENSORS = `aquasense/${DEVICE_ID}/sensors`;
const TOPIC_FEEDING = `aquasense/${DEVICE_ID}/feeding`;

let sensorTimer  = null;
let feedingTimer = null;
let remainingSensorPublishes = PUBLISH_COUNT;

// ── Stirrer state simulasi ────────────────────────────────────
let stirIntervalMin  = 30;
let stirDurationSec  = 10;
let stirRunning      = false;
let stirLastDir      = 0;
let stirNextRunMs    = stirIntervalMin * 60 * 1000;

const client = mqtt.connect(BROKER_URL, {
    clientId:       `aquasense-dummy-publisher-${DEVICE_ID}`,
    clean:          true,
    reconnectPeriod: 5000,
    connectTimeout:  10000,
    ...(USERNAME && { username: USERNAME }),
    ...(PASSWORD && { password: PASSWORD }),
});

// ─────────────────────────────────────────────────────────────
// Generate dummy sensor payload — identik dengan mqtt_manager.cpp
// ─────────────────────────────────────────────────────────────
function generateSensorPayload() {
    const feedOK        = Math.random() > 0.1;
    const feedLevelPct  = +(10 + Math.random() * 90).toFixed(1);
    const feedDist      = Math.floor(100 + (1 - feedLevelPct / 100) * 1100);

    // Simulasi stirrer berputar sesekali
    stirNextRunMs = Math.max(0, stirNextRunMs - PUBLISH_INTERVAL_MS);
    if (stirNextRunMs === 0) {
        stirRunning   = true;
        stirNextRunMs = stirIntervalMin * 60 * 1000;
    } else if (stirRunning && Math.random() > 0.7) {
        stirRunning  = false;
        stirLastDir  = stirLastDir === 0 ? 1 : 0;
    }

    return {
        // ── Sensor air ──────────────────────────────────────
        temperature:  +(23 + Math.random() * 9).toFixed(2),
        ph:           +(6.0 + Math.random() * 3.0).toFixed(2),   // ← BARU: PH-4502C
        turbidity_raw: Math.floor(600 + Math.random() * 1800),

        // ── Feed level (VL53L0X) ─────────────────────────────
        feed_sensor_ok:    feedOK,
        feed_level_pct:    feedOK ? feedLevelPct : null,
        feed_distance_mm:  feedOK ? feedDist : null,

        // ── Stirrer status ───────────────────────────────────  ← BARU
        stir_interval_min:   stirIntervalMin,
        stir_duration_sec:   stirDurationSec,
        stir_running:        stirRunning,
        stir_last_direction: stirLastDir,
        stir_next_run_ms:    stirNextRunMs,

        // ── Metadata ─────────────────────────────────────────
        rssi:      -Math.floor(45 + Math.random() * 40),
        uptime_ms: Date.now() % 10000000,
    };
}

function generateFeedingPayload() {
    return {
        trigger_type: 'scheduled',
        duration_sec: 3 + Math.floor(Math.random() * 5),
        fed_at:       new Date().toISOString(),
    };
}

// ─────────────────────────────────────────────────────────────
client.on('connect', () => {
    console.log(`✅ Terhubung ke broker: ${BROKER_URL}`);
    console.log(`📡 Sensor topic : ${TOPIC_SENSORS}`);
    console.log(`📡 Feeding topic: ${TOPIC_FEEDING}`);
    console.log(`🧪 Mode test    : ${PUBLISH_COUNT === 1 ? 'once' : PUBLISH_COUNT > 0 ? `${PUBLISH_COUNT}x` : 'loop'}`);
    console.log('Tekan Ctrl+C untuk berhenti\n');

    publishSensors();

    if (PUBLISH_COUNT !== 1) {
        sensorTimer = setInterval(publishSensors, PUBLISH_INTERVAL_MS);
    }

    if (!SENSOR_ONLY) {
        if (INCLUDE_FEEDING) {
            publishFeeding();
            if (PUBLISH_COUNT !== 1) {
                feedingTimer = setInterval(publishFeeding, FEEDING_INTERVAL_MS);
            }
        }
    }
});

function publishSensors() {
    const payload = JSON.stringify(generateSensorPayload());

    client.publish(TOPIC_SENSORS, payload, { qos: 1 }, (err) => {
        if (err) {
            console.error('❌ Gagal publish sensor:', err.message);
            return;
        }
        console.log(`✅ Sensor → ${payload}`);

        if (remainingSensorPublishes > 0) {
            remainingSensorPublishes -= 1;
            if (remainingSensorPublishes === 0) stopAfterFlush();
        }
    });
}

function publishFeeding() {
    const payload = JSON.stringify(generateFeedingPayload());
    client.publish(TOPIC_FEEDING, payload, { qos: 1 }, (err) => {
        if (err) console.error('❌ Gagal publish feeding:', err.message);
        else     console.log(`🐟 Feeding → ${payload}`);
    });
}

function stopAfterFlush() {
    if (sensorTimer)  clearInterval(sensorTimer);
    if (feedingTimer) clearInterval(feedingTimer);
    setTimeout(() => client.end(true, () => process.exit(0)), 250);
}

// ─────────────────────────────────────────────────────────────
function parseArgs(args) {
    const result = {};
    for (let i = 0; i < args.length; i++) {
        const cur = args[i];
        if (!cur.startsWith('--')) continue;
        const [key, inlineVal] = cur.slice(2).split('=', 2);
        if (inlineVal !== undefined) { result[key] = normalizeArgValue(inlineVal); continue; }
        const next = args[i + 1];
        if (!next || next.startsWith('--')) { result[key] = true; continue; }
        result[key] = normalizeArgValue(next);
        i++;
    }
    return result;
}

function normalizeArgValue(v) {
    if (v === 'true')  return true;
    if (v === 'false') return false;
    return v;
}

function toNumber(v, fallback) {
    const n = Number(v);
    return Number.isFinite(n) ? n : fallback;
}

client.on('error',     (err) => console.error('❌ MQTT Error:', err.message));
client.on('reconnect', ()    => console.log('🔄 Reconnecting...'));

process.on('SIGINT', () => {
    console.log('\n🛑 Stopping publisher...');
    if (sensorTimer)  clearInterval(sensorTimer);
    if (feedingTimer) clearInterval(feedingTimer);
    client.end(true, () => process.exit(0));
});