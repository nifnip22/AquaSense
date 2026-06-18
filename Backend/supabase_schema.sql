-- ╔══════════════════════════════════════════════════════════════╗
-- ║          AquaSense — Supabase Database Schema                ║
-- ║  Sensors : DS18B20 (Temp) | PH-4502C (pH) |                ║
-- ║            TSW-20M (Turbidity RAW ADC) |                    ║
-- ║            VL53L0X (Feed Level)                             ║
-- ║  Actuators: Servo MG996R (Feed Gate) |                      ║
-- ║             Relay 2CH + Motor (Stirrer)                      ║
-- ║                                                              ║
-- ║  Cara pakai: Jalankan SELURUH file ini di Supabase →         ║
-- ║  SQL Editor → New Query → Paste → Run                        ║
-- ╚══════════════════════════════════════════════════════════════╝


-- ═════════════════════════════════════════════════════════════
-- RESET (opsional — hapus semua tabel lama jika ada)
-- Uncomment bagian ini jika ingin mulai fresh
-- ═════════════════════════════════════════════════════════════
-- DROP VIEW  IF EXISTS latest_readings;
-- DROP TABLE IF EXISTS feeding_logs;
-- DROP TABLE IF EXISTS alerts;
-- DROP TABLE IF EXISTS sensor_readings;


-- ═════════════════════════════════════════════════════════════
-- 1. TABEL: sensor_readings
--    Menyimpan semua data pembacaan sensor dari ESP32 DevKit V1
--
--    Payload MQTT terbaru dari ESP32 (mqtt_manager.cpp):
--    {
--      "temperature":        27.50,   ← DS18B20
--      "ph":                 7.20,    ← PH-4502C
--      "turbidity_raw":      1200,    ← TSW-20M ADC 0–4095
--      "feed_sensor_ok":     true,    ← VL53L0X status
--      "feed_level_pct":     65.3,    ← VL53L0X level %
--      "feed_distance_mm":   450,     ← VL53L0X jarak mm
--      "stir_interval_min":  30,      ← jadwal stirrer (menit)
--      "stir_duration_sec":  10,      ← durasi stirrer (detik)
--      "stir_running":       false,   ← status motor saat ini
--      "stir_last_direction":0,       ← arah terakhir (0=A, 1=B)
--      "stir_next_run_ms":   1234567, ← ms hingga jadwal berikutnya
--      "rssi":               -65,     ← WiFi signal
--      "uptime_ms":          123456   ← ESP32 uptime
--    }
-- ═════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS sensor_readings (
    id           BIGSERIAL    PRIMARY KEY,
    device_id    TEXT         NOT NULL DEFAULT 'ESP32-DEVKIT-01',
    recorded_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    -- ── Temperature — DS18B20 ──────────────────────────────
    -- Range valid: 25–30°C untuk ikan nila
    -- Nilai -999 = sensor error / terputus
    temperature  NUMERIC(5,2),
    temp_status  TEXT,
    -- temp_status enum: 'normal' | 'too_cold' | 'too_hot' | 'error'

    -- ── PH AIR — PH-4502C ────────────────────────────────────
    ph           NUMERIC(4,2),
    ph_status    TEXT,
    -- ph_status enum: 'normal' | 'too_low' | 'too_high' | 'error'

    -- ── Turbidity — TSW-20M (RAW ADC) ─────────────────────
    -- ADC 12-bit ESP32: 0–4095
    -- Makin TINGGI = makin JERNIH | Makin RENDAH = makin KERUH
    -- Optimal ikan nila: ADC 900–2000
    turbidity_raw    INTEGER,
    turbidity_status TEXT,
    -- turbidity_status enum: 'optimal' | 'too_clear' | 'warning' | 'danger' | 'unknown'

    -- ── Feed Level — VL53L0X ToF ───────────────────────────
    feed_sensor_ok   BOOLEAN     DEFAULT FALSE,
    feed_level_pct   NUMERIC(5,2),
    feed_distance_mm INTEGER,
    feed_status      TEXT,
    -- feed_status enum: 'full' | 'adequate' | 'low' | 'critical' | 'empty' | 'unknown'

    -- ── Stirrer — Relay 2CH + Motor Power Window ───────────
    -- Status & konfigurasi pengaduk pakan dikirim setiap publish sensor
    stir_interval_min   INTEGER,    -- jadwal interval (menit), sesuai NVS ESP32
    stir_duration_sec   INTEGER,    -- durasi motor aktif (detik), sesuai NVS ESP32
    stir_running        BOOLEAN,    -- true jika motor sedang berjalan saat publish
    stir_last_direction SMALLINT,   -- 0 = arah A (CH1), 1 = arah B (CH2)
    stir_next_run_ms    BIGINT,     -- ms tersisa hingga pengadukan berikutnya (0 = segera)

    -- ── Metadata ESP32 ─────────────────────────────────────
    rssi       INTEGER,   -- WiFi signal strength (dBm)
    uptime_ms  BIGINT     -- Waktu ESP32 aktif sejak boot (ms)
);

