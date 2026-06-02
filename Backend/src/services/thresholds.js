// src/services/thresholds.js
// ─────────────────────────────────────────────────────────────
// Threshold values — HARUS sinkron dengan firmware config.h
// ─────────────────────────────────────────────────────────────

export const TEMP = {
  MIN: 25.0,   // °C — terlalu dingin di bawah ini
  MAX: 30.0,   // °C — terlalu panas di atas ini
};

export const TURBIDITY = {
  NTU_CLEAR_MAX:    1600.0,   // < ini : terlalu jernih
  NTU_OPTIMAL_MIN:  1601.0,
  NTU_OPTIMAL_MAX:  4199.0,
  NTU_WARNING_MAX:  4200.0,   // > ini : bahaya
  NTU_RANGE_MAX:    4550.0,
};

export const MOISTURE = {
  VERY_DRY: 20,   // %
  DRY:      40,
  MOIST:    70,
  WET:      90,
};

// ─────────────────────────────────────────────────────────────
// Helper: evaluate status dari nilai sensor
// ─────────────────────────────────────────────────────────────
export function evaluateTemp(celsius) {
  if (celsius === null || celsius === -999) return 'error';
  if (celsius < TEMP.MIN)  return 'too_cold';
  if (celsius > TEMP.MAX)  return 'too_hot';
  return 'normal';
}

export function evaluateTurbidity(ntu) {
  if (ntu === null) return 'unknown';
  if (ntu < TURBIDITY.NTU_CLEAR_MAX)                              return 'too_clear';
  if (ntu >= TURBIDITY.NTU_OPTIMAL_MIN && ntu <= TURBIDITY.NTU_OPTIMAL_MAX) return 'optimal';
  if (ntu > TURBIDITY.NTU_OPTIMAL_MAX && ntu <= TURBIDITY.NTU_WARNING_MAX)  return 'warning';
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
