// src/services/thresholds.js
// ─────────────────────────────────────────────────────────────
// Threshold values — HARUS sinkron dengan firmware config.h
// ─────────────────────────────────────────────────────────────

export const TEMP = {
  MIN: 25.0,
  MAX: 30.0,
};

// Turbidity pakai RAW ADC (sinkron config.h)
export const TURBIDITY = {
  RAW_CLEAR_MIN:   2100,  // >= ini : terlalu jernih
  RAW_OPTIMAL_MIN:  900,  // range optimal
  RAW_OPTIMAL_MAX: 2000,
  RAW_WARNING_MAX:  800,  // <= ini : warning/danger
};

export const MOISTURE = {
  VERY_DRY: 20,
  DRY:      40,
  MOIST:    70,
  WET:      90,
};

export const FEED = {
  WARNING:  25,  // % — hampir habis
  CRITICAL: 10,  // % — kritis/habis
};

// ─────────────────────────────────────────────────────────────
export function evaluateTemp(celsius) {
  if (celsius === null || celsius === -999) return 'error';
  if (celsius < TEMP.MIN) return 'too_cold';
  if (celsius > TEMP.MAX) return 'too_hot';
  return 'normal';
}

// Evaluasi berbasis RAW ADC (bukan NTU)
export function evaluateTurbidity(raw) {
  if (raw === null || raw === undefined) return 'unknown';
  if (raw >= TURBIDITY.RAW_CLEAR_MIN)                                        return 'too_clear';
  if (raw >= TURBIDITY.RAW_OPTIMAL_MIN && raw <= TURBIDITY.RAW_OPTIMAL_MAX) return 'optimal';
  if (raw >  TURBIDITY.RAW_WARNING_MAX && raw <  TURBIDITY.RAW_OPTIMAL_MIN) return 'warning';
  return 'danger';
}

export function evaluateMoisture(pct) {
  if (pct === null) return 'unknown';
  if (pct < MOISTURE.VERY_DRY) return 'very_dry';
  if (pct < MOISTURE.DRY)      return 'dry';
  if (pct < MOISTURE.MOIST)    return 'moist';
  if (pct < MOISTURE.WET)      return 'wet';
  return 'very_wet';
}

export function evaluateFeedLevel(pct) {
  if (pct === null || pct < 0) return 'unknown';
  if (pct <= FEED.CRITICAL)    return 'empty';
  if (pct <= FEED.WARNING)     return 'critical';
  if (pct <= 50)               return 'low';
  if (pct <= 75)               return 'adequate';
  return 'full';
}
