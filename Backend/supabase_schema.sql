-- ╔══════════════════════════════════════════════════════════════╗
-- ║          AquaSense — Supabase Database Schema v2             ║
-- ║  Disesuaikan dengan payload MQTT dari mqtt_manager.cpp       ║
-- ║                                                              ║
-- ║  Sensors : DS18B20 (Temp) | PH-4502C (pH) |                ║
-- ║            TSW-20M (Turbidity FILTERED ADC) |               ║
-- ║            VL53L0X (Feed Level)                             ║
-- ║  Actuators: Servo MG996R (Feed Gate) |                      ║
-- ║             Relay 2CH + Motor (Mixer)                        ║
-- ╚══════════════════════════════════════════════════════════════╝


-- ═════════════════════════════════════════════════════════════
-- RESET (opsional — hapus semua tabel lama jika ada)
-- Uncomment jika ingin mulai fresh
-- ═════════════════════════════════════════════════════════════
-- DROP VIEW  IF EXISTS latest_readings;
-- DROP TABLE IF EXISTS feeding_logs;
-- DROP TABLE IF EXISTS alerts;
-- DROP TABLE IF EXISTS mixer_schedules;
-- DROP TABLE IF EXISTS mixer_status;
-- DROP TABLE IF EXISTS sensor_readings;


-- ═════════════════════════════════════════════════════════════
-- 1. TABEL: sensor_readings
--
--    Payload MQTT aktual dari mqtt_manager.cpp → mqtt_publish_sensors():
--    {
--      "temperature":          27.50,   ← DS18B20 (null jika -999.0f / error)
--      "ph":                   7.20,    ← PH-4502C dengan ATC
--      "turbidity_filtered":   1450,    ← TSW-20M moving average ADC (0–4095)
--      "feed_sensor_ok":       true,    ← VL53L0X status koneksi
--      "feed_level_pct":       65.3,    ← VL53L0X level % (null jika error)
--      "feed_distance_mm":     450,     ← VL53L0X jarak mm (null jika error)
--      "mixer_on":             false,   ← Status relay mixer saat ini
--      "mixer_remaining_sec":  0,       ← Sisa waktu mixer menyala (detik)
--      "mixer_schedule_count": 2,       ← Jumlah jadwal mixer tersimpan di ESP32
--      "rssi":                 -65,     ← WiFi signal strength (dBm)
--      "uptime_ms":            123456   ← ESP32 uptime sejak boot (ms)
--    }
-- ═════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS sensor_readings (
    id           BIGSERIAL    PRIMARY KEY,
    device_id    TEXT         NOT NULL DEFAULT 'ESP32-DEVKIT-01',
    recorded_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    -- ── Temperature — DS18B20 ──────────────────────────────────
    -- Null = sensor error (ESP32 kirim null jika suhu == -999.0f)
    -- Range valid ikan nila: 26–32°C (optimal), 14–35°C (kritis)
    temperature  NUMERIC(5,2),
    temp_status  TEXT,
    -- temp_status: 'optimal' | 'too_cold' | 'too_hot'
    --            | 'critical_cold' | 'critical_hot' | 'error'

    -- ── pH Air — PH-4502C (dengan ATC suhu otomatis) ──────────
    ph           NUMERIC(4,2),
    ph_status    TEXT,
    -- ph_status: 'optimal' | 'acidic_warning' | 'acidic_danger'
    --          | 'alkaline_warning' | 'alkaline_danger'
    --          | 'critical_acid' | 'critical_alkaline' | 'error'

    -- ── Turbidity — TSW-20M (FILTERED / moving average) ───────
    -- PENTING: ESP32 mengirim turbidity_filtered (moving average buffer),
    -- bukan raw ADC mentah. Ini sudah diproses edge computing di ESP32.
    -- ADC 12-bit ESP32: 0–4095
    -- Interpretasi: TINGGI = JERNIH | RENDAH = KERUH
    -- Threshold (dari config.h):
    --   >= 2001        → terlalu jernih  (too_clear)
    --   900  – 2000    → optimal
    --   801  –  899    → warning (agak keruh)
    --   <= 800         → danger  (terlalu keruh)
    turbidity_filtered   INTEGER,
    turbidity_status     TEXT,
    -- turbidity_status: 'optimal' | 'too_clear' | 'warning' | 'danger' | 'unknown'

    -- ── Feed Level — VL53L0X ToF ──────────────────────────────
    -- feed_sensor_ok = false → feed_level_pct & feed_distance_mm = null
    feed_sensor_ok   BOOLEAN      DEFAULT FALSE,
    feed_level_pct   NUMERIC(5,2),  -- 0.0 – 100.0 %
    feed_distance_mm INTEGER,        -- jarak sensor ke permukaan pakan (mm)
    feed_status      TEXT,
    -- feed_status: 'full' | 'adequate' | 'low' | 'critical' | 'empty' | 'error'

    -- ── Mixer Status (snapshot saat data dikirim) ──────────────
    -- Diambil dari mixer_is_on(), mixer_remaining_sec(), mixer_schedule_count()
    mixer_on             BOOLEAN      DEFAULT FALSE,
    mixer_remaining_sec  INTEGER      DEFAULT 0,   -- detik, 0 jika mati
    mixer_schedule_count SMALLINT     DEFAULT 0,   -- jumlah jadwal di NVS ESP32

    -- ── Metadata ESP32 ────────────────────────────────────────
    rssi       INTEGER,   -- WiFi RSSI (dBm), biasanya -30 s.d. -90
    uptime_ms  BIGINT     -- millis() sejak boot, overflow setelah ~49 hari
);

