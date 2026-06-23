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
//   Data (kuning) → GPIO 4 + pull-up 4.7kΩ ke 3.3V
//   VCC  (merah)  → 3.3V
//   GND  (hitam)  → GND

#define PIN_TEMP_SENSOR         4      // DS18B20 DATA pin

#define TEMP_READ_INTERVAL      500     // ms — interval baca suhu
#define TEMP_FILTER_ALPHA       0.25f   // EMA filter (lebih kecil = lebih halus)
#define TEMP_CALIBRATION_OFFSET 0.0f   // offset kalibrasi (°C)
#define TEMP_MAX_SPIKE          3.0f    // °C — toleransi lonjakan maks antar pembacaan (Edge Anomaly Detection)
#define DS18B20_RESOLUTION      10      // bit — 10-bit konversi cepat (~187.5ms), akurasi 0.25°C (cukup untuk ikan)

// Threshold optimal ikan nila
#define TEMP_MIN                26.0f   // °C — batas optimal bawah
#define TEMP_MAX                32.0f   // °C — batas optimal atas
#define TEMP_KRITIS_MIN         14.0f   // °C — batas kritis bawah
#define TEMP_KRITIS_MAX         35.0f   // °C — batas kritis atas

// ═════════════════════════════════════════════════════════════
// 2. TURBIDITY SENSOR — TSW-20M
// ═════════════════════════════════════════════════════════════
// Wiring:
//   VCC  → 5V (VIN ESP32)
//   GND  → GND
//   AO   → Voltage Divider → GPIO 35
//          R1 = 10kΩ (seri dari AO), R2 = 22kΩ (ke GND)
//          Vadc = Vsensor × 22/(10+22) ≈ Vsensor × 0.6875
//          Max: 4.5V × 0.6875 ≈ 3.09V (aman untuk ESP32)
//   DO   → tidak digunakan

#define TURBIDITY_AO_PIN        35      // GPIO analog input

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
#define TURBIDITY_RAW_CLEAR_MIN    2001  // ADC >= ini → terlalu jernih
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


// ═════════════════════════════════════════════════════════════
// 4. FEED GATE — Servo MG996R (Buka/Tutup Lubang Pakan)
// ═════════════════════════════════════════════════════════════
// Wiring:
//   Sinyal (oranye) → GPIO 13 (PWM)
//   VCC    (merah)  → 5–6V EKSTERNAL (JANGAN dari pin 5V ESP32!)
//   GND    (coklat) → GND ESP32 (WAJIB common ground)
//
// ⚠ PENTING: MG996R bisa menarik arus 1–2A saat start/stall.
// Jika disuplai langsung dari ESP32, board berisiko restart
// atau brownout. Gunakan power supply eksternal 5–6V minimal 2A,
// dan tetap sambungkan GND-nya ke GND ESP32 (common ground).
 
#define SERVO_FEEDER_PIN            13      // GPIO sinyal PWM servo
 
// Sudut servo (derajat) — WAJIB DIKALIBRASI ke mekanisme gerbang
// fisik Anda. Gunakan sketch test_servo_calibration.txt di folder
// /test untuk mencari sudut tertutup & terbuka yang pas sebelum
// mengubah nilai default di bawah ini.
#define SERVO_ANGLE_CLOSED          0       // derajat — posisi tertutup
#define SERVO_ANGLE_OPEN            90      // derajat — posisi terbuka
 
// Pulse width (mikrosekon) — range umum yang aman untuk MG996R
#define SERVO_PULSE_MIN_US          500
#define SERVO_PULSE_MAX_US          2400
 
// Durasi buka (detik). SERVO_DEFAULT_OPEN_SEC dipakai hanya jika
// perintah MQTT/app tidak menyertakan field "duration_sec".
#define SERVO_DEFAULT_OPEN_SEC      3       // detik — default fallback
#define SERVO_MIN_OPEN_SEC          1       // detik — batas bawah (safety)
#define SERVO_MAX_OPEN_SEC          30      // detik — batas atas (safety)


// ═════════════════════════════════════════════════════════════
// 5. PH-4502C
// ═════════════════════════════════════════════════════════════
// Wiring:
// VCC          →   5V (VIN)
// GND          →   GND
// PO (Analog)  →   GPIO 32 (ADC input-only)

#define PH_PIN                  32      // GPIO analog input

#define PH_NUM_SAMPLES          10      // sampel rata-rata
#define PH_SAMPLE_INTERVAL      10      // ms antar sampel
#define PH_READ_INTERVAL        1000    // ms antar pembacaan

#define PH_FILTER_ALPHA         0.15f   // EMA filter (lebih halus)

// Threshold optimal ikan nila
#define PH_KRITIS_MAX           9.0f
#define PH_TOLERANSI_MAX        8.5f
#define PH_MAX                  7.5f
#define PH_MIN                  6.5f
#define PH_TOLERANSI_MIN        6.0f
#define PH_KRITIS_MIN           5.0f

// Default kalibrasi (dipakai sebelum kalibrasi manual)
// Nilai ini AKAN ditimpa setelah kalibrasi disimpan ke NVS
#define PH_DEFAULT_SLOPE        -5.70f  // volt per pH unit (approx)
#define PH_DEFAULT_INTERCEPT    21.34f  // intercept


// ═════════════════════════════════════════════════════════════
// 6. FEED STIRRER — Relay 2 Channel + Motor Power Window
// ═════════════════════════════════════════════════════════════
// Wiring (per channel, motor bisa 2 arah / reversing):
//   ESP32 GPIO(CH1) → IN1 modul relay 5V
//   ESP32 GPIO(CH2) → IN2 modul relay 5V
//   COM1 → Motor Terminal A   | NO1 → Adaptor 12V (+) | NC1 → GND
//   COM2 → Motor Terminal B   | NO2 → Adaptor 12V (+) | NC2 → GND
//
// CH1 & CH2 TIDAK BOLEH aktif bersamaan — sudah dijaga di firmware
// (Stirrer.cpp selalu mematikan channel lain sebelum mengaktifkan
// channel yang baru). Arah motor bergantian otomatis setiap kali
// satu siklus pengadukan selesai.
//
// CATATAN: versi ini sengaja TANPA dioda flyback tambahan dulu
// (keputusan tim: mode prototype/testing). Kontak relay akan lebih
// cepat aus tanpa proteksi ini — pertimbangkan menambah dioda di
// kedua terminal motor (ke GND) kalau alat ini dipakai jangka
// panjang / dipasang permanen.
//
// Jadwal (interval & durasi) diubah dari app lewat MQTT topic
// MQTT_TOPIC_CMD_STIR, disimpan ke NVS (Preferences) agar tetap
// setelah ESP32 restart.
 
#define STIR_RELAY_CH1_PIN          27      // GPIO ke IN1 (arah A)
#define STIR_RELAY_CH2_PIN          26      // GPIO ke IN2 (arah B)
#define STIR_RELAY_ACTIVE_LOW       true    // cek dgn tes nyala/klik — sesuaikan jika ternyata active-HIGH
 
#define STIR_DEFAULT_INTERVAL_MIN   30      // menit antar pengadukan (default sebelum diatur app)
#define STIR_DEFAULT_DURATION_SEC   10      // detik motor menyala tiap pengadukan (default)
 
// Batas aman supaya app tidak bisa kirim nilai yang merusak motor/relay
#define STIR_MIN_INTERVAL_MIN       1
#define STIR_MAX_INTERVAL_MIN       720     // 12 jam
#define STIR_MIN_DURATION_SEC       1
#define STIR_MAX_DURATION_SEC       120     // 2 menit

#endif // CONFIG_H
