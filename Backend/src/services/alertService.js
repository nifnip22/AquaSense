// src/services/alertService.js
import { supabase } from '../db/supabase.js';

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

export async function resolveAlerts(device_id, sensor_type) {
  const { error } = await supabase
    .from('alerts')
    .update({ resolved: true, resolved_at: new Date().toISOString() })
    .eq('device_id', device_id)
    .eq('sensor_type', sensor_type)
    .eq('resolved', false);

  if (error) console.error('[Alert] Gagal resolve alert:', error.message);
}

export async function processAlerts(device_id, reading) {
  const {
    temp_status, temperature,
    turbidity_status, turbidity_raw,
    moisture_status, moisture_pct,
    feed_status, feed_level_pct,
  } = reading;

  // ── Temperature ──
  if (temp_status === 'too_hot') {
    await createAlert({
      device_id, sensor_type: 'temperature', severity: 'warning',
      message: `Suhu terlalu tinggi: ${temperature}°C (max 30°C)`,
      value: temperature, unit: '°C',
    });
  } else if (temp_status === 'too_cold') {
    await createAlert({
      device_id, sensor_type: 'temperature', severity: 'warning',
      message: `Suhu terlalu rendah: ${temperature}°C (min 25°C)`,
      value: temperature, unit: '°C',
    });
  } else if (temp_status === 'normal') {
    await resolveAlerts(device_id, 'temperature');
  }

  // ── Turbidity (RAW ADC) ──
  if (turbidity_status === 'danger') {
    await createAlert({
      device_id, sensor_type: 'turbidity', severity: 'danger',
      message: `Air terlalu keruh: ADC ${turbidity_raw} — segera ganti/filter air!`,
      value: turbidity_raw, unit: 'ADC',
    });
  } else if (turbidity_status === 'warning' || turbidity_status === 'too_clear') {
    await createAlert({
      device_id, sensor_type: 'turbidity', severity: 'warning',
      message: turbidity_status === 'too_clear'
        ? `Air terlalu jernih: ADC ${turbidity_raw} — cek aerasi & plankton`
        : `Kekeruhan perlu dimonitor: ADC ${turbidity_raw}`,
      value: turbidity_raw, unit: 'ADC',
    });
  } else if (turbidity_status === 'optimal') {
    await resolveAlerts(device_id, 'turbidity');
  }

  // ── Moisture ──
  if (moisture_status === 'very_dry' || moisture_status === 'dry') {
    await createAlert({
      device_id, sensor_type: 'moisture', severity: 'warning',
      message: `Kelembapan rendah: ${moisture_pct?.toFixed(1)}%`,
      value: moisture_pct, unit: '%',
    });
  } else if (['moist', 'wet'].includes(moisture_status)) {
    await resolveAlerts(device_id, 'moisture');
  }

  // ── Feed Level ──
  if (feed_status === 'empty') {
    await createAlert({
      device_id, sensor_type: 'feed_level', severity: 'danger',
      message: `Pakan HABIS: ${feed_level_pct?.toFixed(1)}% — segera isi!`,
      value: feed_level_pct, unit: '%',
    });
  } else if (feed_status === 'critical') {
    await createAlert({
      device_id, sensor_type: 'feed_level', severity: 'warning',
      message: `Pakan kritis: ${feed_level_pct?.toFixed(1)}% — siapkan pakan!`,
      value: feed_level_pct, unit: '%',
    });
  } else if (['low', 'adequate', 'full'].includes(feed_status)) {
    await resolveAlerts(device_id, 'feed_level');
  }
}
