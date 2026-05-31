#ifndef TEMPERATURE_H
#define TEMPERATURE_H

#include <Arduino.h>

// Inisialisasi sensor DS18B20
void temperature_init();

// Baca suhu dalam Celsius, return -999.0 jika error
float temperature_read();

// Print hasil ke Serial
void temperature_print(float suhu);

#endif // TEMPERATURE_H