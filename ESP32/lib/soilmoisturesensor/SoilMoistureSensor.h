#ifndef SOIL_MOISTURE_SENSOR_H
#define SOIL_MOISTURE_SENSOR_H

#include <Arduino.h>
#include "config.h"

// ── Status Kelembapan ────────────────────────────────────────
#define SOIL_STATUS_VERY_DRY  "Sangat Kering"   // < 20%
#define SOIL_STATUS_DRY       "Kering"           // 20–40%
#define SOIL_STATUS_MOIST     "Lembap"           // 40–70%
#define SOIL_STATUS_WET       "Basah"            // 70–90%
#define SOIL_STATUS_VERY_WET  "Sangat Basah"     // > 90%

// ── API Publik ───────────────────────────────────────────────
void   soil_init();
int    soil_read_raw();
float  soil_read_percent();
float  soil_read_averaged(uint8_t samples = 10);
String soil_get_status(float percent);
void   soil_print(float percent);

#endif // SOIL_MOISTURE_SENSOR_H