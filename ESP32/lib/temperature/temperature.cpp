#include "temperature.h"
#include "config.h"
#include <OneWire.h>
#include <DallasTemperature.h>

// ── Private objects ───────────────────────────
static OneWire          oneWire(PIN_TEMP_SENSOR);
static DallasTemperature sensors(&oneWire);

// ── Public functions ──────────────────────────
void temperature_init() {
    sensors.begin();
    Serial.println("[TEMP] DS18B20 initialized.");
}

float temperature_read() {
    sensors.requestTemperatures();
    float suhu = sensors.getTempCByIndex(0);

    if (suhu == DEVICE_DISCONNECTED_C) {
        Serial.println("[TEMP] ERROR: Sensor disconnected!");
        return -999.0f;
    }
    return suhu;
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