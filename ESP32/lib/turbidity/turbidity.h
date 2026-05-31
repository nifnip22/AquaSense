#ifndef TURBIDITY_H
#define TURBIDITY_H

#include <Arduino.h>
#include "config.h"

// ─── Wiring TSW-20M ─────────────────────────────────────────
//
//  Sisi Probe          Modul PCB          ESP32
//  ──────────────      ─────────────      ──────────────────────
//  Y (kuning)  ──┐     V  ────────── →    5V (VIN)
//  B (biru)    ──┤     G  ────────── →    GND
//  R (merah)   ──┘     A  → [divider] →   GPIO 34
//                      D  → (tidak dipakai)
//
//  Voltage Divider:
//    Modul AO → R1 (10kΩ) → GPIO 34 → R2 (22kΩ) → GND

// ─── Function Prototypes ─────────────────────────────────────
void  turbiditySetup();
void  turbidityLoop();

int   readAveragedADC(int pin, int samples);
float adcToVoltage(int adcValue);
float voltageToNTU(float volt);
float mapFloat(float x, float inMin, float inMax,
               float outMin, float outMax);
void  printTurbidityData();
void  evaluateWaterQuality(float ntu);

// ─── Extern Variabel ─────────────────────────────────────────
extern float turbidityNTU;
extern float voltage;
extern int   rawADC;

#endif