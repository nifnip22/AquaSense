#ifndef FEED_LEVEL_H
#define FEED_LEVEL_H

#include <Arduino.h>
#include "config.h"

// ╔════════════════════════════════════════════════════════════╗
// ║       AquaSense — Feed Level Module (VL53L0X V2)          ║
// ║  Sensor : VL53L0X Time-of-Flight Laser Range              ║
// ║  I2C    : SDA → GPIO 21 | SCL → GPIO 22                  ║
// ║  Supply : 3.3V / 5V                                       ║
// ╚════════════════════════════════════════════════════════════╝

// ─── Status Level Pakan ──────────────────────────────────────
#define FEED_STATUS_FULL     "PENUH"         // > 75%
#define FEED_STATUS_ADEQUATE "CUKUP"         // 50–75%
#define FEED_STATUS_LOW      "HAMPIR HABIS"  // 25–50%
#define FEED_STATUS_CRITICAL "KRITIS"        // 10–25%
#define FEED_STATUS_EMPTY    "HABIS"         // < 10%

// ─── Tipe Data Hasil Baca ─────────────────────────────────────
struct FeedData {
    uint16_t distanceMM;    // Jarak terukur sensor ke permukaan pakan (mm)
    float    levelPercent;  // Persentase level pakan (0–100%)
    float    levelCM;       // Ketinggian pakan dalam cm
    String   status;        // Status teks level pakan
    bool     sensorOK;      // true jika sensor terbaca normal
};

// ─── API Publik ───────────────────────────────────────────────
bool      feedLevel_init();
FeedData  feedLevel_read();
void      feedLevel_print(const FeedData& data);

#endif // FEED_LEVEL_H