#include "mqtt_manager.h"
#include "secrets.h"
#include "config.h"
#include "FeedGate.h"
#include "mixer.h"

#include <WiFiClientSecure.h>
#include <WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>

// ── Private objects ───────────────────────────────────────────
static WiFiClientSecure wifiClient;
static PubSubClient mqttClient(wifiClient);

// ── Forward declarations ──────────────────────────────────────
static void _wifi_connect();
static void _mqtt_connect();
static void _mqtt_callback(char* topic, byte* payload, unsigned int length);

// ─────────────────────────────────────────────────────────────
void mqtt_manager_setup() {
    Serial.println("[WiFi] Menghubungkan ke: " WIFI_SSID);
    _wifi_connect();

    wifiClient.setInsecure(); // testing, jangan pakai ini di produksi!

    mqttClient.setServer(MQTT_BROKER, MQTT_PORT);
    mqttClient.setCallback(_mqtt_callback);
    mqttClient.setKeepAlive(60);
    mqttClient.setBufferSize(512);

    _mqtt_connect();
}

// ─────────────────────────────────────────────────────────────
void mqtt_manager_loop() {
    if (WiFi.status() != WL_CONNECTED) {
        Serial.println("[WiFi] Koneksi terputus, reconnecting...");
        _wifi_connect();
    }

    if (!mqttClient.connected()) {
        Serial.println("[MQTT] Koneksi terputus, reconnecting...");
        _mqtt_connect();
    }

    mqttClient.loop();
}

// ─────────────────────────────────────────────────────────────
// mqtt_publish_sensors()
// feed_level_pct / feed_distance_mm = -1 jika sensor tidak ada
// ─────────────────────────────────────────────────────────────
bool mqtt_publish_sensors(float temperature,
                          float ph,
                          int   turbidity_raw,
                          float feed_level_pct,
                          int   feed_distance_mm,
                          bool  feed_sensor_ok) {
    if (!mqttClient.connected()) {
        Serial.println("[MQTT] Gagal publish: tidak terhubung.");
        return false;
    }

    JsonDocument doc;

    // ── Water sensors ─────────────────────────────────────────
    if (temperature == -999.0f) {
        Serial.println("[MQTT] ⚠️ Suhu error — temperature dikirim null");
        doc["temperature"] = nullptr;
    } else {
        doc["temperature"] = serialized(String(temperature, 2));
    }
    doc["ph"]             = serialized(String(ph, 2));
    doc["turbidity_raw"]  = turbidity_raw;

    // ── Feed level sensor ─────────────────────────────────────
    doc["feed_sensor_ok"] = feed_sensor_ok;
    if (feed_sensor_ok && feed_level_pct >= 0) {
        doc["feed_level_pct"]   = serialized(String(feed_level_pct, 1));
        doc["feed_distance_mm"] = feed_distance_mm;
    } else {
        doc["feed_level_pct"]   = nullptr;
        doc["feed_distance_mm"] = nullptr;
    }

    // ── Mixer status ──────────────────────────────────────────
    doc["mixer_on"]             = mixer_is_on();
    doc["mixer_remaining_sec"]  = mixer_remaining_sec();
    doc["mixer_schedule_count"] = mixer_schedule_count();
    // ── Metadata ──────────────────────────────────────────────
    doc["rssi"]      = WiFi.RSSI();
    doc["uptime_ms"] = millis();

    char payload[384];
    serializeJson(doc, payload);

    bool ok = mqttClient.publish(MQTT_TOPIC_SENSORS, payload, false);

    if (ok) {
        Serial.printf("[MQTT] ✅ Published → %s\n", MQTT_TOPIC_SENSORS);
        Serial.printf("       Payload: %s\n", payload);
    } else {
        Serial.println("[MQTT] ❌ Publish gagal!");
    }

    return ok;
}

// ─────────────────────────────────────────────────────────────
bool mqtt_publish_feeding(const char* trigger_type, int duration_sec) {
    if (!mqttClient.connected()) return false;

    JsonDocument doc;
    doc["trigger_type"] = trigger_type;
    doc["duration_sec"] = duration_sec;

    char payload[128];
    serializeJson(doc, payload);

    bool ok = mqttClient.publish(MQTT_TOPIC_FEEDING, payload, false);
    Serial.printf("[MQTT] Feeding event published: %s\n", ok ? "OK" : "GAGAL");
    return ok;
}

// ─────────────────────────────────────────────────────────────
bool mqtt_is_connected() {
    return mqttClient.connected();
}

// ─────────────────────────────────────────────────────────────
static void _wifi_connect() {
    WiFi.mode(WIFI_STA);
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

    unsigned long start = millis();
    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        Serial.print(".");
        if (millis() - start > WIFI_TIMEOUT_MS) {
            Serial.println("\n[WiFi] ❌ Timeout! Cek SSID/password.");
            return;
        }
    }

    Serial.printf("\n[WiFi] ✅ Terhubung! IP: %s | RSSI: %d dBm\n",
                  WiFi.localIP().toString().c_str(), WiFi.RSSI());
}

