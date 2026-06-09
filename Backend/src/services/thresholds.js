// src/services/thresholds.js
// ─────────────────────────────────────────────────────────────
// Threshold values — HARUS sinkron dengan ESP32/include/config.h
// Sensors: DS18B20 (temperature) | TSW-20M (turbidity) | VL53L0X (feed)
// ─────────────────────────────────────────────────────────────

// ── Temperature — DS18B20 ─────────────────────────────────────
// Optimal ikan nila: 25–30°C
export const TEMP = {
    MIN: 25.0,  // °C — sinkron config.h TEMP_MIN
    MAX: 30.0,  // °C — sinkron config.h TEMP_MAX
};

// ── Turbidity — TSW-20M (RAW ADC 0–4095) ─────────────────────
// Makin TINGGI raw → makin JERNIH
// Makin RENDAH raw → makin KERUH
// Sinkron config.h TURBIDITY_RAW_*
export const TURBIDITY = {
    RAW_CLEAR_MIN:    2100,  // >= ini → terlalu jernih
    RAW_OPTIMAL_MAX:  2000,  // batas atas optimal
    RAW_OPTIMAL_MIN:   900,  // batas bawah optimal
    RAW_WARNING_MAX:   800,  // <= ini → danger
};

// ── Feed Level — VL53L0X (%) ──────────────────────────────────
// Sinkron config.h FEED_LEVEL_*
export const FEED = {
    FULL:     75,  // % — penuh
    ADEQUATE: 50,  // % — cukup
    LOW:      25,  // % — hampir habis
    CRITICAL: 10,  // % — kritis, segera isi
};

// ─────────────────────────────────────────────────────────────
// Evaluasi Suhu
// Return: 'normal' | 'too_cold' | 'too_hot' | 'error'
// ─────────────────────────────────────────────────────────────
export function evaluateTemp(celsius) {
    if (celsius === null || celsius === undefined || celsius === -999) return 'error';
    if (celsius < TEMP.MIN) return 'too_cold';
    if (celsius > TEMP.MAX) return 'too_hot';
    return 'normal';
}

// ─────────────────────────────────────────────────────────────
// Evaluasi Turbiditas (RAW ADC)
// Return: 'optimal' | 'too_clear' | 'warning' | 'danger' | 'unknown'
// ─────────────────────────────────────────────────────────────
export function evaluateTurbidity(raw) {
    if (raw === null || raw === undefined) return 'unknown';
    if (raw >= TURBIDITY.RAW_CLEAR_MIN)                                                  return 'too_clear';
    if (raw >= TURBIDITY.RAW_OPTIMAL_MIN && raw <= TURBIDITY.RAW_OPTIMAL_MAX)            return 'optimal';
    if (raw >  TURBIDITY.RAW_WARNING_MAX && raw <  TURBIDITY.RAW_OPTIMAL_MIN)            return 'warning';
    return 'danger'; // raw <= RAW_WARNING_MAX
}

// ─────────────────────────────────────────────────────────────
// Evaluasi Level Pakan (%)
// Return: 'full' | 'adequate' | 'low' | 'critical' | 'empty' | 'unknown'
// ─────────────────────────────────────────────────────────────
export function evaluateFeedLevel(pct) {
    if (pct === null || pct === undefined || pct < 0) return 'unknown';
    if (pct > FEED.FULL)     return 'full';
    if (pct > FEED.ADEQUATE) return 'adequate';
    if (pct > FEED.LOW)      return 'low';
    if (pct > FEED.CRITICAL) return 'critical';
    return 'empty';
}