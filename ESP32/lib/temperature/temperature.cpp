#include "temperature.h"
#include "config.h"
#include <OneWire.h>
#include <DallasTemperature.h>

// ── Private objects ───────────────────────────
static OneWire          oneWire(PIN_TEMP_SENSOR);
static DallasTemperature sensors(&oneWire);

// ── Internal helpers ──────────────────────────
static float _applyCalibration(float suhu) {
    return suhu + TEMP_CALIBRATION_OFFSET;
}

static float _smoothTemperature(float suhu) {
    static float filtered = NAN;

    if (isnan(filtered)) {
        filtered = suhu;
    } else {
        filtered += TEMP_FILTER_ALPHA * (suhu - filtered);
    }
    return filtered;
}

// ── Public functions ──────────────────────────
void temperature_init() {
    sensors.begin();
    Serial.printf("[TEMP] DS18B20 initialized. Offset=%.1f°C, Filter=%.2f\n",
                  TEMP_CALIBRATION_OFFSET, TEMP_FILTER_ALPHA);
}

float temperature_read() {
    sensors.requestTemperatures();
    float suhu = sensors.getTempCByIndex(0);

    if (suhu == DEVICE_DISCONNECTED_C) {
        Serial.println("[TEMP] ERROR: Sensor disconnected!");
        return -999.0f;
    }

    suhu = _applyCalibration(suhu);
    return _smoothTemperature(suhu);
}

void temperature_print(float suhu) {
    if (suhu == -999.0f) return;

    Serial.print("[TEMP] Suhu Air: ");
    Serial.print(suhu, 1);
    Serial.print(" °C");

    if (suhu < TEMP_MIN) {
        Serial.println("  ⚠ Terlalu DINGIN");
    } else if (suhu > TEMP_MAX) {
        Serial.println("  ⚠ Terlalu PANAS");
    } else {
        Serial.println("  ✓ Normal");
    }
}