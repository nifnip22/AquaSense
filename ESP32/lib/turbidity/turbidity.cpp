#include "turbidity.h"

// ╔════════════════════════════════════════════════════════════╗
// ║         AquaSense — Turbidity Module (TSW-20M) v2.0       ║
// ║  Optimasi: Edge Computing, Stabilitas, Error Handling     ║
// ║  Supply  : 5V ke modul                                     ║
// ║  Output  : AO → voltage divider (10kΩ/22kΩ) → GPIO 35     ║
// ║  ADC     : 12-bit, atenuasi 11db, Vref 5.0V                ║
// ║  Mode    : Median Filter + Moving Average + Trend Detection║
// ╚════════════════════════════════════════════════════════════╝

// ─── Private State Management ────────────────────────────────
static TurbidityData_t turbData = {
    .raw = 0,
    .filtered = 0,
    .trend = 0,
    .anomaly = false,
    .readFailures = 0,
    .lastReadTime = 0,
    .isHealthy = false
};

// ─── Moving Average Buffer (Edge Computing) ──────────────────
static int adc_buffer[TURBIDITY_BUFFER_SIZE] = {0};
static int buffer_index = 0;
static bool buffer_full = false;

// ─── Calibration ────────────────────────────────────────────
static int calibrationOffset = TURBIDITY_CALIBRATION_OFFSET;

// ─── Previous state untuk Hysteresis ─────────────────────────
static int prev_status = -1;  // Status evaluasi sebelumnya
static int prev_filtered = 0; // Nilai filter sebelumnya untuk trend

// ─── Timing ──────────────────────────────────────────────────
static unsigned long lastRead = 0;

// ─── Forward Declarations ────────────────────────────────────
bool turbidity_validate_reading(int raw);
int  turbidity_read_raw_samples(int pin, int samples);
int  turbidity_apply_median_filter(int* buffer, int size);
void turbidity_update_buffer(int newValue);
void turbidity_detect_anomaly(int newValue);
void turbidity_detect_trend();

// ═════════════════════════════════════════════════════════════
// ░░░░░░░░░░░░░░░░ INITIALIZATION & SETUP ░░░░░░░░░░░░░░░░
// ═════════════════════════════════════════════════════════════

void turbiditySetup() {
    analogReadResolution(12);
    analogSetPinAttenuation(TURBIDITY_AO_PIN, ADC_11db);

    // Initialize buffer
    memset(adc_buffer, 0, sizeof(adc_buffer));
    buffer_index = 0;
    buffer_full = false;

    Serial.println("\n╔════════════════════════════════════════════╗");
    Serial.println("║  AquaSense - Turbidity Sensor v2.0        ║");
    Serial.println("║  TSW-20M + Edge Computing                 ║");
    Serial.println("╚════════════════════════════════════════════╝");
    Serial.printf("  ADC Pin       : GPIO%d\n", TURBIDITY_AO_PIN);
    Serial.printf("  Resolution    : 12-bit (0-4095)\n");
    Serial.printf("  Buffer Size   : %d samples (edge computing)\n", TURBIDITY_BUFFER_SIZE);
    Serial.printf("  Median Window : %d samples (outlier rejection)\n", TURBIDITY_MEDIAN_WINDOW);
    Serial.printf("  Anomaly Threshold: ±%d ADC\n", TURBIDITY_ANOMALY_THRESHOLD);
    Serial.printf("  Optimal Range : %d — %d ADC\n",
                  TURBIDITY_RAW_OPTIMAL_MIN, TURBIDITY_RAW_OPTIMAL_MAX);
    Serial.println("────────────────────────────────────────────");
    
    turbData.isHealthy = false;
    turbData.readFailures = 0;
    
    Serial.println("[Turbidity] Setup complete.\n");
}

// ═════════════════════════════════════════════════════════════
// ░░░░░░░░░░░░░░░░ MAIN LOOP (Edge Computing) ░░░░░░░░░░░░░░
// ═════════════════════════════════════════════════════════════

void turbidityLoop() {
    unsigned long now = millis();

    if (now - lastRead >= TURBIDITY_READ_INTERVAL) {
        lastRead = now;
        
        // 1. Baca sampel mentah dengan median filter
        int rawSample = turbidity_read_raw_samples(TURBIDITY_AO_PIN, TURBIDITY_NUM_SAMPLES);
        
        // 2. Validasi data
        if (turbidity_validate_reading(rawSample)) {
            // 3. Tambah ke buffer (edge computing)
            turbidity_update_buffer(rawSample);
            
            // 4. Deteksi anomali
            turbidity_detect_anomaly(rawSample);
            
            // 5. Hitung trend
            turbidity_detect_trend();
            
            // 6. Reset error counter
            turbData.readFailures = 0;
            turbData.isHealthy = true;
        } else {
            // Sensor error atau data invalid
            turbData.readFailures++;
            if (turbData.readFailures >= TURBIDITY_MAX_READ_FAILURES) {
                turbData.isHealthy = false;
                Serial.printf("[Turbidity] !! ERROR: Sensor unhealthy (%d failures)\n", 
                              turbData.readFailures);
            }
        }
        
        // 7. Update timestamp
        turbData.lastReadTime = now;
        
        // 8. Print & Evaluate
        turbidityPrint();
        turbidityEvaluate(turbData.filtered);
        
        Serial.println("────────────────────────────────────────────");
    }
    
    // Timeout check
    if (millis() - turbData.lastReadTime > TURBIDITY_READ_TIMEOUT_MS) {
        if (turbData.isHealthy) {
            Serial.println("[Turbidity] !! WARNING: Read timeout");
            turbData.isHealthy = false;
        }
    }
}

