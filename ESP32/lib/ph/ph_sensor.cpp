#include "ph_sensor.h"
#include "temperature.h"
#include <Preferences.h>

// ╔════════════════════════════════════════════════════════════╗
// ║                AquaSense — PH-4502C v2.0                   ║
// ║  Optimasi: Edge Computing, Stabilitas, Error Handling      ║
// ║  Supply  : 5V ke modul                                     ║
// ║  Output  : AO → voltage divider (10kΩ/22kΩ) → GPIO 32      ║
// ║  ADC     : 12-bit, atenuasi 11db, Vref 3.3V                ║
// ║  Mode    : Median Filter + Moving Average + Trend Detection║
// ╚════════════════════════════════════════════════════════════╝

// ── NVS namespace ─────────────────────────────────────────────
static Preferences _prefs;
#define NVS_NAMESPACE   "ph_cal"
#define NVS_KEY_SLOPE   "slope"
#define NVS_KEY_INTERC  "intercept"
#define NVS_KEY_VALID   "valid"

// ── Parameter kalibrasi aktif ─────────────────────────────────
static float _slope     = PH_DEFAULT_SLOPE;
static float _intercept = PH_DEFAULT_INTERCEPT;
static bool  _calibrated = false;

// ── EMA filter state ──────────────────────────────────────────
static float _filtered_ph = NAN;

// ── Helper ────────────────────────────────────────────────────
static float _voltage_to_ph(float voltage, float current_temp) {
    float active_slope = _slope;
    
    // 🧠 EDGE COMPUTING: Automatic Temperature Compensation (ATC) Nernst
    // Asumsi: Kalibrasi fisik (V@pH4 & V@pH7) dilakukan pada suhu standar 25°C (298.15 K)
    if (current_temp != -999.0f && !isnan(current_temp)) {
        float temp_kelvin = current_temp + 273.15f;
        // Slope tegangan sensor pH (pH/V) berbanding terbalik dengan perubahan suhu absolut (Kelvin)
        active_slope = _slope * (298.15f / temp_kelvin); 
    }
    
    return active_slope * voltage + _intercept;
}

static float _ema_filter(float new_val) {
    if (isnan(_filtered_ph)) {
        _filtered_ph = new_val;
    } else {
        _filtered_ph += PH_FILTER_ALPHA * (new_val - _filtered_ph);
    }
    return _filtered_ph;
}

// ─────────────────────────────────────────────────────────────
// ph_init()
// ─────────────────────────────────────────────────────────────
void ph_init() {
    analogReadResolution(12);
    analogSetPinAttenuation(PH_PIN, ADC_11db);

    // Load kalibrasi dari NVS
    _prefs.begin(NVS_NAMESPACE, true); // read-only
    _calibrated = _prefs.getBool(NVS_KEY_VALID, false);

    if (_calibrated) {
        _slope     = _prefs.getFloat(NVS_KEY_SLOPE,  PH_DEFAULT_SLOPE);
        _intercept = _prefs.getFloat(NVS_KEY_INTERC, PH_DEFAULT_INTERCEPT);
        Serial.printf("[pH] ✅ Kalibrasi dimuat dari NVS: slope=%.4f, intercept=%.4f\n",
                      _slope, _intercept);
    } else {
        Serial.println("[pH] ⚠ Belum dikalibrasi! Gunakan ph_calibrate() sekali.");
        Serial.printf("[pH]   Default slope=%.4f, intercept=%.4f\n",
                      _slope, _intercept);
    }

    _prefs.end();
    Serial.printf("[pH] Sensor siap (ATC Active). Pin: GPIO%d | Filter: %.2f\n",
                  PH_PIN, PH_FILTER_ALPHA);
}

