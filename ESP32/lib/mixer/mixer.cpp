#include "mixer.h"
#include <ArduinoJson.h>
#include <Preferences.h>
#include <time.h>

// ╔════════════════════════════════════════════════════════════╗
// ║        AquaSense — Mixer Module (Clock-Based Schedule)     ║
// ╚════════════════════════════════════════════════════════════╝

// ── NTP Config ────────────────────────────────────────────────
// UTC+8 = Asia/Makassar (Kalimantan Timur)
#define NTP_SERVER      "pool.ntp.org"
#define NTP_GMT_OFFSET  (8 * 3600)   // UTC+8 dalam detik
#define NTP_DST_OFFSET  0

// ── Private state ─────────────────────────────────────────────
static MixerSchedule  _schedules[MIXER_MAX_SCHEDULES];
static uint8_t        _scheduleCount  = 0;

static bool           _isOn           = false;
static unsigned long  _turnOffAtMs    = 0;    // 0 = tidak ada timer

static Preferences    _prefs;
#define NVS_NAMESPACE   "mixer"
#define NVS_KEY_COUNT   "sched_count"
#define NVS_KEY_SCHED   "sched_data"  // simpan JSON ringkas

// Untuk cegah trigger jadwal ganda dalam 1 menit yang sama
static int  _lastTriggeredHour   = -1;
static int  _lastTriggeredMinute = -1;

// ── Helper: relay control ─────────────────────────────────────
// Reuse pin dari config.h (STIR_RELAY_CH1_PIN / CH2_PIN)
// Untuk mixer: cukup CH1 saja (satu arah), CH2 selalu OFF
static inline void _relayWrite(bool energized) {
    bool level = STIR_RELAY_ACTIVE_LOW ? !energized : energized;
    digitalWrite(STIR_RELAY_CH1_PIN, level ? HIGH : LOW);
    digitalWrite(STIR_RELAY_CH2_PIN, LOW);  // CH2 selalu mati untuk mixer
}

// ── Helper: simpan jadwal ke NVS ─────────────────────────────
static void _saveSchedulesToNVS() {
    // Simpan sebagai JSON ringkas: [[jam,menit,durasi],...]
    JsonDocument doc;
    JsonArray arr = doc.to<JsonArray>();
    for (uint8_t i = 0; i < _scheduleCount; i++) {
        JsonArray item = arr.add<JsonArray>();
        item.add(_schedules[i].hour);
        item.add(_schedules[i].minute);
        item.add(_schedules[i].duration_min);
    }
    String json;
    serializeJson(doc, json);

    _prefs.begin(NVS_NAMESPACE, false);
    _prefs.putString(NVS_KEY_SCHED, json);
    _prefs.putUChar(NVS_KEY_COUNT,  _scheduleCount);
    _prefs.end();

    Serial.printf("[Mixer] 💾 %d jadwal disimpan ke NVS.\n", _scheduleCount);
}

// ── Helper: muat jadwal dari NVS ─────────────────────────────
static void _loadSchedulesFromNVS() {
    _prefs.begin(NVS_NAMESPACE, true);
    _scheduleCount = _prefs.getUChar(NVS_KEY_COUNT, 0);
    String json    = _prefs.getString(NVS_KEY_SCHED, "[]");
    _prefs.end();

    if (_scheduleCount == 0) return;

    JsonDocument doc;
    DeserializationError err = deserializeJson(doc, json);
    if (err || !doc.is<JsonArray>()) {
        Serial.println("[Mixer] ⚠ Gagal load jadwal dari NVS, reset.");
        _scheduleCount = 0;
        return;
    }

    JsonArray arr  = doc.as<JsonArray>();
    _scheduleCount = 0;
    for (JsonArray item : arr) {
        if (_scheduleCount >= MIXER_MAX_SCHEDULES) break;
        _schedules[_scheduleCount].hour         = item[0];
        _schedules[_scheduleCount].minute       = item[1];
        _schedules[_scheduleCount].duration_min = item[2];
        _schedules[_scheduleCount].valid        = true;
        _scheduleCount++;
    }

    Serial.printf("[Mixer] 📂 %d jadwal dimuat dari NVS.\n", _scheduleCount);
    for (uint8_t i = 0; i < _scheduleCount; i++) {
        Serial.printf("  [%d] %02d:%02d — %d menit\n",
            i + 1,
            _schedules[i].hour,
            _schedules[i].minute,
            _schedules[i].duration_min);
    }
}

// ─────────────────────────────────────────────────────────────
// mixer_init()
// ─────────────────────────────────────────────────────────────
void mixer_init() {
    pinMode(STIR_RELAY_CH1_PIN, OUTPUT);
    pinMode(STIR_RELAY_CH2_PIN, OUTPUT);
    _relayWrite(false);  // pastikan mati saat boot

    // Inisialisasi NTP
    configTime(NTP_GMT_OFFSET, NTP_DST_OFFSET, NTP_SERVER);
    Serial.println("[Mixer] ⏰ Sinkronisasi NTP...");

    // Tunggu NTP sampai dapat waktu (maks 10 detik)
    struct tm timeinfo;
    unsigned long start = millis();
    while (!getLocalTime(&timeinfo) && millis() - start < 10000) {
        delay(500);
        Serial.print(".");
    }
    if (getLocalTime(&timeinfo)) {
        Serial.printf("\n[Mixer] ✅ Waktu NTP: %02d:%02d:%02d\n",
                      timeinfo.tm_hour, timeinfo.tm_min, timeinfo.tm_sec);
    } else {
        Serial.println("\n[Mixer] ⚠ NTP timeout! Jadwal tidak akan berjalan sampai waktu sync.");
    }

    // Load jadwal dari NVS (bertahan setelah restart)
    _loadSchedulesFromNVS();

    Serial.printf("[Mixer] Relay CH1: GPIO%d | CH2: GPIO%d\n",
                  STIR_RELAY_CH1_PIN, STIR_RELAY_CH2_PIN);
    Serial.println("[Mixer] Siap. Jadwal akan dicek setiap menit.");
}