// ═════════════════════════════════════════════════════════════
// ░░░░░░░░░░░░░░░░ RAW ADC READING ░░░░░░░░░░░░░░░░
// ═════════════════════════════════════════════════════════════

/**
 * Baca single ADC value dengan delay minimal
 */
int turbidity_read_single(int pin) {
    return analogRead(pin);
}

/**
 * Baca N sampel dan terapkan median filter untuk outlier removal
 * Lebih stabil dari rata-rata biasa karena tolerate outliers
 */
int turbidity_read_raw_samples(int pin, int samples) {
    if (samples <= 0 || samples > 20) {
        samples = TURBIDITY_NUM_SAMPLES;
    }
    
    // Buffer sementara untuk sorting
    int temp_buffer[20] = {0};
    
    // Baca sampel dengan delay antar sampling
    for (int i = 0; i < samples; i++) {
        temp_buffer[i] = analogRead(pin);
        delay(TURBIDITY_SAMPLE_INTERVAL);
    }
    
    // Terapkan median filter jika lebih dari 1 sampel
    if (samples > 1) {
        return turbidity_apply_median_filter(temp_buffer, samples);
    }
    
    return temp_buffer[0];
}

/**
 * Median filter: sortir dan ambil middle value
 * Lebih robust terhadap outliers dibanding average
 */
int turbidity_apply_median_filter(int* buffer, int size) {
    if (size <= 0) return 0;
    if (size == 1) return buffer[0];
    
    // Simple bubble sort (efficient untuk buffer kecil)
    int sorted[20];
    memcpy(sorted, buffer, size * sizeof(int));
    
    for (int i = 0; i < size - 1; i++) {
        for (int j = 0; j < size - i - 1; j++) {
            if (sorted[j] > sorted[j + 1]) {
                int temp = sorted[j];
                sorted[j] = sorted[j + 1];
                sorted[j + 1] = temp;
            }
        }
    }
    
    // Return median
    return sorted[size / 2];
}

/**
 * Validasi rentang ADC
 */
bool turbidity_validate_reading(int raw) {
    return (raw >= TURBIDITY_VALID_ADC_MIN && raw <= TURBIDITY_VALID_ADC_MAX);
}

// ═════════════════════════════════════════════════════════════
// ░░░░░░░░░░░░░░░░ EDGE COMPUTING ░░░░░░░░░░░░░░░░
// ═════════════════════════════════════════════════════════════

/**
 * Update moving average buffer (FIFO)
 * Digunakan untuk edge computing & trend detection
 */
void turbidity_update_buffer(int newValue) {
    adc_buffer[buffer_index] = newValue;
    buffer_index = (buffer_index + 1) % TURBIDITY_BUFFER_SIZE;
    
    if (buffer_index == 0) {
        buffer_full = true;
    }
    
    // Update filtered value = moving average
    int sum = 0;
    int count = buffer_full ? TURBIDITY_BUFFER_SIZE : buffer_index;
    
    for (int i = 0; i < count; i++) {
        sum += adc_buffer[i];
    }
    
    turbData.raw = newValue + calibrationOffset;
    turbData.filtered = sum / count;
}

/**
 * Deteksi anomali: sudden spike/drop dalam ADC
 * Gunakan untuk alert atau quality metrics
 */
void turbidity_detect_anomaly(int newValue) {
    if (buffer_full && prev_filtered > 0) {
        int delta = abs(newValue - prev_filtered);
        turbData.anomaly = (delta > TURBIDITY_ANOMALY_THRESHOLD);
        
        if (turbData.anomaly) {
            Serial.printf("[Turbidity] ⚠ ANOMALY DETECTED: Δ=%d (threshold=%d)\n", 
                          delta, TURBIDITY_ANOMALY_THRESHOLD);
        }
    }
    
    prev_filtered = turbData.filtered;
}

/**
 * Deteksi trend: data naik, turun, atau stabil
 * Gunakan untuk predictive analytics
 */