-- Index time-series (paling sering diquery)
CREATE INDEX IF NOT EXISTS idx_sensor_readings_recorded_at
    ON sensor_readings (recorded_at DESC);

CREATE INDEX IF NOT EXISTS idx_sensor_readings_device_id
    ON sensor_readings (device_id, recorded_at DESC);

-- Constraints validasi data
ALTER TABLE sensor_readings
    ADD CONSTRAINT chk_temperature
    CHECK (temperature IS NULL OR temperature BETWEEN -55 AND 125);

-- ADC 12-bit ESP32 (0–4095)
ALTER TABLE sensor_readings
    ADD CONSTRAINT chk_turbidity_filtered
    CHECK (turbidity_filtered IS NULL OR turbidity_filtered BETWEEN 0 AND 4095);

-- Persentase pakan 0–100
ALTER TABLE sensor_readings
    ADD CONSTRAINT chk_feed_level_pct
    CHECK (feed_level_pct IS NULL OR feed_level_pct BETWEEN 0 AND 100);

-- pH range fisik yang valid (0–14)
ALTER TABLE sensor_readings
    ADD CONSTRAINT chk_ph
    CHECK (ph IS NULL OR ph BETWEEN 0 AND 14);

-- Sisa waktu mixer tidak boleh negatif
ALTER TABLE sensor_readings
    ADD CONSTRAINT chk_mixer_remaining_sec
    CHECK (mixer_remaining_sec IS NULL OR mixer_remaining_sec >= 0);


