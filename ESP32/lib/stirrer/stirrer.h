#ifndef STIRRER_H
#define STIRRER_H

#include <Arduino.h>
#include "config.h"

// ╔════════════════════════════════════════════════════════════╗
// ║     AquaSense — Feed Stirrer Module (2-Relay Reversing)    ║
// ║  Fungsi   : Mengaduk pakan secara berkala agar tidak lembap║
// ║  Aktuator : Motor power window 12V, arah bolak-balik lewat ║
// ║             2 channel relay (CH1 = arah A, CH2 = arah B)  ║
// ║  Jadwal   : interval & durasi diatur dari app lewat MQTT, ║
// ║             disimpan ke NVS (Preferences) agar tetap      ║
// ║             setelah ESP32 restart                          ║
// ║                                                              ║
// ║  CATATAN  : versi ini BELUM pakai dioda flyback tambahan  ║
// ║  (keputusan: prototype/testing). Kalau nanti dipasang     ║
// ║  permanen, disarankan tambah dioda di kedua terminal motor║
// ║  untuk mengurangi keausan kontak relay.                    ║
// ╚════════════════════════════════════════════════════════════╝

enum StirDirection : uint8_t {
    STIR_DIR_A = 0,
    STIR_DIR_B = 1
};

// ─── API Publik ─────────────────────────────────────────────
void stirrer_init();
void stirrer_loop();

// Jadwal otomatis — dipanggil dari MQTT callback (mode="schedule")
void stirrer_set_schedule(uint32_t intervalMin, uint16_t durationSec);

// Kontrol manual — dipanggil dari MQTT callback (mode="manual")
void stirrer_trigger_now();   // ON manual / juga dipakai internal saat jadwal jatuh
void stirrer_force_stop();    // OFF manual (paksa berhenti kalau sedang jalan)

// Getter — dipakai untuk publish status ke app lewat MQTT
uint32_t stirrer_get_interval_min();
uint16_t stirrer_get_duration_sec();
bool     stirrer_is_running();
uint8_t  stirrer_get_last_direction(); // 0 = arah A, 1 = arah B
uint32_t stirrer_get_next_run_in_ms();

#endif // STIRRER_H