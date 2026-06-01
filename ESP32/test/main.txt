#include <Arduino.h>

// ************************************************************
// * Sensor: Kekeruhan Air (Turbidity) dengan SEN0189
// * Fungsi: Mengukur tingkat kekeruhan air
// * Author: M. Rengga Wicaksono
// * Tanggal: 2026-05-26
// ************************************************************


// ─── Pin Definition ─────────────────────────────────────────
#define TURBIDITY_AO_PIN  34      // Analog Output → GPIO34
#define TURBIDITY_DO_PIN  35      // Digital Output → GPIO35
#define NUM_SAMPLES       10      // Jumlah sampel untuk rata-rata
#define SAMPLE_INTERVAL   50      // Interval antar sampel (ms)
#define READ_INTERVAL     2000    // Interval pembacaan utama (ms)


// ─── Thresholds untuk Ikan Nila ─────────────────────────────
// Nilai NTU (Nephelometric Turbidity Unit)
// Nila optimal: 25–40 NTU (FAO / referensi budidaya)
#define NTU_CLEAR_MAX     25.0   // Di bawah ini: terlalu jernih
#define NTU_OPTIMAL_MIN   25.0   // Batas bawah optimal
#define NTU_OPTIMAL_MAX   40.0   // Batas atas optimal
#define NTU_WARNING_MAX   80.0   // Di atas ini: mulai berbahaya > 80 NTU: keruh berlebihan


// ─── Variabel Global ────────────────────────────────────────
float   turbidityNTU    = 0.0;
int     rawADC          = 0;
float   voltage         = 0.0;
unsigned long lastRead  = 0;


// ─── Function Prototypes ────────────────────────────────────
int   readAveragedADC(int pin, int samples);
float adcToVoltage(int adcValue);
float voltageToNTU(float volt);
float map_float(float x, float in_min, float in_max, float out_min, float out_max);
void  printTurbidityData();
void  evaluateWaterQuality(float ntu);


// ────────────────────────────────────────────────────────────
void setup() {
  Serial.begin(115200);
  delay(500);

  // Konfigurasi ADC ESP32
  pinMode(TURBIDITY_DO_PIN, INPUT);   // ← tambahkan ini untuk membaca digital output (jika diperlukan)
  analogReadResolution(12);         // 12-bit: nilai 0–4095
  analogSetAttenuation(ADC_11db);   // Range tegangan: 0–3.3V

  Serial.println("============================================");
  Serial.println("  AquaSense - Turbidity Sensor Initialized ");
  Serial.println("  Target Spesies: Ikan Nila (Tilapia)      ");
  Serial.println("============================================");
  Serial.println();
}


// ────────────────────────────────────────────────────────────
void loop() {
  unsigned long now = millis();

  if (now - lastRead >= READ_INTERVAL) {
    lastRead = now;

    // Baca dan proses data sensor
    bool digitalState = digitalRead(TURBIDITY_DO_PIN);
    rawADC        = readAveragedADC(TURBIDITY_AO_PIN, NUM_SAMPLES);
    voltage       = adcToVoltage(rawADC);
    turbidityNTU  = voltageToNTU(voltage);

    // Tampilkan hasil
    printTurbidityData();
    evaluateWaterQuality(turbidityNTU);
    Serial.println("--------------------------------------------");
  }
}


// ────────────────────────────────────────────────────────────
//  FUNGSI: Rata-rata ADC untuk mengurangi noise
// ────────────────────────────────────────────────────────────
int readAveragedADC(int pin, int samples) {
  long total = 0;
  for (int i = 0; i < samples; i++) {
    total += analogRead(pin);
    delay(SAMPLE_INTERVAL);
  }
  return (int)(total / samples);
}


// ────────────────────────────────────────────────────────────
//  FUNGSI: Konversi ADC → Tegangan (Volt)
// ────────────────────────────────────────────────────────────
float adcToVoltage(int adcValue) {
  // ESP32 ADC 12-bit dengan attenuation 11dB → max ~3.3V
  return (adcValue / 4095.0) * 3.3;
}


// ────────────────────────────────────────────────────────────
//  FUNGSI: Konversi Tegangan → NTU
//  Formula linear berdasarkan karakteristik SEN0189:
//  Jernih (NTU rendah)  → Tegangan TINGGI (~4.2V di 5V sensor)
//  Keruh  (NTU tinggi)  → Tegangan RENDAH
//
//  Karena ESP32 membaca 0–3.3V (setelah voltage divider internal
//  sensor), gunakan pemetaan linear sebagai estimasi:
//  V ≈ 2.5V  → ~0 NTU  (sangat jernih)
//  V ≈ 0.5V  → ~100 NTU (sangat keruh)
// ────────────────────────────────────────────────────────────
#define VOLT_CLEAR   2.80    // Ukur sendiri saat air jernih
#define VOLT_TURBID  0.33    // Ukur sendiri saat air keruh

float voltageToNTU(float volt) {
  float ntu = 0.0;

  if (volt >= VOLT_CLEAR) {
    ntu = 0.0;
  } else if (volt <= VOLT_TURBID) {
    ntu = 100.0;
  } else {
    ntu = map_float(volt, VOLT_CLEAR, VOLT_TURBID, 0.0, 100.0);
  }

  return constrain(ntu, 0.0, 100.0);
}


// ────────────────────────────────────────────────────────────
//  FUNGSI: Map float (seperti map() tapi untuk float)
// ────────────────────────────────────────────────────────────
float map_float(float x, float in_min, float in_max,
                float out_min, float out_max) {
  return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}


// ────────────────────────────────────────────────────────────
//  FUNGSI: Tampilkan data ke Serial Monitor
// ────────────────────────────────────────────────────────────
void printTurbidityData() {
  Serial.println("[AquaSense] Turbidity Reading:");
  Serial.print("  ADC Raw   : "); Serial.println(rawADC);
  Serial.print("  Voltage   : "); Serial.print(voltage, 3);
  Serial.println(" V");
  Serial.print("  Turbidity : "); Serial.print(turbidityNTU, 2);
  Serial.println(" NTU");
  Serial.print("  DO State  : ");
  Serial.println(digitalRead(TURBIDITY_DO_PIN) ? "HIGH (Jernih)" : "LOW (Keruh)");
}


// ────────────────────────────────────────────────────────────
//  FUNGSI: Evaluasi kualitas air untuk ikan nila
// ────────────────────────────────────────────────────────────
void evaluateWaterQuality(float ntu) {
  Serial.print("  Status    : ");

  if (ntu < NTU_CLEAR_MAX) {
    Serial.println("⚠️  TERLALU JERNIH — Risiko stres cahaya, tambah aerasi");
  } else if (ntu >= NTU_OPTIMAL_MIN && ntu <= NTU_OPTIMAL_MAX) {
    Serial.println("✅  OPTIMAL — Kondisi ideal untuk ikan nila");
  } else if (ntu > NTU_OPTIMAL_MAX && ntu <= NTU_WARNING_MAX) {
    Serial.println("⚠️  AGAK KERUH — Monitor lebih sering, cek pakan");
  } else if (ntu > NTU_WARNING_MAX) {
    Serial.println("🚨  BAHAYA — Air terlalu keruh! Segera ganti/filter air");
  }
}