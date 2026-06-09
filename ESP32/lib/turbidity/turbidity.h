#ifndef TURBIDITY_H
#define TURBIDITY_H

#include <Arduino.h>
#include "config.h"

// ─── Wiring TSW-20M ─────────────────────────────────────────
//
//  Sisi Probe         Modul PCB         ESP32
//  ─────────────      ─────────────     ──────────────────────
//  Y (kuning)  ──┐    V  ──────────  →  5V (VIN)
//  B (biru)    ──┤    G  ──────────  →  GND
//  R (merah)   ──┘    A  → [divider] →  GPIO 32
//                     D  → tidak dipakai
//
//  Voltage Divider:
//    Modul AO → R1 (10kΩ) → GPIO 32 → R2 (22kΩ) → GND

// ─── Extern variabel (dibaca dari main/mqtt) ─────────────────
extern int rawADC;

// ─── Function Prototypes ─────────────────────────────────────
void turbiditySetup();
void turbidityLoop();

int  turbidity_read_averaged(int pin, int samples);
void turbidityPrint();
void turbidityEvaluate(int raw);

// ─── Getter API untuk MQTT ────────────────────────────────────
int  turbidity_get_raw();

#endif // TURBIDITY_H