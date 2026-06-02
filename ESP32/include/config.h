#ifndef CONFIG_H
#define CONFIG_H

// ── Pin Definitions ──────────────────────────────────────────
#define PIN_TEMP_SENSOR     14     // DS18B20 DATA (kabel kuning)

// ── Temperature Sampling ─────────────────────────────────────
#define TEMP_READ_INTERVAL  500  // ms
#define TEMP_SAMPLE_COUNT   5    // Jumlah sampel suhu untuk smoothing
#define TEMP_FILTER_ALPHA   0.25f // Semakin kecil = lebih halus, namun lambat respons
#define TEMP_CALIBRATION_OFFSET 0.0f // Koreksi offset suhu sensor (°C)

// ── Temperature Threshold Tilapia ────────────────────────────
#define TEMP_MIN            25.0f
#define TEMP_MAX            30.0f


//========================================================================================================
//========================================================================================================


// ─── Konfigurasi Sensor Kelembapan Tanah ──────────────────────────────
#define SOIL_PIN      34      // Pin analog sensor (GPIO34 pada ESP32)
#define DRY_VALUE   3500      // Nilai ADC saat tanah kering  → sesuaikan dengan kalibrasi
#define WET_VALUE    800      // Nilai ADC saat tanah basah   → sesuaikan dengan kalibrasi
#define READ_INTERVAL 2000    // Interval baca (ms)


//========================================================================================================
//========================================================================================================


// ── Turbidity Sensor (TSW-20M) ───────────────────────────────
// Supply modul : 5V (dari pin VIN/5V ESP32)
// Output AO    : 0–4.5V (keruh = tegangan turun)
// Voltage divider WAJIB sebelum pin ADC ESP32:
//   Modul AO → R1 (10kΩ) → GPIO 32 → R2 (22kΩ) → GND
//   Rasio    : Vadc = Vsensor × 22/(10+22) ≈ Vsensor × 0.6875
//   Maks ADC : 4.5V × 0.6875 ≈ 3.09V  (aman untuk ESP32)
// DO tidak digunakan

#define TURBIDITY_AO_PIN    32
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
#define NTU_MAX             0.0f

// ── Threshold Kualitas Air (Ikan Nila / Tilapia) ─────────────
// #define NTU_CLEAR_MAX       85.0f   
// #define NTU_OPTIMAL_MIN     300.0f  
// #define NTU_OPTIMAL_MAX     500.0f
// #define NTU_WARNING_MAX     700.0f 
                               
// ── Turbidity RAW ADC thresholds (used when reporting RAW ADC)
// Adjust these to match your sensor calibration (0-4095)
#define TURBIDITY_RAW_CLEAR_MIN    2100  // ADC >= -> too clear
#define TURBIDITY_RAW_OPTIMAL_MAX  2000  // ADC range considered optimal
#define TURBIDITY_RAW_OPTIMAL_MIN  900  // ADC range considered optimal
#define TURBIDITY_RAW_WARNING_MAX  800  // ADC <= -> warning/danger


//========================================================================================================
//========================================================================================================


// ╔════════════════════════════════════════════════════════════╗
// ║         Feed Level Sensor — VL53L0X V2 (I2C)               ║
// ╠════════════════════════════════════════════════════════════╣
// ║  Wiring:                                                   ║
// ║    VCC  → 3.3V ESP32                                       ║
// ║    GND  → GND ESP32                                        ║
// ║    SDA  → GPIO 21 (default I2C ESP32)                      ║
// ║    SCL  → GPIO 22 (default I2C ESP32)                      ║
// ║    XSHUT→ (opsional) GPIO 5 — untuk reset hardware         ║
// ║    GPIO1→ tidak digunakan                                  ║
// ╚════════════════════════════════════════════════════════════╝
 
// ── Pin I2C VL53L0X ──────────────────────────────────────────
#define FEED_SDA_PIN        21
#define FEED_SCL_PIN        22
 
// ── Dimensi Wadah Pakan ──────────────────────────────────────
// SESUAIKAN dengan tinggi DALAM wadah pakan (mm)
// Contoh: wadah 300mm tinggi → sensor di atas, jarak ke dasar = 300mm
#define FEED_CONTAINER_HEIGHT_MM   1300   // mm — tinggi wadah pakan
 
// ── Batas Jarak Valid VL53L0X ─────────────────────────────────
// VL53L0X default range: 30–1200 mm
// Long-range mode: hingga ~2000 mm (akurasi berkurang)
#define FEED_MIN_DISTANCE_MM       1    // mm — jarak minimum terbaca
                                               // Sensor tidak bisa mengukur lebih dekat dari ini,
                                               // jadi kondisi penuh (=100%) dipetakan dari jarak minimum.
#define FEED_MAX_DISTANCE_MM       1200  // mm — jarak maksimum normal
 
// ── Waktu Pengukuran (Timing Budget) ─────────────────────────
// Makin besar → makin akurat, makin lambat
// 20000  µs = 20 ms  — cepat, noise lebih besar
// 33000  µs = 33 ms  — default
// 200000 µs = 200 ms — akurat, disarankan untuk pakan
#define FEED_TIMING_BUDGET_US      200000
 
// ── Long Range Mode ───────────────────────────────────────────
// Set ke 1 jika wadah pakan tinggi > 1.2m
// Set ke 0 untuk wadah pendek (akurasi lebih baik)
#define FEED_LONG_RANGE            0
 
// ── Interval Pembacaan Feed Level ────────────────────────────
#define FEED_READ_INTERVAL         5000  // ms (setiap 5 detik)

#endif // CONFIG_H