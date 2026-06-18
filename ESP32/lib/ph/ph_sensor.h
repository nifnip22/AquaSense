#ifndef PH_SENSOR_H
#define PH_SENSOR_H

#include <Arduino.h>
#include "config.h"

// ── Status pH ────────────────────────────────────────────────
#define PH_STATUS_ACIDIC    "Asam"      // < PH_MIN
#define PH_STATUS_OPTIMAL   "Optimal"   // PH_MIN – PH_MAX
#define PH_STATUS_ALKALINE  "Basa"      // > PH_MAX

// ── API Publik ───────────────────────────────────────────────
void   ph_init();
float  ph_read_voltage();
float  ph_read(bool averaged = true);
String ph_get_status(float ph);
void   ph_print(float ph);

// ── Kalibrasi (simpan ke NVS, cukup sekali) ──────────────────
void  ph_calibrate(float voltage_at_ph4, float voltage_at_ph7);
void  ph_print_calibration_guide();
bool  ph_is_calibrated();

#endif // PH_SENSOR_H