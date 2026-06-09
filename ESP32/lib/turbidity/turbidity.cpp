#include "turbidity.h"

// ╔════════════════════════════════════════════════════════════╗
// ║           AquaSense — Turbidity Module (TSW-20M)          ║
// ║  Supply  : 5V ke modul                                    ║
// ║  Output  : AO → voltage divider (10kΩ/22kΩ) → GPIO 32   ║
// ║  ADC     : 12-bit, atenuasi 11db, Vref 3.3V              ║
// ║  DO      : tidak digunakan                                ║
// ║  Mode    : RAW ADC direct (no NTU conversion)             ║
// ╚════════════════════════════════════════════════════════════╝

// ─── Variabel Global ─────────────────────────────────────────
int           rawADC   = 0;
unsigned long lastRead = 0;

// ─────────────────────────────────────────────────────────────
void turbiditySetup() {
    analogReadResolution(12);
    analogSetPinAttenuation(TURBIDITY_AO_PIN, ADC_11db);

    Serial.println("============================================");
    Serial.println("  AquaSense - Turbidity Sensor (TSW-20M)  ");
    Serial.println("  Supply : 5V | Divider: 10kΩ/22kΩ        ");
    Serial.printf("  ADC Pin: GPIO%d | 12-bit | 0-3.3V\n", TURBIDITY_AO_PIN);
    Serial.printf("  Optimal: ADC %d – %d\n",
                  TURBIDITY_RAW_OPTIMAL_MIN, TURBIDITY_RAW_OPTIMAL_MAX);
    Serial.println("============================================");
}

// ─────────────────────────────────────────────────────────────
void turbidityLoop() {
    unsigned long now = millis();

    if (now - lastRead >= TURBIDITY_READ_INTERVAL) {
        lastRead = now;
        rawADC   = turbidity_read_averaged(TURBIDITY_AO_PIN, TURBIDITY_NUM_SAMPLES);
        turbidityPrint();
        turbidityEvaluate(rawADC);
        Serial.println("--------------------------------------------");
    }
}

// ─────────────────────────────────────────────────────────────
// Rata-rata ADC dari beberapa sampel untuk mengurangi noise
// ─────────────────────────────────────────────────────────────
int turbidity_read_averaged(int pin, int samples) {
    long total = 0;
    for (int i = 0; i < samples; i++) {
        total += analogRead(pin);
        delay(TURBIDITY_SAMPLE_INTERVAL);
    }
    return (int)(total / samples);
}

// ─────────────────────────────────────────────────────────────
void turbidityPrint() {
    Serial.println("[Turbidity] TSW-20M Reading:");
    Serial.printf("  ADC Raw : %d\n", rawADC);
}

// ─────────────────────────────────────────────────────────────
// Evaluasi status kualitas air berdasarkan RAW ADC threshold
// (config.h — sinkron dengan backend thresholds.js)
// ─────────────────────────────────────────────────────────────
void turbidityEvaluate(int raw) {
    Serial.print("  Status  : ");

    if (raw >= TURBIDITY_RAW_CLEAR_MIN) {
        Serial.println("[WARNING] Terlalu jernih — cek aerasi & plankton");
    } else if (raw >= TURBIDITY_RAW_OPTIMAL_MIN && raw <= TURBIDITY_RAW_OPTIMAL_MAX) {
        Serial.println("[OK] OPTIMAL — Kondisi ideal untuk ikan nila");
    } else if (raw > TURBIDITY_RAW_WARNING_MAX && raw < TURBIDITY_RAW_OPTIMAL_MIN) {
        Serial.println("[WARNING] Agak keruh — monitor lebih sering");
    } else {
        Serial.println("[DANGER] Terlalu keruh! Segera filter/ganti air");
    }
}

// ─────────────────────────────────────────────────────────────
// Getter untuk MQTT publish
// ─────────────────────────────────────────────────────────────
int turbidity_get_raw() {
    return rawADC;
}