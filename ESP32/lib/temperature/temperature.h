#ifndef TEMPERATURE_H
#define TEMPERATURE_H

#include <Arduino.h>

// Inisialisasi sensor DS18B20 (Mengaktifkan mode hemat waktu / Asinkron)
void temperature_init();

// Baca suhu dalam Celsius (Non-blocking). Mengembalikan nilai float.
// Sesuai dengan panggilan di main.cpp: float suhu = temperature_read();
float temperature_read();

// Print hasil ke Serial beserta evaluasi ambang batas lokal
// Sesuai dengan panggilan di main.cpp: temperature_print(suhu);
void temperature_print(float suhu);

#endif // TEMPERATURE_H