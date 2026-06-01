#include "SoilMoistureSensor.h"

// ─────────────────────────────────────────────────────────────
// Helper internal: map ADC raw → persen
// ─────────────────────────────────────────────────────────────
static float _map_to_percent(int raw) {
    if (DRY_VALUE == WET_VALUE) return 0.0f;

    float pct = (float)(DRY_VALUE - raw) / (float)(DRY_VALUE - WET_VALUE) * 100.0f;
    if (pct < 0.0f)   pct = 0.0f;
    if (pct > 100.0f) pct = 100.0f;
    return pct;
}

// ─────────────────────────────────────────────────────────────
// soil_init()
// ─────────────────────────────────────────────────────────────
void soil_init() {
    pinMode(SOIL_PIN, INPUT);
    Serial.println("[Soil] Sensor kelembapan tanah siap.");
    Serial.printf("[Soil] Pin: GPIO%d | Kering: %d | Basah: %d\n",
                  SOIL_PIN, DRY_VALUE, WET_VALUE);
}

// ─────────────────────────────────────────────────────────────
// soil_read_raw()
// ─────────────────────────────────────────────────────────────
int soil_read_raw() {
    return analogRead(SOIL_PIN);
}

// ─────────────────────────────────────────────────────────────
// soil_read_percent()
// ─────────────────────────────────────────────────────────────
float soil_read_percent() {
    return _map_to_percent(analogRead(SOIL_PIN));
}

// ─────────────────────────────────────────────────────────────
// soil_read_averaged()
// ─────────────────────────────────────────────────────────────
float soil_read_averaged(uint8_t samples) {
    if (samples == 0) samples = 1;

    long total = 0;
    for (uint8_t i = 0; i < samples; i++) {
        total += analogRead(SOIL_PIN);
        delay(10);
    }
    return _map_to_percent((int)(total / samples));
}

// ─────────────────────────────────────────────────────────────
// soil_get_status()
// ─────────────────────────────────────────────────────────────
String soil_get_status(float percent) {
    if (percent < 20.0f)       return SOIL_STATUS_VERY_DRY;
    else if (percent < 40.0f)  return SOIL_STATUS_DRY;
    else if (percent < 70.0f)  return SOIL_STATUS_MOIST;
    else if (percent < 90.0f)  return SOIL_STATUS_WET;
    else                       return SOIL_STATUS_VERY_WET;
}

// ─────────────────────────────────────────────────────────────
// soil_print()
// ─────────────────────────────────────────────────────────────
void soil_print(float percent) {
    String status = soil_get_status(percent);
    Serial.println("─────────────────────────────");
    Serial.println("[Soil] Kelembapan Tanah");
    Serial.printf("  Raw     : %d\n",   soil_read_raw());
    Serial.printf("  Persen  : %.1f%%\n", percent);
    Serial.printf("  Status  : %s\n",   status.c_str());
    Serial.println("─────────────────────────────");
}