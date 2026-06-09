#ifndef SECRETS_H
#define SECRETS_H

// ── WiFi ──────────────────────────────────────────────────────
#define WIFI_SSID       "renggahalu2"
#define WIFI_PASSWORD   "renggasigma1"

// ── MQTT Broker ───────────────────────────────────────────────
// Lokal  : IP address PC/server yang menjalankan Mosquitto
// Cloud  : "broker.hivemq.com" atau "broker.emqx.io"
#define MQTT_BROKER     "97a04da693044074996c74c83148f611.s1.eu.hivemq.cloud"
#define MQTT_PORT       8883
#define MQTT_USERNAME   "AquaSense"   // kosongkan jika tidak pakai auth
#define MQTT_PASSWORD   "Minerva123"   // kosongkan jika tidak pakai auth

// ── Device Identity ───────────────────────────────────────────
#define MQTT_DEVICE_ID  "ESP32-DEVKIT-01"

#endif // SECRETS_H
