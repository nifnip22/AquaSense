#include "ph_sensor.h"
#include <Preferences.h>

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
static float _voltage_to_ph(float voltage) {
    return _slope * voltage + _intercept;
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
    pinMode(PH_PIN, INPUT);
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
    Serial.printf("[pH] Sensor siap. Pin: GPIO%d | Filter: %.2f\n",
                  PH_PIN, PH_FILTER_ALPHA);
}

// ─────────────────────────────────────────────────────────────
// ph_read_voltage()
// ─────────────────────────────────────────────────────────────
float ph_read_voltage() {
    long total = 0;
    for (int i = 0; i < PH_NUM_SAMPLES; i++) {
        total += analogRead(PH_PIN);
        delay(PH_SAMPLE_INTERVAL);
    }
    int raw = (int)(total / PH_NUM_SAMPLES);
    return (raw / 4095.0f) * 3.3f;
}

// ─────────────────────────────────────────────────────────────
// ph_read()
// ─────────────────────────────────────────────────────────────
float ph_read(bool averaged) {
    float voltage = averaged ? ph_read_voltage() : (analogRead(PH_PIN) / 4095.0f * 3.3f);
    float ph_raw  = _voltage_to_ph(voltage);
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
    if (ph < PH_MIN)       return PH_STATUS_ACIDIC;
    else if (ph > PH_MAX)  return PH_STATUS_ALKALINE;
    else                   return PH_STATUS_OPTIMAL;
}

// ─────────────────────────────────────────────────────────────
// ph_print()
// ─────────────────────────────────────────────────────────────
void ph_print(float ph) {
    String status = ph_get_status(ph);
    Serial.println("─────────────────────────────");
    Serial.println("[pH] Sensor pH 4502C");
    Serial.printf("  Voltage : %.4f V\n",  ph_read_voltage());
    Serial.printf("  pH      : %.2f\n",    ph);
    Serial.printf("  Status  : %s\n",      status.c_str());
    if (ph < PH_MIN)       Serial.println("  ⚠ Terlalu ASAM — cek kualitas air!");
    else if (ph > PH_MAX)  Serial.println("  ⚠ Terlalu BASA — cek kualitas air!");
    else                   Serial.println("  ✓ Normal untuk ikan nila");
    Serial.println("─────────────────────────────");
}

// ─────────────────────────────────────────────────────────────
// ph_calibrate()
// Dipanggil SEKALI dengan tegangan yang diukur saat sensor
// dicelup ke buffer pH 4.0 dan pH 7.0
// ─────────────────────────────────────────────────────────────
void ph_calibrate(float voltage_at_ph4, float voltage_at_ph7) {
    if (voltage_at_ph4 <= 0 || voltage_at_ph7 <= 0 ||
        voltage_at_ph4 == voltage_at_ph7) {
        Serial.println("[pH] ❌ Kalibrasi gagal: tegangan tidak valid!");
        return;
    }

    // Hitung slope dan intercept dari 2 titik:
    // pH = slope * V + intercept
    // → slope     = (pH2 - pH1) / (V2 - V1) = (7.0 - 4.0) / (V_ph7 - V_ph4)
    // → intercept = pH1 - slope * V1

    _slope     = (7.0f - 4.0f) / (voltage_at_ph7 - voltage_at_ph4);
    _intercept = 4.0f - _slope * voltage_at_ph4;

    Serial.printf("[pH] ✅ Kalibrasi berhasil!\n");
    Serial.printf("  V@pH4 : %.4f V\n", voltage_at_ph4);
    Serial.printf("  V@pH7 : %.4f V\n", voltage_at_ph7);
    Serial.printf("  Slope     : %.4f\n", _slope);
    Serial.printf("  Intercept : %.4f\n", _intercept);

    // Simpan ke NVS (permanen, tidak hilang saat restart)
    _prefs.begin(NVS_NAMESPACE, false); // read-write
    _prefs.putFloat(NVS_KEY_SLOPE,  _slope);
    _prefs.putFloat(NVS_KEY_INTERC, _intercept);
    _prefs.putBool(NVS_KEY_VALID,   true);
    _prefs.end();

    _calibrated = true;
    _filtered_ph = NAN; // reset EMA setelah kalibrasi baru

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