#ifndef MIXER_H
#define MIXER_H

#include <Arduino.h>
#include "config.h"

// ╔════════════════════════════════════════════════════════════╗
// ║        AquaSense — Mixer Module (Clock-Based Schedule)     ║
// ║                                                            ║
// ║  PRINSIP KERJA:                                            ║
// ║  - Jadwal dikirim dari app via MQTT command/mixer_schedules ║
// ║  - ESP32 cek jam NTP setiap menit                          ║
// ║  - Jika jam cocok dengan jadwal → mixer ON selama          ║
// ║    duration_min menit                                      ║
// ║  - App juga bisa toggle ON/OFF manual via command/mixer     ║
// ║                                                            ║
// ║  Hardware: relay 2CH + motor (sama dengan stirrer lama)    ║
// ║  Pin      : STIR_RELAY_CH1_PIN & STIR_RELAY_CH2_PIN        ║
// ║             (reuse dari config.h)                          ║
// ╚════════════════════════════════════════════════════════════╝

// Maksimum jadwal yang bisa disimpan di ESP32
#define MIXER_MAX_SCHEDULES     10

struct MixerSchedule {
    uint8_t hour;           // jam (0–23)
    uint8_t minute;         // menit (0–59)
    uint16_t duration_min;  // durasi mixer menyala (menit)
    bool    valid;          // true jika slot ini terisi
};

// ─── API Publik ───────────────────────────────────────────────

// Inisialisasi mixer (relay pin, NTP)
void mixer_init();

// Dipanggil tiap loop() — cek jadwal & matiin otomatis
void mixer_loop();

// ── Kontrol manual (dari MQTT command/mixer) ──────────────────
void mixer_turn_on(uint16_t duration_min);
void mixer_turn_off();

// ── Manajemen jadwal (dari MQTT command/mixer_schedules) ──────
// Hapus semua jadwal lama lalu set jadwal baru dari array JSON
// Contoh string: [{"time":"08:00","duration_min":15},...]
void mixer_set_schedules(const String& json_array);

// ── Getter status ─────────────────────────────────────────────
bool     mixer_is_on();
uint32_t mixer_remaining_sec();    // sisa waktu menyala (detik), 0 jika mati
uint8_t  mixer_schedule_count();   // jumlah jadwal aktif tersimpan

#endif // MIXER_H