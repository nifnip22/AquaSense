// src/services/alertService.js
import { supabase } from '../db/supabase.js';

// ─────────────────────────────────────────────────────────────
// Cek apakah alert yang sama sudah ada dalam 10 menit terakhir
// (mencegah duplikasi alert)
// ─────────────────────────────────────────────────────────────
async function hasPendingAlert(device_id, sensor_type, severity) {
    const { data } = await supabase
        .from('alerts')
        .select('id')
        .eq('device_id', device_id)
        .eq('sensor_type', sensor_type)
        .eq('severity', severity)
        .eq('resolved', false)
        .gte('created_at', new Date(Date.now() - 10 * 60 * 1000).toISOString())
        .limit(1);

    return data && data.length > 0;
}

// ─────────────────────────────────────────────────────────────
export async function createAlert({ device_id, sensor_type, severity, message, value, unit }) {
    const duplicate = await hasPendingAlert(device_id, sensor_type, severity);
    if (duplicate) return null;

    const { data, error } = await supabase
        .from('alerts')
        .insert([{ device_id, sensor_type, severity, message, value, unit }])
        .select()
        .single();

    if (error) {
        console.error('[Alert] Gagal insert alert:', error.message);
        return null;
    }

    console.warn(`[Alert] 🚨 ${severity.toUpperCase()} | ${sensor_type} | ${message}`);
    return data;
}

// ─────────────────────────────────────────────────────────────
export async function resolveAlerts(device_id, sensor_type) {
    const { error } = await supabase
        .from('alerts')
        .update({ resolved: true, resolved_at: new Date().toISOString() })
        .eq('device_id', device_id)
        .eq('sensor_type', sensor_type)
        .eq('resolved', false);

    if (error) console.error('[Alert] Gagal resolve alert:', error.message);
}

// ─────────────────────────────────────────────────────────────
// processAlerts()
// Dipanggil setiap kali data sensor masuk dari MQTT.
// Sensor yang dievaluasi: temperature | ph | turbidity | feed_level
// ─────────────────────────────────────────────────────────────
export async function processAlerts(device_id, reading) {
    const {
        temp_status,      temperature,
        ph_status,        ph,
        // ✅ Ganti turbidity_raw → turbidity_filtered sesuai field DB dan payload ESP32
        turbidity_status, turbidity_filtered,
        feed_status,      feed_level_pct,
    } = reading;

    // ── Temperature ──────────────────────────────────────────
    if (temp_status === 'too_hot') {
        await createAlert({
            device_id, sensor_type: 'temperature', severity: 'warning',
            message: `Suhu terlalu tinggi: ${temperature}°C (batas max ${process.env.TEMP_MAX ?? 30}°C)`,
            value: temperature, unit: '°C',
        });
    } else if (temp_status === 'too_cold') {
        await createAlert({
            device_id, sensor_type: 'temperature', severity: 'warning',
            message: `Suhu terlalu rendah: ${temperature}°C (batas min ${process.env.TEMP_MIN ?? 25}°C)`,
            value: temperature, unit: '°C',
        });
    } else if (temp_status === 'error') {
        await createAlert({
            device_id, sensor_type: 'temperature', severity: 'danger',
            message: 'Sensor suhu error / terputus!',
            value: temperature, unit: '°C',
        });
    } else if (temp_status === 'normal') {
        await resolveAlerts(device_id, 'temperature');
    }

    // ── pH Air ───────────────────────────────────────────────
    if (ph_status === 'too_high') {
        await createAlert({
            device_id, sensor_type: 'ph', severity: 'danger',
            message: `pH air terlalu tinggi: ${ph} — segera atasi!`,
            value: ph, unit: 'pH',
        });
    } else if (ph_status === 'too_low') {
        await createAlert({
            device_id, sensor_type: 'ph', severity: 'warning',
            message: `pH air terlalu rendah: ${ph} — cek dosing pH!`,
            value: ph, unit: 'pH',
        });
    } else if (ph_status === 'error') {
        await createAlert({
            device_id, sensor_type: 'ph', severity: 'danger',
            message: 'Sensor pH error / terputus!',
            value: ph, unit: 'pH',
        });
    } else if (ph_status === 'normal') {
        await resolveAlerts(device_id, 'ph');
    }

    // ── Turbidity ─────────────────────────────────────────────
    // ✅ Semua referensi ke turbidity_raw diganti turbidity_filtered
    if (turbidity_status === 'danger') {
        await createAlert({
            device_id, sensor_type: 'turbidity', severity: 'danger',
            message: `Air terlalu keruh: ADC ${turbidity_filtered} — segera ganti/filter air!`,
            value: turbidity_filtered, unit: 'ADC',
        });
    } else if (turbidity_status === 'warning') {
        await createAlert({
            device_id, sensor_type: 'turbidity', severity: 'warning',
            message: `Kekeruhan air perlu dimonitor: ADC ${turbidity_filtered}`,
            value: turbidity_filtered, unit: 'ADC',
        });
    } else if (turbidity_status === 'too_clear') {
        await createAlert({
            device_id, sensor_type: 'turbidity', severity: 'warning',
            message: `Air terlalu jernih: ADC ${turbidity_filtered} — cek aerasi & plankton`,
            value: turbidity_filtered, unit: 'ADC',
        });
    } else if (turbidity_status === 'optimal') {
        await resolveAlerts(device_id, 'turbidity');
    }

    // ── Feed Level ────────────────────────────────────────────
    if (feed_status === 'empty') {
        await createAlert({
            device_id, sensor_type: 'feed_level', severity: 'danger',
            message: `Pakan HABIS: ${feed_level_pct?.toFixed(1)}% — segera isi!`,
            value: feed_level_pct, unit: '%',
        });
    } else if (feed_status === 'critical') {
        await createAlert({
            device_id, sensor_type: 'feed_level', severity: 'warning',
            message: `Pakan kritis: ${feed_level_pct?.toFixed(1)}% — siapkan pakan segera!`,
            value: feed_level_pct, unit: '%',
        });
    } else if (feed_status === 'low') {
        await createAlert({
            device_id, sensor_type: 'feed_level', severity: 'warning',
            message: `Pakan hampir habis: ${feed_level_pct?.toFixed(1)}%`,
            value: feed_level_pct, unit: '%',
        });
    } else if (['adequate', 'full'].includes(feed_status)) {
        await resolveAlerts(device_id, 'feed_level');
    }
}