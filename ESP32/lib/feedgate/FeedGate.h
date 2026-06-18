#ifndef FEED_GATE_H
#define FEED_GATE_H

#include <Arduino.h>
#include "config.h"

// ╔════════════════════════════════════════════════════════════╗
// ║       AquaSense — Feed Gate Module (Servo MG996R)         ║
// ║                                                            ║
// ║  PRINSIP KERJA:                                            ║
// ║  Servo memutar flap/penutup lubang pakan.                  ║
// ║   - SERVO_ANGLE_CLOSED → lubang tertutup (posisi standby)  ║
// ║   - SERVO_ANGLE_OPEN   → lubang terbuka, pakan jatuh       ║
// ║                                                            ║
// ║  feedGate_openFor(detik) membuka gerbang lalu MENUTUP      ║
// ║  SENDIRI setelah durasi tersebut berlalu — non-blocking,   ║
// ║  dicek lewat feedGate_loop() yang harus dipanggil setiap   ║
// ║  iterasi loop() di main.cpp.                               ║
// ╚════════════════════════════════════════════════════════════╝

// ─── API Publik ───────────────────────────────────────────────
void     feedGate_init();

// Kontrol manual langsung (tanpa timer otomatis)
void     feedGate_open();
void     feedGate_close();

// Buka selama N detik, lalu otomatis menutup sendiri (non-blocking)
void     feedGate_openFor(uint16_t durationSec);

// WAJIB dipanggil setiap loop() — mengecek apakah sudah waktunya menutup
void     feedGate_loop();

// ─── Status ─────────────────────────────────────────────────
bool     feedGate_isOpen();
uint16_t feedGate_remainingSec();   // sisa waktu terbuka (detik), 0 jika tertutup

#endif // FEED_GATE_H