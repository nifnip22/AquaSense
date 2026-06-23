// src/services/thresholds.js
// ─────────────────────────────────────────────────────────────
// Threshold values — HARUS sinkron dengan ESP32/include/config.h
// Sensors: DS18B20 (temperature) | PH-4502C (ph) | TSW-20M (turbidity) | VL53L0X (feed)
// Actuators: Servo MG996R (feed gate) | Relay 2CH (stirrer)
// ─────────────────────────────────────────────────────────────

// ── Temperature — DS18B20 ─────────────────────────────────────
// Optimal ikan nila: 25–30°C
// Sinkron: config.h TEMP_MIN / TEMP_MAX
export const TEMP = {
    MIN: 26.0,
    MAX: 32.0,
    KRITIS_MIN: 14.0,
    KRITIS_MAX: 35.0
};

// ── PH AIR — PH-4502C ────────────────────────────────────────
// Optimal ikan nila: 6.5–8.5
// Sinkron: config.h PH_MIN / PH_MAX
export const PH = {
    KRITIS_MAX: 9.0,
    TOLERANSI_MAX: 8.5,
    MAX: 7.5,
    MIN: 6.5,
    TOLERANSI_MIN: 6.0,
    KRITIS_MIN: 5.0
};

// ── Turbidity — TSW-20M (RAW ADC 0–4095) ─────────────────────
// Makin TINGGI raw → makin JERNIH
// Makin RENDAH raw → makin KERUH
// Sinkron: config.h TURBIDITY_RAW_*
export const TURBIDITY = {
    RAW_CLEAR_MIN:    2100,  // >= ini → terlalu jernih
    RAW_OPTIMAL_MAX:  2000,  // batas atas optimal
    RAW_OPTIMAL_MIN:   900,  // batas bawah optimal
    RAW_WARNING_MAX:   800,  // <= ini → danger
};

// ── Feed Level — VL53L0X (%) ──────────────────────────────────
// Sinkron: config.h FEED_LEVEL_*
export const FEED = {
    FULL:     75,  // %
    ADEQUATE: 50,  // %
    LOW:      25,  // %
    CRITICAL: 10,  // %
};

// ── Stirrer (motor pengaduk pakan) ────────────────────────────
// Batas jadwal yang aman — sinkron config.h STIR_*
export const STIR = {
    MIN_INTERVAL_MIN:  1,
    MAX_INTERVAL_MIN:  720,  // 12 jam
    MIN_DURATION_SEC:  1,
    MAX_DURATION_SEC:  120,  // 2 menit
};

// ─────────────────────────────────────────────────────────────
// evaluateTemp()
// Return: 'normal' | 'too_cold' | 'too_hot' | 'error'
// ─────────────────────────────────────────────────────────────
export function evaluateTemp(celsius) {
    if (celsius === null || celsius === undefined || celsius === -999) return 'error';
    if (celsius < TEMP.MIN) return 'WARNING';
    if (celsius > TEMP.MAX) return 'WARNING';
    if (celsius <= TEMP.KRITIS_MIN) return 'DANGER';
    if (celsius >= TEMP.KRITIS_MAX) return 'DANGER';
    return 'OPTIMAL';
}

// ─────────────────────────────────────────────────────────────
// evaluatePh()
// Return: 'normal' | 'too_low' | 'too_high' | 'error'
// ─────────────────────────────────────────────────────────────
export function evaluatePh(ph) {
    if (ph === null || ph === undefined || ph === -999 || ph < 0 || ph > 10) return 'error';
    if (ph < PH.MIN) return 'WARNING';
    if (ph > PH.MAX) return 'WARNING';
    if (ph <= PH.KRITIS_MIN) return 'DANGER';
    if (ph >= PH.KRITIS_MAX) return 'DANGER';
    return 'OPTIMAL';
}

// ─────────────────────────────────────────────────────────────
// evaluateTurbidity()
// Return: 'optimal' | 'too_clear' | 'warning' | 'danger' | 'unknown'
// ─────────────────────────────────────────────────────────────
export function evaluateTurbidity(raw) {
    if (raw === null || raw === undefined) return 'unknown';
    if (raw >= TURBIDITY.RAW_CLEAR_MIN)                                                          return 'WARNING';
    if (raw >= TURBIDITY.RAW_OPTIMAL_MIN && raw <= TURBIDITY.RAW_OPTIMAL_MAX)                    return 'OPTIMAL';
    if (raw >  TURBIDITY.RAW_WARNING_MAX && raw <  TURBIDITY.RAW_OPTIMAL_MIN)                    return 'WARNING';
    return 'DANGER';
}

// ─────────────────────────────────────────────────────────────
// evaluateFeedLevel()
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

// ─────────────────────────────────────────────────────────────
// validateStirSchedule()
// Validasi parameter jadwal stirrer sebelum dikirim ke ESP32.
// Return: { valid: true } | { valid: false, reason: string }
// ─────────────────────────────────────────────────────────────
export function validateStirSchedule(interval_min, duration_sec) {
    if (!Number.isInteger(interval_min) || interval_min < STIR.MIN_INTERVAL_MIN || interval_min > STIR.MAX_INTERVAL_MIN) {
        return { valid: false, reason: `interval_min harus integer antara ${STIR.MIN_INTERVAL_MIN}–${STIR.MAX_INTERVAL_MIN}` };
    }
    if (!Number.isInteger(duration_sec) || duration_sec < STIR.MIN_DURATION_SEC || duration_sec > STIR.MAX_DURATION_SEC) {
        return { valid: false, reason: `duration_sec harus integer antara ${STIR.MIN_DURATION_SEC}–${STIR.MAX_DURATION_SEC}` };
    }
    return { valid: true };
}