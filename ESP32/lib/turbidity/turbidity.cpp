#include "turbidity.h"

// ╔════════════════════════════════════════════════════════════╗
// ║           AquaSense — Turbidity Module (TSW-20M)          ║
// ║  Supply  : 5V ke modul                                    ║
// ║  Output  : AO → voltage divider (10kΩ/22kΩ) → GPIO 34   ║
// ║  ADC     : 12-bit, atenuasi 11db, Vref 3.3V              ║
// ║  DO      : tidak digunakan                                ║
// ║  RAW ADC : 0–4095 (direct mapping, no voltage conversion)║
// ╚════════════════════════════════════════════════════════════╝

// ─── Variabel Global ─────────────────────────────────────────
int           rawADC       = 0;
unsigned long lastRead     = 0;

// ─────────────────────────────────────────────────────────────
void turbiditySetup() {
  analogReadResolution(12);                           // 12-bit → 0–4095
  analogSetPinAttenuation(TURBIDITY_AO_PIN, ADC_11db); // ESP32: 0–3.3V range

  Serial.println("============================================");
  Serial.println("  AquaSense - Turbidity Sensor (TSW-20M)  ");
  Serial.println("  Supply   : 5V | Divider: 10k/22k        ");
  Serial.println("  ADC      : GPIO 34, 12-bit, 0-3.3V      ");
  Serial.println("  Mode     : RAW ADC direct mapping        ");
  Serial.println("  Target   : Ikan Nila (Tilapia)          ");
  Serial.println("============================================");
}

// ─────────────────────────────────────────────────────────────
void turbidityLoop() {
  unsigned long now = millis();

  if (now - lastRead >= READ_INTERVAL) {
    lastRead = now;

    rawADC       = readAveragedADC(TURBIDITY_AO_PIN, NUM_SAMPLES);

    printTurbidityData();
    evaluateWaterQuality(rawADC);
    Serial.println("--------------------------------------------");
  }
}

// ─────────────────────────────────────────────────────────────
// Rata-rata ADC dari beberapa sampel untuk mengurangi noise
int readAveragedADC(int pin, int samples) {
  long total = 0;
  for (int i = 0; i < samples; i++) {
    total += analogRead(pin);
    delay(SAMPLE_INTERVAL);
  }
  return (int)(total / samples);
}
// (NTU conversion removed) We report RAW ADC only and use RAW thresholds
// for status messages (see config.h for threshold macros).


// ─────────────────────────────────────────────────────────────
void printTurbidityData() {
  Serial.println("[Turbidity] TSW-20M Reading:");
  Serial.print("  ADC Raw   : "); Serial.println(rawADC);
}

// ─────────────────────────────────────────────────────────────
// Status evaluation using RAW ADC thresholds (config.h)
void evaluateWaterQuality(int rawAdc) {
  Serial.print("  Status    : ");

  if (rawAdc >= TURBIDITY_RAW_CLEAR_MIN) {
    Serial.println("[WARNING] Terlalu jernih - cek aerasi & plankton");
  } else if (rawAdc >= TURBIDITY_RAW_OPTIMAL_MIN && rawAdc <= TURBIDITY_RAW_OPTIMAL_MAX) {
    Serial.println("[OK] OPTIMAL - Kondisi ideal untuk ikan nila");
  } else if (rawAdc > TURBIDITY_RAW_WARNING_MAX && rawAdc < TURBIDITY_RAW_OPTIMAL_MIN) {
    Serial.println("[WARNING] Agak keruh - monitor lebih sering");
  } else {
    Serial.println("[DANGER] Terlalu keruh! Segera filter/ganti air");
  }
}

// ═════════════════════════════════════════════════════════════
// ─── Getter Functions (API for MQTT) ────────────────────────
// ═════════════════════════════════════════════════════════════

int turbidity_get_raw() {
  return rawADC;
}