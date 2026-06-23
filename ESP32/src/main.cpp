#include <Arduino.h>
#include "config.h"
#include "temperature.h"
#include "turbidity.h"
#include "FeedLevel.h"
#include "FeedGate.h"
#include "ph_sensor.h"
#include "secrets.h"
#include "mqtt_manager.h"
#include "mixer.h"

// ── Timing ────────────────────────────────────────────────────
static unsigned long lastFeedRead = 0;
static unsigned long lastPublish  = 0;
static bool feedSensorReady       = false;

// ── Cache feed data ───────────────────────────────────────────
static FeedData g_feed = {};

// ─────────────────────────────────────────────────────────────
void setup() {
    Serial.begin(9600);
    delay(500);
    Serial.println("============================================");
    Serial.println("  AquaSense — ESP32 DevKit V1 Booting...  ");
    Serial.println("  Sensors: DS18B20 | TSW-20M | VL53L0X    ");
    Serial.println("  Aktuator: Servo MG996R (Feed Gate)      ");
    Serial.println("============================================");

    temperature_init();
    turbiditySetup();
    ph_init();
    ph_calibrate(3.05f, 2.63f);

    feedSensorReady = feedLevel_init();
    if (!feedSensorReady) {
        Serial.println("[FEED] !! VL53L0X gagal init — feed level tidak akan dipublish.");
    }
 
    // Init gerbang pakan — selalu mulai dalam posisi TERTUTUP
    feedGate_init();
 
    // Init koneksi WiFi + MQTT
    mqtt_manager_setup();

    // Init mixer relay + NTP + jadwal dari NVS
    mixer_init();
 
    Serial.println("[Main] Setup selesai. Mulai loop...\n");
}

// ─────────────────────────────────────────────────────────────
void loop() {
    unsigned long now = millis();

    // Jaga koneksi MQTT tetap hidup
    mqtt_manager_loop();

    // Cek timer OFF mixer + jadwal otomatis
    mixer_loop();

    // ── Cek timer gerbang pakan (auto-close setelah durasi habis)
    feedGate_loop();

    // ── Baca Suhu ─────────────────────────────────────────────
    float suhu = temperature_read();
    temperature_print(suhu);

    // ── Baca Turbiditas ───────────────────────────────────────
    turbidityLoop();
    
    if (!turbidity_is_healthy()) {
        Serial.println("[Main] ⚠️ Turbidity sensor: unhealthy state detected!");
    }
    
    // Cek anomali (optional: bisa trigger alert ke backend)
    if (turbidity_is_anomaly()) {
        Serial.printf("[Main] ⚠️ Turbidity anomaly: trend=%d, value=%d\n", 
                      turbidity_get_trend(), turbidity_get_filtered());
        turbidity_reset_anomaly();  // Reset flag setelah handle
    }

    // ── Baca Level Pakan ──────────────────────────────────────
    if (feedSensorReady && (now - lastFeedRead >= FEED_READ_INTERVAL)) {
        lastFeedRead = now;
        g_feed = feedLevel_read();
        feedLevel_print(g_feed);
    }

    // ── Baca pH ───────────────────────────────────────────────
    static float    g_ph          = 7.0f;
    static unsigned long lastPhRead = 0;
    if (now - lastPhRead >= PH_READ_INTERVAL) {
        lastPhRead = now;
        g_ph = ph_read();
        ph_print(g_ph);
    }

    // ── Publish ke MQTT ───────────────────────────────────────
    // Gunakan filtered value (moving average) daripada raw untuk:
    // - Stabilitas data di backend
    // - Mengurangi noise dari sensor
    // - Lebih akurat untuk decision making
    if (now - lastPublish >= MQTT_PUBLISH_INTERVAL) {
        lastPublish = now;
        mqtt_publish_sensors(
            suhu,
            g_ph,
            turbidity_get_filtered(),
            feedSensorReady ? g_feed.levelPercent : -1.0f,
            feedSensorReady ? (int)g_feed.distanceMM : -1,
            feedSensorReady ? g_feed.sensorOK : false
        );
    }    
    

    delay(TEMP_READ_INTERVAL);
}
