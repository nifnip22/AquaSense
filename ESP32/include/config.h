#ifndef CONFIG_H
#define CONFIG_H

// ── Pin Definitions ──────────────────────────────────────────
#define PIN_TEMP_SENSOR     4     // DS18B20 DATA (kabel kuning)

// ── Temperature Sampling ─────────────────────────────────────
#define TEMP_READ_INTERVAL  2000  // ms

// ── Temperature Threshold Tilapia ────────────────────────────
#define TEMP_MIN            25.0f
#define TEMP_MAX            30.0f

// ─── Konfigurasi Sensor Kelembapan Tanah ──────────────────────────────
#define SOIL_PIN      34      // Pin analog sensor (GPIO34 pada ESP32)
#define DRY_VALUE   3500      // Nilai ADC saat tanah kering  → sesuaikan dengan kalibrasi
#define WET_VALUE    800      // Nilai ADC saat tanah basah   → sesuaikan dengan kalibrasi
#define READ_INTERVAL 2000    // Interval baca (ms)

// ── Turbidity Sensor (TSW-20M) ───────────────────────────────
// Supply modul : 5V (dari pin VIN/5V ESP32)
// Output AO    : 0–4.5V (keruh = tegangan turun)
// Voltage divider WAJIB sebelum pin ADC ESP32:
//   Modul AO → R1 (10kΩ) → GPIO 34 → R2 (22kΩ) → GND
//   Rasio    : Vadc = Vsensor × 22/(10+22) ≈ Vsensor × 0.6875
//   Maks ADC : 4.5V × 0.6875 ≈ 3.09V  (aman untuk ESP32)
// DO tidak digunakan

#define TURBIDITY_AO_PIN    34
#define NUM_SAMPLES         10
#define SAMPLE_INTERVAL     50    // ms antar sampel
#define READ_INTERVAL       2000  // ms antar pembacaan

// ── ADC ESP32 ────────────────────────────────────────────────
#define ADC_RESOLUTION      4095  // 12-bit
#define ADC_VREF            3.3f  // Vref ESP32 (V)

// ── Voltage Divider (10kΩ atas, 22kΩ bawah) ─────────────────
#define VOLT_DIV_RATIO      (22.0f / (10.0f + 22.0f))  // ≈ 0.6875

// ── Tegangan di pin ADC (sesudah voltage divider) ────────────
// Air jernih   : ~4.3V dari modul → 4.3 × 0.6875 ≈ 2.96V di ADC
// Sangat keruh : ~2.5V dari modul → 2.5 × 0.6875 ≈ 1.72V di ADC
#define VOLT_CLEAR          0.800f // V — tegangan ADC saat air jernih
#define VOLT_TURBID         0.500f // V — tegangan ADC saat sangat keruh

// ── Range NTU TSW-20M ────────────────────────────────────────
#define NTU_MAX             4550.0f

// ── Threshold Kualitas Air (Ikan Nila / Tilapia) ─────────────
#define NTU_CLEAR_MAX       1600.0f   // < 25 NTU    : Terlalu jernih
#define NTU_OPTIMAL_MIN     1601.0f   //  25–100 NTU : Optimal
#define NTU_OPTIMAL_MAX     4199.0f
#define NTU_WARNING_MAX     4200.0f  // 100–4550 NTU : Perlu monitor
                                    // > 4550 NTU   : Bahaya

#endif // CONFIG_H