-- Index untuk query time-series yang cepat
CREATE INDEX IF NOT EXISTS idx_sensor_readings_recorded_at
    ON sensor_readings (recorded_at DESC);

CREATE INDEX IF NOT EXISTS idx_sensor_readings_device_id
    ON sensor_readings (device_id, recorded_at DESC);

-- Constraint suhu range DS18B20 (-55 s.d. 125°C)
ALTER TABLE sensor_readings
    ADD CONSTRAINT chk_temperature
    CHECK (temperature IS NULL OR temperature BETWEEN -55 AND 125);

-- Constraint ADC 12-bit ESP32
ALTER TABLE sensor_readings
    ADD CONSTRAINT chk_turbidity_raw
    CHECK (turbidity_raw IS NULL OR turbidity_raw BETWEEN 0 AND 4095);

-- Constraint persentase pakan 0–100
ALTER TABLE sensor_readings
    ADD CONSTRAINT chk_feed_level_pct
    CHECK (feed_level_pct IS NULL OR feed_level_pct BETWEEN 0 AND 100);

-- Constraint stirrer direction: hanya 0 atau 1
ALTER TABLE sensor_readings
    ADD CONSTRAINT chk_stir_last_direction
    CHECK (stir_last_direction IS NULL OR stir_last_direction IN (0, 1));


-- ═════════════════════════════════════════════════════════════
-- MIGRASI (jika tabel sudah ada, jalankan ALTER TABLE ini)
-- Uncomment jika perlu menambah kolom stirrer ke tabel existing:
-- ═════════════════════════════════════════════════════════════
-- ALTER TABLE sensor_readings
--     ADD COLUMN IF NOT EXISTS stir_interval_min   INTEGER,
--     ADD COLUMN IF NOT EXISTS stir_duration_sec   INTEGER,
--     ADD COLUMN IF NOT EXISTS stir_running        BOOLEAN,
--     ADD COLUMN IF NOT EXISTS stir_last_direction SMALLINT,
--     ADD COLUMN IF NOT EXISTS stir_next_run_ms    BIGINT;
--
-- ALTER TABLE sensor_readings
--     ADD CONSTRAINT chk_stir_last_direction
--     CHECK (stir_last_direction IS NULL OR stir_last_direction IN (0, 1));