// ─────────────────────────────────────────────────────────────
// ph_read_voltage() -> DIPERBAGUS DENGAN EDGE MEDIAN FILTER
// ─────────────────────────────────────────────────────────────
float ph_read_voltage() {
    int raw_mv[PH_NUM_SAMPLES];
    
    // 1. Ambil sampel milivolt akurat kalibrasi hardware internal ESP32
    for (int i = 0; i < PH_NUM_SAMPLES; i++) {
        raw_mv[i] = analogReadMilliVolts(PH_PIN);
        delay(PH_SAMPLE_INTERVAL);
    }

    // 2. EDGE COMPUTING: Sortir array (Bubble Sort)
    for (int i = 0; i < PH_NUM_SAMPLES - 1; i++) {
        for (int j = i + 1; j < PH_NUM_SAMPLES; j++) {
            if (raw_mv[i] > raw_mv[j]) {
                int temp = raw_mv[i];
                raw_mv[i] = raw_mv[j];
                raw_mv[j] = temp;
            }
        }
    }

    // 3. Buang lonjakan ekstrem (noise), ambil nilai stabil di tengah
    long sum_mv = 0;
    int count = 0;
    // Jika PH_NUM_SAMPLES = 10, kita buang 2 tertinggi & 2 terendah (pakai index 2 sampai 7)
    for (int i = 2; i < PH_NUM_SAMPLES - 2; i++) {
        sum_mv += raw_mv[i];
        count++;
    }
    
    float median_mv = (float)sum_mv / count;
    return median_mv / 1000.0f; // Kembalikan dalam satuan Volt
}

// ─────────────────────────────────────────────────────────────
// ph_read() -> DIINTEGRASIKAN DENGAN SENSOR SUHU
// ─────────────────────────────────────────────────────────────
float ph_read(bool averaged) {
    float voltage = averaged ? ph_read_voltage() : (analogReadMilliVolts(PH_PIN) / 1000.0f);
    
    // 🔗 BACA SUHU SECARA INTERNAL (NON-BLOCKING)
    float current_temp = temperature_read(); 

    // Kalkulasi pH dengan kompensasi suhu
    float ph_raw  = _voltage_to_ph(voltage, current_temp);
    
    // Filter tren akhir
    float ph      = _ema_filter(ph_raw);

    // Clamp ke range fisik yang masuk akal
    if (ph < 0.0f)  ph = 0.0f;
    if (ph > 14.0f) ph = 14.0f;
    return ph;
}

// ─────────────────────────────────────────────────────────────
// ph_get_status()
// ─────────────────────────────────────────────────────────────
String ph_get_status(float ph) {
    if (ph <= PH_KRITIS_MIN)        return "KRITIS ASAM";
    else if (ph <= PH_TOLERANSI_MIN)return "BAHAYA ASAM";
    else if (ph < PH_MIN)           return "Asam (Warning)";
    else if (ph >= PH_KRITIS_MAX)   return "KRITIS BASA";
    else if (ph > PH_TOLERANSI_MAX) return "BAHAYA BASA";
    else if (ph > PH_MAX)           return "Basa (Warning)"; // Tidak tersentuh jika MAX & TOLERANSI sama, tapi disiapkan
    else                            return "Optimal";
}

