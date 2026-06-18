#ifndef MQTT_MANAGER_H
#define MQTT_MANAGER_H

#include <Arduino.h>

// ── MQTT Topics ───────────────────────────────────────────────
#define MQTT_TOPIC_SENSORS  "aquasense/" MQTT_DEVICE_ID "/sensors"
#define MQTT_TOPIC_FEEDING  "aquasense/" MQTT_DEVICE_ID "/feeding"
#define MQTT_TOPIC_CMD_FEED "aquasense/" MQTT_DEVICE_ID "/command/feed"
#define MQTT_TOPIC_CMD_STIR "aquasense/" MQTT_DEVICE_ID "/command/stir"
#define MQTT_TOPIC_CMD_MIXER "aquasense/" MQTT_DEVICE_ID "/command/mixer"
#define MQTT_TOPIC_CMD_MIXER_SCHEDULES "aquasense/" MQTT_DEVICE_ID "/command/mixer_schedules"

// ── Format payload MQTT_TOPIC_CMD_STIR (USULAN — konfirmasi ke BE) ─
// Mode jadwal:
//   {"mode":"schedule","interval_min":30,"duration_sec":10}
// Mode manual (tombol ON/OFF dari app):
//   {"mode":"manual","action":"on"}
//   {"mode":"manual","action":"off"}
//
// Nama field di atas masih usulan dari sisi firmware. Kalau BE
// temenmu sudah punya skema field yang berbeda, cukup sesuaikan
// nama key di _mqtt_callback() (mqtt_manager.cpp) — struktur
// logikanya tidak perlu diubah.

// ── Timing ────────────────────────────────────────────────────
#define MQTT_PUBLISH_INTERVAL  5000   // ms — kirim sensor data tiap 5 detik
#define WIFI_TIMEOUT_MS        15000  // ms — timeout koneksi WiFi

// ── API Publik ────────────────────────────────────────────────
void mqtt_manager_setup();
void mqtt_manager_loop();

/**
 * Publish data sensor ke broker MQTT.
 * 
 * @param temperature      Suhu air (°C), -999 jika error
 * @param turbidity_raw    Nilai ADC mentah turbidity (0–4095)
 * @param feed_level_pct   Level pakan (%), -1 jika sensor tidak ada
 * @param feed_distance_mm Jarak sensor ke pakan (mm), -1 jika tidak ada
 * @param feed_sensor_ok   true jika VL53L0X berhasil dibaca
 * @param ph                pH air, -1 jika error atau belum kalibrasi
 */
bool mqtt_publish_sensors(float temperature,
                          float ph,
                          int   turbidity_raw,
                          float feed_level_pct,
                          int   feed_distance_mm,
                          bool  feed_sensor_ok);

/**
 * Publish event feeding ke broker MQTT.
 * 
 * @param trigger_type  "scheduled" | "manual" | "remote"
 * @param duration_sec  Durasi motor aktif (detik)
 */
bool mqtt_publish_feeding(const char* trigger_type, int duration_sec);

bool mqtt_is_connected();

#endif // MQTT_MANAGER_H