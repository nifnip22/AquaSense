#ifndef MQTT_MANAGER_H
#define MQTT_MANAGER_H

#include <Arduino.h>

// ── MQTT Topics ───────────────────────────────────────────────
#define MQTT_TOPIC_SENSORS  "aquasense/" MQTT_DEVICE_ID "/sensors"
#define MQTT_TOPIC_FEEDING  "aquasense/" MQTT_DEVICE_ID "/feeding"
#define MQTT_TOPIC_CMD_FEED "aquasense/" MQTT_DEVICE_ID "/command/feed"
#define MQTT_TOPIC_CMD_MIXER "aquasense/" MQTT_DEVICE_ID "/command/mixer"
#define MQTT_TOPIC_CMD_MIXER_SCHEDULES "aquasense/" MQTT_DEVICE_ID "/command/mixer_schedules"

#define MQTT_PUBLISH_INTERVAL  5000   // ms — kirim sensor data tiap 5 detik
#define WIFI_TIMEOUT_MS        15000  // ms — timeout koneksi WiFi

// ── API Publik ────────────────────────────────────────────────
void mqtt_manager_setup();
void mqtt_manager_loop();

/**
 * Publish data sensor ke broker MQTT.
 * 
 * @param temperature      Suhu air (°C), -999 jika error
 * @param ph                pH air, -1 jika error atau belum kalibrasi
 * @param turbidity_get_filtered  Nilai turbidity (ADC) setelah filter
 * @param feed_level_pct   Level pakan (%), -1 jika sensor tidak ada
 * @param feed_distance_mm Jarak sensor ke pakan (mm), -1 jika tidak ada
 * @param feed_sensor_ok   true jika VL53L0X berhasil dibaca
 */
bool mqtt_publish_sensors(float temperature,
                          float ph,
                          int   turbidity_get_filtered,
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