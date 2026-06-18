#include "Stirrer.h"
#include <Preferences.h>

// ── Private objects ───────────────────────────────────────────
static Preferences prefs;

// ── State jadwal (bisa diubah dari app via MQTT) ───────────────
static uint32_t intervalMin = STIR_DEFAULT_INTERVAL_MIN;
static uint16_t durationSec = STIR_DEFAULT_DURATION_SEC;

// ── State motor ──────────────────────────────────────────────
static bool          isRunning   = false;
static uint8_t       currentDir  = STIR_DIR_A;
static unsigned long lastStirAt  = 0;   // millis() saat siklus interval terakhir mulai dihitung
static unsigned long stirStartAt = 0;   // millis() saat motor ON

// ─────────────────────────────────────────────────────────────
// Helper internal: tulis ke salah satu channel relay
// ─────────────────────────────────────────────────────────────
static inline void _relayWrite(uint8_t channel, bool energized) {
    uint8_t pin   = (channel == STIR_DIR_A) ? STIR_RELAY_CH1_PIN : STIR_RELAY_CH2_PIN;
    bool    level = STIR_RELAY_ACTIVE_LOW ? !energized : energized;
    digitalWrite(pin, level ? HIGH : LOW);
}

static inline void _motorOff() {
    _relayWrite(STIR_DIR_A, false);
    _relayWrite(STIR_DIR_B, false);
}

// Nyalakan motor ke arah tertentu — pastikan channel lain mati dulu
// supaya CH1 & CH2 tidak pernah aktif bersamaan.
static inline void _motorRun(uint8_t direction) {
    uint8_t other = (direction == STIR_DIR_A) ? STIR_DIR_B : STIR_DIR_A;
    _relayWrite(other, false);
    _relayWrite(direction, true);
}

static void _startActivation() {
    if (isRunning) return;

    isRunning   = true;
    stirStartAt = millis();
    _motorRun(currentDir);

    Serial.printf("[Stirrer] Motor ON — arah %s\n", currentDir == STIR_DIR_A ? "A" : "B");
}

static void _stopActivation() {
    if (!isRunning) return;

    _motorOff();
    isRunning = false;

    // Gantian arah untuk aktivasi berikutnya (bolak-balik otomatis)
    currentDir = (currentDir == STIR_DIR_A) ? STIR_DIR_B : STIR_DIR_A;
    prefs.putUChar("lastDir", currentDir);

    lastStirAt = millis(); // hitung ulang interval dari titik motor berhenti

    Serial.printf("[Stirrer] Motor OFF — arah berikutnya: %s\n",
                  currentDir == STIR_DIR_A ? "A" : "B");
}

// ─────────────────────────────────────────────────────────────
// stirrer_init()
// ─────────────────────────────────────────────────────────────
void stirrer_init() {
    pinMode(STIR_RELAY_CH1_PIN, OUTPUT);
    pinMode(STIR_RELAY_CH2_PIN, OUTPUT);
    _motorOff(); // pastikan motor mati saat boot

    prefs.begin("stirrer", false);
    intervalMin = prefs.getUInt("interval", STIR_DEFAULT_INTERVAL_MIN);
    durationSec = prefs.getUShort("duration", STIR_DEFAULT_DURATION_SEC);
    currentDir  = prefs.getUChar("lastDir", STIR_DIR_A);

    lastStirAt = millis();

    Serial.println("[Stirrer] Modul pengaduk pakan siap (2 arah, tanpa dioda tambahan - mode prototype).");
    Serial.printf("[Stirrer] CH1=GPIO%d | CH2=GPIO%d | Interval=%lu menit | Durasi=%u detik\n",
                  STIR_RELAY_CH1_PIN, STIR_RELAY_CH2_PIN, intervalMin, durationSec);
}

// ─────────────────────────────────────────────────────────────
// stirrer_set_schedule()
// Dipanggil dari MQTT callback saat app mengubah jadwal.
// Nilai disimpan ke NVS supaya tetap setelah ESP32 restart.
// ─────────────────────────────────────────────────────────────
void stirrer_set_schedule(uint32_t newIntervalMin, uint16_t newDurationSec) {
    newIntervalMin = constrain(newIntervalMin, STIR_MIN_INTERVAL_MIN, STIR_MAX_INTERVAL_MIN);
    newDurationSec = constrain(newDurationSec, STIR_MIN_DURATION_SEC, STIR_MAX_DURATION_SEC);

    intervalMin = newIntervalMin;
    durationSec = newDurationSec;

    prefs.putUInt("interval", intervalMin);
    prefs.putUShort("duration", durationSec);

    Serial.printf("[Stirrer] Jadwal diupdate dari app -> Interval=%lu menit | Durasi=%u detik\n",
                  intervalMin, durationSec);
}

// ─────────────────────────────────────────────────────────────
// Kontrol manual (dipanggil dari MQTT callback, mode="manual")
// ─────────────────────────────────────────────────────────────
void stirrer_trigger_now() { _startActivation(); }
void stirrer_force_stop()  { _stopActivation();  }

// ─────────────────────────────────────────────────────────────
// stirrer_loop()
// Non-blocking — dipanggil tiap iterasi loop() utama.
// ─────────────────────────────────────────────────────────────
void stirrer_loop() {
    unsigned long now = millis();

    if (!isRunning) {
        unsigned long intervalMs = (unsigned long)intervalMin * 60000UL;
        if (now - lastStirAt >= intervalMs) {
            lastStirAt = now;
            _startActivation();
        }
    } else {
        unsigned long durationMs = (unsigned long)durationSec * 1000UL;
        if (now - stirStartAt >= durationMs) {
            _stopActivation();
        }
    }
}

// ─────────────────────────────────────────────────────────────
// Getters — untuk publish status ke MQTT
// ─────────────────────────────────────────────────────────────
uint32_t stirrer_get_interval_min()   { return intervalMin; }
uint16_t stirrer_get_duration_sec()   { return durationSec; }
bool     stirrer_is_running()         { return isRunning; }
uint8_t  stirrer_get_last_direction() { return currentDir; }

uint32_t stirrer_get_next_run_in_ms() {
    if (isRunning) return 0;
    unsigned long intervalMs = (unsigned long)intervalMin * 60000UL;
    unsigned long elapsed    = millis() - lastStirAt;
    return (elapsed >= intervalMs) ? 0 : (uint32_t)(intervalMs - elapsed);
}