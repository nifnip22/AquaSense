#ifndef SECRETS_H
#define SECRETS_H

// ── WiFi ──────────────────────────────────────────────────────
#define WIFI_SSID       "ibal.2.4"
#define WIFI_PASSWORD   "ilhamkarjo123"

// ── MQTT Broker ───────────────────────────────────────────────
// Lokal  : IP address PC/server yang menjalankan Mosquitto
// Cloud  : "broker.hivemq.com" atau "broker.emqx.io"
#define MQTT_BROKER     "broker.hivemq.com"
#define MQTT_PORT       1883
#define MQTT_USERNAME   ""   // kosongkan jika tidak pakai auth
#define MQTT_PASSWORD   ""   // kosongkan jika tidak pakai auth

// ── Device Identity ───────────────────────────────────────────
#define MQTT_DEVICE_ID  "ESP32-DEVKIT-01"

#endif // SECRETS_H