// ─────────────────────────────────────────────────────────────
static void _mqtt_connect() {
    uint8_t retries = 0;

    while (!mqttClient.connected() && retries < 3) {
        Serial.printf("[MQTT] Connecting ke %s:%d ...\n", MQTT_BROKER, MQTT_PORT);

        bool connected = (strlen(MQTT_USERNAME) > 0)
            ? mqttClient.connect(MQTT_DEVICE_ID, MQTT_USERNAME, MQTT_PASSWORD)
            : mqttClient.connect(MQTT_DEVICE_ID);

        if (connected) {
            Serial.println("[MQTT] ✅ Terhubung ke broker!");
            mqttClient.subscribe(MQTT_TOPIC_CMD_FEED);
            Serial.printf("[MQTT] 📡 Subscribe: %s\n", MQTT_TOPIC_CMD_FEED);
            mqttClient.subscribe(MQTT_TOPIC_CMD_STIR);
            Serial.printf("[MQTT] 📡 Subscribe: %s\n", MQTT_TOPIC_CMD_STIR);
            mqttClient.subscribe(MQTT_TOPIC_CMD_MIXER);
            Serial.printf("[MQTT] 📡 Subscribe: %s\n", MQTT_TOPIC_CMD_MIXER);
            mqttClient.subscribe(MQTT_TOPIC_CMD_MIXER_SCHEDULES);
            Serial.printf("[MQTT] 📡 Subscribe: %s\n", MQTT_TOPIC_CMD_MIXER_SCHEDULES);
        } else {
            Serial.printf("[MQTT] ❌ Gagal (rc=%d) Wifi=%d IP=%s, retry %d/3...\n",
                          mqttClient.state(), WiFi.status(), WiFi.localIP().toString().c_str(), retries + 1);
            delay(3000);
            retries++;
        }
    }
}

// ─────────────────────────────────────────────────────────────
static void _mqtt_callback(char* topic, byte* payload, unsigned int length) {
    char msg[length + 1];
    memcpy(msg, payload, length);
    msg[length] = '\0';

    Serial.printf("[MQTT] ← Pesan masuk | Topic: %s\n", topic);
    Serial.printf("[MQTT]   Payload: %s\n", msg);

    if (strcmp(topic, MQTT_TOPIC_CMD_FEED) == 0) {
        JsonDocument doc;
        DeserializationError err = deserializeJson(doc, msg);

        if (err) {
            Serial.println("[MQTT] JSON tidak valid!");
            return;
        }

        int duration_sec = doc["duration_sec"] | 3;
        Serial.printf("[MQTT] 🐟 Perintah FEEDING diterima! Durasi: %d detik\n", duration_sec);

        // TODO: aktifkan motor feeder
        // digitalWrite(PIN_FEEDER_MOTOR, HIGH);
        // delay(duration_sec * 1000);
        // digitalWrite(PIN_FEEDER_MOTOR, LOW);
        feedGate_openFor((uint16_t)duration_sec);

        mqtt_publish_feeding("remote", duration_sec);
    }
    else if (strcmp(topic, MQTT_TOPIC_CMD_MIXER) == 0) {
        JsonDocument doc;
        DeserializationError err = deserializeJson(doc, msg);

        if (err) {
            Serial.println("[MQTT] JSON tidak valid (mixer)!");
            return;
        }
        bool is_on = doc["is_on"] | false;
        uint16_t duration_min = doc["duration_min"] | 5;

        if (is_on) {
            mixer_turn_on(duration_min);
            Serial.printf("[MQTT] 🔀 Mixer ON selama %d menit (manual dari app).\n", duration_min);
        } else {
            mixer_turn_off();
            Serial.println("[MQTT] 🔀 Mixer OFF (manual dari app).");
        }
    }
    else if (strcmp(topic, MQTT_TOPIC_CMD_MIXER_SCHEDULES) == 0) {
        // Backend mengirim { "schedules": [{"time":"08:00","duration_min":15},...] }
        JsonDocument doc;
        DeserializationError err = deserializeJson(doc, msg);

        if (err || !doc["schedules"].is<JsonArray>()) {
            Serial.println("[MQTT] JSON tidak valid (mixer_schedules)!");
            return;
        }

        // Ekstrak array schedules lalu kirim ke mixer sebagai string JSON array
        String schedulesJson;
        serializeJson(doc["schedules"], schedulesJson);
        mixer_set_schedules(schedulesJson);
        Serial.println("[MQTT] 🔀 Jadwal mixer diupdate dari app.");
    }
}
