#include <Arduino.h>
#include "config.h"
#include "temperature.h"
#include "SoilMoistureSensor.h"
#include "turbidity.h"
#include "FeedLevel.h"
#include "secrets.h"
#include "mqtt_manager.h"

// ── Timing ────────────────────────────────────────────────────
static unsigned long lastFeedRead = 0;
static unsigned long lastPublish  = 0;
static bool feedSensorReady       = false;

// ── Cache feed data ───────────────────────────────────────────
static FeedData g_feed = {};

// ─────────────────────────────────────────────────────────────
void setup() {
    Serial.begin(9600);
    Serial.println("=== AquaSense Booting ===");

    temperature_init();
    soil_init();
    turbiditySetup();

    feedSensorReady = feedLevel_init();
    if (!feedSensorReady) {
        Serial.println("[FEED] !! Sensor VL53L0X gagal init. Cek wiring!");
    }

    mqtt_manager_setup();
}

// ─────────────────────────────────────────────────────────────
void loop() {
    unsigned long now = millis();

    // Jaga koneksi MQTT tetap hidup
    mqtt_manager_loop();

    // ── Baca Suhu ─────────────────────────────────────────────
    float suhu = temperature_read();
    temperature_print(suhu);

    // ── Baca Kelembapan ───────────────────────────────────────
    float kelembapan = soil_read_averaged(10);
    soil_print(kelembapan);

    // ── Baca Turbiditas ───────────────────────────────────────
    // turbidityLoop() baca + simpan ke state internal
    // Getter dipakai untuk ambil nilai ke MQTT
    turbidityLoop();

    // ── Baca Level Pakan ──────────────────────────────────────
    if (feedSensorReady && (now - lastFeedRead >= FEED_READ_INTERVAL)) {
        lastFeedRead = now;
        g_feed = feedLevel_read();
        feedLevel_print(g_feed);
    }

    // ── Publish ke MQTT ───────────────────────────────────────
    if (now - lastPublish >= MQTT_PUBLISH_INTERVAL) {
        lastPublish = now;

        if (suhu == -999.0f) {
            Serial.println("[Main] Sensor suhu error — skip publish.");
        } else {
            mqtt_publish_sensors(
                suhu,
                turbidity_get_raw(),
                kelembapan,
                soil_read_raw(),
                feedSensorReady ? g_feed.levelPercent : -1.0f,
                feedSensorReady ? (int)g_feed.distanceMM : -1,
                feedSensorReady ? g_feed.sensorOK : false
            );
        }
    }

    delay(TEMP_READ_INTERVAL);
}
