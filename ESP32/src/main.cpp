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
static bool          feedSensorReady = false;

// ── Cache data sensor ─────────────────────────────────────────
static FeedData g_feed        = {};
static float    g_temperature = -999.0f;
static float    g_soil_pct    = -1.0f;
static int      g_soil_raw    = -1;
static int      g_turb_raw    = 0;

// ─────────────────────────────────────────────────────────────
void setup() {
    Serial.begin(9600);
    delay(500);

    Serial.println("============================================");
    Serial.println("  AquaSense — ESP32 DevKit V1 Booting...  ");
    Serial.println("  Sensors: DS18B20 | TSW-20M | VL53L0X    ");
    Serial.println("============================================");

    // Init semua sensor
    temperature_init();
    soil_init();
    turbiditySetup();

    feedSensorReady = feedLevel_init();
    if (!feedSensorReady) {
        Serial.println("[FEED] !! VL53L0X gagal init — feed level tidak akan dipublish.");
    }

    // Init koneksi WiFi + MQTT
    mqtt_manager_setup();

    Serial.println("[Main] Setup selesai. Mulai loop...\n");
}

// ─────────────────────────────────────────────────────────────
void loop() {
    unsigned long now = millis();

    // ── Jaga koneksi MQTT ─────────────────────────────────────
    mqtt_manager_loop();

    // ── Baca Suhu (setiap TEMP_READ_INTERVAL = 500ms) ─────────
    g_temperature = temperature_read();
    temperature_print(g_temperature);

    // ── Baca Turbiditas (internal timer TURBIDITY_READ_INTERVAL)
    // turbidityLoop() mengelola timing-nya sendiri secara non-blocking
    turbidityLoop();
    g_turb_raw = turbidity_get_raw();

    // ── Baca Level Pakan (setiap FEED_READ_INTERVAL = 5000ms) ──
    if (feedSensorReady && (now - lastFeedRead >= FEED_READ_INTERVAL)) {
        lastFeedRead = now;
        g_feed = feedLevel_read();
        feedLevel_print(g_feed);
    }

    // ── Publish ke MQTT (setiap MQTT_PUBLISH_INTERVAL = 5000ms)
    if (now - lastPublish >= MQTT_PUBLISH_INTERVAL) {
        lastPublish = now;

        if (g_temperature == -999.0f) {
            Serial.println("[Main] ⚠ Sensor suhu error — skip publish cycle ini.");
        } else {
            g_soil_raw = soil_read_raw();
            g_soil_pct = soil_read_percent();

            mqtt_publish_sensors(
                g_temperature,
                g_turb_raw,
                g_soil_pct,
                g_soil_raw,
                feedSensorReady ? g_feed.levelPercent  : -1.0f,
                feedSensorReady ? (int)g_feed.distanceMM : -1,
                feedSensorReady ? g_feed.sensorOK       : false
            );
        }
    }

    // Non-blocking delay — beri waktu untuk MQTT loop & sensor baca
    delay(TEMP_READ_INTERVAL); // 500ms
}