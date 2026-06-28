#include "FeedGate.h"
#include <ESP32Servo.h>

// ── Private objects & state ───────────────────────────────────
static Servo          _servo;
static bool           _gateOpen   = false;
static unsigned long  _openTimeMs = 0;   // Waktu mulai buka
static unsigned long  _durationMs = 0;   // Durasi target (ms)

// ─────────────────────────────────────────────────────────────
void feedGate_init() {
    _servo.setPeriodHertz(50);   // servo analog standar: 50Hz
    
    // Pastikan posisi awal SELALU tertutup, lalu matikan motor
    _servo.attach(SERVO_FEEDER_PIN, SERVO_PULSE_MIN_US, SERVO_PULSE_MAX_US);
    _servo.write(SERVO_ANGLE_CLOSED);
    delay(500);
    _servo.detach(); // Detach agar tidak ada arus bocor / jitter

    Serial.println("[FeedGate] Servo MG996R siap. (Mode Hemat Daya)");
    Serial.printf("[FeedGate] Pin: GPIO%d | Closed: %d° | Open: %d°\n",
                  SERVO_FEEDER_PIN, SERVO_ANGLE_CLOSED, SERVO_ANGLE_OPEN);
}

// ─────────────────────────────────────────────────────────────
void feedGate_open() {
    _servo.attach(SERVO_FEEDER_PIN, SERVO_PULSE_MIN_US, SERVO_PULSE_MAX_US);
    delay(30); // Beri jeda listrik stabil
    _servo.write(SERVO_ANGLE_OPEN);
    _gateOpen = true;
    Serial.println("[FeedGate] 🟢 Gerbang TERBUKA");
}

void feedGate_close() {
    if (!_servo.attached()) {
        _servo.attach(SERVO_FEEDER_PIN, SERVO_PULSE_MIN_US, SERVO_PULSE_MAX_US);
    }
    _servo.write(SERVO_ANGLE_CLOSED);
    delay(600); // Beri waktu 0.6 detik agar servo selesai berputar
    _servo.detach(); // Putuskan kuncian servo agar motor mati total
    _gateOpen = false;
    Serial.println("[FeedGate] 🔴 Gerbang TERTUTUP");
}

// ─────────────────────────────────────────────────────────────
void feedGate_openFor(uint16_t durationSec) {
    if (durationSec < SERVO_MIN_OPEN_SEC) durationSec = SERVO_MIN_OPEN_SEC;
    if (durationSec > SERVO_MAX_OPEN_SEC) durationSec = SERVO_MAX_OPEN_SEC;

    feedGate_open();
    _openTimeMs = millis();
    _durationMs = (unsigned long)durationSec * 1000UL;

    Serial.printf("[FeedGate] ⏱ Akan menutup otomatis dalam %u detik\n", durationSec);
}

// ─────────────────────────────────────────────────────────────
void feedGate_loop() {
    // Logika aman dari bug millis() overflow
    if (_gateOpen && _durationMs != 0 && (millis() - _openTimeMs >= _durationMs)) {
        feedGate_close();
        _durationMs = 0; // Reset
    }
}

// ─────────────────────────────────────────────────────────────
bool feedGate_isOpen() {
    return _gateOpen;
}