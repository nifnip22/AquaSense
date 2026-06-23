#ifndef TURBIDITY_H
#define TURBIDITY_H

#include <Arduino.h>
#include "config.h"

// ╔════════════════════════════════════════════════════════════╗
// ║         AquaSense — Turbidity Module (TSW-20M) v2.0       ║
// ║  Optimized: Edge Computing, Stability, Error Handling     ║
// ╚════════════════════════════════════════════════════════════╝

// ─── Wiring TSW-20M ─────────────────────────────────────────
//
//  Sisi Probe         Modul PCB         ESP32
//  ─────────────      ─────────────     ──────────────────────
//  Y (kuning)  ──┐    V  ──────────  →  5V (VIN)
//  B (biru)    ──┤    G  ──────────  →  GND
//  R (merah)   ──┘    A  → [divider] →  GPIO 32
//                     D  → tidak dipakai
//
//  Voltage Divider:
//    Modul AO → R1 (10kΩ) → GPIO 32 → R2 (22kΩ) → GND

// ─── Edge Computing Constants ────────────────────────────────
#define TURBIDITY_BUFFER_SIZE        15      // Moving average buffer
#define TURBIDITY_MEDIAN_WINDOW      5       // Median filter window
#define TURBIDITY_ANOMALY_THRESHOLD  300     // ADC delta for anomaly
#define TURBIDITY_HYSTERESIS         100     // Hysteresis untuk status change
#define TURBIDITY_CALIBRATION_OFFSET 0       // ADC offset kalibrasi

// ─── Sensor Health Monitoring ────────────────────────────────
#define TURBIDITY_MAX_READ_FAILURES  5       // Batas gagal baca sebelum error
#define TURBIDITY_READ_TIMEOUT_MS    5000    // Timeout jika tidak baca > 5s
#define TURBIDITY_VALID_ADC_MIN      100     // ADC minimum untuk valid
#define TURBIDITY_VALID_ADC_MAX      4095    // ADC maximum untuk valid

// ─── Data Structure untuk State Management ───────────────────
typedef struct {
    int raw;                    // Raw ADC terbaru (setelah filter)
    int filtered;               // Filtered value (moving average)
    int trend;                  // Trend detection (-1, 0, +1)
    bool anomaly;               // Anomaly detected flag
    uint8_t readFailures;       // Counter kegagalan baca
    unsigned long lastReadTime; // Timestamp baca terakhir
    bool isHealthy;             // Sensor health status
} TurbidityData_t;

// ─── Function Prototypes ─────────────────────────────────────
void turbiditySetup();
void turbidityLoop();

// Low-level reads
int  turbidity_read_single(int pin);
int  turbidity_read_raw_samples(int pin, int samples);
int  turbidity_apply_median_filter(int* buffer, int size);

// Edge computing
void turbidity_update_buffer(int newValue);
void turbidity_detect_anomaly(int newValue);
void turbidity_detect_trend();
int  turbidity_get_filtered();

// Evaluation
void turbidityEvaluate(int raw);
void turbidityPrint();

// Getter API untuk MQTT & Main
int   turbidity_get_raw();
int   turbidity_get_filtered();
int   turbidity_get_trend();      // -1 (menurun), 0 (stabil), +1 (naik)
bool  turbidity_is_anomaly();
bool  turbidity_is_healthy();
void  turbidity_reset_anomaly();
void  turbidity_set_calibration(int offset);

#endif // TURBIDITY_H