void turbidity_detect_trend() {
    if (!buffer_full || buffer_index < 3) {
        turbData.trend = 0;
        return;
    }
    
    // buffer_index adalah posisi seluler KOSONG untuk penulisan berikutnya
    // idx_new = 1 langkah ke belakang
    // idx_old = 4 langkah ke belakang (artinya 3 slot sebelum idx_new)
    
    int idx_new = (buffer_index - 1 + TURBIDITY_BUFFER_SIZE) % TURBIDITY_BUFFER_SIZE;
    int idx_old = (buffer_index - 4 + TURBIDITY_BUFFER_SIZE) % TURBIDITY_BUFFER_SIZE;
    
    int old_val = adc_buffer[idx_old];
    int new_val = adc_buffer[idx_new];
    
    int threshold = 50; // Hysteresis untuk trend
    
    if (new_val > old_val + threshold) {
        turbData.trend = 1;  // Naik
    } else if (new_val < old_val - threshold) {
        turbData.trend = -1; // Turun
    } else {
        turbData.trend = 0;  // Stabil
    }
}

/**
 * Get filtered value (moving average dari buffer)
 */
int turbidity_get_filtered() {
    return turbData.filtered;
}

/**
 * Get trend (-1, 0, +1)
 */
int turbidity_get_trend() {
    return turbData.trend;
}

/**
 * Check anomaly flag
 */
bool turbidity_is_anomaly() {
    return turbData.anomaly;
}

/**
 * Reset anomaly flag (setelah di-handle di main)
 */
void turbidity_reset_anomaly() {
    turbData.anomaly = false;
}

/**
 * Get sensor health status
 */
bool turbidity_is_healthy() {
    return turbData.isHealthy;
}

/**
 * Set calibration offset
 */
void turbidity_set_calibration(int offset) {
    calibrationOffset = offset;
    Serial.printf("[Turbidity] Calibration offset set to: %d\n", offset);
}

// ═════════════════════════════════════════════════════════════
// ░░░░░░░░░░░░░░░░ EVALUATION & REPORTING ░░░░░░░░░░░░░░░░
// ═════════════════════════════════════════════════════════════

/**
 * Print status sensor ke Serial
 */
void turbidityPrint() {
    Serial.println("[Turbidity] TSW-20M Reading:");
    Serial.printf("  Raw       : %d ADC\n", turbData.raw);
    Serial.printf("  Filtered  : %d ADC (moving avg)\n", turbData.filtered);
    Serial.printf("  Trend     : %s\n", 
                  turbData.trend == 1 ? "📈 Naik" : 
                  turbData.trend == -1 ? "📉 Turun" : "→ Stabil");
    Serial.printf("  Anomaly   : %s\n", turbData.anomaly ? "⚠️ YES" : "✓ No");
    Serial.printf("  Health    : %s\n", turbData.isHealthy ? "✓ Healthy" : "✗ ERROR");
    Serial.printf("  Failures  : %d/%d\n", turbData.readFailures, TURBIDITY_MAX_READ_FAILURES);
}

/**
 * Evaluasi kualitas air & status dengan HYSTERESIS
 * Gunakan filtered value, bukan raw, untuk stabilitas
 */
void turbidityEvaluate(int filtered) {
    Serial.print("  Status    : ");
    static int prev_eval_filtered = 0;
    
    int status = -1; // -1: danger, 0: warning, 1: optimal, 2: too clear
    
    // Evaluasi dengan hysteresis
    if (filtered >= TURBIDITY_RAW_CLEAR_MIN) {
        status = 2;
    } else if (filtered >= TURBIDITY_RAW_OPTIMAL_MIN && filtered <= TURBIDITY_RAW_OPTIMAL_MAX) {
        status = 1;
    } else if (filtered > TURBIDITY_RAW_WARNING_MAX && filtered < TURBIDITY_RAW_OPTIMAL_MIN) {
        status = 0;
    } else {
        status = -1;
    }
    
    // Apply hysteresis: only change if delta > TURBIDITY_HYSTERESIS
    if (prev_status != -1) {
        if (abs(filtered - prev_eval_filtered) < TURBIDITY_HYSTERESIS && prev_status != status) {
            status = prev_status;
        }
    }
    
    prev_status = status;
    prev_eval_filtered = filtered;
    
    // Print status dengan emoji
    switch (status) {
        case 2:
            Serial.println("[WARNING] 📊 Terlalu jernih — cek aerasi & plankton");
            break;
        case 1:
            Serial.println("[OK] ✓ OPTIMAL — Kondisi ideal untuk ikan nila");
            break;
        case 0:
            Serial.println("[WARNING] ⚠️ Agak keruh — monitor lebih sering");
            break;
        case -1:
            Serial.println("[DANGER] 🔴 Terlalu keruh! Segera filter/ganti air");
            break;
    }
}

// ═════════════════════════════════════════════════════════════
// ░░░░░░░░░░░░░░░░ GETTER API untuk MQTT ░░░░░░░░░░░░░░░░
// ═════════════════════════════════════════════════════════════

int turbidity_get_raw() {
    return turbData.raw;
}