-- ╔══════════════════════════════════════════════════════════════╗
-- ║          AquaSense — Supabase Database Schema                ║
-- ║  Jalankan script ini di Supabase SQL Editor                  ║
-- ╚══════════════════════════════════════════════════════════════╝

-- ─────────────────────────────────────────────────────────────
-- 1. Tabel: sensor_readings
--    Menyimpan semua data pembacaan sensor dari ESP32
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS sensor_readings (
  id              BIGSERIAL PRIMARY KEY,
  device_id       TEXT        NOT NULL DEFAULT 'ESP32-DEVKIT-01',
  recorded_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Temperature (DS18B20)
  temperature     NUMERIC(5,2),          -- °C
  temp_status     TEXT,                  -- 'normal' | 'too_hot' | 'too_cold' | 'error'

  -- Turbidity (TSW-20M)
  turbidity_ntu   NUMERIC(8,2),          -- NTU
  turbidity_volt  NUMERIC(5,3),          -- Volt di pin ADC
  turbidity_raw   INTEGER,               -- Raw ADC 12-bit
  turbidity_status TEXT,                 -- 'optimal' | 'too_clear' | 'warning' | 'danger'

  -- Soil/Water Moisture (analog sensor)
  moisture_pct    NUMERIC(5,2),          -- % (0–100)
  moisture_raw    INTEGER,
  moisture_status TEXT,                  -- 'very_dry'|'dry'|'moist'|'wet'|'very_wet'

  -- Metadata
  rssi            INTEGER,               -- WiFi signal strength (dBm)
  uptime_ms       BIGINT                 -- ESP32 uptime in ms
);

-- Index untuk query time-series
CREATE INDEX idx_sensor_readings_recorded_at
  ON sensor_readings (recorded_at DESC);

CREATE INDEX idx_sensor_readings_device_id
  ON sensor_readings (device_id, recorded_at DESC);

-- ─────────────────────────────────────────────────────────────
-- 2. Tabel: alerts
--    Log alert/warning otomatis berdasarkan threshold
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS alerts (
  id            BIGSERIAL PRIMARY KEY,
  device_id     TEXT        NOT NULL DEFAULT 'ESP32-DEVKIT-01',
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  sensor_type   TEXT        NOT NULL,  -- 'temperature' | 'turbidity' | 'moisture'
  severity      TEXT        NOT NULL,  -- 'warning' | 'danger'
  message       TEXT        NOT NULL,
  value         NUMERIC,
  unit          TEXT,                  -- '°C' | 'NTU' | '%'
  resolved      BOOLEAN     NOT NULL DEFAULT FALSE,
  resolved_at   TIMESTAMPTZ
);

CREATE INDEX idx_alerts_created_at ON alerts (created_at DESC);
CREATE INDEX idx_alerts_resolved   ON alerts (resolved, created_at DESC);

-- ─────────────────────────────────────────────────────────────
-- 3. Tabel: feeding_logs
--    Log aktivitas feeding otomatis (untuk future feature)
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS feeding_logs (
  id            BIGSERIAL PRIMARY KEY,
  device_id     TEXT        NOT NULL DEFAULT 'ESP32-DEVKIT-01',
  fed_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  trigger_type  TEXT        NOT NULL,  -- 'scheduled' | 'manual' | 'auto'
  duration_sec  INTEGER,               -- Durasi motor aktif
  notes         TEXT
);

-- ─────────────────────────────────────────────────────────────
-- 4. View: latest_readings
--    Mengambil data terbaru per device
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW latest_readings AS
SELECT DISTINCT ON (device_id) *
FROM sensor_readings
ORDER BY device_id, recorded_at DESC;

-- ─────────────────────────────────────────────────────────────
-- 5. Row Level Security (opsional, untuk dashboard publik)
-- ─────────────────────────────────────────────────────────────
ALTER TABLE sensor_readings ENABLE ROW LEVEL SECURITY;
ALTER TABLE alerts          ENABLE ROW LEVEL SECURITY;
ALTER TABLE feeding_logs    ENABLE ROW LEVEL SECURITY;

-- Allow service role full access (backend pakai service_role_key)
CREATE POLICY "service_role_all" ON sensor_readings
  FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "service_role_all" ON alerts
  FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "service_role_all" ON feeding_logs
  FOR ALL USING (auth.role() = 'service_role');
