#ifndef CONFIG_H
#define CONFIG_H

// ╔════════════════════════════════════════════════════════════╗
// ║              AquaSense — ESP32 DevKit V1                  ║
// ║  Sensors: DS18B20 (Temp) | TSW-20M (Turbidity) |         ║
// ║           VL53L0X (Feed Level)                            ║
// ╚════════════════════════════════════════════════════════════╝

// ═════════════════════════════════════════════════════════════
// 1. TEMPERATURE SENSOR — DS18B20
// ═════════════════════════════════════════════════════════════
// Wiring:
//   Data (kuning) → GPIO 14 + pull-up 4.7kΩ ke 3.3V
//   VCC  (merah)  → 3.3V
//   GND  (hitam)  → GND

#define PIN_TEMP_SENSOR         14      // DS18B20 DATA pin

#define TEMP_READ_INTERVAL      500     // ms — interval baca suhu
#define TEMP_SAMPLE_COUNT       5       // jumlah sampel untuk smoothing
#define TEMP_FILTER_ALPHA       0.25f   // EMA filter (lebih kecil = lebih halus)
#define TEMP_CALIBRATION_OFFSET 0.0f   // offset kalibrasi (°C)

// Threshold optimal ikan nila
#define TEMP_MIN                25.0f   // °C — batas bawah
#define TEMP_MAX                30.0f   // °C — batas atas


// ═════════════════════════════════════════════════════════════
// 1B. SOIL MOISTURE SENSOR — Analog probe
// ═════════════════════════════════════════════════════════════
// Wiring:
//   AO   → GPIO 34 (ADC input-only)
//   VCC  → 3.3V
//   GND  → GND
//
// Kalibrasi default ini hanya fallback. Sesuaikan dengan nilai
// sensor Anda setelah membaca raw saat kondisi kering/basah.
#ifndef SOIL_PIN
#define SOIL_PIN                34      // GPIO analog input untuk sensor tanah
#endif

#ifndef DRY_VALUE
#define DRY_VALUE               4095    // nilai raw saat sensor benar-benar kering
#endif

#ifndef WET_VALUE
#define WET_VALUE               1800    // nilai raw saat sensor benar-benar basah
#endif


// ═════════════════════════════════════════════════════════════
// 2. TURBIDITY SENSOR — TSW-20M
// ═════════════════════════════════════════════════════════════
// Wiring:
//   VCC  → 5V (VIN ESP32)
//   GND  → GND
//   AO   → Voltage Divider → GPIO 32
//          R1 = 10kΩ (seri dari AO), R2 = 22kΩ (ke GND)
//          Vadc = Vsensor × 22/(10+22) ≈ Vsensor × 0.6875
//          Max: 4.5V × 0.6875 ≈ 3.09V (aman untuk ESP32)
//   DO   → tidak digunakan

#define TURBIDITY_AO_PIN        32      // GPIO analog input

#define TURBIDITY_NUM_SAMPLES   10      // sampel rata-rata untuk noise reduction
#define TURBIDITY_SAMPLE_INTERVAL 50    // ms antar sampel
#define TURBIDITY_READ_INTERVAL 2000    // ms antar pembacaan utama

// ADC config
#define ADC_RESOLUTION          4095    // 12-bit
#define ADC_VREF                3.3f    // Vref ESP32 (V)

// Voltage divider ratio
#define VOLT_DIV_RATIO          (22.0f / (10.0f + 22.0f))  // ≈ 0.6875

// RAW ADC thresholds — sinkron dengan Backend/src/services/thresholds.js
// Semakin TINGGI raw ADC → air semakin JERNIH
// Semakin RENDAH raw ADC → air semakin KERUH
#define TURBIDITY_RAW_CLEAR_MIN    2100  // ADC >= ini → terlalu jernih
#define TURBIDITY_RAW_OPTIMAL_MAX  2000  // batas atas optimal
#define TURBIDITY_RAW_OPTIMAL_MIN   900  // batas bawah optimal
#define TURBIDITY_RAW_WARNING_MAX   800  // ADC <= ini → danger


// ═════════════════════════════════════════════════════════════
// 3. FEED LEVEL SENSOR — VL53L0X V2 (Time-of-Flight, I2C)
// ═════════════════════════════════════════════════════════════
// Wiring:
//   VCC  → 3.3V
//   GND  → GND
//   SDA  → GPIO 21 (default I2C ESP32)
//   SCL  → GPIO 22 (default I2C ESP32)
//   XSHUT→ (opsional) GPIO 5 — untuk hard reset
//   GPIO1→ tidak digunakan
//
// Prinsip: sensor dipasang di ATAS wadah, menghadap ke bawah.
// Jarak kecil = pakan penuh | Jarak besar = pakan habis

#define FEED_SDA_PIN                21
#define FEED_SCL_PIN                22

// Sesuaikan dengan dimensi DALAM wadah pakan (mm)
#define FEED_CONTAINER_HEIGHT_MM    1300    // mm — tinggi dalam wadah

// Batas valid VL53L0X (default mode: 30–1200mm)
#define FEED_MIN_DISTANCE_MM        1       // mm — pakan sangat penuh
#define FEED_MAX_DISTANCE_MM        1200    // mm — pakan habis / sensor error

// Timing budget: lebih besar = lebih akurat, lebih lambat
// 33000 µs = default | 200000 µs = disarankan untuk pakan
#define FEED_TIMING_BUDGET_US       200000

// Long range mode: set 1 jika wadah > 1.2m
#define FEED_LONG_RANGE             0

// Interval baca feed level
#define FEED_READ_INTERVAL          5000    // ms (setiap 5 detik)

// Threshold level pakan (%)
#define FEED_LEVEL_FULL             75      // % — penuh
#define FEED_LEVEL_ADEQUATE         50      // % — cukup
#define FEED_LEVEL_LOW              25      // % — hampir habis
#define FEED_LEVEL_CRITICAL         10      // % — kritis/habis

#endif // CONFIG_H