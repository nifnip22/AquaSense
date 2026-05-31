#include "turbidity.h"

// ╔════════════════════════════════════════════════════════════╗
// ║           AquaSense — Turbidity Module (TSW-20M)          ║
// ║  Supply  : 5V ke modul                                    ║
// ║  Output  : AO → voltage divider (10kΩ/22kΩ) → GPIO 34   ║
// ║  ADC     : 12-bit, atenuasi 11db, Vref 3.3V              ║
// ║  DO      : tidak digunakan                                ║
// ╚════════════════════════════════════════════════════════════╝

// ─── Variabel Global ─────────────────────────────────────────
float         turbidityNTU = 0.0f;
float         voltage      = 0.0f;  // Tegangan di pin ADC (setelah divider)
int           rawADC       = 0;
unsigned long lastRead     = 0;

// ─────────────────────────────────────────────────────────────
void turbiditySetup() {
  analogReadResolution(12);         // 12-bit → 0–4095
  analogSetAttenuation(ADC_11db);   // Input range 0–3.3V

  Serial.println("============================================");
  Serial.println("  AquaSense - Turbidity Sensor (TSW-20M)  ");
  Serial.println("  Supply   : 5V | Divider: 10k/22k        ");
  Serial.println("  ADC      : GPIO 34, 12-bit, 0-3.3V      ");
  Serial.println("  Target   : Ikan Nila (Tilapia)          ");
  Serial.println("============================================");
}

// ─────────────────────────────────────────────────────────────
void turbidityLoop() {
  unsigned long now = millis();

  if (now - lastRead >= READ_INTERVAL) {
    lastRead = now;

    rawADC       = readAveragedADC(TURBIDITY_AO_PIN, NUM_SAMPLES);
    voltage      = adcToVoltage(rawADC);
    turbidityNTU = voltageToNTU(voltage);

    printTurbidityData();
    evaluateWaterQuality(turbidityNTU);
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

// ─────────────────────────────────────────────────────────────
// Konversi nilai ADC 12-bit → tegangan di pin (setelah divider)
float adcToVoltage(int adcValue) {
  return (adcValue / (float)ADC_RESOLUTION) * ADC_VREF;
}

// ─────────────────────────────────────────────────────────────
// Konversi tegangan pin ADC → NTU
// TSW-20M: tegangan TURUN saat turbiditas NAIK
//   VOLT_CLEAR  : ~2.96V di ADC saat air jernih
//   VOLT_TURBID : ~1.72V di ADC saat sangat keruh
float voltageToNTU(float volt) {
  float ntu;

  if (volt >= VOLT_CLEAR) {
    ntu = 0.0f;
  } else if (volt <= VOLT_TURBID) {
    ntu = NTU_MAX;
  } else {
    ntu = mapFloat(volt, VOLT_CLEAR, VOLT_TURBID, 0.0f, NTU_MAX);
  }

  return constrain(ntu, 0.0f, NTU_MAX);
}

// ─────────────────────────────────────────────────────────────
// Mapping float dari satu range ke range lain
float mapFloat(float x, float inMin, float inMax,
               float outMin, float outMax) {
  return (x - inMin) * (outMax - outMin) / (inMax - inMin) + outMin;
}

// ─────────────────────────────────────────────────────────────
void printTurbidityData() {
  Serial.println("[AquaSense] TSW-20M Reading:");
  Serial.print("  ADC Raw   : "); Serial.println(rawADC);
  Serial.print("  Voltage   : "); Serial.print(voltage, 3); Serial.println(" V");
  Serial.print("  Turbidity : "); Serial.print(turbidityNTU, 1); Serial.println(" NTU");
}

// ─────────────────────────────────────────────────────────────
void evaluateWaterQuality(float ntu) {
  Serial.print("  Status    : ");

  if (ntu < NTU_CLEAR_MAX) {
    Serial.println("[WARNING] Terlalu jernih - cek aerasi & plankton");
  } else if (ntu >= NTU_OPTIMAL_MIN && ntu <= NTU_OPTIMAL_MAX) {
    Serial.println("[OK] OPTIMAL - Kondisi ideal untuk ikan nila");
  } else if (ntu > NTU_OPTIMAL_MAX && ntu <= NTU_WARNING_MAX) {
    Serial.println("[WARNING] Agak keruh - monitor lebih sering");
  } else {
    Serial.println("[DANGER] Terlalu keruh! Segera filter/ganti air");
  }
}