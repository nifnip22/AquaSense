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
// ║  [Sensor VL53L0X]  ← dipasang di tutup wadah              ║
// ║       │  ← CONTAINER_HEIGHT_MM (jarak sensor ke dasar)    ║
// ║       │                                                    ║
// ║  ─────┼──── ← permukaan pakan (jarak = distanceMM)        ║
// ║       │  ← levelMM = CONTAINER_HEIGHT_MM - distanceMM     ║
// ║  ═════╪════ ← dasar wadah                                 ║
// ║                                                            ║
// ║  Jarak KECIL → pakan PENUH                                ║
// ║  Jarak BESAR → pakan HABIS                                ║
// ╚════════════════════════════════════════════════════════════╝

static VL53L0X sensor;

// ─────────────────────────────────────────────────────────────
bool feedLevel_init() {
    Wire.begin(FEED_SDA_PIN, FEED_SCL_PIN);

    if (!sensor.init()) {
        Serial.println("[FEED] ERROR: VL53L0X tidak terdeteksi!");
        Serial.println("[FEED] Periksa wiring SDA(21)/SCL(22) dan power 3.3V.");
        return false;
    }

    sensor.setMeasurementTimingBudget(FEED_TIMING_BUDGET_US);

#if FEED_LONG_RANGE
    sensor.setSignalRateLimit(0.1);
    sensor.setVcselPulsePeriod(VL53L0X::VcselPeriodPreRange, 18);
    sensor.setVcselPulsePeriod(VL53L0X::VcselPeriodFinalRange, 14);
#endif

    Serial.println("============================================");
    Serial.println("  AquaSense - Feed Level Sensor (VL53L0X)  ");
    Serial.printf("  SDA: GPIO%d | SCL: GPIO%d\n", FEED_SDA_PIN, FEED_SCL_PIN);
    Serial.printf("  Tinggi Wadah   : %d mm\n",  FEED_CONTAINER_HEIGHT_MM);
    Serial.printf("  Jarak Min Valid: %d mm\n",  FEED_MIN_DISTANCE_MM);
    Serial.printf("  Jarak Maks     : %d mm\n",  FEED_MAX_DISTANCE_MM);
    Serial.printf("  Threshold: Full>%d%% | Cukup>%d%% | Low>%d%% | Kritis>%d%%\n",
                  FEED_LEVEL_FULL, FEED_LEVEL_ADEQUATE,
                  FEED_LEVEL_LOW,  FEED_LEVEL_CRITICAL);
    Serial.println("============================================");

    return true;
}

// ─────────────────────────────────────────────────────────────
FeedData feedLevel_read() {
    FeedData data;
    data.sensorOK = false;

    uint16_t dist = sensor.readRangeSingleMillimeters();

    if (sensor.timeoutOccurred() || dist == 0 || dist > FEED_MAX_DISTANCE_MM) {
        Serial.println("[FEED] ERROR: Timeout atau bacaan tidak valid.");
        data.distanceMM   = 0;
        data.levelPercent = 0.0f;
        data.levelCM      = 0.0f;
        data.status       = "ERROR";
        return data;
    }

    data.sensorOK   = true;
    data.distanceMM = dist;

    // Clamp jika terlalu dekat (sensor tidak bisa baca < MIN)
    uint16_t clampedDist = (dist < FEED_MIN_DISTANCE_MM) ? FEED_MIN_DISTANCE_MM : dist;

    // levelMM = tinggi wadah - jarak sensor ke permukaan pakan
    int levelMM = (int)FEED_CONTAINER_HEIGHT_MM - (int)clampedDist;
    if (levelMM < 0) levelMM = 0;

    data.levelCM = levelMM / 10.0f;

    // Konversi ke persen terhadap tinggi maksimal yang terukur
    int maxLevelMM = (int)FEED_CONTAINER_HEIGHT_MM - (int)FEED_MIN_DISTANCE_MM;
    data.levelPercent = ((float)levelMM / (float)maxLevelMM) * 100.0f;
    if (data.levelPercent > 100.0f) data.levelPercent = 100.0f;
    if (data.levelPercent < 0.0f)   data.levelPercent = 0.0f;

    // Status berdasarkan threshold dari config.h
    if (data.levelPercent > (float)FEED_LEVEL_FULL)
        data.status = FEED_STATUS_FULL;
    else if (data.levelPercent > (float)FEED_LEVEL_ADEQUATE)
        data.status = FEED_STATUS_ADEQUATE;
    else if (data.levelPercent > (float)FEED_LEVEL_LOW)
        data.status = FEED_STATUS_LOW;
    else if (data.levelPercent > (float)FEED_LEVEL_CRITICAL)
        data.status = FEED_STATUS_CRITICAL;
    else
        data.status = FEED_STATUS_EMPTY;

    return data;
}

// ─────────────────────────────────────────────────────────────
void feedLevel_print(const FeedData& data) {
    Serial.println("--------------------------------------------");
    Serial.println("[FEED] Level Pakan Ikan:");

    if (!data.sensorOK) {
        Serial.println("  !! Sensor Error - Data tidak valid !!");
        Serial.println("--------------------------------------------");
        return;
    }

    Serial.printf("  Jarak Sensor : %d mm\n",    data.distanceMM);
    Serial.printf("  Tinggi Pakan : %.1f cm\n",  data.levelCM);
    Serial.printf("  Level        : %.1f%%\n",   data.levelPercent);

    // Visual bar (20 karakter)
    int filled = (int)(data.levelPercent / 5.0f);
    Serial.print("  [");
    for (int i = 0; i < 20; i++) Serial.print(i < filled ? "█" : "░");
    Serial.printf("] %.0f%%\n", data.levelPercent);

    Serial.print("  Status       : ");
    if (data.levelPercent <= (float)FEED_LEVEL_CRITICAL) {
        Serial.println("[!!!] " + data.status + " — Segera isi pakan!");
    } else if (data.levelPercent <= (float)FEED_LEVEL_LOW) {
        Serial.println("[!!] " + data.status + " — Siapkan pakan!");
    } else if (data.levelPercent <= (float)FEED_LEVEL_ADEQUATE) {
        Serial.println("[!] " + data.status);
    } else {
        Serial.println("[OK] " + data.status);
    }
}