-- ═════════════════════════════════════════════════════════════
-- 2. TABEL: alerts
--    Log alert otomatis berdasarkan threshold sensor
-- ═════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS alerts (
    id           BIGSERIAL    PRIMARY KEY,
    device_id    TEXT         NOT NULL DEFAULT 'ESP32-DEVKIT-01',
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    sensor_type  TEXT         NOT NULL,
    -- sensor_type enum: 'temperature' | 'ph' | 'turbidity' | 'feed_level'

    severity     TEXT         NOT NULL,
    -- severity enum: 'warning' | 'danger'

    message      TEXT         NOT NULL,

    value        NUMERIC,
    unit         TEXT,
    -- unit: '°C' | 'ADC' | '%' | 'pH'

    resolved     BOOLEAN      NOT NULL DEFAULT FALSE,
    resolved_at  TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_alerts_created_at
    ON alerts (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_alerts_unresolved
    ON alerts (resolved, device_id, created_at DESC)
    WHERE resolved = FALSE;

ALTER TABLE alerts
    ADD CONSTRAINT chk_severity
    CHECK (severity IN ('warning', 'danger'));

ALTER TABLE alerts
    ADD CONSTRAINT chk_sensor_type
    CHECK (sensor_type IN ('temperature', 'ph', 'turbidity', 'feed_level'));


-- ═════════════════════════════════════════════════════════════
-- 3. TABEL: feeding_logs
--    Log setiap kejadian pemberian pakan
-- ═════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS feeding_logs (
    id           BIGSERIAL    PRIMARY KEY,
    device_id    TEXT         NOT NULL DEFAULT 'ESP32-DEVKIT-01',
    fed_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    trigger_type TEXT         NOT NULL,
    -- trigger_type enum: 'scheduled' | 'manual' | 'remote' | 'auto'

    duration_sec INTEGER,
    notes        TEXT
);

CREATE INDEX IF NOT EXISTS idx_feeding_logs_fed_at
    ON feeding_logs (fed_at DESC);

CREATE INDEX IF NOT EXISTS idx_feeding_logs_device_id
    ON feeding_logs (device_id, fed_at DESC);

ALTER TABLE feeding_logs
    ADD CONSTRAINT chk_trigger_type
    CHECK (trigger_type IN ('scheduled', 'manual', 'remote', 'auto'));


-- ═════════════════════════════════════════════════════════════
-- 4. VIEW: latest_readings
--    Data terbaru dari setiap device — dipakai GET /api/sensors/latest
-- ═════════════════════════════════════════════════════════════
CREATE OR REPLACE VIEW latest_readings AS
SELECT DISTINCT ON (device_id)
    id,
    device_id,
    recorded_at,
    -- Temperature
    temperature,
    temp_status,
    -- PH Air
    ph,
    ph_status,
    -- Turbidity
    turbidity_raw,
    turbidity_status,
    -- Feed Level
    feed_sensor_ok,
    feed_level_pct,
    feed_distance_mm,
    feed_status,
    -- Stirrer
    stir_interval_min,
    stir_duration_sec,
    stir_running,
    stir_last_direction,
    stir_next_run_ms,
    -- Metadata
    rssi,
    uptime_ms
FROM sensor_readings
ORDER BY device_id, recorded_at DESC;


-- ═════════════════════════════════════════════════════════════
-- 5. ROW LEVEL SECURITY (RLS)
-- ═════════════════════════════════════════════════════════════
ALTER TABLE sensor_readings ENABLE ROW LEVEL SECURITY;
ALTER TABLE alerts          ENABLE ROW LEVEL SECURITY;
ALTER TABLE feeding_logs    ENABLE ROW LEVEL SECURITY;

CREATE POLICY "service_role_all" ON sensor_readings
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "service_role_all" ON alerts
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "service_role_all" ON feeding_logs
    FOR ALL USING (auth.role() = 'service_role');

-- Opsional: izinkan anon membaca data (untuk dashboard publik)
-- CREATE POLICY "anon_read_sensors" ON sensor_readings
--     FOR SELECT USING (auth.role() = 'anon');
-- CREATE POLICY "anon_read_alerts" ON alerts
--     FOR SELECT USING (auth.role() = 'anon');
-- CREATE POLICY "anon_read_feeding" ON feeding_logs
--     FOR SELECT USING (auth.role() = 'anon');


-- ═════════════════════════════════════════════════════════════
-- 6. VERIFIKASI SCHEMA
-- ═════════════════════════════════════════════════════════════
-- SELECT table_name, column_name, data_type
-- FROM information_schema.columns
-- WHERE table_schema = 'public'
--   AND table_name IN ('sensor_readings', 'alerts', 'feeding_logs')
-- ORDER BY table_name, ordinal_position;