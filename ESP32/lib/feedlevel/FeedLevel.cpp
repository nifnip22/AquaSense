#include "FeedLevel.h"
#include <Wire.h>
#include <VL53L0X.h>

// ╔════════════════════════════════════════════════════════════╗
// ║       AquaSense — Feed Level Module (VL53L0X V2)          ║
// ║                                                            ║
// ║  PRINSIP KERJA:                                            ║
// ║  Sensor dipasang di ATAS wadah pakan, menghadap KE BAWAH. ║
// ║  Sensor mengukur jarak dari sensor ke permukaan pakan.     ║
// ║                                                            ║
// ║  [Sensor VL53L0X]                                          ║
// ║       │  ← CONTAINER_HEIGHT_MM (jarak sensor ke dasar)    ║
// ║       │                                                    ║
// ║  ─────┼───────── ← permukaan pakan (jarak = distanceMM)   ║
// ║       │  ← levelMM = CONTAINER_HEIGHT_MM - distanceMM     ║
// ║  ═════╪═════════ ← dasar wadah                            ║
// ║                                                            ║
// ║  Makin KECIL jarak (distanceMM) → pakan MAKIN PENUH       ║
// ╚════════════════════════════════════════════════════════════╝

static VL53L0X sensor;

// ─────────────────────────────────────────────────────────────
// feedLevel_init()
// Inisialisasi VL53L0X via I2C
// Return: true jika sensor berhasil ditemukan
// ─────────────────────────────────────────────────────────────
bool feedLevel_init() {
    Wire.begin(FEED_SDA_PIN, FEED_SCL_PIN);

    if (!sensor.init()) {
        Serial.println("[FEED] ERROR: VL53L0X tidak terdeteksi!");
        Serial.println("[FEED] Periksa wiring SDA/SCL dan power 3.3V.");
        return false;
    }

    // Mode pengukuran: LONG_RANGE untuk wadah tinggi (hingga ~2m)
    sensor.setMeasurementTimingBudget(FEED_TIMING_BUDGET_US);

#if FEED_LONG_RANGE
    // Long range mode: tingkatkan gain, turunkan batas sinyal
    sensor.setSignalRateLimit(0.1);
    sensor.setVcselPulsePeriod(VL53L0X::VcselPeriodPreRange, 18);
    sensor.setVcselPulsePeriod(VL53L0X::VcselPeriodFinalRange, 14);
#endif

    Serial.println("============================================");
    Serial.println("  AquaSense - Feed Level Sensor (VL53L0X)  ");
    Serial.printf("  SDA: GPIO%d | SCL: GPIO%d\n",
                  FEED_SDA_PIN, FEED_SCL_PIN);
    Serial.printf("  Tinggi Wadah  : %d mm\n", FEED_CONTAINER_HEIGHT_MM);
    Serial.printf("  Jarak Min Baca: %d mm\n", FEED_MIN_DISTANCE_MM);
    Serial.printf("  Jarak Maks    : %d mm\n", FEED_MAX_DISTANCE_MM);
    Serial.println("============================================");

    return true;
}

// ─────────────────────────────────────────────────────────────
// feedLevel_read()
// Baca jarak dari sensor, konversi ke level & persentase pakan
// ─────────────────────────────────────────────────────────────
FeedData feedLevel_read() {
    FeedData data;
    data.sensorOK = false;

    uint16_t dist = sensor.readRangeSingleMillimeters();

    // Cek timeout / error sensor
    if (sensor.timeoutOccurred() || dist == 0 || dist > FEED_MAX_DISTANCE_MM) {
        Serial.println("[FEED] ERROR: Timeout atau bacaan tidak valid.");
        data.distanceMM   = 0;
        data.levelPercent = 0.0f;
        data.levelCM      = 0.0f;
        data.status       = "ERROR";
        return data;
    }

    data.sensorOK    = true;
    data.distanceMM  = dist;

    // Sensor VL53L0X tidak bisa mengukur lebih dekat dari FEED_MIN_DISTANCE_MM.
    // Jika permukaan pakan sangat penuh, hitung 100% dari jarak minimum tersebut.
    if (dist < FEED_MIN_DISTANCE_MM) {
        dist = FEED_MIN_DISTANCE_MM;
    }

    // Hitung ketinggian pakan dalam mm
    // levelMM = tinggi wadah - jarak sensor ke permukaan pakan
    int levelMM = (int)FEED_CONTAINER_HEIGHT_MM - (int)dist;
    if (levelMM < 0) levelMM = 0;

    // Konversi ke cm
    data.levelCM = levelMM / 10.0f;

    // Konversi ke persen (0–100%) menggunakan tinggi maksimal yang dapat diukur.
    int maxLevelMM = (int)FEED_CONTAINER_HEIGHT_MM - (int)FEED_MIN_DISTANCE_MM;
    data.levelPercent = ((float)levelMM / (float)maxLevelMM) * 100.0f;
    if (data.levelPercent > 100.0f) data.levelPercent = 100.0f;
    if (data.levelPercent < 0.0f)   data.levelPercent = 0.0f;

    // Tentukan status
    if (data.levelPercent > 75.0f)
        data.status = FEED_STATUS_FULL;
    else if (data.levelPercent > 50.0f)
        data.status = FEED_STATUS_ADEQUATE;
    else if (data.levelPercent > 25.0f)
        data.status = FEED_STATUS_LOW;
    else if (data.levelPercent > 10.0f)
        data.status = FEED_STATUS_CRITICAL;
    else
        data.status = FEED_STATUS_EMPTY;

    return data;
}

// ─────────────────────────────────────────────────────────────
// feedLevel_print()
// Print hasil pembacaan ke Serial Monitor
// ─────────────────────────────────────────────────────────────
void feedLevel_print(const FeedData& data) {
    Serial.println("--------------------------------------------");
    Serial.println("[FEED] Level Pakan Ikan:");

    if (!data.sensorOK) {
        Serial.println("  !! Sensor Error - Data tidak valid !!");
        Serial.println("--------------------------------------------");
        return;
    }

    Serial.printf("  Jarak Sensor  : %d mm\n", data.distanceMM);
    Serial.printf("  Tinggi Pakan  : %.1f cm\n", data.levelCM);
    Serial.printf("  Level         : %.1f%%\n", data.levelPercent);

    // Visual bar indikator (20 karakter)
    int filled = (int)(data.levelPercent / 5.0f);  // 0–20
    Serial.print("  [");
    for (int i = 0; i < 20; i++) {
        Serial.print(i < filled ? "█" : "░");
    }
    Serial.printf("] %.0f%%\n", data.levelPercent);

    // Status dengan tanda peringatan
    Serial.print("  Status        : ");
    if (data.levelPercent <= 10.0f) {
        Serial.println("[!!!] " + data.status + " - Segera isi pakan!");
    } else if (data.levelPercent <= 25.0f) {
        Serial.println("[!!] " + data.status + " - Siapkan pakan!");
    } else if (data.levelPercent <= 50.0f) {
        Serial.println("[!] " + data.status);
    } else {
        Serial.println("[OK] " + data.status);
    }

    Serial.println("--------------------------------------------");
}