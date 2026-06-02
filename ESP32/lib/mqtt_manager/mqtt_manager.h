#ifndef MQTT_MANAGER_H
#define MQTT_MANAGER_H

#include <Arduino.h>

// ── MQTT Topics ───────────────────────────────────────────────
#define MQTT_TOPIC_SENSORS  "aquasense/" MQTT_DEVICE_ID "/sensors"
#define MQTT_TOPIC_FEEDING  "aquasense/" MQTT_DEVICE_ID "/feeding"
#define MQTT_TOPIC_CMD_FEED "aquasense/" MQTT_DEVICE_ID "/command/feed"

// ── Interval ──────────────────────────────────────────────────
#define MQTT_PUBLISH_INTERVAL  5000   // ms — kirim data tiap 5 detik
#define WIFI_TIMEOUT_MS        15000  // ms — timeout koneksi WiFi

// ── API Publik ────────────────────────────────────────────────
void mqtt_manager_setup();
void mqtt_manager_loop();

bool mqtt_publish_sensors(float temperature,
                          int   turbidity_raw,
                          float moisture_pct,
                          int   moisture_raw,
                          float feed_level_pct,   // -1 jika sensor tidak ada
                          int   feed_distance_mm, // -1 jika sensor tidak ada
                          bool  feed_sensor_ok);

bool mqtt_publish_feeding(const char* trigger_type, int duration_sec);

bool mqtt_is_connected();

#endif // MQTT_MANAGER_H
