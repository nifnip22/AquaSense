#include <Arduino.h>
#include "config.h"
#include "temperature.h"
#include "SoilMoistureSensor.h"
#include "turbidity.h"    // ← tambah ini

void setup() {
  Serial.begin(9600);
  Serial.println("=== AquaSense Booting ===");

  temperature_init();
  turbiditySetup();       // ← tambah ini
}

void loop() {
  float suhu = temperature_read();
  temperature_print(suhu);

  float kelembapan = soil_read_averaged(10);  // rata-rata 10 sampel
  soil_print(kelembapan);

  delay(TEMP_READ_INTERVAL);
  turbidityLoop();        // ← tambah ini

  delay(READ_INTERVAL);
}