#include "temperature.h"
#include "config.h"
#include <OneWire.h>
#include <DallasTemperature.h>

static OneWire          oneWire(PIN_TEMP_SENSOR);
static DallasTemperature sensors(&oneWire);

// Variabel internal untuk pemrosesan data di level Edge
static float filtered_temp = NAN;
static float last_raw_temp = NAN;
static unsigned long last_request_time = 0;

// ── Private Helpers (Pemrosesan Data Lokal) ──────────────────────────
static float _applyCalibration(float suhu) {
    return suhu + TEMP_CALIBRATION_OFFSET;
}

// Edge Anomaly Detection & Smoothing Filter
static float _processEdgeFiltering(float raw_suhu) {
    // 1. Validasi Lonjakan Ekstrem (Spike Filter)
    if (!isnan(last_raw_temp)) {
        if (abs(raw_suhu - last_raw_temp) > TEMP_MAX_SPIKE) {
            Serial.printf("[TEMP] Edge Alert: Terdeteksi lonjakan liar (%.2f°C)! Mengabaikan noise listrik.\n", raw_suhu);
            return filtered_temp; 
        }
    }
    last_raw_temp = raw_suhu;

    // 2. Exponential Moving Average (EMA)
    if (isnan(filtered_temp)) {
        filtered_temp = raw_suhu;
    } else {
        filtered_temp += TEMP_FILTER_ALPHA * (raw_suhu - filtered_temp);
    }
    return filtered_temp;
}

// ── Public Functions ────────────────────────────────────────────────
void temperature_init() {
    sensors.begin();
    sensors.setResolution(DS18B20_RESOLUTION);
    sensors.setWaitForConversion(false); // Async Mode
    
    // Request pembacaan pertama
    sensors.requestTemperatures();
    last_request_time = millis();

    Serial.printf("[TEMP] DS18B20 Edge Initialized (Async Mode, %d-bit)\n", DS18B20_RESOLUTION);
}

float temperature_read() {
    // Cek apakah waktu konversi sensor 10-bit sudah terpenuhi (~190ms)
    if (millis() - last_request_time >= 190) {
        float raw_suhu = sensors.getTempCByIndex(0);

        // Perintahkan konversi baru untuk loop berikutnya
        sensors.requestTemperatures();
        last_request_time = millis();

        if (raw_suhu == DEVICE_DISCONNECTED_C) {
            Serial.println("[TEMP] ERROR: Sensor DS18B20 Terputus secara fisik!");
            filtered_temp = NAN;
            return -999.0f;
        }

        raw_suhu = _applyCalibration(raw_suhu);
        filtered_temp = _processEdgeFiltering(raw_suhu);
    }

    return (isnan(filtered_temp)) ? -999.0f : filtered_temp;
}

void temperature_print(float suhu) {
    if (suhu == -999.0f) return;

    Serial.print("[TEMP] Suhu Air: ");
    Serial.print(suhu, 1);
    Serial.print(" °C");

    // Keputusan Otonom Lokal (Edge Monitoring) dengan Multi-Level Threshold
    if (suhu <= TEMP_KRITIS_MIN) {
        Serial.println("  🚨 KRITIS: Sangat DINGIN! (Bahaya Kematian Ikan)");
    } else if (suhu >= TEMP_KRITIS_MAX) {
        Serial.println("  🚨 KRITIS: Sangat PANAS! (Bahaya Kematian Ikan)");
    } else if (suhu < TEMP_MIN) {
        Serial.println("  ⚠ WARNING: Suhu Dibawah Normal (Masih Aman, tapi perhatikan)");
    } else if (suhu > TEMP_MAX) {
        Serial.println("  ⚠ WARNING: Suhu Diatas Normal (Masih Aman, tapi perhatikan)");
    } else {
        Serial.println("  ✓ OPTIMAL (Kondisi Ideal)");
    }
}