// ─────────────────────────────────────────────────────────────
// ph_print()
// ─────────────────────────────────────────────────────────────
void ph_print(float ph) {
    String status = ph_get_status(ph);
    float current_temp = temperature_read(); // Intip suhu buat UI

    Serial.println("─────────────────────────────");
    Serial.println("[pH] Sensor pH 4502C (ATC Active)");
    Serial.printf("  Voltage : %.4f V\n",  ph_read_voltage());
    
    if (current_temp != -999.0f && !isnan(current_temp)) {
        Serial.printf("  Suhu Air: %.1f °C (Terkompensasi)\n", current_temp);
    } else {
        Serial.println("  Suhu Air: ⚠ Error/Gagal Dibaca (Kompensasi Mati)");
    }
    
    Serial.printf("  pH      : %.2f\n",    ph);
    Serial.printf("  Status  : %s\n",      status.c_str());
    
    // 🧠 EDGE COMPUTING: Evaluasi Kondisi Berlapis
    if (ph <= PH_KRITIS_MIN) {
        Serial.println("  🚨 FATAL: Sangat ASAM! Segera evakuasi/ganti air!");
    } else if (ph <= PH_TOLERANSI_MIN) {
        Serial.println("  ⚠ BAHAYA: Mendekati Kritis Asam, sistem terancam.");
    } else if (ph < PH_MIN) {
        Serial.println("  ⚠ PERINGATAN: Air mulai Asam. Pantau kualitas air.");
    } else if (ph >= PH_KRITIS_MAX) {
        Serial.println("  🚨 FATAL: Sangat BASA! Segera evakuasi/ganti air!");
    } else if (ph > PH_MAX) { // Karena di config PH_MAX == PH_TOLERANSI_MAX (8.5), masuk ke sini jika > 8.5
        Serial.println("  ⚠ PERINGATAN/BAHAYA: Air menuju Basa. Pantau kualitas air.");
    } else {
        Serial.println("  ✓ Normal (Kualitas Optimal untuk Nila)");
    }
    Serial.println("─────────────────────────────");
}

// ─────────────────────────────────────────────────────────────
// ph_calibrate()
// ─────────────────────────────────────────────────────────────
void ph_calibrate(float voltage_at_ph4, float voltage_at_ph7) {
    if (voltage_at_ph4 <= 0 || voltage_at_ph7 <= 0 ||
        voltage_at_ph4 == voltage_at_ph7) {
        Serial.println("[pH] ❌ Kalibrasi gagal: tegangan tidak valid!");
        return;
    }

    _slope     = (7.0f - 4.0f) / (voltage_at_ph7 - voltage_at_ph4);
    _intercept = 4.0f - _slope * voltage_at_ph4;

    Serial.printf("[pH] ✅ Kalibrasi berhasil!\n");
    Serial.printf("  V@pH4 : %.4f V\n", voltage_at_ph4);
    Serial.printf("  V@pH7 : %.4f V\n", voltage_at_ph7);
    Serial.printf("  Slope     : %.4f\n", _slope);
    Serial.printf("  Intercept : %.4f\n", _intercept);

    // Simpan ke NVS
    _prefs.begin(NVS_NAMESPACE, false); 
    _prefs.putFloat(NVS_KEY_SLOPE,  _slope);
    _prefs.putFloat(NVS_KEY_INTERC, _intercept);
    _prefs.putBool(NVS_KEY_VALID,   true);
    _prefs.end();

    _calibrated = true;
    _filtered_ph = NAN; 

    Serial.println("[pH] 💾 Kalibrasi disimpan ke NVS. Tidak perlu kalibrasi ulang.");
}

// ─────────────────────────────────────────────────────────────
// ph_print_calibration_guide()
// ─────────────────────────────────────────────────────────────
void ph_print_calibration_guide() {
    Serial.println("============================================");
    Serial.println("  PANDUAN KALIBRASI pH 4502C (Sekali Saja)");
    Serial.println("============================================");
    Serial.println("1. Siapkan 2 larutan buffer: pH 4.0 dan pH 7.0");
    Serial.println("2. Celupkan probe ke buffer pH 4.0");
    Serial.println("   Tunggu 30 detik hingga stabil");
    Serial.println("   Catat tegangan yang muncul di Serial Monitor");
    Serial.println("3. Bilas probe dengan air suling");
    Serial.println("4. Celupkan probe ke buffer pH 7.0");
    Serial.println("   Tunggu 30 detik hingga stabil");
    Serial.println("   Catat tegangan");
    Serial.println("5. Jalankan: ph_calibrate(V_pH4, V_pH7)");
    Serial.println("   Contoh: ph_calibrate(3.05, 2.50)");
    Serial.println("6. Selesai! Nilai disimpan permanen di flash.");
    Serial.println("============================================");
}

// ─────────────────────────────────────────────────────────────
bool ph_is_calibrated() {
    return _calibrated;
}