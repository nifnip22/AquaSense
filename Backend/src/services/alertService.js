// src/services/alertService.js
import { supabase } from '../db/supabase.js';

// ─────────────────────────────────────────────────────────────
// Periksa apakah ada alert aktif yang sama belum resolved
// untuk menghindari duplikat alert dalam waktu singkat
// ─────────────────────────────────────────────────────────────
async function hasPendingAlert(device_id, sensor_type, severity) {
  const { data } = await supabase
    .from('alerts')
    .select('id')
    .eq('device_id', device_id)
    .eq('sensor_type', sensor_type)
    .eq('severity', severity)
    .eq('resolved', false)
    .gte('created_at', new Date(Date.now() - 10 * 60 * 1000).toISOString()) // 10 menit terakhir
    .limit(1);

  return data && data.length > 0;
}

// ─────────────────────────────────────────────────────────────
// Buat alert baru
// ─────────────────────────────────────────────────────────────
export async function createAlert({ device_id, sensor_type, severity, message, value, unit }) {
  const duplicate = await hasPendingAlert(device_id, sensor_type, severity);
  if (duplicate) return null; // skip duplikat

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
// Auto-resolve alert jika kondisi kembali normal
// ─────────────────────────────────────────────────────────────
export async function resolveAlerts(device_id, sensor_type) {
  const { error } = await supabase
    .from('alerts')
    .update({ resolved: true, resolved_at: new Date().toISOString() })
    .eq('device_id', device_id)
    .eq('sensor_type', sensor_type)
    .eq('resolved', false);

  if (error) {
    console.error('[Alert] Gagal resolve alert:', error.message);
  }
}

// ─────────────────────────────────────────────────────────────
// Evaluasi dan dispatch alert berdasarkan status
// ─────────────────────────────────────────────────────────────
export async function processAlerts(device_id, reading) {
  const { temp_status, temperature, turbidity_status, turbidity_ntu, moisture_status, moisture_pct } = reading;

  // ── Temperature alerts ──
  if (temp_status === 'too_hot') {
    await createAlert({
      device_id, sensor_type: 'temperature', severity: 'warning',
      message: `Suhu terlalu tinggi: ${temperature}°C (max ${30}°C)`,
      value: temperature, unit: '°C'
    });
  } else if (temp_status === 'too_cold') {
    await createAlert({
      device_id, sensor_type: 'temperature', severity: 'warning',
      message: `Suhu terlalu rendah: ${temperature}°C (min ${25}°C)`,
      value: temperature, unit: '°C'
    });
  } else if (temp_status === 'normal') {
    await resolveAlerts(device_id, 'temperature');
  }

  // ── Turbidity alerts ──
  if (turbidity_status === 'danger') {
    await createAlert({
      device_id, sensor_type: 'turbidity', severity: 'danger',
      message: `Air terlalu keruh: ${turbidity_ntu?.toFixed(0)} NTU — segera ganti/filter air!`,
      value: turbidity_ntu, unit: 'NTU'
    });
  } else if (turbidity_status === 'warning' || turbidity_status === 'too_clear') {
    await createAlert({
      device_id, sensor_type: 'turbidity', severity: 'warning',
      message: turbidity_status === 'too_clear'
        ? `Air terlalu jernih: ${turbidity_ntu?.toFixed(0)} NTU — cek aerasi & plankton`
        : `Kekeruhan perlu dimonitor: ${turbidity_ntu?.toFixed(0)} NTU`,
      value: turbidity_ntu, unit: 'NTU'
    });
  } else if (turbidity_status === 'optimal') {
    await resolveAlerts(device_id, 'turbidity');
  }

  // ── Moisture alerts ──
  if (moisture_status === 'very_dry' || moisture_status === 'dry') {
    await createAlert({
      device_id, sensor_type: 'moisture', severity: 'warning',
      message: `Kelembapan rendah: ${moisture_pct?.toFixed(1)}%`,
      value: moisture_pct, unit: '%'
    });
  } else if (['moist', 'wet'].includes(moisture_status)) {
    await resolveAlerts(device_id, 'moisture');
  }
}