// ─────────────────────────────────────────────────────────────
// mixer_loop()
// Non-blocking — dipanggil setiap iterasi loop() utama
// ─────────────────────────────────────────────────────────────
void mixer_loop() {
    unsigned long now = millis();

    // 1. Cek timer OFF (manual atau dari jadwal)
    if (_isOn && _turnOffAtMs != 0 && now >= _turnOffAtMs) {
        mixer_turn_off();
        return;
    }

    // 2. Cek jadwal clock-based (hanya jika mixer tidak sedang ON)
    if (!_isOn && _scheduleCount > 0) {
        struct tm timeinfo;
        if (!getLocalTime(&timeinfo)) return;  // NTP belum sync

        int currentHour   = timeinfo.tm_hour;
        int currentMinute = timeinfo.tm_min;

        // Cegah trigger ganda di menit yang sama
        bool alreadyTriggered = (_lastTriggeredHour   == currentHour &&
                                 _lastTriggeredMinute == currentMinute);

        if (!alreadyTriggered) {
            for (uint8_t i = 0; i < _scheduleCount; i++) {
                if (_schedules[i].hour   == currentHour &&
                    _schedules[i].minute == currentMinute) {

                    Serial.printf("[Mixer] ⏰ Jadwal %02d:%02d cocok — ON selama %d menit\n",
                                  currentHour, currentMinute, _schedules[i].duration_min);

                    mixer_turn_on(_schedules[i].duration_min);
                    _lastTriggeredHour   = currentHour;
                    _lastTriggeredMinute = currentMinute;
                    break;
                }
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────
// mixer_turn_on()
// ─────────────────────────────────────────────────────────────
void mixer_turn_on(uint16_t duration_min) {
    if (duration_min < 1)   duration_min = 1;
    if (duration_min > 120) duration_min = 120;

    _relayWrite(true);
    _isOn        = true;
    _turnOffAtMs = millis() + ((unsigned long)duration_min * 60000UL);

    Serial.printf("[Mixer] 🟢 ON — durasi %d menit, mati otomatis pukul +%dm\n",
                  duration_min, duration_min);
}

// ─────────────────────────────────────────────────────────────
// mixer_turn_off()
// ─────────────────────────────────────────────────────────────
void mixer_turn_off() {
    _relayWrite(false);
    _isOn        = false;
    _turnOffAtMs = 0;
    Serial.println("[Mixer] 🔴 OFF");
}

// ─────────────────────────────────────────────────────────────
// mixer_set_schedules()
// Dipanggil dari _mqtt_callback saat terima command/mixer_schedules
// json_array contoh: [{"time":"08:00","duration_min":15},...]
// ─────────────────────────────────────────────────────────────
void mixer_set_schedules(const String& json_array) {
    JsonDocument doc;
    DeserializationError err = deserializeJson(doc, json_array);

    if (err || !doc.is<JsonArray>()) {
        Serial.printf("[Mixer] ❌ JSON jadwal tidak valid: %s\n", err.c_str());
        return;
    }

    // Reset semua jadwal lama
    memset(_schedules, 0, sizeof(_schedules));
    _scheduleCount = 0;

    for (JsonObject item : doc.as<JsonArray>()) {
        if (_scheduleCount >= MIXER_MAX_SCHEDULES) {
            Serial.printf("[Mixer] ⚠ Maks %d jadwal, sisanya diabaikan.\n", MIXER_MAX_SCHEDULES);
            break;
        }

        const char* timeStr    = item["time"]         | "";
        uint16_t    durationMin = item["duration_min"] | 15;

        // Parse "HH:MM"
        int hour = -1, minute = -1;
        if (sscanf(timeStr, "%d:%d", &hour, &minute) != 2 ||
            hour < 0 || hour > 23 || minute < 0 || minute > 59) {
            Serial.printf("[Mixer] ⚠ Format waktu tidak valid: '%s' — dilewati.\n", timeStr);
            continue;
        }

        _schedules[_scheduleCount].hour         = (uint8_t)hour;
        _schedules[_scheduleCount].minute       = (uint8_t)minute;
        _schedules[_scheduleCount].duration_min = constrain(durationMin, 1, 120);
        _schedules[_scheduleCount].valid        = true;
        _scheduleCount++;
    }

    // Reset tracker trigger agar jadwal baru bisa langsung aktif
    _lastTriggeredHour   = -1;
    _lastTriggeredMinute = -1;

    // Simpan ke NVS
    _saveSchedulesToNVS();

    Serial.printf("[Mixer] ✅ %d jadwal baru disimpan:\n", _scheduleCount);
    for (uint8_t i = 0; i < _scheduleCount; i++) {
        Serial.printf("  [%d] %02d:%02d — %d menit\n",
            i + 1,
            _schedules[i].hour,
            _schedules[i].minute,
            _schedules[i].duration_min);
    }
}

// ─────────────────────────────────────────────────────────────
// Getter
// ─────────────────────────────────────────────────────────────
bool mixer_is_on() {
    return _isOn;
}

uint32_t mixer_remaining_sec() {
    if (!_isOn || _turnOffAtMs == 0) return 0;
    unsigned long now = millis();
    if (now >= _turnOffAtMs)         return 0;
    return (uint32_t)((_turnOffAtMs - now) / 1000UL);
}

uint8_t mixer_schedule_count() {
    return _scheduleCount;
}