-- ═════════════════════════════════════════════════════════════
-- 2. TABEL: alerts
--    Log alert otomatis dari backend berdasarkan threshold sensor
-- ═════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS alerts (
    id           BIGSERIAL    PRIMARY KEY,
    device_id    TEXT         NOT NULL DEFAULT 'ESP32-DEVKIT-01',
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    sensor_type  TEXT         NOT NULL,
    -- sensor_type: 'temperature' | 'ph' | 'turbidity' | 'feed_level' | 'mixer'

    severity     TEXT         NOT NULL,
    -- severity: 'warning' | 'danger'

    message      TEXT         NOT NULL,

    value        NUMERIC,     -- nilai sensor saat alert terjadi
    unit         TEXT,        -- '°C' | 'ADC' | '%' | 'pH' | 'detik'

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
    CHECK (sensor_type IN ('temperature', 'ph', 'turbidity', 'feed_level', 'mixer'));


-- ═════════════════════════════════════════════════════════════
-- 3. TABEL: feeding_logs
--    Log dari mqtt_publish_feeding() di ESP32
--
--    Payload MQTT dari topic: aquasense/{device_id}/feeding
--    {
--      "trigger_type": "remote",  ← "scheduled"|"manual"|"remote"|"auto"
--      "duration_sec": 3          ← durasi servo terbuka (detik)
--    }
-- ═════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS feeding_logs (
    id           BIGSERIAL    PRIMARY KEY,
    device_id    TEXT         NOT NULL DEFAULT 'ESP32-DEVKIT-01',
    fed_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    trigger_type TEXT         NOT NULL,
    -- trigger_type: 'scheduled' | 'manual' | 'remote' | 'auto'

    duration_sec INTEGER,     -- durasi servo terbuka (detik), dari config SERVO_DEFAULT_OPEN_SEC
    notes        TEXT
);

CREATE INDEX IF NOT EXISTS idx_feeding_logs_fed_at
    ON feeding_logs (fed_at DESC);

CREATE INDEX IF NOT EXISTS idx_feeding_logs_device_id
    ON feeding_logs (device_id, fed_at DESC);

ALTER TABLE feeding_logs
    ADD CONSTRAINT chk_trigger_type
    CHECK (trigger_type IN ('scheduled', 'manual', 'remote', 'auto'));

-- Durasi servo sesuai batas config.h: SERVO_MIN_OPEN_SEC=1, SERVO_MAX_OPEN_SEC=30
ALTER TABLE feeding_logs
    ADD CONSTRAINT chk_duration_sec
    CHECK (duration_sec IS NULL OR duration_sec BETWEEN 1 AND 30);


-- ═════════════════════════════════════════════════════════════
-- 4. TABEL: mixer_schedules
--    Jadwal mixer yang dikirim backend → ESP32 via MQTT
--    topic: aquasense/{device_id}/command/mixer_schedules
--
--    Format payload ke ESP32:
--    { "schedules": [{"time":"08:00","duration_min":15}, ...] }
--    (max MIXER_MAX_SCHEDULES = 10 dari mixer.h)
-- ═════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS mixer_schedules (
    id           BIGSERIAL    PRIMARY KEY,
    device_id    TEXT         NOT NULL DEFAULT 'ESP32-DEVKIT-01',

    schedule_time  TIME       NOT NULL,   -- format HH:MM
    duration_min   INTEGER    NOT NULL DEFAULT 15,
    is_active      BOOLEAN    NOT NULL DEFAULT TRUE,

    created_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_duration_min
        CHECK (duration_min BETWEEN 1 AND 120)
        -- Sesuai mixer_set_schedules(): constrain(durationMin, 1, 120)
);

CREATE INDEX IF NOT EXISTS idx_mixer_schedules_device_active
    ON mixer_schedules (device_id, is_active, schedule_time);


-- ═════════════════════════════════════════════════════════════
-- 5. TABEL: mixer_status
--    Snapshot status mixer terkini (untuk dashboard realtime)
--    Diupdate setiap backend terima data MQTT sensors
--    (bisa juga diambil langsung dari sensor_readings terbaru)
-- ═════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS mixer_status (
    id        INTEGER      NOT NULL DEFAULT 1,   -- single-row table
    device_id TEXT         NOT NULL DEFAULT 'ESP32-DEVKIT-01',

    is_on                BOOLEAN    NOT NULL DEFAULT FALSE,
    remaining_sec        INTEGER    NOT NULL DEFAULT 0,
    schedule_count       SMALLINT   NOT NULL DEFAULT 0,

    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    CONSTRAINT mixer_status_pkey PRIMARY KEY (id)
);

-- Seed baris awal (single-row upsert)
INSERT INTO mixer_status (id, device_id, is_on, remaining_sec, schedule_count, updated_at)
VALUES (1, 'ESP32-DEVKIT-01', FALSE, 0, 0, NOW())
ON CONFLICT (id) DO NOTHING;


-- ═════════════════════════════════════════════════════════════
-- 6. VIEW: latest_readings
--    Data terbaru tiap device — untuk GET /api/sensors/latest
--    Mencakup semua field termasuk mixer yang baru
-- ═════════════════════════════════════════════════════════════
CREATE OR REPLACE VIEW latest_readings AS
SELECT DISTINCT ON (device_id)
    id,
    device_id,
    recorded_at,

    -- Temperature
    temperature,
    temp_status,

    -- pH
    ph,
    ph_status,

    -- Turbidity (filtered moving average dari ESP32)
    turbidity_filtered,
    turbidity_status,

    -- Feed Level
    feed_sensor_ok,
    feed_level_pct,
    feed_distance_mm,
    feed_status,

    -- Mixer snapshot
    mixer_on,
    mixer_remaining_sec,
    mixer_schedule_count,

    -- Metadata
    rssi,
    uptime_ms

FROM sensor_readings
ORDER BY device_id, recorded_at DESC;


-- ═════════════════════════════════════════════════════════════
-- 7. ROW LEVEL SECURITY (RLS)
-- ═════════════════════════════════════════════════════════════
ALTER TABLE sensor_readings  ENABLE ROW LEVEL SECURITY;
ALTER TABLE alerts           ENABLE ROW LEVEL SECURITY;
ALTER TABLE feeding_logs     ENABLE ROW LEVEL SECURITY;
ALTER TABLE mixer_schedules  ENABLE ROW LEVEL SECURITY;
ALTER TABLE mixer_status     ENABLE ROW LEVEL SECURITY;

CREATE POLICY "service_role_all" ON sensor_readings
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "service_role_all" ON alerts
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "service_role_all" ON feeding_logs
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "service_role_all" ON mixer_schedules
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "service_role_all" ON mixer_status
    FOR ALL USING (auth.role() = 'service_role');

-- Opsional: izinkan anon read untuk dashboard publik
-- CREATE POLICY "anon_read_sensors"  ON sensor_readings  FOR SELECT USING (auth.role() = 'anon');
-- CREATE POLICY "anon_read_alerts"   ON alerts           FOR SELECT USING (auth.role() = 'anon');
-- CREATE POLICY "anon_read_feeding"  ON feeding_logs     FOR SELECT USING (auth.role() = 'anon');
-- CREATE POLICY "anon_read_mixer"    ON mixer_schedules  FOR SELECT USING (auth.role() = 'anon');
-- CREATE POLICY "anon_read_mstatus"  ON mixer_status     FOR SELECT USING (auth.role() = 'anon');


-- ═════════════════════════════════════════════════════════════
-- 8. VERIFIKASI SCHEMA
-- ═════════════════════════════════════════════════════════════
-- SELECT table_name, column_name, data_type
-- FROM information_schema.columns
-- WHERE table_schema = 'public'
--   AND table_name IN (
--       'sensor_readings', 'alerts', 'feeding_logs',
--       'mixer_schedules', 'mixer_status'
--   )
-- ORDER BY table_name, ordinal_position;