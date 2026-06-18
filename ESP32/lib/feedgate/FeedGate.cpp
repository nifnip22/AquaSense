#include "FeedGate.h"
#include <ESP32Servo.h>

// ── Private objects & state ───────────────────────────────────
static Servo          _servo;
static bool           _gateOpen   = false;
static unsigned long  _closeAtMs  = 0;   // 0 = tidak ada timer aktif

// ─────────────────────────────────────────────────────────────
// feedGate_init()
// ─────────────────────────────────────────────────────────────
void feedGate_init() {
    _servo.setPeriodHertz(50);   // servo analog standar: 50Hz
    _servo.attach(SERVO_FEEDER_PIN, SERVO_PULSE_MIN_US, SERVO_PULSE_MAX_US);

    feedGate_close();   // pastikan posisi awal SELALU tertutup

    Serial.println("[FeedGate] Servo MG996R siap.");
    Serial.printf("[FeedGate] Pin: GPIO%d | Closed: %d° | Open: %d°\n",
                  SERVO_FEEDER_PIN, SERVO_ANGLE_CLOSED, SERVO_ANGLE_OPEN);
}

// ─────────────────────────────────────────────────────────────
// feedGate_open() / feedGate_close()  — kontrol manual
// ─────────────────────────────────────────────────────────────
void feedGate_open() {
    _servo.write(SERVO_ANGLE_OPEN);
    _gateOpen = true;
    Serial.println("[FeedGate] 🟢 Gerbang TERBUKA");
}

void feedGate_close() {
    _servo.write(SERVO_ANGLE_CLOSED);
    _gateOpen  = false;
    _closeAtMs = 0;
    Serial.println("[FeedGate] 🔴 Gerbang TERTUTUP");
}

// ─────────────────────────────────────────────────────────────
// feedGate_openFor()
// Buka gerbang, lalu set timer kapan harus menutup sendiri.
// Durasi di-clamp ke SERVO_MIN_OPEN_SEC..SERVO_MAX_OPEN_SEC (safety).
// ─────────────────────────────────────────────────────────────
void feedGate_openFor(uint16_t durationSec) {
    if (durationSec < SERVO_MIN_OPEN_SEC) durationSec = SERVO_MIN_OPEN_SEC;
    if (durationSec > SERVO_MAX_OPEN_SEC) durationSec = SERVO_MAX_OPEN_SEC;

    feedGate_open();
    _closeAtMs = millis() + ((unsigned long)durationSec * 1000UL);

    Serial.printf("[FeedGate] ⏱ Akan menutup otomatis dalam %u detik\n", durationSec);
}

// ─────────────────────────────────────────────────────────────
// feedGate_loop()
// Panggil di SETIAP iterasi loop() utama. Non-blocking — tidak
// memakai delay(), hanya membandingkan millis() ke target waktu
// tutup. Jika gerbang dibuka manual (feedGate_open(), tanpa
// openFor), _closeAtMs tetap 0 sehingga TIDAK akan ditutup
// otomatis — harus ditutup manual lewat feedGate_close().
// ─────────────────────────────────────────────────────────────
void feedGate_loop() {
    if (_gateOpen && _closeAtMs != 0 && millis() >= _closeAtMs) {
        feedGate_close();
    }
}

// ─────────────────────────────────────────────────────────────
bool feedGate_isOpen() {
    return _gateOpen;
}

uint16_t feedGate_remainingSec() {
    if (!_gateOpen || _closeAtMs == 0) return 0;

    unsigned long now = millis();
    if (now >= _closeAtMs) return 0;

    return (uint16_t)((_closeAtMs - now) / 1000UL);
}