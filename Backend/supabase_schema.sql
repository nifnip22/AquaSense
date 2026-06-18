-- ╔══════════════════════════════════════════════════════════════╗
-- ║          AquaSense — Supabase Database Schema                ║
-- ║  Sensors: DS18B20 (Temp) | TSW-20M (Turbidity RAW ADC)       ║
-- ║           VL53L0X (Feed Level)                               ║
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
--    Kolom yang ada sesuai dengan payload MQTT dari ESP32:
--    {
--      "temperature":      27.50,   ← DS18B20
--      "ph":               7.0,     ← PH-420
--      "turbidity_raw":    1200,    ← TSW-20M ADC 0-4095
--      "feed_sensor_ok":   true,    ← VL53L0X status
--      "feed_level_pct":   65.3,    ← VL53L0X level %
--      "feed_distance_mm": 450,     ← VL53L0X jarak mm
--      "rssi":             -65,     ← WiFi signal
--      "uptime_ms":        123456   ← ESP32 uptime
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

    -- ── PH AIR — PH-420 ──────────────────────────────────────
    ph          NUMERIC(4,2),
    ph_status   TEXT,
    -- ph_status enum: 'normal' | 'too_low' | 'too_high' | 'error'

    -- ── Turbidity — TSW-20M (RAW ADC) ─────────────────────
    -- ADC 12-bit ESP32: 0–4095
    -- Makin TINGGI = makin JERNIH | Makin RENDAH = makin KERUH
    -- Optimal ikan nila: ADC 900–2000
    turbidity_raw    INTEGER,
    turbidity_status TEXT,
    -- turbidity_status enum: 'optimal' | 'too_clear' | 'warning' | 'danger' | 'unknown'

    -- ── Feed Level — VL53L0X ToF ───────────────────────────
    -- Sensor dipasang di ATAS wadah, menghadap ke bawah
    -- feed_sensor_ok = false jika VL53L0X tidak terdeteksi saat boot
    feed_sensor_ok   BOOLEAN     DEFAULT FALSE,
    feed_level_pct   NUMERIC(5,2),          -- Persentase level pakan (0–100%)
    feed_distance_mm INTEGER,               -- Jarak sensor ke permukaan pakan (mm)
    feed_status      TEXT,
    -- feed_status enum: 'full' | 'adequate' | 'low' | 'critical' | 'empty' | 'unknown'

    -- ── Metadata ESP32 ─────────────────────────────────────
    rssi       INTEGER,   -- WiFi signal strength (dBm), biasanya -30 sampai -90
    uptime_ms  BIGINT     -- Waktu ESP32 aktif sejak boot (ms)
);

-- Index untuk query time-series yang cepat
CREATE INDEX IF NOT EXISTS idx_sensor_readings_recorded_at
    ON sensor_readings (recorded_at DESC);

CREATE INDEX IF NOT EXISTS idx_sensor_readings_device_id
    ON sensor_readings (device_id, recorded_at DESC);

-- Constraint: temperature harus dalam range sensor yang masuk akal
-- (-55 sampai 125 adalah range DS18B20)
ALTER TABLE sensor_readings
    ADD CONSTRAINT chk_temperature
    CHECK (temperature IS NULL OR temperature BETWEEN -55 AND 125);

-- Constraint: ADC 12-bit ESP32
ALTER TABLE sensor_readings
    ADD CONSTRAINT chk_turbidity_raw
    CHECK (turbidity_raw IS NULL OR turbidity_raw BETWEEN 0 AND 4095);

-- Constraint: persentase pakan 0–100
ALTER TABLE sensor_readings
    ADD CONSTRAINT chk_feed_level_pct
    CHECK (feed_level_pct IS NULL OR feed_level_pct BETWEEN 0 AND 100);


-- ═════════════════════════════════════════════════════════════
-- 2. TABEL: alerts
--    Log alert otomatis berdasarkan threshold sensor
--    Dibuat otomatis oleh backend (alertService.js)
--    Tidak duplikat dalam 10 menit untuk kondisi yang sama
-- ═════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS alerts (
    id           BIGSERIAL    PRIMARY KEY,
    device_id    TEXT         NOT NULL DEFAULT 'ESP32-DEVKIT-01',
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    -- Tipe sensor yang memicu alert
    sensor_type  TEXT         NOT NULL,
    -- sensor_type enum: 'temperature' | 'ph' | 'turbidity' | 'feed_level'

    -- Tingkat keparahan
    severity     TEXT         NOT NULL,
    -- severity enum: 'warning' | 'danger'

    -- Pesan deskriptif untuk ditampilkan di dashboard
    message      TEXT         NOT NULL,

    -- Nilai sensor saat alert dipicu
    value        NUMERIC,
    unit         TEXT,
    -- unit: '°C' | 'ADC' | '%' | 'pH'

    -- Status resolusi
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
--    Dipublikasikan oleh ESP32 via MQTT topic .../feeding
--    Atau di-trigger manual via API POST /api/feeding
-- ═════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS feeding_logs (
    id           BIGSERIAL    PRIMARY KEY,
    device_id    TEXT         NOT NULL DEFAULT 'ESP32-DEVKIT-01',
    fed_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    -- Sumber trigger pemberian pakan
    trigger_type TEXT         NOT NULL,
    -- trigger_type enum: 'scheduled' | 'manual' | 'remote' | 'auto'

    -- Berapa lama motor feeder aktif
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
--    Data terbaru dari setiap device
--    Dipakai oleh GET /api/sensors/latest
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
    -- Metadata
    rssi,
    uptime_ms
FROM sensor_readings
ORDER BY device_id, recorded_at DESC;


-- ═════════════════════════════════════════════════════════════
-- 5. ROW LEVEL SECURITY (RLS)
--    Backend menggunakan service_role_key → akses penuh
--    Frontend (jika ada) harus gunakan anon key + RLS policy
-- ═════════════════════════════════════════════════════════════
ALTER TABLE sensor_readings ENABLE ROW LEVEL SECURITY;
ALTER TABLE alerts          ENABLE ROW LEVEL SECURITY;
ALTER TABLE feeding_logs    ENABLE ROW LEVEL SECURITY;

-- Service role (backend) punya akses penuh ke semua tabel
CREATE POLICY "service_role_all" ON sensor_readings
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "service_role_all" ON alerts
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "service_role_all" ON feeding_logs
    FOR ALL USING (auth.role() = 'service_role');

-- Opsional: izinkan anon membaca data (untuk dashboard publik)
-- Uncomment jika diperlukan:
-- CREATE POLICY "anon_read_sensors" ON sensor_readings
--     FOR SELECT USING (auth.role() = 'anon');
-- CREATE POLICY "anon_read_alerts" ON alerts
--     FOR SELECT USING (auth.role() = 'anon');
-- CREATE POLICY "anon_read_feeding" ON feeding_logs
--     FOR SELECT USING (auth.role() = 'anon');


-- ═════════════════════════════════════════════════════════════
-- 6. VERIFIKASI SCHEMA
--    Jalankan query ini untuk memastikan semua tabel terbuat
-- ═════════════════════════════════════════════════════════════
-- SELECT table_name, column_name, data_type
-- FROM information_schema.columns
-- WHERE table_schema = 'public'
--   AND table_name IN ('sensor_readings', 'alerts', 'feeding_logs')
-- ORDER BY table_name, ordinal_position;